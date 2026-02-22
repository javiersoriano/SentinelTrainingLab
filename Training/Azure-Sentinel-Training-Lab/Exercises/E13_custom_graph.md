# Exercise 13 - Creating a Custom Graph in Microsoft Sentinel (Hands‑On, Step by Step)

As you saw in exercise 12, there are several native experiences to use Sentinel graph available in the Defender portal. However, users might want to be able to create their own custom graph representations for their own data.

This guide walks through how to create a **custom graph** in Microsoft Sentinel graph.  

> ⚠️ The setup is currently more manual, but this will become more “out-of-the-box” over time as the experience matures.

## Prerequisites

- GitHub Copilot setup in VSCode
- Signup for the Custom Graph and Graph MCP tools private preview [here](https://customervoice.microsoft.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR9i0TN7NE5lOkU0ftWbP3rlUMDkyWU9FRzJFV0dHTllPS0ZKUEhKSTZDVCQlQCN0PWcu) 

---

## 1. Setup

Follow these steps to get your environment ready:

- Open a new VSCode window and create a new folder called for this project. For example, "Vibe Graphing"
- Copy these two markdown files to your local machine
    - SDK API reference - [graph_builder_api_reference.md](../Artifacts/CustomGraph/graph_builder_api_reference.md)
    - Copilot instructions - [copilot-instructions.md](../Artifacts/CustomGraph/copilot-instructions.md). 
    ![VibeGraphing1](../Images/VibeGraphing1.jpg)
    - Open copilot-instructions.md file after you copy it locally and go to line 356. Change the path to point to your local copy of the graph builder doc from previous step(see image below)
    ![VibeGraphing2](../Images/VibeGraphing2.jpg)

These two files instruct GitHub Copilot how to create a custom graph using a Jupyter Notebook.

## 2. Create custom graph notebook

1. Open a new Github Copilot chat.
2. Write this prompt:

> *"Query each table for the last 2 days of data and identify evidence of a multi-stage attack kill chain — look for brute force or credential-based logon activity, successful logons to machines, EDR alerts with MITRE ATT&CK tactics, and outbound network connections being blocked by the firewall. Based on what you actually find, build a graph notebook that connects accounts to the machines they targeted, machines to the alerts they triggered, alerts to their MITRE tactics, and machines to blocked outbound destinations — so I can trace the full attack path from initial access through to impact."*

3. GitHub Copilot will start building the notebook for you. This will take a few minutes.
4. Once it finishes, review the output and click "Keep" if you're happy with the results

## 3. Execute custom graph notebook

Run each cell in the notebook and review the outputs.

---

## Next steps

Congratulations, you have completed all exercises in this lab! You've explored Microsoft Sentinel's full capabilities from incident investigation to custom graph building.
