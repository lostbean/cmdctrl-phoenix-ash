# Agent Analysis

Queries for analyzing agent performance and behavior.

## Agent Overview

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalSpans: recordCount
      agentSpans: recordCount(filterCondition: "span_kind == 'AGENT'")
      toolSpans: recordCount(filterCondition: "span_kind == 'TOOL'")
      llmSpans: recordCount(filterCondition: "span_kind == 'LLM'")
    }
  }
}
```

## Recent Agent Executions

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'AGENT'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusCode
            latencyMs
            cumulativeTokenCountTotal
            numChildSpans
            startTime
          }
        }
      }
    }
  }
}
```

**Note**: `cumulativeTokenCountTotal` includes all child LLM calls.

## Tool Usage

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 50
        filterCondition: "span_kind == 'TOOL'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            statusCode
            startTime
          }
        }
      }
    }
  }
}
```

Group by `name` client-side to find most frequent tools.

## Tool Performance

Slowest tools first:

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'TOOL'"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            statusCode
            startTime
          }
        }
      }
    }
  }
}
```

## Agent Token Usage

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'AGENT'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            tokenCountTotal
            cumulativeTokenCountTotal
            numChildSpans
            startTime
          }
        }
      }
    }
  }
}
```

## Complete Agent Execution Flow

```graphql
query GetAgentFlow($spanId: GlobalID!) {
  node(id: $spanId) {
    ... on Span {
      id
      name
      statusCode
      latencyMs
      cumulativeTokenCountTotal
      numChildSpans
      descendants(first: 100) {
        edges {
          node {
            id
            name
            spanKind
            parentId
            statusCode
            latencyMs
            tokenCountTotal
            startTime
          }
        }
      }
      trace {
        traceId
        numSpans
      }
    }
  }
}
```

Variables: `{"spanId": "AGENT_SPAN_ID"}`

Build execution tree client-side using `parentId`.

## Agent Success Rate

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalAgents: recordCount(filterCondition: "span_kind == 'AGENT'")
      successfulAgents: recordCount(
        filterCondition: "span_kind == 'AGENT' and status_code == 'OK'"
      )
      failedAgents: recordCount(
        filterCondition: "span_kind == 'AGENT' and status_code == 'ERROR'"
      )
    }
  }
}
```

Calculate: `(successfulAgents / totalAgents) * 100`

## Failed Agents

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'AGENT' and status_code == 'ERROR'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusMessage
            latencyMs
            numChildSpans
            trace {
              traceId
            }
            startTime
          }
        }
      }
    }
  }
}
```

## Agent Chains

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "span_kind == 'CHAIN'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            numChildSpans
            startTime
          }
        }
      }
    }
  }
}
```

## Tool Call Sequence

Get all operations in a trace:

```graphql
query GetToolSequence($traceId: GlobalID!) {
  node(id: $traceId) {
    ... on Trace {
      traceId
      latencyMs
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

Variables: `{"traceId": "TRACE_GLOBAL_ID"}`

## Performance Metrics

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Agent latency
      agentP50: spanLatencyMsQuantile(
        probability: 0.5
        filterCondition: "span_kind == 'AGENT'"
      )
      agentP95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'AGENT'"
      )

      # Tool latency
      toolP50: spanLatencyMsQuantile(
        probability: 0.5
        filterCondition: "span_kind == 'TOOL'"
      )
      toolP95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'TOOL'"
      )

      # Token usage
      totalAgentTokens: tokenCountTotal(filterCondition: "span_kind == 'AGENT'")

      # Counts
      totalAgents: recordCount(filterCondition: "span_kind == 'AGENT'")
      totalTools: recordCount(filterCondition: "span_kind == 'TOOL'")
    }
  }
}
```

P95/P99 show worst-case latency.

## Time-Based Analysis

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Last hour
      recentAgents: recordCount(
        filterCondition: "span_kind == 'AGENT'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # Failed in last hour
      recentFailures: recordCount(
        filterCondition: "span_kind == 'AGENT' and status_code == 'ERROR'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )
    }
  }
}
```

## Slowest Operations

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      slowestLLM: spans(
        first: 5
        filterCondition: "span_kind == 'LLM'"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            trace {
              traceId
            }
          }
        }
      }

      slowestTools: spans(
        first: 5
        filterCondition: "span_kind == 'TOOL'"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
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

## Dashboard Query

```graphql
query AgentDashboard {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Counts
      agentCount: recordCount(filterCondition: "span_kind == 'AGENT'")
      toolCount: recordCount(filterCondition: "span_kind == 'TOOL'")
      llmCount: recordCount(filterCondition: "span_kind == 'LLM'")

      # Success/Error
      successfulAgents: recordCount(
        filterCondition: "span_kind == 'AGENT' and status_code == 'OK'"
      )
      failedAgents: recordCount(
        filterCondition: "span_kind == 'AGENT' and status_code == 'ERROR'"
      )

      # Performance
      agentP50: spanLatencyMsQuantile(
        probability: 0.5
        filterCondition: "span_kind == 'AGENT'"
      )
      agentP95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'AGENT'"
      )

      # Token usage
      totalTokens: tokenCountTotal
      agentTokens: tokenCountTotal(filterCondition: "span_kind == 'AGENT'")

      # Recent activity
      recentAgents: spans(
        first: 5
        filterCondition: "span_kind == 'AGENT'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            statusCode
            latencyMs
            cumulativeTokenCountTotal
            startTime
          }
        }
      }
    }
  }
}
```

## Key Insights

- **Cumulative metrics** include all child operations
- **Propagated status** shows if any descendant failed
- **Percentiles** (P95, P99) reveal worst-case performance
- **Time ranges** help analyze recent activity
- **Trace IDs** connect agents to complete execution context

## Next Steps

- **LLM metrics**: `llm-metrics.md` - Detailed LLM analysis
- **Debugging**: `debugging.md` - Error investigation
- **Filters**: `reference/filters.md` - Filter syntax
- **Fragments**: `reference/query-fragments.md` - Reusable patterns
