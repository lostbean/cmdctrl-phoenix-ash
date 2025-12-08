# Query Patterns and Best Practices

Proven patterns for querying Phoenix GraphQL API effectively.

## Core Query Patterns

For basic filter syntax, sorting, and pagination patterns, see:

- **Filters**: `reference/filters.md` - Complete filter syntax and enum values
- **Fragments**: `reference/query-fragments.md` - Reusable query patterns

This document focuses on advanced query patterns and best practices.

## Aggregate Queries

Use aggregate fields for summaries without fetching individual records.

### Token Counts

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Total across all spans
      totalTokens: tokenCountTotal
      promptTokens: tokenCountPrompt
      completionTokens: tokenCountCompletion

      # Filtered by span kind
      llmTokens: tokenCountTotal(filterCondition: "span_kind == 'LLM'")
      toolTokens: tokenCountTotal(filterCondition: "span_kind == 'TOOL'")
    }
  }
}
```

### Record Counts

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalTraces: traceCount
      totalSpans: recordCount
      llmSpans: recordCount(filterCondition: "span_kind == 'LLM'")
      errorSpans: recordCount(filterCondition: "status_code == 'ERROR'")
    }
  }
}
```

### Percentiles

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # All spans
      p50: spanLatencyMsQuantile(probability: 0.5)
      p95: spanLatencyMsQuantile(probability: 0.95)
      p99: spanLatencyMsQuantile(probability: 0.99)

      # LLM spans only
      llmP50: spanLatencyMsQuantile(
        probability: 0.5
        filterCondition: "span_kind == 'LLM'"
      )
      llmP99: spanLatencyMsQuantile(
        probability: 0.99
        filterCondition: "span_kind == 'LLM'"
      )
    }
  }
}
```

**Common probabilities:**

- `0.5` - Median (50th percentile)
- `0.75` - 75th percentile
- `0.90` - 90th percentile
- `0.95` - 95th percentile
- `0.99` - 99th percentile

### Cost Summaries

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalCost: costSummary {
        total {
          cost
          tokens
        }
        prompt {
          cost
          tokens
        }
        completion {
          cost
          tokens
        }
      }

      llmCost: costSummary(filterCondition: "span_kind == 'LLM'") {
        total {
          cost
          tokens
        }
      }
    }
  }
}
```

## Hierarchical Queries

### Parent/Child Relationships

```graphql
query {
  node(id: "SPAN_ID") {
    ... on Span {
      id
      name
      parentId # null for root spans
      numChildSpans

      # Get all descendants
      descendants(first: 100) {
        edges {
          node {
            id
            name
            parentId
            latencyMs
          }
        }
      }
    }
  }
}
```

### Trace to Spans

```graphql
query {
  node(id: "TRACE_ID") {
    ... on Trace {
      id
      traceId
      rootSpan {
        id
        name
        spanKind
      }
      spans(first: 100) {
        edges {
          node {
            id
            name
            parentId
            latencyMs
          }
        }
      }
    }
  }
}
```

### Span to Trace

```graphql
query {
  node(id: "SPAN_ID") {
    ... on Span {
      id
      name
      trace {
        traceId
        numSpans
        latencyMs
      }
    }
  }
}
```

## Cumulative Metrics

Cumulative fields include metrics from descendant spans:

```graphql
query {
  node(id: "SPAN_ID") {
    ... on Span {
      id
      name

      # Just this span
      tokenCountTotal
      tokenCountPrompt
      tokenCountCompletion

      # This span + all descendants
      cumulativeTokenCountTotal
      cumulativeTokenCountPrompt
      cumulativeTokenCountCompletion

      # Propagated from descendants
      statusCode # This span's status
      propagatedStatusCode # Includes descendant errors
    }
  }
}
```

## Filter Validation

Validate filters before running expensive queries:

```graphql
query ValidateFilter($projectId: GlobalID!, $condition: String!) {
  node(id: $projectId) {
    ... on Project {
      validateSpanFilterCondition(condition: $condition) {
        isValid
        errorMessage
      }
    }
  }
}
```

Variables:
`{"projectId": "PROJECT_ID", "condition": "span_kind == 'LLM' and latency_ms > 10000"}`

## Best Practices

### 1. Use Uppercase for Enums

⚠️ **Always use uppercase** for `span_kind` and `status_code`:

```graphql
# ✅ Correct
filterCondition: "span_kind == 'LLM'"

# ❌ Wrong - will not match
filterCondition: "span_kind == 'llm'"
```

See `reference/filters.md` for complete enum documentation.

### 2. Validate Complex Filters

For complex filter conditions, validate before running:

```graphql
validateSpanFilterCondition(condition: "...")
```

### 3. Request Only Needed Fields

GraphQL is most efficient when you request only what you need:

```graphql
# ✅ Good - minimal fields
{
  id
  name
  latencyMs
}

# ❌ Wasteful - unnecessary fields
{
  id
  name
  latencyMs
  input {
    value
  } # Only if needed
  output {
    value
  } # Only if needed
  attributes # Large JSON string
}
```

⚠️ **Warning**: `input`, `output`, and `attributes` fields can be very large.

### 4. Use Time Ranges

For recent data, always use `timeRange`:

```graphql
timeRange: {
  start: "2025-11-17T00:00:00Z"
  end: "2025-11-18T00:00:00Z"
}
```

See `reference/query-fragments.md` for time range patterns.

### 5. Combine Filters

More efficient to combine filters than make multiple queries:

```graphql
# ✅ Efficient - one query
filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"

# ❌ Inefficient - two queries
# Query 1: filterCondition: "span_kind == 'LLM'"
# Query 2: filterCondition: "status_code == 'ERROR'"
```

### 6. Use Aggregates for Counts

Don't fetch records just to count them:

```graphql
# ✅ Efficient
recordCount(filterCondition: "span_kind == 'LLM'")

# ❌ Wasteful
spans(first: 10000, filterCondition: "span_kind == 'LLM'") {
  edges { node { id } }
}
```

### 7. Limit Page Size

For queries with large fields (input/output), use smaller pages:

```graphql
# With I/O fields
spans(first: 10, filterCondition: "span_kind == 'TOOL'") {
  edges {
    node {
      input { value }
      output { value }
    }
  }
}

# Without I/O fields
spans(first: 100, filterCondition: "span_kind == 'TOOL'") {
  edges {
    node {
      id
      name
      latencyMs
    }
  }
}
```

### 8. Use Variables

Use GraphQL variables for dynamic values:

```graphql
query GetSpans($projectId: GlobalID!, $filter: String!) {
  node(id: $projectId) {
    ... on Project {
      spans(first: 50, filterCondition: $filter) {
        edges {
          node {
            id
            name
          }
        }
      }
    }
  }
}
```

Variables: `{"projectId": "PROJECT_ID", "filter": "span_kind == 'LLM'"}`

## Known Limitations

Based on testing:

1. **Token count filtering**: `token_count_total > N` does not work
2. **Attribute filtering**: Direct attribute access not supported
3. **Time series queries**: Some time series queries return errors
4. **Top models**: `topModelsByCost` and `topModelsByTokenCount` failed

**Workarounds:**

- Filter by `latency_ms` as proxy for token usage
- Fetch attributes and filter client-side
- Use aggregate fields instead of time series

See `reference/filters.md` for complete list of working vs non-working filters.

## See Also

- **Filters**: `reference/filters.md` - Complete filter syntax
- **Fragments**: `reference/query-fragments.md` - Reusable patterns
- **Schema**: `reference/schema.md` - Type reference
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
- [Relay Pagination](https://relay.dev/graphql/connections.htm)
- [Phoenix Query API](https://arize.com/docs/ax/resources/graphql-api)
