# Basic Queries

Foundational queries for Phoenix GraphQL. Start here after `quick-start.md`.

## List All Projects

```graphql
query {
  projects {
    edges {
      node {
        id
        name
        traceCount
        recordCount
      }
    }
  }
}
```

Use project `id` for all subsequent queries.

## Get Project Details

```graphql
query {
  node(id: "UHJvamVjdDoy") {
    ... on Project {
      name
      traceCount
      recordCount
      tokenCountTotal
      startTime
      endTime
    }
  }
}
```

## Recent Spans

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(first: 10, sort: { col: startTime, dir: desc }) {
        edges {
          node {
            id
            name
            spanKind
            statusCode
            latencyMs
            startTime
          }
        }
      }
    }
  }
}
```

## Filter by Span Kind

**LLM spans:**

```graphql
filterCondition: "span_kind == 'LLM'"
```

**Tool spans:**

```graphql
filterCondition: "span_kind == 'TOOL'"
```

**Agent spans:**

```graphql
filterCondition: "span_kind == 'AGENT'"
```

⚠️ **Always UPPERCASE**: `'LLM'` not `'llm'`. See `reference/filters.md` for all
values.

## Filter by Status

**Successful:**

```graphql
filterCondition: "status_code == 'OK'"
```

**Failed:**

```graphql
filterCondition: "status_code == 'ERROR'"
```

**Unset (incomplete):**

```graphql
filterCondition: "status_code == 'UNSET'"
```

## Combine Filters

**Failed LLM calls:**

```graphql
filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
```

**Successful tools or LLM:**

```graphql
filterCondition: "(span_kind == 'LLM' or span_kind == 'TOOL') and status_code == 'OK'"
```

See `reference/filters.md` for all operators.

## Filter by Time Range

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 50
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      ) {
        edges {
          node {
            id
            name
            startTime
          }
        }
      }
    }
  }
}
```

Format: ISO 8601 `YYYY-MM-DDTHH:MM:SSZ`

## Sort Spans

**By latency (slowest first):**

```graphql
sort: {col: latencyMs, dir: desc}
```

**By time (most recent first):**

```graphql
sort: {col: startTime, dir: desc}
```

**By tokens:**

```graphql
sort: {col: tokenCountTotal, dir: desc}
```

Available columns: `startTime`, `endTime`, `latencyMs`, `tokenCountTotal`,
`tokenCountPrompt`, `tokenCountCompletion`

## Get Span Details

```graphql
query {
  node(id: "SPAN_ID") {
    ... on Span {
      id
      name
      spanKind
      statusCode
      startTime
      endTime
      latencyMs
      tokenCountTotal
      parentId
      trace {
        traceId
        numSpans
      }
      project {
        name
      }
    }
  }
}
```

## Get Span I/O

```graphql
query {
  node(id: "SPAN_ID") {
    ... on Span {
      id
      name
      input {
        value
      } # JSON string
      output {
        value
      } # JSON string
      attributes # JSON string
    }
  }
}
```

⚠️ **Warning**: I/O fields can be very large. Only request when needed.

## Pagination

```graphql
query GetSpans($cursor: String) {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(first: 20, after: $cursor) {
        edges {
          cursor
          node {
            id
            name
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}
```

**First page**: `{"cursor": null}` **Next page**:
`{"cursor": "endCursor_from_previous"}`

## Get Trace

```graphql
query {
  node(id: "TRACE_ID") {
    ... on Trace {
      traceId
      startTime
      latencyMs
      numSpans
      tokenCountTotal
      rootSpan {
        id
        name
        spanKind
      }
    }
  }
}
```

## Get Trace by OpenTelemetry ID

```graphql
query {
  getTraceByOtelId(traceId: "2167f156bac7e54b0778cd39d35392dd") {
    id
    traceId
    numSpans
    latencyMs
    rootSpan {
      name
      spanKind
    }
  }
}
```

Use when you have trace ID from application logs.

## Count Spans

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalSpans: recordCount
      llmSpans: recordCount(filterCondition: "span_kind == 'LLM'")
      toolSpans: recordCount(filterCondition: "span_kind == 'TOOL'")
      errorSpans: recordCount(filterCondition: "status_code == 'ERROR'")
    }
  }
}
```

Efficient - doesn't fetch span data.

## Filter by Name

**Exact match:**

```graphql
filterCondition: "name == 'submit_suggestion'"
```

**Contains:**

```graphql
filterCondition: "'llm' in name"
```

## Filter by Latency

**Slow operations (>10 seconds):**

```graphql
filterCondition: "latency_ms > 10000"
```

**Fast operations (<1 second):**

```graphql
filterCondition: "latency_ms < 1000"
```

**Range:**

```graphql
filterCondition: "latency_ms >= 1000 and latency_ms <= 5000"
```

## Common Patterns

### Recent Failed LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusMessage
            latencyMs
            startTime
          }
        }
      }
    }
  }
}
```

### Slowest Tool Executions

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'TOOL'"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            startTime
          }
        }
      }
    }
  }
}
```

### Most Token-Heavy LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'LLM'"
        sort: { col: tokenCountTotal, dir: desc }
      ) {
        edges {
          node {
            id
            name
            tokenCountTotal
            tokenCountPrompt
            tokenCountCompletion
            latencyMs
          }
        }
      }
    }
  }
}
```

## Combining Features

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'LLM' and latency_ms > 5000"
        timeRange: {
          start: "2025-11-17T00:00:00Z"
          end: "2025-11-18T00:00:00Z"
        }
        sort: { col: tokenCountTotal, dir: desc }
      ) {
        edges {
          cursor
          node {
            id
            name
            latencyMs
            tokenCountTotal
            costSummary {
              total {
                cost
              }
            }
            startTime
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}
```

Combines: filter, time range, sorting, pagination, cost data.

## Next Steps

- **Agent analysis**: `agent-analysis.md` - Agent-specific queries
- **LLM metrics**: `llm-metrics.md` - Token usage, costs, latency
- **Debugging**: `debugging.md` - Error investigation
- **Filters**: `reference/filters.md` - Complete filter syntax
- **Fragments**: `reference/query-fragments.md` - Reusable patterns

## Common Mistakes

❌ **Wrong**: `filterCondition: "span_kind == 'llm'"` (lowercase) ✅
**Correct**: `filterCondition: "span_kind == 'LLM'"` (UPPERCASE)

❌ **Wrong**: `filterCondition: "status == 'OK'"` (wrong field name) ✅
**Correct**: `filterCondition: "status_code == 'OK'"`

See `reference/filters.md` for complete rules.
