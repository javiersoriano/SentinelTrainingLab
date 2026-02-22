# Exercise 12 - Creating a Custom Graph in Microsoft Sentinel (Hands‑On, Step by Step)

This guide walks through how to create a **custom graph** in Microsoft Sentinel..  

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

## 2. Building your own custom graph



