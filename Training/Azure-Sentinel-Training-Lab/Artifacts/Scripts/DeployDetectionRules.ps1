<#
.SYNOPSIS
    Deploys custom detection rules to Microsoft 365 Defender via the
    Microsoft Graph Security API (beta).

.DESCRIPTION
    Reads detection rule definitions from a JSON array file and creates each
    rule by POSTing to:
        POST https://graph.microsoft.com/beta/security/rules/detectionRules

    The script authenticates using a User-Assigned Managed Identity (UAMI)
    that must already have the CustomDetection.ReadWrite.All Graph permission.
    The UAMI client ID is read from an Automation Variable set by the ARM
    template, or can be passed as a parameter.

    Existing rules whose displayName already matches are skipped to keep the
    operation idempotent.

    Designed to run as an Azure Automation runbook before data-ingestion so
    that rules are already active when telemetry arrives.

.PARAMETER ManagedIdentityClientId
    Client ID of the User-Assigned Managed Identity. If omitted, the script
    reads it from the Automation Variable 'DetectionRulesManagedIdentityClientId'.

.PARAMETER RepoZipUrl
    URL of the repository zip archive. Defaults to the master branch.

.PARAMETER RepoRootName
    Folder name after extracting the zip (GitHub convention).

.PARAMETER RulesRelativePath
    Path inside the extracted repo to the rules JSON file.
#>
param(
    [string]$ManagedIdentityClientId,
    [string]$RepoZipUrl     = "https://github.com/kapetanios55/SentinelTrainingDemo/archive/refs/heads/master.zip",
    [string]$RepoRootName   = "SentinelTrainingDemo-master",
    [string]$RulesRelativePath = "Training/Azure-Sentinel-Training-Lab/Artifacts/DetectionRules/rules.json"
)

$ErrorActionPreference = "Stop"

# ── Resolve UAMI client ID ──────────────────────────────────────────────────
if (-not $ManagedIdentityClientId) {
    try {
        $raw = Get-AutomationVariable -Name 'DetectionRulesManagedIdentityClientId'
        $ManagedIdentityClientId = $raw.Trim().Trim('"')
    }
    catch {
        throw "ManagedIdentityClientId not provided and Automation Variable 'DetectionRulesManagedIdentityClientId' not found."
    }
}

Write-Output "Using Managed Identity Client ID: $ManagedIdentityClientId"

# ── Authenticate with User-Assigned Managed Identity ─────────────────────────
Import-Module Az.Accounts -ErrorAction Stop
Connect-AzAccount -Identity -AccountId $ManagedIdentityClientId | Out-Null

# Acquire a token for Microsoft Graph
$graphToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
$headers = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

# Retry settings for tables that may not exist yet (e.g., OktaV2_CL)
$retryMaxAttempts  = 6
$retryDelaySeconds = 300

# ── Download & extract repo ──────────────────────────────────────────────────
$workdir  = Join-Path -Path $env:TEMP -ChildPath "sentinel-training-demo"
$repoZip  = Join-Path -Path $workdir  -ChildPath "repo.zip"
$repoDir  = Join-Path -Path $workdir  -ChildPath $RepoRootName

if (-not (Test-Path -Path $workdir)) {
    New-Item -ItemType Directory -Path $workdir | Out-Null
}

Write-Output "Downloading repository archive..."
Invoke-WebRequest -Uri $RepoZipUrl -OutFile $repoZip
if (Test-Path -Path $repoDir) {
    Remove-Item -Recurse -Force $repoDir
}
Expand-Archive -Path $repoZip -DestinationPath $workdir -Force

# ── Load rule definitions ────────────────────────────────────────────────────
$rulesFile = Join-Path -Path $repoDir -ChildPath $RulesRelativePath
if (-not (Test-Path -Path $rulesFile)) {
    throw "Rules file not found: $rulesFile"
}

$rules = Get-Content -Path $rulesFile -Raw | ConvertFrom-Json
Write-Output "Loaded $($rules.Count) detection rule(s) from $RulesRelativePath"

# ── Fetch existing rules for idempotency ─────────────────────────────────────
$graphBaseUrl   = "https://graph.microsoft.com/beta/security/rules/detectionRules"

Write-Output "Fetching existing custom detection rules..."
$existingRules  = @()
$nextLink       = $graphBaseUrl

while ($nextLink) {
    $response  = Invoke-RestMethod -Uri $nextLink -Headers $headers -Method Get
    $existingRules += $response.value
    $nextLink  = $response.'@odata.nextLink'
}

$existingNames = $existingRules | ForEach-Object { $_.displayName }
Write-Output "Found $($existingRules.Count) existing rule(s)"

# ── Create rules ─────────────────────────────────────────────────────────────
$created = 0
$skipped = 0

foreach ($rule in $rules) {
    if ($rule.displayName -in $existingNames) {
        Write-Output "SKIP  : '$($rule.displayName)' already exists"
        $skipped++
        continue
    }

    $body = $rule | ConvertTo-Json -Depth 10 -Compress
    $queryText = $rule.queryCondition.queryText
    $requiresOktaTable = $queryText -match '\bOktaV2_CL\b'
    Write-Output "CREATE: '$($rule.displayName)' ..."

    $attempt = 1
    while ($true) {
        try {
            $result = Invoke-RestMethod -Uri $graphBaseUrl `
                -Headers $headers `
                -Method Post `
                -Body $body

            Write-Output "  -> Created with id $($result.id)"
            $created++
            break
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $detail     = $_.ErrorDetails.Message
            $isSyntaxError = $detail -match 'syntax errors'

            if ($requiresOktaTable -and $isSyntaxError -and $attempt -lt $retryMaxAttempts) {
                Write-Warning "  -> FAILED ($statusCode): $detail"
                Write-Output "  -> Waiting $retryDelaySeconds seconds for OktaV2_CL to appear (attempt $attempt/$retryMaxAttempts)..."
                Start-Sleep -Seconds $retryDelaySeconds
                $attempt++
                continue
            }

            Write-Warning "  -> FAILED ($statusCode): $detail"
            break
        }
    }
}

Write-Output "`nDone. Created: $created | Skipped: $skipped | Total in file: $($rules.Count)"
