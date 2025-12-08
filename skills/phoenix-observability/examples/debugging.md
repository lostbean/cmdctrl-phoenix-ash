# Debugging and Error Investigation

Queries for investigating errors, failures, and performance issues.

## Find All Recent Errors

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 50
        filterCondition: "status_code == 'ERROR'"
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
            spanKind
            statusCode
            statusMessage
            latencyMs
            startTime
            trace {
              traceId
            }
          }
        }
      }
    }
  }
}
```

Quick overview of recent failures across all span types.

⚠️ **Filter syntax**: See `reference/filters.md` for UPPERCASE enum rules.

## Failed LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusCode
            statusMessage
            latencyMs
            tokenCountTotal
            startTime
            input {
              value
            } # Prompt that caused failure
            output {
              value
            } # Error response
            attributes
            trace {
              traceId
            }
          }
        }
      }
    }
  }
}
```

Check `statusMessage`, `input.value` for prompt, `output.value` for error
details.

## Failed Tool Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'TOOL' and status_code == 'ERROR'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusCode
            statusMessage
            latencyMs
            startTime
            input {
              value
            } # Tool parameters
            output {
              value
            } # Error details
            trace {
              traceId
            }
          }
        }
      }
    }
  }
}
```

## Error Count by Type

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalErrors: recordCount(filterCondition: "status_code == 'ERROR'")
      llmErrors: recordCount(
        filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
      )
      toolErrors: recordCount(
        filterCondition: "span_kind == 'TOOL' and status_code == 'ERROR'"
      )
      agentErrors: recordCount(
        filterCondition: "span_kind == 'AGENT' and status_code == 'ERROR'"
      )
      chainErrors: recordCount(
        filterCondition: "span_kind == 'CHAIN' and status_code == 'ERROR'"
      )
    }
  }
}
```

Identify which component is failing most frequently.

## Trace Error Propagation

```graphql
query GetTraceWithErrors($traceId: GlobalID!) {
  node(id: $traceId) {
    ... on Trace {
      traceId
      startTime
      latencyMs
      numSpans
      rootSpan {
        id
        name
        statusCode
        propagatedStatusCode
      }
      spans(first: 100) {
        edges {
          node {
            id
            name
            spanKind
            parentId
            statusCode
            propagatedStatusCode
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

Variables: `{"traceId": "TRACE_GLOBAL_ID"}`

`propagatedStatusCode` shows if any descendant failed.

## Full Span Context for Debugging

```graphql
query GetFullSpanContext($spanId: GlobalID!) {
  node(id: $spanId) {
    ... on Span {
      id
      name
      spanKind
      statusCode
      statusMessage
      startTime
      endTime
      latencyMs

      # Hierarchy
      parentId
      numChildSpans
      propagatedStatusCode

      # I/O
      input {
        value
      }
      output {
        value
      }

      # OpenTelemetry attributes (may contain error details)
      attributes
      metadata

      # Token metrics
      tokenCountTotal
      tokenCountPrompt
      tokenCountCompletion

      # Descendants (to see if child span caused error)
      descendants(first: 50) {
        edges {
          node {
            id
            name
            spanKind
            statusCode
            statusMessage
            latencyMs
          }
        }
      }

      # Trace context
      trace {
        traceId
        numSpans
        latencyMs
      }

      # Project context
      project {
        id
        name
      }
    }
  }
}
```

Variables: `{"spanId": "SPAN_ID"}`

Complete debugging context. Check descendants to see if child span caused the
error.

## Slow Operations (Potential Issues)

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Very slow LLM calls (>10 seconds)
      slowLLM: spans(
        first: 20
        filterCondition: "span_kind == 'LLM' and latency_ms > 10000"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            statusCode
            startTime
            trace {
              traceId
            }
          }
        }
      }

      # Very slow tools (>5 seconds)
      slowTools: spans(
        first: 20
        filterCondition: "span_kind == 'TOOL' and latency_ms > 5000"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            statusCode
            startTime
            trace {
              traceId
            }
          }
        }
      }
    }
  }
}
```

High latency often indicates problems even if status is OK.

## Timeouts and Unset Status

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "status_code == 'UNSET'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            spanKind
            statusCode
            latencyMs
            startTime
            endTime
          }
        }
      }
    }
  }
}
```

UNSET status may indicate incomplete or timed-out operations.

## Error Rate Over Time

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Last hour
      recentTotal: recordCount(
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )
      recentErrors: recordCount(
        filterCondition: "status_code == 'ERROR'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # Last 24 hours
      dailyTotal: recordCount(
        timeRange: {
          start: "2025-11-16T19:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )
      dailyErrors: recordCount(
        filterCondition: "status_code == 'ERROR'"
        timeRange: {
          start: "2025-11-16T19:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # All time
      totalAll: recordCount
      totalErrors: recordCount(filterCondition: "status_code == 'ERROR'")
    }
  }
}
```

Calculate error rates: `(errors / total) * 100`.

## Find Specific Error Pattern

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 50
        filterCondition: "status_code == 'ERROR' and 'timeout' in name"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusCode
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

**Note**: Filtering by `statusMessage` content is not directly supported. Fetch
errors and filter client-side.

## Repeated Failures

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 100
        filterCondition: "status_code == 'ERROR'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            spanKind
            statusCode
            statusMessage
            startTime
          }
        }
      }
    }
  }
}
```

Group by `name` client-side to find which operations fail repeatedly.

## Debugging Workflow

**1. Find the error span:**

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "status_code == 'ERROR'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusMessage
            trace {
              id
              traceId
            }
          }
        }
      }
    }
  }
}
```

**2. Get full trace context:**

```graphql
query GetFullTrace($traceId: GlobalID!) {
  node(id: $traceId) {
    ... on Trace {
      traceId
      numSpans
      rootSpan {
        id
        name
        statusCode
        propagatedStatusCode
      }
      spans(first: 100) {
        edges {
          node {
            id
            name
            spanKind
            parentId
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

**3. Get detailed span info:**

```graphql
query GetSpanDetails($spanId: GlobalID!) {
  node(id: $spanId) {
    ... on Span {
      id
      name
      statusMessage
      input {
        value
      }
      output {
        value
      }
      attributes
      descendants(first: 20) {
        edges {
          node {
            id
            name
            statusCode
            statusMessage
          }
        }
      }
    }
  }
}
```

**4. Correlate with logs:**

Use Tidewave MCP to query application logs with the trace ID:

```
mcp__tidewave__get_logs
```

Filter logs by trace ID found in step 1.

## Performance Regression Detection

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Recent performance (last hour)
      recentP95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # Historical performance (previous hour)
      historicalP95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-17T17:00:00Z"
          end: "2025-11-17T18:00:00Z"
        }
      )

      # Overall baseline
      overallP95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'LLM'"
      )
    }
  }
}
```

Compare `recentP95` to `historicalP95` and `overallP95`. Significant increase
indicates regression.

## Error Debugging Checklist

- [ ] Get error count by type (LLM, TOOL, AGENT)
- [ ] Find recent error examples
- [ ] Get full trace context for failed operations
- [ ] Check `statusMessage` for error description
- [ ] Inspect `input.value` to see what caused the error
- [ ] Check `output.value` for error response details
- [ ] Look at `attributes` for additional OpenTelemetry context
- [ ] Check descendant spans to see if child caused error
- [ ] Correlate with application logs via Tidewave MCP
- [ ] Look for patterns (same tool, same time, etc.)
- [ ] Check if errors correlate with high latency
- [ ] Review recent deployments or config changes

## Common Error Patterns

**LLM Errors:**

- Rate limiting: `statusMessage` contains "rate limit"
- Context length: `statusMessage` contains "token limit" or "context length"
- Invalid request: Check `input.value` for malformed prompts
- Timeout: High `latencyMs` with ERROR status

**Tool Errors:**

- Authorization: `statusMessage` contains "forbidden" or "unauthorized"
- Not found: Resource doesn't exist
- Validation: Invalid parameters in `input.value`
- Timeout: Database or external API timeout

**Agent Errors:**

- Tool failure: Check `propagatedStatusCode` and descendant spans
- LLM failure: Agent couldn't complete due to LLM error
- Invalid state: Agent state machine error

## Integration with Tidewave

Combine Phoenix GraphQL with Tidewave MCP for complete debugging:

1. **Find error in Phoenix**: Get trace ID and timestamp
2. **Query logs in Tidewave**: Use trace ID to find related logs
3. **Check database state**: Query your application database via Tidewave
4. **Inspect code**: Use Tidewave to find source location

Full observability: traces (Phoenix) + logs (Tidewave) + code (Tidewave).

## Next Steps

- **Basic queries**: `basic-queries.md` - Query fundamentals
- **Agent analysis**: `agent-analysis.md` - Agent-specific debugging
- **LLM metrics**: `llm-metrics.md` - LLM performance analysis
- **Query patterns**: `reference/query-patterns.md` - Advanced filtering
