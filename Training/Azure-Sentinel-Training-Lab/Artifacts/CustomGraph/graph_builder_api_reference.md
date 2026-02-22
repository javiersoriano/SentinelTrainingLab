# Graph Builder API Reference

Comprehensive API reference for building and querying graphs using the Sentinel Graph Provider.

---

## Table of Contents

1. [GraphSpecBuilder](#graphspecbuilder)
2. [GraphSpec](#graphspec)
3. [Graph](#graph)
4. [Node Builders](#node-builders)
   - [NodeBuilderInitial](#nodebuilderInitial)
   - [NodeBuilderSourceSet](#nodebuildersourceset)
5. [Edge Builders](#edge-builders)
   - [EdgeBuilderInitial](#edgebuilderInitial)
   - [EdgeBuilderSourceSet](#edgebuildersourceset)
6. [Schema Classes](#schema-classes)
   - [Property](#property)
   - [Node](#node)
   - [Edge](#edge)
   - [GraphSchema](#graphschema)
7. [Query Results](#query-results)
   - [QueryResult](#queryresult)

---

## GraphSpecBuilder

Fluent builder for creating graph specifications with ETL pipelines and schema integration.

### Constructor

```python
GraphSpecBuilder(context: ExecutionContext)
```

**Parameters:**
- `context` (ExecutionContext): Execution context containing Spark session and configuration

**Raises:**
- `ValueError`: If context is None or graph name cannot be determined

### Static Methods

#### `start`

```python
@staticmethod
GraphSpecBuilder.start(context: Optional[ExecutionContext] = None) -> GraphSpecBuilder
```

Define a new fluent graph builder.

**Parameters:**
- `context` (ExecutionContext, optional): ExecutionContext instance. If None, uses default context.

**Returns:**
- `GraphSpecBuilder`: New builder instance

**Example:**
```python
builder = GraphSpecBuilder.start(context=context)
```

### Instance Methods

#### `add_node`

```python
def add_node(alias: str) -> NodeBuilderInitial
```

Start building a node definition.

**Parameters:**
- `alias` (str): Unique identifier for this node within the graph

**Returns:**
- `NodeBuilderInitial`: Node builder in initial state

**Example:**
```python
builder.add_node("user")
```

#### `add_edge`

```python
def add_edge(alias: str) -> EdgeBuilderInitial
```

Start building an edge definition.

**Parameters:**
- `alias` (str): Identifier for this edge within the graph (can be shared across multiple edges)

**Returns:**
- `EdgeBuilderInitial`: Edge builder in initial state

**Example:**
```python
builder.add_edge("accessed")
```

#### `done`

```python
def done() -> GraphSpec
```

Finalize graph specification and return GraphSpec instance.

**Returns:**
- `GraphSpec`: Complete graph specification with ETL pipeline and schema

**Raises:**
- `ValueError`: If graph has no nodes or edges, or if validation fails

**Example:**
```python
graph_spec = builder.done()
```

### Properties

#### `_spark`

```python
@property
def _spark() -> SparkSession
```

Access to the SparkSession from the execution context.

**Returns:**
- `SparkSession`: Active Spark session

---

## GraphSpec

Complete graph specification with ETL pipeline, schema, and query/visualization capabilities. Extends `Graph` class.

### Constructor

```python
GraphSpec(
    name: str,
    context: ExecutionContext,
    graph_schema: GraphSchema,
    etl_pipeline: Optional[ETLPipeline] = None
)
```

**Parameters:**
- `name` (str): Graph name
- `context` (ExecutionContext): Execution context
- `graph_schema` (GraphSchema): Graph schema definition
- `etl_pipeline` (ETLPipeline, optional): ETL pipeline for data processing

### Properties

#### `nodes`

```python
@property
def nodes() -> DataFrame
```

Get nodes DataFrame (lazy, cached). Automatically determines source from ETL pipeline or lake table.

**Returns:**
- `DataFrame`: Spark DataFrame containing all nodes

**Raises:**
- `ValueError`: If context is missing or DataFrames cannot be loaded

#### `edges`

```python
@property
def edges() -> DataFrame
```

Get edges DataFrame (lazy, cached). Automatically determines source from ETL pipeline or lake table.

**Returns:**
- `DataFrame`: Spark DataFrame containing all edges

**Raises:**
- `ValueError`: If context is missing or DataFrames cannot be loaded

### Methods

#### `build_graph_with_data`

```python
def build_graph_with_data() -> Dict[str, Any]
```

Execute the ETL pipeline and create graph instance via API.

**Returns:**
- `Dict[str, Any]`: Dictionary containing:
  - `etl_result`: ETL execution results
  - `api_result`: API creation results (if successful)
  - `instance_name`: Graph instance name
  - `status`: "success" or "etl_only"

**Raises:**
- `ValueError`: If this is a remote graph without local ETL pipeline

**Example:**
```python
result = graph_spec.build_graph_with_data()
print(f"Status: {result['status']}")
```

#### `get_schema`

```python
def get_schema() -> GraphSchema
```

Get the graph schema.

**Returns:**
- `GraphSchema`: Graph schema definition

#### `get_pipeline`

```python
def get_pipeline() -> Optional[ETLPipeline]
```

Get the ETL pipeline (None for remote graphs).

**Returns:**
- `ETLPipeline` or `None`: ETL pipeline if available

#### `to_graphframe`

```python
def to_graphframe(column_mapping: Optional[Dict[str, str]] = None) -> GraphFrame
```

Convert entire graph to GraphFrame for running graph algorithms.

**Parameters:**
- `column_mapping` (Dict[str, str], optional): Custom column mapping with keys:
  - `"id"`: Vertex ID column name
  - `"source_id"`: Edge source ID column name
  - `"target_id"`: Edge target ID column name

**Returns:**
- `GraphFrame`: GraphFrame object with all vertices and edges

**Raises:**
- `ValueError`: If ExecutionContext is not available

**Example:**
```python
gf = graph_spec.to_graphframe()
pagerank = gf.pageRank(resetProbability=0.15, maxIter=10)
```

#### `show`

```python
def show(limit: int = 100, viz_format: str = "visual") -> None
```

Display graph data in various formats.

**Parameters:**
- `limit` (int, default=100): Maximum nodes/edges to display
- `viz_format` (str, default="visual"): Output format
  - `"table"`: Full DataFrame tables (all columns)
  - `"visual"`: Interactive graph visualization
  - `"all"`: Show all formats

**Raises:**
- `ValueError`: If format is not one of the supported values

**Example:**
```python
graph_spec.show(limit=50, viz_format="table")
```

---

## Graph

Graph instance for querying existing graphs. Base class for `GraphSpec`.

### Constructor

```python
Graph(name: str, context: ExecutionContext)
```

**Parameters:**
- `name` (str): Graph name
- `context` (ExecutionContext): Execution context

**Raises:**
- `ValueError`: If ExecutionContext is None

### Static Methods

#### `get`

```python
@staticmethod
Graph.get(name: str, context: Optional[ExecutionContext] = None) -> Graph
```

Gets a graph instance from an existing graph.

**Parameters:**
- `name` (str): Graph instance name
- `context` (ExecutionContext, optional): Execution context (defaults to ExecutionContext.default())

**Returns:**
- `Graph`: Graph instance

**Raises:**
- `ValueError`: If graph name is empty or graph instance does not exist

**Example:**
```python
graph = Graph.get("my_graph", context=context)
```

### Methods

#### `query`

```python
def query(query_string: str, query_language: str = "GQL") -> QueryResult
```

Execute a query against the graph instance using GQL.

**Parameters:**
- `query_string` (str): Graph query string (GQL Language)
- `query_language` (str, default="GQL"): Query language

**Returns:**
- `QueryResult`: Object containing nodes, edges, and metadata

**Raises:**
- `ValueError`: If ExecutionContext or Spark session is missing
- `RuntimeError`: If client initialization or query execution fails

**Example:**
```python
result = graph.query("MATCH (u:user) WHERE u.age > 30 RETURN u")
result.show()
```

#### `reachability`

```python
def reachability(query_input: ReachabilityQueryInput) -> QueryResult
```

Perform reachability analysis between source and target nodes.

**Parameters:**
- `query_input` (ReachabilityQueryInput): Query parameters

**Returns:**
- `QueryResult`: Containing the reachability paths

#### `k_hop`

```python
def k_hop(query_input: K_HopQueryInput) -> QueryResult
```

Perform k-hop analysis from a given source node.

**Parameters:**
- `query_input` (K_HopQueryInput): Query parameters

**Returns:**
- `QueryResult`: Containing the k-hop paths

#### `blast_radius`

```python
def blast_radius(query_input: BlastRadiusQueryInput) -> QueryResult
```

Perform blast radius analysis from source node to target node.

**Parameters:**
- `query_input` (BlastRadiusQueryInput): Query parameters

**Returns:**
- `QueryResult`: Containing the blast radius paths

#### `centrality`

```python
def centrality(query_input: CentralityQueryInput) -> QueryResult
```

Perform centrality analysis on the graph.

**Parameters:**
- `query_input` (CentralityQueryInput): Query parameters

**Returns:**
- `QueryResult`: Containing the centrality metrics

#### `ranked`

```python
def ranked(query_input: RankedQueryInput) -> QueryResult
```

Perform ranked analysis on the graph.

**Parameters:**
- `query_input` (RankedQueryInput): Query parameters

**Returns:**
- `QueryResult`: Containing the ranked nodes/edges

#### `to_graphframe`

```python
def to_graphframe(column_mapping: Optional[Dict[str, str]] = None) -> GraphFrame
```

Convert entire graph to GraphFrame.

**Parameters:**
- `column_mapping` (Dict[str, str], optional): Custom column mapping

**Returns:**
- `GraphFrame`: GraphFrame object with all vertices and edges

**Example:**
```python
gf = graph.to_graphframe()
```

#### `show`

```python
def show() -> None
```

Display basic info about the graph instance.

---

## Node Builders

### NodeBuilderInitial

Initial state for node builder: only data source methods available.

#### Constructor

```python
NodeBuilderInitial(alias: str, graph_builder: GraphSpecBuilder)
```

**Note:** Typically created via `GraphSpecBuilder.add_node()`, not directly instantiated.

#### Methods

##### `from_table`

```python
def from_table(table_name: str, database: Optional[str] = None) -> NodeBuilderSourceSet
```

Set table as data source with intelligent database resolution.

**Parameters:**
- `table_name` (str): Name of the table (required)
- `database` (str, optional): Explicit database name (takes precedence over context default)

**Returns:**
- `NodeBuilderSourceSet`: Builder for further configuration

**Raises:**
- `ValueError`: If table not found or multiple conflicting tables found

**Database Resolution Order:**
1. Explicit `database` parameter (highest precedence)
2. ExecutionContext.default_database
3. Search all databases (with conflict detection)

**Example:**
```python
builder.add_node("user").from_table("SigninLogs", database="security_db")
```

##### `from_query`

```python
def from_query(query: str) -> NodeBuilderSourceSet
```

Set SQL query as data source.

**Parameters:**
- `query` (str): SQL query string

**Returns:**
- `NodeBuilderSourceSet`: Builder for further configuration

**Example:**
```python
builder.add_node("user").from_query("SELECT * FROM users WHERE active = true")
```

##### `from_dataframe`

```python
def from_dataframe(dataframe: DataFrame) -> NodeBuilderSourceSet
```

Set Spark DataFrame as data source.

**Parameters:**
- `dataframe` (DataFrame): Spark DataFrame

**Returns:**
- `NodeBuilderSourceSet`: Builder for further configuration

**Example:**
```python
df = spark.read.table("users")
builder.add_node("user").from_dataframe(df)
```

---

### NodeBuilderSourceSet

Node builder after data source is set: configuration methods available.

#### Constructor

```python
NodeBuilderSourceSet(alias: str, graph_builder: GraphSpecBuilder, source_step: DataInputETLStep)
```

**Note:** Created internally by NodeBuilderInitial source methods.

#### Methods

##### `with_time_range`

```python
def with_time_range(
    time_column: str,
    start_time: Optional[Union[str, datetime]] = None,
    end_time: Optional[Union[str, datetime]] = None,
    lookback_hours: Optional[float] = None
) -> NodeBuilderSourceSet
```

Apply time range filtering to the node's data source.

**Parameters:**
- `time_column` (str): Column name containing timestamp data (required)
- `start_time` (str or datetime, optional): Start date ('10/20/25', '2025-10-20', or datetime object)
- `end_time` (str or datetime, optional): End date (same formats as start_time)
- `lookback_hours` (float, optional): Hours to look back from now

**Returns:**
- `NodeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If time column not found in source schema

**Time Range Logic:**
1. If start_time and end_time provided: use them directly
2. If only lookback_hours provided: end=now, start=now-lookback_hours
3. If nothing provided: no time filtering
4. If start/end AND lookback_hours: start/end take precedence

**Example:**
```python
# Explicit date range
builder.add_node("user").from_table("SigninLogs") \
    .with_time_range(time_column="TimeGenerated", start_time="2025-01-01", end_time="2025-01-31")

# Lookback window
builder.add_node("user").from_table("SigninLogs") \
    .with_time_range(time_column="TimeGenerated", lookback_hours=24)
```

##### `with_label`

```python
def with_label(label: str) -> NodeBuilderSourceSet
```

Set node label (defaults to alias if not called).

**Parameters:**
- `label` (str): Node label

**Returns:**
- `NodeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If label already set

**Example:**
```python
builder.add_node("u").from_table("Users").with_label("user")
```

##### `with_columns`

```python
def with_columns(
    *columns: str,
    key: str,
    display: str
) -> NodeBuilderSourceSet
```

Configure columns with required key and display designation.

**Parameters:**
- `*columns` (str): Column names to include (at least one required)
- `key` (str): Column name to mark as key (required, must be in columns)
- `display` (str): Column name to mark as display value (required, must be in columns, can be same as key)

**Returns:**
- `NodeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If validation fails (duplicate columns, missing key/display, etc.)

**Notes:**
- Properties are automatically built from column types
- Time filter column is automatically added if specified
- Property types are auto-inferred from source schema

**Example:**
```python
builder.add_node("user").from_table("Users") \
    .with_columns("id", "name", "email", "created_at", key="id", display="name")
```

##### `add_node`

```python
def add_node(alias: str) -> NodeBuilderInitial
```

Finish this node and start building another node.

**Parameters:**
- `alias` (str): Alias for the new node

**Returns:**
- `NodeBuilderInitial`: New node builder

**Example:**
```python
builder.add_node("user").from_table("Users") \
    .with_columns("id", "name", key="id", display="name") \
    .add_node("device")
```

##### `add_edge`

```python
def add_edge(alias: str) -> EdgeBuilderInitial
```

Finish this node and start building an edge.

**Parameters:**
- `alias` (str): Alias for the edge

**Returns:**
- `EdgeBuilderInitial`: New edge builder

**Example:**
```python
builder.add_node("user").from_table("Users") \
    .with_columns("id", "name", key="id", display="name") \
    .add_edge("accessed")
```

##### `done`

```python
def done() -> GraphSpec
```

Finalize this node and complete the graph specification.

**Returns:**
- `GraphSpec`: Complete graph specification

**Example:**
```python
graph_spec = builder.add_node("user").from_table("Users") \
    .with_columns("id", "name", key="id", display="name") \
    .done()
```

---

## Edge Builders

### EdgeBuilderInitial

Initial state for edge builder: only data source methods available.

#### Constructor

```python
EdgeBuilderInitial(alias: str, graph_builder: GraphSpecBuilder)
```

**Note:** Typically created via `GraphSpecBuilder.add_edge()`, not directly instantiated.

#### Methods

##### `from_table`

```python
def from_table(table_name: str, database: Optional[str] = None) -> EdgeBuilderSourceSet
```

Set table as data source with intelligent database resolution.

**Parameters:**
- `table_name` (str): Name of the table (required)
- `database` (str, optional): Explicit database name

**Returns:**
- `EdgeBuilderSourceSet`: Builder for further configuration

**Raises:**
- `ValueError`: If table not found or multiple conflicting tables found

**Example:**
```python
builder.add_edge("accessed").from_table("AccessLogs")
```

##### `from_query`

```python
def from_query(query: str) -> EdgeBuilderSourceSet
```

Set SQL query as data source.

**Parameters:**
- `query` (str): SQL query string

**Returns:**
- `EdgeBuilderSourceSet`: Builder for further configuration

**Example:**
```python
builder.add_edge("accessed").from_query("SELECT * FROM access_logs")
```

##### `from_dataframe`

```python
def from_dataframe(dataframe: DataFrame) -> EdgeBuilderSourceSet
```

Set Spark DataFrame as data source.

**Parameters:**
- `dataframe` (DataFrame): Spark DataFrame

**Returns:**
- `EdgeBuilderSourceSet`: Builder for further configuration

**Example:**
```python
df = spark.read.table("access_logs")
builder.add_edge("accessed").from_dataframe(df)
```

---

### EdgeBuilderSourceSet

Edge builder after data source is set: configuration methods available.

#### Constructor

```python
EdgeBuilderSourceSet(alias: str, graph_builder: GraphSpecBuilder, source_step: DataInputETLStep)
```

**Note:** Created internally by EdgeBuilderInitial source methods.

#### Methods

##### `edge_label`

```python
def edge_label(label: str) -> EdgeBuilderSourceSet
```

Set edge relationship type/label (defaults to alias if not called).

**Parameters:**
- `label` (str): Edge label

**Returns:**
- `EdgeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If label already set

**Example:**
```python
builder.add_edge("acc").from_table("AccessLogs").edge_label("accessed")
```

##### `source`

```python
def source(id_column: str, node_type: str) -> EdgeBuilderSourceSet
```

Set source node with ID column and label.

**Parameters:**
- `id_column` (str): Column name containing source node ID
- `node_type` (str): Source node label

**Returns:**
- `EdgeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If source already set

**Example:**
```python
builder.add_edge("accessed").from_table("AccessLogs") \
    .source(id_column="user_id", node_type="user")
```

##### `target`

```python
def target(id_column: str, node_type: str) -> EdgeBuilderSourceSet
```

Set target node with ID column and label.

**Parameters:**
- `id_column` (str): Column name containing target node ID
- `node_type` (str): Target node label

**Returns:**
- `EdgeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If target already set

**Example:**
```python
builder.add_edge("accessed").from_table("AccessLogs") \
    .source(id_column="user_id", node_type="user") \
    .target(id_column="device_id", node_type="device")
```

##### `with_time_range`

```python
def with_time_range(
    time_column: str,
    start_time: Optional[Union[str, datetime]] = None,
    end_time: Optional[Union[str, datetime]] = None,
    lookback_hours: Optional[float] = None
) -> EdgeBuilderSourceSet
```

Apply time range filtering to the edge's data source.

**Parameters:**
- `time_column` (str): Column name containing timestamp data (required)
- `start_time` (str or datetime, optional): Start date
- `end_time` (str or datetime, optional): End date
- `lookback_hours` (float, optional): Hours to look back from now

**Returns:**
- `EdgeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If time column not found in source schema

**Example:**
```python
builder.add_edge("accessed").from_table("AccessLogs") \
    .with_time_range(time_column="TimeGenerated", lookback_hours=48)
```

##### `with_columns`

```python
def with_columns(
    *columns: str,
    key: str,
    display: str
) -> EdgeBuilderSourceSet
```

Configure columns with required key and display designation.

**Parameters:**
- `*columns` (str): Column names to include (at least one required)
- `key` (str): Column name to mark as key (required, must be in columns)
- `display` (str): Column name to mark as display value (required, must be in columns)

**Returns:**
- `EdgeBuilderSourceSet`: Self for method chaining

**Raises:**
- `ValueError`: If validation fails

**Example:**
```python
builder.add_edge("accessed").from_table("AccessLogs") \
    .source(id_column="user_id", node_type="user") \
    .target(id_column="device_id", node_type="device") \
    .with_columns("id", "location", "status", key="id", display="location")
```

##### `add_node`

```python
def add_node(alias: str) -> NodeBuilderInitial
```

Finish this edge and start building a node.

**Parameters:**
- `alias` (str): Alias for the new node

**Returns:**
- `NodeBuilderInitial`: New node builder

##### `add_edge`

```python
def add_edge(alias: str) -> EdgeBuilderInitial
```

Finish this edge and start building another edge.

**Parameters:**
- `alias` (str): Alias for the new edge

**Returns:**
- `EdgeBuilderInitial`: New edge builder

**Example:**
```python
builder.add_edge("accessed").from_table("AccessLogs") \
    .source(id_column="user_id", node_type="user") \
    .target(id_column="device_id", node_type="device") \
    .with_columns("id", "location", key="id", display="location") \
    .add_edge("connected_to")
```

##### `done`

```python
def done() -> GraphSpec
```

Finalize this edge and complete the graph specification.

**Returns:**
- `GraphSpec`: Complete graph specification

---

## Schema Classes

### Property

Property definition with type-safe interface.

#### Constructor

```python
Property(
    name: str,
    property_type: PropertyType,
    is_non_null: bool = False,
    description: str = "",
    is_key: bool = False,
    is_display_value: bool = False,
    is_internal: bool = False
)
```

**Parameters:**
- `name` (str): Property name
- `property_type` (PropertyType): Property data type
- `is_non_null` (bool, default=False): Whether property is required
- `description` (str, default=""): Property description
- `is_key` (bool, default=False): Whether property is a key
- `is_display_value` (bool, default=False): Whether property is display value
- `is_internal` (bool, default=False): Whether property is internal

**Raises:**
- `ValueError`: If name is empty or validation fails

#### Class Methods

##### `key`

```python
@classmethod
Property.key(
    name: str,
    property_type: PropertyType,
    description: str = "",
    is_non_null: bool = False
) -> Property
```

Create a key property with common settings (is_key=True, is_display_value=True).

##### `display`

```python
@classmethod
Property.display(
    name: str,
    property_type: PropertyType,
    description: str = "",
    is_non_null: bool = False
) -> Property
```

Create a display value property (is_display_value=True).

#### Methods

##### `describe`

```python
def describe(text: str) -> Property
```

Add description fluently.

**Parameters:**
- `text` (str): Description text

**Returns:**
- `Property`: Self for method chaining

##### `to_dict`

```python
def to_dict() -> Dict[str, Any]
```

Serialize property to dictionary with @-prefixed annotation keys.

**Returns:**
- `Dict[str, Any]`: Serialized property

##### `to_gql`

```python
def to_gql() -> str
```

Generate GQL property definition.

**Returns:**
- `str`: GQL string representation

---

### Node

Node definition with type-safe interface.

#### Constructor

```python
Node(
    alias: str = "",
    labels: List[str] = [],
    implies_labels: List[str] = [],
    properties: List[Property] = [],
    description: str = "",
    entity_group: str = "",
    dynamic_labels: bool = False,
    abstract_edge_aliases: bool = False
)
```

**Parameters:**
- `alias` (str, default=""): Node alias (auto-set to first label if empty)
- `labels` (List[str]): Node labels (at least one required)
- `implies_labels` (List[str], default=[]): Implied labels
- `properties` (List[Property], default=[]): Node properties
- `description` (str, default=""): Node description
- `entity_group` (str, default=""): Entity group name
- `dynamic_labels` (bool, default=False): Whether node has dynamic labels
- `abstract_edge_aliases` (bool, default=False): Whether node uses abstract edge aliases

**Raises:**
- `ValueError`: If validation fails (no labels, no key property, no display property, etc.)

**Auto-mutation:**
- If alias is empty, it's set to the first label
- If entity_group is empty, it's set to the primary label

#### Methods

##### `get_primary_label`

```python
def get_primary_label() -> Optional[str]
```

Get the primary (first) label.

**Returns:**
- `str` or `None`: Primary label or None if no labels

##### `get_entity_group_name`

```python
def get_entity_group_name() -> str
```

Get entity group name or fallback to primary label.

**Returns:**
- `str`: Entity group name

##### `get_primary_key_property_name`

```python
def get_primary_key_property_name() -> Optional[str]
```

Get the name of the primary key property.

**Returns:**
- `str` or `None`: Primary key property name

##### `get_properties`

```python
def get_properties() -> Dict[str, Property]
```

Get properties as a dictionary for easy access.

**Returns:**
- `Dict[str, Property]`: Properties keyed by name

##### `get_property`

```python
def get_property(name: str) -> Optional[Property]
```

Get a specific property by name.

**Parameters:**
- `name` (str): Property name

**Returns:**
- `Property` or `None`: Property if found

##### `add_property`

```python
def add_property(prop: Property) -> None
```

Add a property to this node.

**Parameters:**
- `prop` (Property): Property to add

**Raises:**
- `ValueError`: If property name is duplicate

##### `describe`

```python
def describe(text: str) -> Node
```

Add description fluently.

**Parameters:**
- `text` (str): Description text

**Returns:**
- `Node`: Self for method chaining

##### `to_dict`

```python
def to_dict() -> Dict[str, Any]
```

Serialize node to dictionary.

**Returns:**
- `Dict[str, Any]`: Serialized node

##### `to_gql`

```python
def to_gql() -> str
```

Generate GQL node definition.

**Returns:**
- `str`: GQL string representation

**Raises:**
- `ValueError`: If node lacks required fields for GQL

---

### Edge

Edge definition with type-safe interface.

#### Constructor

```python
Edge(
    relationship_type: str,
    source_node_label: str,
    target_node_label: str,
    direction: EdgeDirection = EdgeDirection.DIRECTED_RIGHT,
    properties: List[Property] = [],
    description: str = "",
    entity_group: str = "",
    dynamic_type: bool = False
)
```

**Parameters:**
- `relationship_type` (str): Edge relationship type (e.g., "FOLLOWS", "OWNS")
- `source_node_label` (str): Source node label
- `target_node_label` (str): Target node label
- `direction` (EdgeDirection, default=DIRECTED_RIGHT): Edge direction
- `properties` (List[Property], default=[]): Edge properties
- `description` (str, default=""): Edge description
- `entity_group` (str, default=""): Entity group name
- `dynamic_type` (bool, default=False): Whether edge has dynamic type

**Raises:**
- `ValueError`: If validation fails

**Auto-mutation:**
- `labels` list is automatically populated with `[relationship_type]`
- If entity_group is empty, it's set to relationship_type

#### Properties

##### `edge_type`

```python
@property
def edge_type() -> str
```

Backward compatibility alias for relationship_type.

**Returns:**
- `str`: Relationship type

#### Methods

##### `get_entity_group_name`

```python
def get_entity_group_name() -> str
```

Get entity group name or fallback to relationship type.

**Returns:**
- `str`: Entity group name

##### `is_dynamic_type`

```python
def is_dynamic_type() -> bool
```

Check if edge has dynamic type.

**Returns:**
- `bool`: True if dynamic type

##### `add_property`

```python
def add_property(edge_property: Property) -> None
```

Add a property to this edge.

**Parameters:**
- `edge_property` (Property): Property to add

##### `describe`

```python
def describe(text: str) -> Edge
```

Add description fluently.

**Parameters:**
- `text` (str): Description text

**Returns:**
- `Edge`: Self for method chaining

##### `to_dict`

```python
def to_dict() -> Dict[str, Any]
```

Serialize edge to dictionary.

**Returns:**
- `Dict[str, Any]`: Serialized edge

##### `to_gql`

```python
def to_gql() -> str
```

Generate GQL edge definition.

**Returns:**
- `str`: GQL string representation

---

### GraphSchema

Graph schema definition with type-safe interface.

#### Constructor

```python
GraphSchema(
    name: str,
    nodes: List[Node] = [],
    edges: List[Edge] = [],
    base_graphs: List[GraphSchema] = [],
    description: str = "",
    version: str = "1.0",
    fully_qualified_name: str = "",
    namespace: str = ""
)
```

**Parameters:**
- `name` (str): Graph schema name
- `nodes` (List[Node], default=[]): Node definitions
- `edges` (List[Edge], default=[]): Edge definitions
- `base_graphs` (List[GraphSchema], default=[]): Base graph schemas
- `description` (str, default=""): Schema description
- `version` (str, default="1.0"): Schema version
- `fully_qualified_name` (str, default=""): Fully qualified name
- `namespace` (str, default=""): Namespace

**Raises:**
- `ValueError`: If validation fails (duplicate aliases, edges reference non-existent nodes, etc.)

#### Methods

##### `get_fully_qualified_name`

```python
def get_fully_qualified_name() -> str
```

Get fully qualified name.

**Returns:**
- `str`: Fully qualified name

##### `get_namespace`

```python
def get_namespace() -> str
```

Get namespace from fully qualified name or return default.

**Returns:**
- `str`: Namespace

##### `get_version`

```python
def get_version() -> str
```

Get version.

**Returns:**
- `str`: Version string

##### `get_node`

```python
def get_node(label_or_alias: str) -> Optional[Node]
```

Get node by label or alias.

**Parameters:**
- `label_or_alias` (str): Node label or alias

**Returns:**
- `Node` or `None`: Node if found

##### `get_edge`

```python
def get_edge(name: str) -> Optional[Edge]
```

Get edge by name/type.

**Parameters:**
- `name` (str): Edge relationship type

**Returns:**
- `Edge` or `None`: Edge if found

##### `add_node`

```python
def add_node(node: Node) -> None
```

Add a node to this graph.

**Parameters:**
- `node` (Node): Node to add

**Raises:**
- `ValueError`: If node alias is duplicate

##### `add_edge`

```python
def add_edge(edge: Edge) -> None
```

Add an edge to this graph.

**Parameters:**
- `edge` (Edge): Edge to add

**Raises:**
- `ValueError`: If edge type is duplicate

##### `include_graph`

```python
def include_graph(fully_qualified_name: str, version: str) -> GraphSchema
```

Add a graph include (fluent API).

**Parameters:**
- `fully_qualified_name` (str): Fully qualified name of graph to include
- `version` (str): Version of graph to include

**Returns:**
- `GraphSchema`: Self for method chaining

##### `describe`

```python
def describe(text: str) -> GraphSchema
```

Add description fluently.

**Parameters:**
- `text` (str): Description text

**Returns:**
- `GraphSchema`: Self for method chaining

##### `to_dict`

```python
def to_dict() -> Dict[str, Any]
```

Serialize schema to dictionary.

**Returns:**
- `Dict[str, Any]`: Serialized schema

##### `to_json`

```python
def to_json(indent: int = 2) -> str
```

Generate JSON representation.

**Parameters:**
- `indent` (int, default=2): JSON indentation level

**Returns:**
- `str`: JSON string

##### `to_gql`

```python
def to_gql() -> str
```

Generate GQL schema definition.

**Returns:**
- `str`: GQL string representation

---

## Query Results

### QueryResult

Result from a graph query with lazy DataFrame access.

#### Constructor

```python
QueryResult(raw_response: Dict[str, Any], graph_spec: Graph)
```

**Parameters:**
- `raw_response` (Dict[str, Any]): Raw API response dictionary
- `graph_spec` (Graph): Reference to parent Graph

**Note:** Typically created by `Graph.query()`, not directly instantiated.

#### Methods

##### `to_dataframe`

```python
def to_dataframe() -> DataFrame
```

Converts the query result to a Spark DataFrame.

**Returns:**
- `DataFrame`: Query result as Spark DataFrame

**Raises:**
- `ValueError`: If conversion fails

**Example:**
```python
result = graph.query("MATCH (u:user) RETURN u")
df = result.to_dataframe()
df.show()
```

##### `get_raw_data`

```python
def get_raw_data() -> Dict[str, Any]
```

Get RawData section from response.

**Returns:**
- `Dict[str, Any]`: Dictionary with raw metadata, or empty dict if not present

**Example:**
```python
result = graph.query("MATCH (u:user) RETURN u")
metadata = result.get_raw_data()
```

##### `show`

```python
def show(format: str = "visual") -> None
```

Display query result in various formats.

**Parameters:**
- `format` (str, default="visual"): Output format
  - `"table"`: Full DataFrame tables (all columns)
  - `"visual"`: Interactive graph visualization with VSC plugin
  - `"all"`: Show all formats

**Raises:**
- `ValueError`: If format is not one of the supported values

**Example:**
```python
result = graph.query("MATCH (u:user)-[r:accessed]->(d:device) RETURN u, r, d")
result.show()  # Visual by default
result.show(format="table")  # Table format
```

---

## Complete Example

```python
from sentinel_graph.builders import GraphSpecBuilder
from sentinel_graph.core.context import ExecutionContext

# Create execution context
context = ExecutionContext.default()

# Build graph specification
graph_spec = (
    GraphSpecBuilder.start(context)
    
    # Define user node
    .add_node("user")
    .from_table("SigninLogs")
    .with_time_range(time_column="TimeGenerated", lookback_hours=24)
    .with_label("user")
    .with_columns("UserId", "UserName", "Email", key="UserId", display="UserName")
    
    # Define device node
    .add_node("device")
    .from_table("DeviceInfo")
    .with_label("device")
    .with_columns("DeviceId", "DeviceName", "OS", key="DeviceId", display="DeviceName")
    
    # Define accessed edge
    .add_edge("accessed")
    .from_table("AccessLogs")
    .with_time_range(time_column="TimeGenerated", lookback_hours=24)
    .source(id_column="UserId", node_type="user")
    .target(id_column="DeviceId", node_type="device")
    .with_columns("AccessId", "Location", "Status", key="AccessId", display="Location")
    
    .done()
)

# Build graph with data
result = graph_spec.build_graph_with_data()
print(f"Build status: {result['status']}")

# Query the graph
query_result = graph_spec.query("MATCH (u:user)-[a:accessed]->(d:device) RETURN u, a, d LIMIT 100")
query_result.show()

# Convert to DataFrame for further analysis
df = query_result.to_dataframe()
df.printSchema()

# Convert to GraphFrame for graph algorithms
gf = graph_spec.to_graphframe()
pagerank_result = gf.pageRank(resetProbability=0.15, maxIter=10)
pagerank_result.vertices.select("id", "pagerank").show()
```

---

## Notes on Design Patterns

### Fluent API

All builders support method chaining for readable, declarative graph definitions:

```python
builder.add_node("user") \
    .from_table("Users") \
    .with_columns("id", "name", key="id", display="name") \
    .add_edge("follows")
```

### Union Schemas

Multiple edges with the same alias are automatically union'ed with merged properties:

```python
# Both edges use alias "sign_in" - they will be merged into one schema edge
builder.add_edge("sign_in") \
    .from_table("AzureSignins") \
    .source(id_column="UserId", node_type="AZuser") \
    .target(id_column="DeviceId", node_type="device")

builder.add_edge("sign_in") \
    .from_table("EntraSignins") \
    .source(id_column="UserId", node_type="EntraUser") \
    .target(id_column="DeviceId", node_type="device")
```

### Auto-configuration

Many fields have sensible defaults:
- Node/edge labels default to their aliases
- Properties are auto-inferred from source schemas
- Entity groups default to primary labels/relationship types

### Lazy Evaluation

DataFrames and resources are loaded lazily and cached:
- `graph_spec.nodes` and `graph_spec.edges` are loaded on first access
- Query results create DataFrames only when requested

---
