# Welcome to Microsoft Sentinel Training Lab

<p align="center">
<img src="./Images/sentinel-labs-logo.png?raw=true">
</p>

## Introduction
These labs help you get ramped up with Microsoft Sentinel and provide hands-on practical experience for product features, capabilities, and scenarios. 

The lab deploys a Microsoft Sentinel workspace and ingests pre-recorded data to simulate scenarios that showcase various Microsoft Sentinel features. You should expect very little or no cost at all due to the size of the data (~10 MB), and the fact that Microsoft Sentinel offers a 30-day free trial on new workspaces.

## Prerequisites

Before you begin, make sure you have:

1. **Azure subscription** — If you don't have one, create a [free account](https://azure.microsoft.com/pricing/purchase-options/azure-account).
2. **Owner or Contributor role** on the target resource group (needed to create resources and assign RBAC roles during deployment).
3. **Microsoft Sentinel workspace onboarded to Microsoft Defender XDR** — The Log Analytics workspace must be connected to the [unified security operations platform (Defender XDR)](https://learn.microsoft.com/en-us/azure/sentinel/microsoft-sentinel-defender-portal) and set as the **primary workspace**. The [Onboarding exercise](./Exercises/Onboarding.md) walks you through this step by step.
4. **For the best experience**, enable [Microsoft Sentinel Data Lake](https://learn.microsoft.com/en-us/azure/sentinel/data-lake) on your workspace. This allows long-term, low-cost retention of security data and enables advanced hunting over extended time ranges.

## Custom Detection Rules Setup

This lab deploys **custom detection rules** to Microsoft Defender XDR via the Microsoft Graph Security API. The Automation runbook that creates the rules needs an identity with the `CustomDetection.ReadWrite.All` Microsoft Graph application permission. You can use **either** a User-Assigned Managed Identity (UAMI) **or** a Service Principal (App Registration) — pick the option that suits your environment.

> **Tip:** Leave all identity fields empty during deployment if you want to skip custom detection rules entirely.

Complete **one** of the two options below before deployment.

---

### Option A — User-Assigned Managed Identity (UAMI)

#### A1. Create the UAMI

```powershell
# Create the UAMI (adjust resource group and name as needed)
az identity create `
  --resource-group <your-resource-group> `
  --name SentinelDetectionRulesIdentity
```

#### A2. Grant the Microsoft Graph permission

```powershell
# Variables
$miObjectId   = (az identity show --resource-group <your-resource-group> --name SentinelDetectionRulesIdentity --query principalId -o tsv)
$graphAppId   = "00000003-0000-0000-c000-000000000000"   # Microsoft Graph
$appRoleId    = "e0fd9c8d-a12e-4cc9-9827-20c8c3cd6fb8"   # CustomDetection.ReadWrite.All

# Get the Microsoft Graph service principal
$graphSpId = (az ad sp show --id $graphAppId --query id -o tsv)

# Assign the app role to the managed identity
az rest --method POST `
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$graphSpId/appRoleAssignedTo" `
  --headers "Content-Type=application/json" `
  --body "{\"principalId\":\"$miObjectId\",\"resourceId\":\"$graphSpId\",\"appRoleId\":\"$appRoleId\"}"
```

#### A3. Deploy

Pass the UAMI's **full resource ID** as the `detectionRulesIdentityResourceId` parameter when deploying (in [Onboarding Exercise 8](./Exercises/Onboarding.md#exercise-8-deploy-the-microsoft-sentinel-training-lab-solution)):

```
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/SentinelDetectionRulesIdentity
```

---

### Option B — Service Principal (App Registration)

Use this option when you cannot create or use a Managed Identity (e.g., cross-tenant deployments or restricted RBAC environments).

#### B1. Create an App Registration

```powershell
# Create the app registration
az ad app create --display-name SentinelDetectionRulesSPN

# Note the appId (client ID) from the output
$appId = (az ad app list --display-name SentinelDetectionRulesSPN --query "[0].appId" -o tsv)

# Create a service principal for the app
az ad sp create --id $appId
```

#### B2. Grant the Microsoft Graph permission

```powershell
$spObjectId   = (az ad sp show --id $appId --query id -o tsv)
$graphAppId   = "00000003-0000-0000-c000-000000000000"   # Microsoft Graph
$appRoleId    = "e0fd9c8d-a12e-4cc9-9827-20c8c3cd6fb8"   # CustomDetection.ReadWrite.All

$graphSpId = (az ad sp show --id $graphAppId --query id -o tsv)

az rest --method POST `
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$graphSpId/appRoleAssignedTo" `
  --headers "Content-Type=application/json" `
  --body "{\"principalId\":\"$spObjectId\",\"resourceId\":\"$graphSpId\",\"appRoleId\":\"$appRoleId\"}"
```

> **Note:** Granting application permissions requires **Global Administrator** or **Privileged Role Administrator** in Microsoft Entra ID, or admin consent must be granted afterwards.

#### B3. Create a client secret

```powershell
az ad app credential reset --id $appId --append
# Save the "password" value — it will not be shown again.
```

#### B4. Deploy

During deployment, provide the following three parameters (leave the UAMI field empty):

| Parameter | Value |
|---|---|
| `detectionRulesSpnTenantId` | Your Microsoft Entra **Tenant ID** |
| `detectionRulesSpnClientId` | The **Application (client) ID** from step B1 |
| `detectionRulesSpnClientSecret` | The **client secret** from step B3 |

## Getting started

Start with the **Onboarding** exercise to set up your workspace, install solutions, and deploy the lab. Then work through Exercises 1–6 in order — each builds on the previous one.

## Exercises

[**Onboarding — Setting up the environment**](./Exercises/Onboarding.md)
- Create a Log Analytics workspace and onboard Microsoft Sentinel
- Install Content Hub solutions and set up data connectors
- Deploy the Training Lab solution

[**Exercise 1 — Threat Intel IOC Matching**](./Exercises/E1_threat_intel_ioc_matching.md)

[**Exercise 2 — Port Scan Threshold Tuning**](./Exercises/E2_port_scan_threshold_tuning.md)

[**Exercise 3 — Okta MFA Manipulation**](./Exercises/E3_okta_mfa_manipulation.md)

[**Exercise 4 — Watchlist Integration**](./Exercises/E4_watchlist_integration.md)

[**Exercise 5 — Data Lake Port Diversity**](./Exercises/E5_datalake_port_diversity.md)

[**Exercise 6 — Device Isolation Response**](./Exercises/E6_device_isolation_response.md)

---

## Reference

### Log ingestion (modern API)

The training lab includes a script that uses the Azure Monitor Logs Ingestion API to ingest **custom tables only** (tables ending with `_CL`). Built-in tables are not ingested by this API and should be populated via their native data connectors instead.

- Script: [Artifacts/Scripts/IngestCSV-LogsIngestionApi.ps1](Artifacts/Scripts/IngestCSV.ps1)
- Telemetry folders:
	- Custom: [Artifacts/Telemetry/Custom](Artifacts/Telemetry/Custom)
	- Built-in: [Artifacts/Telemetry/BuiltIn](Artifacts/Telemetry/BuiltIn)
- DCR templates output: [Artifacts/DCRTemplates](Artifacts/DCRTemplates)

This script:
- Scans the custom telemetry folder for CSV files ending in `_CL.csv`.
- Optionally scans the built-in telemetry folder when a built-in DCR immutable ID is provided.
- Generates a DCR template per custom table using the CSV schema.
- Optionally deploys the DCE/DCR resources and ingests the data.

See the script header for parameters and usage.

### Release notes

* Version 1.0 - Microsoft Sentinel Training Lab
