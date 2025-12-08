# LLM Metrics and Cost Analysis

Queries for analyzing LLM performance, token usage, and costs.

## Total Token Usage

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalTokens: tokenCountTotal
      promptTokens: tokenCountPrompt
      completionTokens: tokenCountCompletion
    }
  }
}
```

## LLM-Only Token Usage

Filter tokens used specifically by LLM spans:

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      llmTokensTotal: tokenCountTotal(filterCondition: "span_kind == 'LLM'")
      llmTokensPrompt: tokenCountPrompt(filterCondition: "span_kind == 'LLM'")
      llmTokensCompletion: tokenCountCompletion(
        filterCondition: "span_kind == 'LLM'"
      )
      llmCallCount: recordCount(filterCondition: "span_kind == 'LLM'")
    }
  }
}
```

⚠️ **Filter syntax**: See `reference/filters.md` for UPPERCASE enum rules.

## Top Token-Consuming LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
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
            startTime
            costSummary {
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
          }
        }
      }
    }
  }
}
```

Identify expensive LLM calls for optimization.

## LLM Latency Distribution

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      llmP50: spanLatencyMsQuantile(
        probability: 0.5
        filterCondition: "span_kind == 'LLM'"
      )
      llmP75: spanLatencyMsQuantile(
        probability: 0.75
        filterCondition: "span_kind == 'LLM'"
      )
      llmP90: spanLatencyMsQuantile(
        probability: 0.90
        filterCondition: "span_kind == 'LLM'"
      )
      llmP95: spanLatencyMsQuantile(
        probability: 0.95
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

P95/P99 show worst-case response times.

## Slowest LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'LLM'"
        sort: { col: latencyMs, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            tokenCountPrompt
            tokenCountCompletion
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

High token counts often correlate with high latency.

## Fastest LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'LLM' and latency_ms > 0"
        sort: { col: latencyMs, dir: asc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            startTime
          }
        }
      }
    }
  }
}
```

## Cost Analysis

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
        prompt {
          cost
          tokens
        }
        completion {
          cost
          tokens
        }
      }
    }
  }
}
```

Costs are in USD.

## Most Expensive LLM Calls

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
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
            startTime
            costSummary {
              total {
                cost
                tokens
              }
            }
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

Sorted by token count (proxy for cost).

## LLM Call Details

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

      # Token metrics
      tokenCountTotal
      tokenCountPrompt
      tokenCountCompletion

      # Cost
      costSummary {
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

      # I/O
      input {
        value
      } # JSON: messages, model, parameters
      output {
        value
      } # JSON: response, usage
      # OpenTelemetry attributes
      attributes # JSON: llm.model_name, llm.invocation_parameters
      # Context
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

⚠️ **Warning**: I/O fields can be very large. Only request when needed.

## LLM Throughput

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Last hour
      recentLLMCalls: recordCount(
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # Last 24 hours
      dailyLLMCalls: recordCount(
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-16T19:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # All time
      totalLLMCalls: recordCount(filterCondition: "span_kind == 'LLM'")
    }
  }
}
```

Calculate calls/hour: `recentLLMCalls / 1`.

## Token Usage by Time Period

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Last hour
      recentTokens: tokenCountTotal(
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # Last 24 hours
      dailyTokens: tokenCountTotal(
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-16T19:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      )

      # All time
      totalTokens: tokenCountTotal(filterCondition: "span_kind == 'LLM'")
    }
  }
}
```

## Cost by Time Period

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Last hour
      recentCost: costSummary(
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-17T18:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      ) {
        total {
          cost
          tokens
        }
      }

      # Last 24 hours
      dailyCost: costSummary(
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-16T19:00:00Z"
          end: "2025-11-17T19:00:00Z"
        }
      ) {
        total {
          cost
          tokens
        }
      }
    }
  }
}
```

Project future costs based on recent usage.

## Average Tokens per Call

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalTokens: tokenCountTotal(filterCondition: "span_kind == 'LLM'")
      totalCalls: recordCount(filterCondition: "span_kind == 'LLM'")
    }
  }
}
```

Calculate average: `totalTokens / totalCalls`.

## LLM Success Rate

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      totalLLM: recordCount(filterCondition: "span_kind == 'LLM'")
      successfulLLM: recordCount(
        filterCondition: "span_kind == 'LLM' and status_code == 'OK'"
      )
      failedLLM: recordCount(
        filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
      )
    }
  }
}
```

Calculate success rate: `(successfulLLM / totalLLM) * 100`.

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
            }
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

Check `statusMessage` and `input.value` for debugging clues.

## LLM Performance Dashboard

Comprehensive LLM metrics in one query:

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      # Counts
      totalLLMCalls: recordCount(filterCondition: "span_kind == 'LLM'")
      successfulCalls: recordCount(
        filterCondition: "span_kind == 'LLM' and status_code == 'OK'"
      )
      failedCalls: recordCount(
        filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
      )

      # Token usage
      totalTokens: tokenCountTotal(filterCondition: "span_kind == 'LLM'")
      promptTokens: tokenCountPrompt(filterCondition: "span_kind == 'LLM'")
      completionTokens: tokenCountCompletion(
        filterCondition: "span_kind == 'LLM'"
      )

      # Latency
      p50: spanLatencyMsQuantile(
        probability: 0.5
        filterCondition: "span_kind == 'LLM'"
      )
      p95: spanLatencyMsQuantile(
        probability: 0.95
        filterCondition: "span_kind == 'LLM'"
      )
      p99: spanLatencyMsQuantile(
        probability: 0.99
        filterCondition: "span_kind == 'LLM'"
      )

      # Cost
      costs: costSummary(filterCondition: "span_kind == 'LLM'") {
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

      # Recent expensive calls
      expensiveCalls: spans(
        first: 5
        filterCondition: "span_kind == 'LLM'"
        sort: { col: tokenCountTotal, dir: desc }
      ) {
        edges {
          node {
            id
            name
            tokenCountTotal
            latencyMs
            costSummary {
              total {
                cost
              }
            }
            startTime
          }
        }
      }

      # Recent slow calls
      slowCalls: spans(
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
            startTime
          }
        }
      }
    }
  }
}
```

Single query for complete LLM observability dashboard.

## Cost Optimization Tips

1. **Monitor token usage**: Track `tokenCountTotal` trends
2. **Identify expensive calls**: Sort by `tokenCountTotal`
3. **Analyze latency**: High latency often indicates large prompts
4. **Check prompt efficiency**: Compare `tokenCountPrompt` across similar
   operations
5. **Use percentiles**: P95/P99 reveal outliers worth optimizing

## Next Steps

- **Agent analysis**: `agent-analysis.md` - Agent-level metrics
- **Debugging**: `debugging.md` - Error investigation
- **Query patterns**: `reference/query-patterns.md` - Optimization tips
