# Exercise 9 — Sentinel MCP Server Demo Prompts

These prompts are designed for Solutions Engineers to demonstrate the Microsoft Sentinel MCP Server capabilities during customer PoCs. Each prompt showcases a different MCP capability and maps to the PoCaaS attack scenario data.

> **Tip:** Paste these prompts directly into GitHub Copilot Chat (or any MCP-enabled AI assistant) with the Sentinel MCP server connected. The AI will call the appropriate MCP tools automatically.

---

## Prerequisites — Setting Up MCP in VS Code

Before running any of the prompts below, you need to connect VS Code to the Sentinel MCP server. The setup takes under a minute:

1. Open the Command Palette (`Ctrl + Shift + P`) → **MCP: Add Server** → choose **HTTP (HTTP or Server-Sent Events)**.
2. Enter the MCP server URL for the collection you want (see the table below).
3. Give it a friendly Server ID (e.g. `Sentinel Data Exploration`).
4. When prompted, **Allow** authentication — sign in with an account that has at least the **Security Reader** role.
5. Open **Copilot Chat** (`Ctrl + Alt + I`), switch to **Agent mode**, and confirm the MCP tools appear under the tools icon.

Repeat steps 1–3 for each collection you want to connect (Data Exploration + Triage recommended for PoCs).

> **Full step-by-step guide with screenshots:** [Use an MCP tool in Visual Studio Code — Microsoft Learn](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-use-tool-visual-studio-code)

---

## MCP Server Architecture — Three Tool Collections

The Sentinel MCP server is **not** just data lake querying. It exposes **three distinct tool collections**, each with its own server URL:

| Collection | Server URL | What It Does |
|---|---|---|
| **Data Exploration** | `https://sentinel.microsoft.com/mcp/data-exploration` | `search_tables`, `query_lake`, `analyze_user_entity`, `analyze_url_entity`, `list_sentinel_workspaces` — explore and query raw data in the Sentinel Data Lake |
| **Triage** | `https://sentinel.microsoft.com/mcp/triage` | `ListIncidents`, `GetIncidentById`, `ListAlerts`, `GetAlertByID`, `RunAdvancedHuntingQuery`, `GetDefenderFileInfo`, `GetDefenderIpAlerts`, `GetDefenderMachine`, `GetDefenderMachineAlerts`, `ListDefenderIndicators`, `ListDefenderInvestigations`, + more — direct API access to Defender XDR incidents, alerts, devices, files, IOCs, vulnerabilities, and automated investigations |
| **Security Copilot Agent Creation** | `https://sentinel.microsoft.com/mcp/security-copilot-agent-creation` | Create Security Copilot agents for complex workflows |

Additionally, **Sentinel Graph** provides unified graph analytics (attack paths, blast radius, graph-based hunting) — it auto-provisions when the Data Lake is enabled and powers experiences in the Defender portal. The graph is accessed through the Defender portal UI and through MCP's triage tools (incident graph, entity relationships).

> **For PoC demos:** Connect **both** the Data Exploration and Triage collections. The prompts below indicate which collection each prompt targets.

---

## 1 — Incident Triage & Prioritisation

**Collection:** Triage | **Tools:** `ListIncidents`, `GetIncidentById`, `ListAlerts`

> *"List the most recent security incidents in my tenant, sorted by severity. For the most critical one, pull its full details including all correlated alerts and their evidence. Which incident should I triage first and why?"*

**What the customer sees:** The MCP server calls `ListIncidents` to retrieve incidents directly from the Defender/Sentinel incident queue — the same API that powers the portal. It then calls `GetIncidentById` with alert data included. The AI reasons over the correlated alerts and recommends which incident to triage first based on severity, alert count, and MITRE coverage.

---

## 2 — Attack Timeline & Kill Chain Diagram

**Collection:** Data Exploration | **Tools:** `query_lake` (multi-table) + Mermaid rendering

> *"Build me a chronological attack timeline for the user mirage@pkwork.onmicrosoft.com by correlating security alerts across all data sources — CrowdStrike, Okta, AWS CloudTrail, Palo Alto, and MailGuard. Map each stage to the MITRE ATT&CK tactic and the data source that detected it. Then render the full kill chain as a Mermaid flow diagram, colour-coded by severity."*

**What the customer sees:** The AI queries `SecurityAlert`, `CrowdStrikeDetections`, `OktaV2_CL`, `AWSCloudTrail`, and `CommonSecurityLog`, building a unified timeline. It then renders a **Mermaid flowchart** showing: Phishing (MailGuard) → Payload Execution (CrowdStrike) → Credential Dump (CrowdStrike) → Account Takeover (Okta) → C2 Beaconing (Palo Alto) → Data Exfiltration (Palo Alto) → Cloud Attack (AWS). This is the single most impressive visual — a full kill chain diagram built live from real data.

---

## 3 — Cross-Source Threat Hunting

**Collection:** Data Exploration | **Tools:** `search_tables`, `query_lake`

> *"I want to threat-hunt across all my third-party data sources. First discover what tables are available, then for each source — CrowdStrike endpoint detections, Okta identity events, AWS CloudTrail activity, and Palo Alto firewall logs — summarise the most suspicious activity in the last 7 days. Which data source shows the most critical findings?"*

**What the customer sees:** The MCP server discovers all custom tables via `search_tables`, then queries each source in turn. It surfaces CrowdStrike credential dumps, Okta MFA manipulation and brute-force, AWS IAM escalation and CloudTrail disabling, and Palo Alto C2/exfiltration traffic. The AI ranks the sources by criticality. This demonstrates Sentinel's ability to ingest and query 5 third-party data sources through a single pane.

---

## 4 — User Entity Behaviour Analysis

**Collection:** Data Exploration | **Tools:** `analyze_user_entity`

> *"Run a full security analysis on the user mirage@pkwork.onmicrosoft.com. Check for anomalous behaviour, risk indicators, authentication anomalies, and any security incidents associated with this user over the last 7 days. Is this user compromised?"*

**What the customer sees:** The MCP server performs an asynchronous entity analysis, checking UEBA anomalies, sign-in patterns, associated incidents, and risk level across Entra ID, Identity Protection, and Sentinel incidents. It returns a verdict with supporting evidence — demonstrating how Sentinel provides a 360-degree user risk profile through AI.

---

## 5 — IOC & Entity Investigation (Domain + File)

**Collection:** Data Exploration + Triage | **Tools:** `analyze_url_entity`, `GetDefenderFileInfo`, `GetDefenderFileStatistics`, `GetDefenderFileRelatedMachines`, `ListDefenderIndicators`

> *"Investigate these two IOCs from our attack scenario: (1) Analyse the domain update-service-cdn.xyz — is it malicious, has it been seen in our environment, and what does threat intelligence say? (2) Look up the file hash e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 in Defender — get its prevalence, related alerts, and which devices have seen it. Also list any IOC indicators we've configured."*

**What the customer sees:** The AI uses **both** MCP collections — `analyze_url_entity` from Data Exploration checks the C2 domain against Microsoft TI, watchlists, and org prevalence; then the Triage tools query the Defender file APIs for hash details, device spread, and the IOC management API. This shows how MCP unifies Sentinel and Defender investigation surfaces in a single prompt.

---

## 6 — Entity Relationship Graph

**Collection:** Data Exploration | **Tools:** `query_lake` + Mermaid rendering

> *"For the active multi-stage incident in my Sentinel workspace, map out all the entities involved — users, hosts, IP addresses, domains, and file hashes. Show me a visual entity relationship graph that connects them, so I can see how the attacker pivoted through the environment. Render it as a Mermaid diagram."*

**What the customer sees:** The AI queries `SecurityAlert` and `SecurityIncident` to extract all entities (Mirage, win11a, attacker IPs, C2 domain, malicious file hash). It renders a **Mermaid entity relationship diagram** showing how each entity connects — the user on the host, the host to the C2 IP, the IP to the domain, and the phishing email delivering the file. This mimics the Sentinel Investigation Graph / Sentinel Graph blast radius capabilities, generated entirely through AI + MCP.

---

## 7 — Device Investigation & Lateral Movement

**Collection:** Triage | **Tools:** `GetDefenderMachine`, `GetDefenderMachineAlerts`, `GetDefenderMachineLoggedOnUsers`, `FindDefenderMachineByIp`, `ListUserRelatedMachines` + Mermaid rendering

> *"Investigate the compromised endpoint at IP 10.0.1.50. Get its full device profile from Defender — OS, health status, risk score, vulnerabilities. Then find who else has logged into that device, what other devices those users accessed, and whether any of those users have security alerts. Render the lateral movement paths as a Mermaid diagram."*

**What the customer sees:** The MCP server calls `FindDefenderMachineByIp` to identify win11a, `GetDefenderMachine` for full device metadata, `GetDefenderMachineLoggedOnUsers` for sign-in history, then `ListUserRelatedMachines` and `ListUserRelatedAlerts` for each user. It renders a **Mermaid graph** showing device → user → other devices → alerts. This demonstrates Sentinel Graph-style lateral movement tracing through the Defender APIs.

---

## 8 — Advanced Hunting (Defender XDR)

**Collection:** Triage | **Tools:** `FetchAdvancedHuntingTablesOverview`, `FetchAdvancedHuntingTablesDetailedSchema`, `RunAdvancedHuntingQuery`

> *"Using Defender advanced hunting, find all devices that communicated with IP address 192.0.2.100 in the last 7 days. First discover what hunting tables are available, then run the query. Show me the device names, connection timestamps, and data volumes."*

**What the customer sees:** The AI calls `FetchAdvancedHuntingTablesOverview` to discover Defender tables (DeviceNetworkEvents, etc.), `FetchAdvancedHuntingTablesDetailedSchema` for column details, then `RunAdvancedHuntingQuery` with the KQL. This is distinct from `query_lake` — it runs against the **Defender XDR hunting engine**, not the Sentinel Data Lake. The customer sees that MCP unifies both query surfaces.

---

## 9 — Alert Correlation & Severity Chart

**Collection:** Data Exploration | **Tools:** `query_lake` + Mermaid rendering

> *"Show me all security alerts from the last 7 days, grouped by alert name, severity, and data source. Sort by volume. For the top alert types, explain what attack stage they represent. Then render a visual chart showing alert distribution by data source and severity as a Mermaid diagram."*

**What the customer sees:** A breakdown of all `SecurityAlert` entries — CrowdStrike detections, TI IOC matches, C2 activity, AWS privilege escalation, phishing, credential dumps, and exfiltration alerts — mapped to MITRE stages. The AI then renders a **Mermaid chart** showing alert volumes by source with severity colour coding. This gives an at-a-glance security posture view.

---

## 10 — Data Source Health & Coverage

**Collection:** Data Exploration | **Tools:** `search_tables`, `query_lake`

> *"What third-party data sources are currently ingesting data into my Sentinel workspace? For each one — CrowdStrike, Okta, Palo Alto, AWS, and email security — tell me how many events have been ingested in the last 7 days and whether the data looks healthy. Render a Mermaid diagram showing the data flow from each source into Sentinel."*

**What the customer sees:** The MCP server discovers all custom tables via `search_tables` and queries each for record counts and time range. It then renders a **Mermaid architecture diagram** showing each data source flowing into Sentinel with event counts. This demonstrates data connector health monitoring and gives the customer confidence that everything is flowing.

---

## Quick Reference — MCP Capabilities Showcased

| # | Prompt | Collection | Tools Used | Visual? | Key Feature |
|---|--------|-----------|------------|---------|-------------|
| 1 | Incident Triage | Triage | `ListIncidents`, `GetIncidentById` | | Incident API access |
| 2 | Kill Chain Diagram | Data Exploration | `query_lake` + Mermaid | ✅ | Attack timeline + visual |
| 3 | Cross-Source Hunting | Data Exploration | `search_tables` + `query_lake` | | Multi-source threat hunting |
| 4 | User Analysis | Data Exploration | `analyze_user_entity` | | UEBA & risk profiling |
| 5 | IOC Investigation | Both | `analyze_url_entity` + `GetDefenderFile*` | | Entity + Defender APIs |
| 6 | Entity Graph | Data Exploration | `query_lake` + Mermaid | ✅ | Investigation graph |
| 7 | Device & Lateral Movement | Triage | `GetDefenderMachine*` + Mermaid | ✅ | Graph-style investigation |
| 8 | Advanced Hunting | Triage | `RunAdvancedHuntingQuery` | | Defender hunting engine |
| 9 | Alert Heatmap | Data Exploration | `query_lake` + Mermaid | ✅ | Alert distribution chart |
| 10 | Data Source Health | Data Exploration | `search_tables` + `query_lake` + Mermaid | ✅ | Connector health + arch diagram |

---

## References

- [Use an MCP tool in Visual Studio Code](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-use-tool-visual-studio-code) — setup guide
- [Tool collections in Microsoft Sentinel MCP server](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-tools-overview) — full tool reference
- [Get started with Microsoft Sentinel MCP server](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-get-started) — overview & prerequisites
- [Create and use custom Microsoft Sentinel MCP tools](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-create-custom-tool) — custom tool authoring

