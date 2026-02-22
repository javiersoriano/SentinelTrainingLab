# Copilot Instructions for Sentinel Graph Builder

## Project Overview

This workspace contains Jupyter notebooks for building and analyzing security graphs using the Microsoft Sentinel Graph Provider. The primary API is the **GraphSpecBuilder** fluent API for creating graph specifications with nodes and edges from Sentinel data sources.

## Core Graph Building Patterns

### Three-Step Workflow

Building a graph requires three distinct steps:

1. **Discover Tables and Schema** - Use Microsoft Sentinel MCP `search_tables` tool to find relevant tables and columns
2. **Prepare DataFrames** - Use `MicrosoftSentinelProvider` to read tables, then apply PySpark operations to filter into nodes and edges
3. **Build Graph** - Use `GraphSpecBuilder` to construct the graph specification from prepared DataFrames

### Step 1: Discover Tables with MCP Tool

When a user asks to build a graph, first identify the right tables and columns using the Microsoft Sentinel MCP tool:

```python
# Use the mcp_microsoft_sen_search_tables tool to discover relevant tables
# Example: For user activity analysis, search for tables with user and device information
# This returns table schemas with column names and types
```

**Example queries for search_tables:**
- "tables with user logon events"
- "tables containing file download information"
- "alert and email relationship data"
- "Office 365 SharePoint activity"

The tool returns table names, descriptions, and column schemas to help you identify the right data sources.

### Step 2: Prepare DataFrames

Once you know the tables, read and transform the data:

```python
from sentinel_lake.providers import MicrosoftSentinelProvider
from pyspark.sql.functions import col, lit, window

workspace_name = "YourWorkspaceName"
data_provider = MicrosoftSentinelProvider(spark)

# Read the identified table
source_df = data_provider.read_table("TableName", workspace_name)

# Filter and prepare node DataFrames
user_nodes = source_df.filter(col("UserId").isNotNull()) \
    .selectExpr("UserId as id", "UserType", "TimeGenerated") \
    .distinct() \
    .withColumn("nodeType", lit("User"))

# Prepare edge DataFrames with aggregation
edge_df = source_df.groupBy(
    col("UserId").alias("src"),
    col("DeviceId").alias("dst"),
    lit("AccessedFrom").alias("edgeType")
).count()
```

### Step 3: Build Graph with GraphSpecBuilder

Finally, construct the graph from prepared DataFrames:

```python
from sentinel_graph.builders.graph_builder import GraphSpecBuilder

graph = (GraphSpecBuilder.start()
    .add_node("user")
        .from_dataframe(user_nodes.df)
        .with_columns("id", "UserType", "nodeType", "TimeGenerated", key="id", display="id")
    .add_edge("accessed")
        .from_dataframe(edge_df)
        .source(id_column="src", node_type="user")
        .target(id_column="dst", node_type="device")
        .with_columns("edgeType", "count", key="edgeType", display="edgeType")
).done()
```

### Complete Example Pattern

When building graphs, always follow this pattern:

```python
from sentinel_lake.providers import MicrosoftSentinelProvider
from sentinel_graph.builders.graph_builder import GraphSpecBuilder
from pyspark.sql.functions import col, lit

# Step 1: Read data using MicrosoftSentinelProvider
workspace_name = "YourWorkspaceName"
data_provider = MicrosoftSentinelProvider(spark)

# Step 2: Read table and filter for nodes
source_df = data_provider.read_table("DeviceLogonEvents", workspace_name)
user_nodes_df = source_df.filter(col("AccountName").isNotNull()) \
    .selectExpr("AccountName as id", "AccountDomain", "TimeGenerated") \
    .distinct() \
    .withColumn("nodeType", lit("User"))

device_nodes_df = source_df.filter(col("DeviceName").isNotNull()) \
    .selectExpr("DeviceName as id", "TimeGenerated") \
    .distinct() \
    .withColumn("nodeType", lit("Device"))

# Step 3: Create edges with groupBy/aggregation
edge_df = source_df.groupBy(
    col("AccountName").alias("src"),
    col("DeviceName").alias("dst"),
    lit("LoggedInTo").alias("edgeType")
).count()

# Step 4: Build graph using from_dataframe
graph = (GraphSpecBuilder.start()
    .add_node("user")
        .from_dataframe(user_nodes_df.df)  # Note: use .df to get underlying DataFrame
        .with_columns("id", "AccountDomain", "nodeType", "TimeGenerated", key="id", display="id")
    .add_node("device")
        .from_dataframe(device_nodes_df.df)
        .with_columns("id", "nodeType", "TimeGenerated", key="id", display="id")
    .add_edge("loggedInTo")
        .from_dataframe(edge_df)
        .source(id_column="src", node_type="user")
        .target(id_column="dst", node_type="device")
        .with_columns("edgeType", "count", key="edgeType", display="edgeType")
).done()
```

### Key Principles

1. **Use MCP search_tables first** - When user asks to build a graph, use `mcp_microsoft_sen_search_tables` to discover relevant tables and schemas
2. **Always use `.start()` method** - Never instantiate `GraphSpecBuilder()` directly
3. **Use MicrosoftSentinelProvider to read tables** - Always use `data_provider.read_table()` to load data
4. **Use `.from_dataframe()` not `.from_table()`** - Prepare DataFrames first with filters/transformations, then pass to graph builder
5. **Access underlying DataFrame with `.df`** - MicrosoftSentinelProvider returns wrapped DataFrames; use `.df` property in `.from_dataframe()`
6. **Required parameters for columns** - Both `key` and `display` are REQUIRED in `.with_columns()`
7. **Edge definitions require source and target** - Every edge must have `.source()` and `.target()` called
8. **Filter and transform before building** - Apply all filters, selections, and aggregations in PySpark before passing to graph builder
9. **Chain method calls** - Use fluent API pattern with method chaining
10. **Always call `.done()`** - This finalizes the graph specification

## Common Sentinel Tables

### Device and Endpoint Data
- `DeviceFileEvents` - File operations (downloads, modifications)
- `DeviceProcessEvents` - Process executions
- `DeviceNetworkEvents` - Network connections
- `DeviceLogonEvents` - Authentication events
- `DeviceInfo` - Device inventory

### Identity and Access
- `SigninLogs` - Azure AD sign-ins
- `IdentityLogonEvents` - Identity authentication
- `IdentityInfo` - User/identity information

### Email and Communication
- `EmailEvents` - Email messages
- `EmailAttachmentInfo` - Email attachments
- `EmailUrlInfo` - URLs in emails
- `CloudAppEvents` - Cloud app activities

### Alerts and Security
- `AlertEvidence` - Alert evidence data
- `AlertInfo` - Alert metadata

### Office 365 Activity
- `OfficeActivity` - Office 365 audit logs (SharePoint, OneDrive, Exchange operations)

## Data Preparation Patterns

### Reading Tables with MicrosoftSentinelProvider

Always use the MicrosoftSentinelProvider to read Sentinel tables:

```python
from sentinel_lake.providers import MicrosoftSentinelProvider

workspace_name = "YourWorkspaceName"
data_provider = MicrosoftSentinelProvider(spark)
source_df = data_provider.read_table("TableName", workspace_name)
```

### Preparing Node DataFrames

Create distinct node DataFrames with proper filtering and column selection:

```python
from pyspark.sql.functions import col, lit

# Filter for non-null values, select columns, add nodeType
user_nodes = source_df.filter(col("UserId").isNotNull()) \
    .selectExpr("UserId as id", "UserType", "TimeGenerated") \
    .distinct() \
    .withColumn("nodeType", lit("User"))

device_nodes = source_df.filter(col("DeviceName").isNotNull()) \
    .selectExpr("DeviceName as id", "TimeGenerated") \
    .distinct() \
    .withColumn("nodeType", lit("Device"))
```

### Preparing Edge DataFrames

Use groupBy and aggregation to create edge relationships:

```python
from pyspark.sql.functions import col, lit, window

# Simple edge with count
edge_df = source_df.groupBy(
    col("UserId").alias("src"),
    col("DeviceName").alias("dst"),
    lit("AccessedFrom").alias("edgeType")
).count()

# Edge with time window aggregation
edge_with_time_df = source_df.groupBy(
    col("UserId").alias("src"),
    col("FileName").alias("dst"),
    lit("Accessed").alias("edgeType"),
    window(col("TimeGenerated"), "6 hours").alias("TimeGenerated")
).count()
```

## Time Filtering Best Practices

Always apply time filtering for performance. Prefer using lookback windows by default. Use specific time ranges for targeted investigations. 

Keep a consistent time filter pattern by defining a variable with the time filter expression and then reusing it across all data reads.

To keep things running faster in the beginning, apply a lookback window of 2 hours by default (larger windows will slow down execution):

```python
Apply filters when reading from the data provider:

```python
from pyspark.sql.functions import col, expr

time_filter = col("TimeGenerated") >= expr("current_timestamp() - INTERVAL 2 HOURS")

# Filter at read time
source_df = data_provider.read_table("DeviceFileEvents", workspace_name)
filtered_df = source_df.filter(time_filter)

# Or use specific date range
filtered_df = source_df.filter(
    (col("TimeGenerated") >= "2025-01-01") & 
    (col("TimeGenerated") < "2025-01-31")
)
```

## Required Workflow

1. **Define graph spec** - Use `GraphSpecBuilder.start()`
2. **Add nodes** - At least one node required, use `.add_node()`
3. **Add edges** - At least one edge required, use `.add_edge()`
4. **Finalize graph spec** - Call `.done()` to get `GraphSpec` and save a reference to this object.
5. ** View the graph schema ** - Call `.show_schema()` on the graph spec object to visualize the defined nodes and edges. The user can now view the structure of the graph before materialization. 
If the user doesn't like the schema, they can go back and modify the graph spec before proceeding to materialization.

6. **Build graph** - Call `.build_graph_with_data()` to materialize the graph. The value returned is just an operation result. The original graph spec object is now in materialized form.
7. **Query or analyze** - Use predifined analytics methods `blast_radius`, `centrality`, `reachability`, `k_hop`, `ranked`, or convert to graphframe with `to_graphframe()` and perform other analytics, or build an open ended GQL query using `.query()`.

## Error Prevention

### Common Mistakes to Avoid

❌ **Don't do this:**
```python
# Missing key/display parameters
.with_columns("id", "name")  # ERROR!

# Missing source/target
.add_edge("edge").from_dataframe(df)  # ERROR!

# Direct instantiation
builder = GraphSpecBuilder()  # ERROR!

# Using from_table instead of from_dataframe
.add_node("user").from_table("IdentityInfo")  # DON'T DO THIS!

# when working with dataframes, do NOT run count() or show() on the dataframe until AFTER the show_schema() step is complete and user decides to proceed with building the graph.
print(filtered_df.count())  # DON'T DO THIS!

filter_df.show()  # DON'T DO THIS!

```



✅ **Do this instead:**
```python
# Include key and display
.with_columns("id", "name", "email", key="id", display="name")

# Complete edge definition
.add_edge("edge")
    .from_dataframe(edge_df)
    .source(id_column="src_id", node_type="source_node")
    .target(id_column="tgt_id", node_type="target_node")
    .with_columns("col1", key="col1", display="col1")

# Use factory method
builder = GraphSpecBuilder.start()

# Prepare DataFrame first, then use from_dataframe
user_df = data_provider.read_table("IdentityInfo", workspace_name)
user_nodes = user_df.filter(col("AccountName").isNotNull()) \
    .selectExpr("AccountName as id", "AccountDomain") \
    .distinct()

graph = GraphSpecBuilder.start() \
    .add_node("user") \
    .from_dataframe(user_nodes.df) \
    .with_columns("id", "AccountDomain", key="id", display="id")
```

## Query and Analysis

After building the graph:

```python
# GQL queries
result = graph.query("MATCH (u:user)-[r:accessed]->(d:device) RETURN u, r, d LIMIT 10")
result.show()

# Convert to DataFrame
df = result.to_dataframe()

# Graph algorithms
gf = graph.to_graphframe()
pagerank = gf.pageRank(resetProbability=0.15, maxIter=10)

# Built-in analytics
from sentinel_graph.builders.query_input import CentralityQueryInput
centrality = graph.centrality(CentralityQueryInput(
    participating_source_node_labels=["user"],
    participating_target_node_labels=["device"],
    participating_edge_labels=["accessed"],
    is_directional=True
))
```

## Code Style

- Use descriptive node/edge aliases that match the domain (e.g., "user", "device", "file")
- Add time filtering to all data sources when possible
- Group related graph building code in single cells
- Include comments explaining the security scenario being modeled
- Use meaningful variable names: `alert_graph`, `user_device_graph`, etc.

## Documentation References

When explaining graph building concepts, refer to:
- The Graph Builder API Reference document at `C:\Users\jasorian\OneDrive - Microsoft\CxE\Sentinel GTP\Graph\Vibe Graphing\docs\graph_builder_api_reference.md`
- Example notebooks in the workspace (`graph_perf_0115.ipynb`, `Sentinel-VibeGraph_115.ipynb`)

## Response Guidelines

When helping with graph building:
1. Always show complete, runnable code examples
2. Include required `key` and `display` parameters in examples
3. Suggest time filtering for performance
4. Explain the security use case being addressed
5. Show both graph building AND query examples
6. Reference specific Sentinel tables by name
