# Phoenix GraphQL Schema Reference

Quick reference for Phoenix GraphQL types and fields.

## Core Types

### Project

Container for organizing traces and spans.

**Key Fields:**

- `id: GlobalID!` - Unique identifier
- `name: String!` - Project name
- `traceCount: Int!` - Total traces
- `recordCount: Int!` - Total spans
- `tokenCountTotal: Int!`, `tokenCountPrompt: Int!`,
  `tokenCountCompletion: Int!` - Token totals
- `startTime: DateTime`, `endTime: DateTime` - Time bounds
- `spans(...)` - Query spans
- `trace(traceId: ID!)` - Get specific trace

**Aggregate Fields (with optional filterCondition):**

- `costSummary(filterCondition: String)` - Cost breakdown
- `latencyMsQuantile(probability: Float, filterCondition: String)` - Latency
  percentiles
- `spanLatencyMsQuantile(probability: Float, filterCondition: String)` - Span
  latency percentiles

### Trace

Complete execution path through an agent workflow.

**Key Fields:**

- `id: GlobalID!`, `traceId: String!` - Identifiers
- `startTime: DateTime!`, `endTime: DateTime`, `latencyMs: Float` - Timing
- `numSpans: Int!` - Span count
- `tokenCountTotal: Int`, `tokenCountPrompt: Int`, `tokenCountCompletion: Int` -
  Token usage
- `rootSpan: Span` - Top-level span
- `spans(...)` - All spans in trace
- `costSummary: TraceCostSummary` - Cost breakdown
- `project: Project!` - Parent project

### Span

Individual unit of work within a trace.

**Core Fields:**

- `id: GlobalID!` - Unique identifier
- `name: String!` - Span name
- `spanKind: SpanKind!` - Operation type (see Enums below)
- `statusCode: SpanStatusCode!` - Execution status (OK, ERROR, UNSET)
- `statusMessage: String!` - Status description
- `startTime: DateTime!`, `endTime: DateTime`, `latencyMs: Float` - Timing
- `parentId: ID` - Parent span ID (null for root)
- `trace: Trace!`, `project: Project!` - Parent references

**Token Fields:**

- `tokenCountTotal: Int`, `tokenCountPrompt: Int`, `tokenCountCompletion: Int` -
  Direct tokens
- `cumulativeTokenCountTotal: Int`, `cumulativeTokenCountPrompt: Int`,
  `cumulativeTokenCountCompletion: Int` - Including descendants

**Cost Fields:**

- `costSummary: SpanCostSummary` - Cost breakdown

**I/O Fields:**

- `input: SpanIOValue` - Input data (JSON string in `value` field)
- `output: SpanIOValue` - Output data (JSON string in `value` field)
- `attributes: String!` - OpenTelemetry attributes (JSON string)
- `metadata: String` - Additional metadata

**Hierarchy Fields:**

- `numChildSpans: Int!` - Number of direct children
- `descendants(...)` - All descendant spans
- `propagatedStatusCode: SpanStatusCode!` - Status percolated from descendants

⚠️ **Warning**: I/O fields (`input`, `output`) can be very large. Only request
when needed.

## Enums

### SpanKind

Types of operations: `LLM`, `TOOL`, `CHAIN`, `AGENT`, `RETRIEVER`, `EMBEDDING`,
`RERANKER`, `EVALUATOR`, `GUARDRAIL`, `UNKNOWN`

⚠️ **Always use UPPERCASE** in filters: `span_kind == 'LLM'` not `'llm'`

See `reference/filters.md` for complete enum documentation.

### SpanStatusCode

Execution status: `OK`, `ERROR`, `UNSET`

Example: `filterCondition: "status_code == 'ERROR'"`

## Connections (Relay-style Pagination)

**Structure:**

```graphql
type SpanConnection {
  edges: [SpanEdge!]!
  pageInfo: PageInfo!
}

type SpanEdge {
  node: Span!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

Use `endCursor` from `pageInfo` as `after` parameter for next page.

## Cost Types

**SpanCostSummary:**

```graphql
type SpanCostSummary {
  total: CostDetail
  prompt: CostDetail
  completion: CostDetail
}

type CostDetail {
  cost: Float # USD
  tokens: Int
}
```

Example usage: `costSummary { total { cost tokens } }`

## Attributes

Spans include OpenTelemetry attributes as a JSON string.

**Common LLM Attributes:**

- `llm.model_name` - Model identifier
- `llm.invocation_parameters` - Model parameters
- `llm.token_count.prompt`, `llm.token_count.completion`,
  `llm.token_count.total` - Token counts

**Common Tool Attributes:**

- `tool.name`, `tool.description`, `tool.parameters` - Tool info

**OpenInference Attributes:**

- `openinference.span.kind` - Span kind
- `input.value`, `output.value` - I/O values

Attributes are returned as JSON string. Parse client-side to access specific
fields.

## Query Root

**Project Queries:**

- `projects` - List all projects
- `node(id: GlobalID!)` - Get any node by ID (Project, Trace, or Span)

**Trace Queries:**

- `getTraceByOtelId(traceId: String!)` - Get trace by OpenTelemetry trace ID
- `getSpanByOtelId(spanId: String!)` - Get span by OpenTelemetry span ID

**Validation:**

- `validateRegularExpression(pattern: String!)` - Validate regex patterns

## Sorting

```graphql
input SpanSort {
  col: SpanColumn!
  dir: SortDir!
}

enum SpanColumn {
  startTime
  endTime
  latencyMs
  tokenCountTotal
  tokenCountPrompt
  tokenCountCompletion
}

enum SortDir {
  asc
  desc
}
```

Example: `sort: { col: latencyMs, dir: desc }`

## Time Ranges

```graphql
input TimeRange {
  start: DateTime! # ISO 8601: "2025-11-17T00:00:00Z"
  end: DateTime!
}
```

Example:
`timeRange: { start: "2025-11-17T00:00:00Z", end: "2025-11-18T00:00:00Z" }`

## Introspection

Query the schema:

**Schema overview:**

```graphql
query {
  __schema {
    queryType {
      name
      fields {
        name
        description
      }
    }
  }
}
```

**Type details:**

```graphql
query {
  __type(name: "Span") {
    fields {
      name
      type {
        name
        kind
      }
    }
  }
}
```

## See Also

- **Examples**: `examples/basic-queries.md` - Query examples
- **Filters**: `reference/filters.md` - Filter syntax and enums
- **Patterns**: `reference/query-patterns.md` - Reusable patterns
- [GraphQL Specification](https://spec.graphql.org/)
- [Relay Connection Specification](https://relay.dev/graphql/connections.htm)
- [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
- [Phoenix GraphQL API Docs](https://arize.com/docs/ax/resources/graphql-api)
