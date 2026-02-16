# Exercise 1 — Threat Intel IOC Matching Across Sources

**Rule:** `[E1] [Threat Intel] IOC Match Across Sources`
**File:** `detections/rules/exercise1_ti_ioc_match.json`
**MITRE ATT&CK:** T1566 (Phishing)
**Difficulty:** Beginner

---

## Objective

Learn how to correlate known Indicators of Compromise (IOCs) — IP addresses and file hashes — across **five heterogeneous data sources** using a single KQL `union` query.

## Background

Threat intelligence (TI) feeds provide lists of known-malicious IPs, domains, and file hashes. A core SOC capability is matching these IOCs against ingested log data to identify whether any known threats have touched the environment.

The Lab attack scenario uses specific IOCs that appear across multiple connectors:

| IOC Type | Value | Appears In |
|---|---|---|
| IP Address | `198.51.100.42` | Palo Alto, Okta, MailGuard |
| IP Address | `203.0.113.77` | AWS, Palo Alto |
| IP Address | `192.0.2.100` | CrowdStrike |
| SHA256 Hash | `e3b0c44298fc1c14...` | CrowdStrike |

> **Reference:** Review the full list in [`threat-intelligence/indicators.json`](../threat-intelligence/indicators.json)

## Techniques Covered

### KQL `union` Operator

The `union` operator combines rows from multiple tables into a single result set. Each sub-query projects a consistent schema so results can be meaningfully combined:

```kusto
union
    (TableA | where ... | project TimeGenerated, DataSource = "A", MatchedIOC, ...),
    (TableB | where ... | project TimeGenerated, DataSource = "B", MatchedIOC, ...),
    (TableC | where ... | project TimeGenerated, DataSource = "C", MatchedIOC, ...)
```

> **Key learning:** Each data source has different column names for the same concept (e.g., `SourceIP` in Palo Alto vs `SrcIpAddr` in Okta vs `SourceIpAddress` in AWS). The `project` operator normalises them into a common schema.

### IOC Matching with `in` Operator

```kusto
let ioc_ips = dynamic(["198.51.100.42", "203.0.113.77", "192.0.2.100"]);
CommonSecurityLog
| where SourceIP in (ioc_ips) or DestinationIP in (ioc_ips)
```

The `in` operator performs a case-sensitive membership test against a `dynamic` array. This is the simplest form of IOC matching without requiring an external TI platform integration.

### Entity Mapping

The query projects the following entity columns for automatic detection by Defender:

| Column | Entity Type | Role |
|---|---|---|
| `AccountUpn` | User | Impacted Asset |
| `DeviceName` | Device | Related Evidence |
| `RemoteIP` | IP | Related Evidence |
| `SHA256` | File | Related Evidence |

## Steps

### Step 1 — Review the Current Query

1. Open **Microsoft Defender XDR** → **Hunting** → **Custom detection rules**
2. Find `[E1] [Threat Intel] IOC Match Across Sources`
3. Click **Modify query** to open the query in Advanced Hunting
4. Run the query — note which data sources return matches

### Step 2 — Understand the Union Structure

Each branch of the union handles one data source:

| Data Source | Table | IP Column(s) | Hash Column |
|---|---|---|---|
| Palo Alto | `CommonSecurityLog` | `SourceIP`, `DestinationIP` | — |
| AWS | `AWSCloudTrail` | `SourceIpAddress` | — |
| Okta | `OktaV2_CL` | `SrcIpAddr` | — |
| MailGuard | `SEG_MailGuard_CL` | `SenderIP` | — |
| CrowdStrike | `CrowdStrikeDetections` | `Device.external_ip` | `Sha256` |

### Step 3 — Extend the Query (Challenge)

Try adding a **6th branch** to the union for `AWSCloudTrail` that matches on `UserIdentityAccessKeyId` against a list of compromised access keys:

```kusto
let ioc_keys = dynamic(["AKIAIOSFODNN7EXAMPLE"]);
// Add this branch to the union:
(AWSCloudTrail
| where TimeGenerated > ago(4h)
| where UserIdentityAccessKeyId in (ioc_keys)
| project TimeGenerated, DataSource = "AWS-Key",
    MatchedIOC = UserIdentityAccessKeyId, IOCType = "accesskey",
    Activity = EventName,
    SourceUserName = UserIdentityUserName,
    SourceHostName = "")
```

### Step 4 — Enable and Verify

1. After modifying the query, click **Save** (or re-deploy with `--rule exercise1_ti_ioc_match.json`)
2. Enable the rule
3. Wait for the next scheduled run (every 1 hour) or click **Run** to trigger immediately
4. Check **Triggered alerts** for IOC match alerts

## Key Takeaways

- `union` is the primary operator for cross-source correlation in Defender XDR
- Each data source requires its own `project` mapping to normalise column names
- IOC lists can be embedded as `dynamic` arrays or loaded from watchlists (see [Exercise 4](./E4_watchlist_integration.md))
- The `ReportId` column must be unique per event — use `hash_sha256(strcat(...))` to generate deterministic IDs

## Microsoft Learn References

- [union operator (KQL)](https://learn.microsoft.com/en-us/kusto/query/union-operator)
- [Advanced hunting schema tables](https://learn.microsoft.com/en-us/defender-xdr/advanced-hunting-schema-tables)
- [Custom detections overview](https://learn.microsoft.com/en-us/defender-xdr/custom-detections-overview)
