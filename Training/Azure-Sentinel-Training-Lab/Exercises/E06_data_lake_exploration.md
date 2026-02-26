# Exercise 6 — Sentinel Data Lake Exploration

**Feature area:** Data lake exploration → KQL queries
**Portal:** [security.microsoft.com](https://security.microsoft.com)
**Difficulty:** Beginner / Intermediate

---

## Objective

Use the KQL query editor in the Microsoft Defender portal to run queries directly against the Microsoft Sentinel **data lake tier** — exploring historical data across multiple workspaces, using the schema browser, running asynchronous queries, and connecting via Azure Data Explorer.

---

## Background

The Microsoft Sentinel data lake stores long-term security data at a lower cost than the analytics tier. Instead of being limited to the 90-day hot window of the analytics tier, the data lake can retain up to **12 years** of data. You can query this data directly using the same KQL syntax you already know from Advanced Hunting and Log Analytics.

### Data lake vs analytics tier

| Capability | Analytics tier | Data lake tier |
|---|---|---|
| Query latency | Fast (indexed) | Slower (unindexed) |
| Retention | Up to 90 days (configurable) | Up to 12 years |
| Cost | Higher | Lower |
| Real-time detections | Yes | No |
| KQL support | Full | Full (with minor exceptions) |
| Multi-workspace | Via workspace() | Via union() / workspace() |

> **When to use the data lake:** Historical investigations, long-term trend analysis, compliance queries, and tables stored in data lake-only mode (e.g., `_CL` tables with archive-only retention).

### Custom table naming conventions

The schema browser groups tables by category. Custom tables follow these naming conventions:

| Suffix | Type |
|---|---|
| `_CL` | Custom log (REST/DCR ingestion) |
| `_KQL_CL` | KQL-derived custom table |
| `_SPARK` | Spark-populated table |
| `_SPARK_CL` | Spark custom log |

In this lab environment, third-party data sources such as Okta, CrowdStrike, MailGuard, and AWS are ingested as `_CL` tables.

---

## Steps

### Step 1 — Open the KQL query editor

1. In the Microsoft Defender portal, expand the **Microsoft Sentinel** section in the left navigation.
2. Select **Data lake exploration** → **KQL queries**.
3. The query editor opens with a blank query tab. Take a moment to identify the key UI areas:

| Area | Location | Purpose |
|---|---|---|
| Query editor | Centre | Write and run KQL |
| Schema browser | Left panel | Explore available tables and columns |
| Selected workspaces | Upper right | Choose one or more workspaces to query |
| Time range picker | Above editor | Set the query time window |
| Results window | Below editor | View query output |
| Query history | Tab bar | Access previously run queries |

> **Note:** Queries are scoped to the workspaces you select. If the schema browser shows no tables, check that the correct workspace is selected.

---

### Step 2 — Select workspaces and explore the schema

1. In the upper right corner, open the **Selected workspaces** dropdown.
2. Confirm your lab workspace is ticked.  
   > If multiple workspaces are selected, the `union()` operator is automatically applied to tables with the same name and schema. Use `workspace("WorkspaceName").TableName` to query a specific workspace explicitly.
3. In the **schema browser** on the left, scroll through the table categories:
   - **Assets** — asset tables from Azure Resource Graph (ARG) and Entra ID.
   - **Custom logs** — `_CL` tables from third-party connectors (e.g. `OktaV2_CL`, `CrowdStrikeDetections`)
4. Click any table name to expand its column list. Hover over a column to see its data type.
5. Use the **search box** at the top of the schema browser to find a specific table — try searching for `Okta`.

---

### Step 3 — Set the time range

1. Click the **time picker** above the query editor.
2. Select **Last 7 days** to cover the ingested lab data.
3. Note the **Custom time range** option — you can specify a precise start and end time, up to a 12-year window.

> **Service limits reminder:**  
> - Interactive queries timeout after **4 minutes** and return a maximum of **500,000 rows** or **64 MB**.  
> - When querying broad time ranges, filter early on `TimeGenerated` in your KQL to avoid hitting these limits.

You can also embed the time range directly in KQL:

```kusto
// Fixed range
| where TimeGenerated between (datetime(2025-01-01) .. datetime(2025-12-31))

// Relative range (last 90–180 days)
| where TimeGenerated between(ago(180d)..ago(90d))
```

---

### Step 4 — Run your first data lake query

Paste the following query into the editor and select **Run query** (or press `Shift+Enter`):

```kusto
OktaV2_CL
| where TimeGenerated > ago(7d)
| summarize Events = count() by EventOriginalType
| sort by Events desc
| take 20
```

This returns the top 20 Okta event types by volume over the last 7 days. Examine the results window:

- Use **Customize columns** to show or hide fields.
- Use **Show empty columns** to toggle empty fields.
- Use the **search box** in the results window to filter rows without re-running the query.
- Select **Export** (upper left of results) to download results as a CSV.

---

### Step 5 — Query multiple tables and compare sources

Run a cross-source query to see overall event volume by table:

```kusto
union OktaV2_CL, CrowdStrikeDetections, AWSCloudTrail, SEG_MailGuard_CL
| where TimeGenerated > ago(7d)
| summarize Events = count() by Type
| sort by Events desc
```

> If a table doesn't exist in your workspace, remove it from the `union` list.

(Optional) Try targeting a specific workspace explicitly (replace `MyWorkspace` with your actual workspace name):

```kusto
workspace("MyWorkspace").AWSCloudTrail
| where TimeGenerated > ago(7d)
| summarize Events = count() by EventName
| sort by Events desc
| take 10
```

---

### Step 6 — Explore out-of-the-box queries

1. Click the **Queries** tab in the query editor panel.
2. Browse the built-in query library — this includes queries for common scenarios such as security incident investigation, compliance reporting, and threat hunting.
3. Locate a query relevant to identity or cloud activity. Select the **...** icon next to a query and choose **Open in new tab** to load it into a query tab for editing.
4. Modify the time filter or table name if needed, then run it.

> Out-of-the-box queries are read-only templates. Any changes you make are in your own query tab — the template is not modified.

---

### Step 7 — Run an asynchronous query

Some data lake queries — particularly those spanning months or years — take longer than the 4-minute synchronous timeout. Asynchronous queries solve this by running on the server while you continue working.

1. Enter the following long-range query:

```kusto
AWSCloudTrail
| where TimeGenerated > ago(365d)
| summarize Events = count(), UniqueUsers = dcount(UserIdentityUserName) by bin(TimeGenerated, 1d)
| sort by TimeGenerated asc
```

2. Instead of clicking **Run query**, click the **down arrow** on the Run button and select **Run async query**.
3. Enter a name for the query, e.g. `AWS Annual Event Trend`, and submit it.
4. Open the **Async Queries** tab to monitor progress.
5. When the status shows **Completed**, select the query and click **Fetch results**.
   - Results are stored for **24 hours** and can be fetched multiple times.
   - You can export to CSV using the **Export** button.

> **Async query limits:**
>
> | Parameter | Limit |
> |---|---|
> | Concurrent async queries per tenant | 3 |
> | Execution timeout | 1 hour |
> | Result cache duration | 24 hours |
> | Query time range | Up to 12 years |

> **Tip:** If a synchronous query runs for more than 2 minutes, the portal will prompt you to switch it to an async query automatically.

---

### Step 8 — Use Query History

1. Click the **Query history** tab.
2. You should see all queries you have run during this session, along with processing time and completion state.
3. Select any previous query to open it in a new tab for editing or re-running.

> Query history is retained for **30 days**.

---

### Step 9 — Connect via Azure Data Explorer (optional)

The data lake can also be queried from **Azure Data Explorer (ADX)** for scenarios requiring its advanced analytics capabilities or integration with external ADX workflows.

1. Open Azure Data Explorer at [dataexplorer.azure.com](https://dataexplorer.azure.com).
2. Add a new connection using the URI:
   ```
   https://api.securityplatform.microsoft.com/lake/kql
   ```
3. When querying tables via ADX, use the `external_table()` function instead of referencing the table name directly:

```kusto
external_table("AWSCloudTrail")
| where TimeGenerated > ago(7d)
| take 100
```

> **Why `external_table()`?** Data lake tables are stored externally to the ADX cluster. The `external_table()` function instructs ADX to retrieve data from the lake storage rather than an indexed cluster shard.

---

## Key Takeaways

- The data lake tier extends retention up to 12 years at lower cost — ideal for historical investigations and compliance queries.
- KQL syntax is identical to the analytics tier, with a small number of unsupported functions (`adx()`, `arg()`, `externaldata()`, `ingestion_time()`).
- The **schema browser** shows all available tables grouped by category, including custom `_CL` tables.
- **Async queries** unlock long-running analysis beyond the 4-minute synchronous limit.
- **Multiple workspaces** can be queried in a single statement using `union()` or scoped with `workspace()`.
- Data lake queries are **billed separately** — avoid running wide-range queries without appropriate `TimeGenerated` filters.

---

## Query Considerations and Limitations

| Consideration | Detail |
|---|---|
| Query scope | Queries run only against selected workspaces |
| Billing | Data lake queries incur separate billing charges |
| Performance | Data lake queries are slower than analytics tier queries |
| Unsupported functions | `adx()`, `arg()`, `externaldata()`, `ingestion_time()` |
| Unsupported features | Custom/out-of-the-box functions; external data calls |
| Supported control commands | `.show version`, `.show databases`, `.show databases entities`, `.show database` |

---

## Next steps

Congratulations, you have completed this exercise! You can now continue to the next exercise:

- **[Exercise 7 — Sentinel data lake KQL Jobs](./E07_table_management.md)**

---

## Microsoft Learn References

- [Run KQL queries on the Microsoft Sentinel data lake](https://learn.microsoft.com/en-us/azure/sentinel/datalake/kql-queries)
- [Microsoft Sentinel data lake overview](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-lake-overview)
- [Onboarding to Microsoft Sentinel data lake](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-lake-onboarding)
- [Create jobs in the Microsoft Sentinel data lake](https://learn.microsoft.com/en-us/azure/sentinel/datalake/kql-jobs)
- [Manage data tiers and retention in Microsoft Defender portal](https://aka.ms/manage-data-defender-portal-overview)
- [Troubleshoot KQL queries in the Microsoft Sentinel data lake](https://learn.microsoft.com/en-us/azure/sentinel/datalake/kql-troubleshoot)
- [KQL overview](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)
