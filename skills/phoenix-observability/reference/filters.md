# Filter Reference

Single source of truth for Phoenix GraphQL filtering.

## Critical Rule: Use UPPERCASE for Enums

**Always use UPPERCASE** for `span_kind` and `status_code`:

```graphql
# ✅ Correct
filterCondition: "span_kind == 'LLM'"
filterCondition: "status_code == 'ERROR'"

# ❌ Wrong - will not match
filterCondition: "span_kind == 'llm'"
filterCondition: "status_code == 'error'"
```

## Span Kind Values

| Value         | Description           |
| ------------- | --------------------- |
| `'LLM'`       | Language model calls  |
| `'TOOL'`      | Tool executions       |
| `'AGENT'`     | Agent operations      |
| `'CHAIN'`     | Chain operations      |
| `'RETRIEVER'` | Document retrieval    |
| `'EMBEDDING'` | Embedding generation  |
| `'RERANKER'`  | Reranking operations  |
| `'EVALUATOR'` | Evaluation operations |
| `'GUARDRAIL'` | Safety checks         |
| `'UNKNOWN'`   | Unknown type          |

## Status Code Values

| Value     | Description                             |
| --------- | --------------------------------------- |
| `'OK'`    | Successful execution                    |
| `'ERROR'` | Failed execution                        |
| `'UNSET'` | Status not set (incomplete/in-progress) |

## Filter Operators

| Operator   | Usage           | Example                                         |
| ---------- | --------------- | ----------------------------------------------- |
| `==`       | Equality        | `span_kind == 'LLM'`                            |
| `!=`       | Inequality      | `status_code != 'ERROR'`                        |
| `>`, `<`   | Comparison      | `latency_ms > 1000`                             |
| `>=`, `<=` | Comparison      | `latency_ms >= 1000`                            |
| `and`      | Logical AND     | `span_kind == 'LLM' and status_code == 'ERROR'` |
| `or`       | Logical OR      | `span_kind == 'LLM' or span_kind == 'TOOL'`     |
| `in`       | String contains | `'generateText' in name`                        |

## Working Filters

✅ **These filters work:**

```graphql
# By span kind
filterCondition: "span_kind == 'LLM'"
filterCondition: "span_kind == 'TOOL'"

# By status
filterCondition: "status_code == 'OK'"
filterCondition: "status_code == 'ERROR'"

# By name
filterCondition: "name == 'submit_suggestion'"
filterCondition: "'llm' in name"

# By latency
filterCondition: "latency_ms > 10000"
filterCondition: "latency_ms >= 1000 and latency_ms <= 5000"

# Combined
filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
filterCondition: "(span_kind == 'LLM' or span_kind == 'TOOL') and status_code == 'OK'"
```

## Non-Working Filters

❌ **These do NOT work (tested):**

```graphql
# Token count filtering doesn't work
filterCondition: "token_count_total > 1000"

# Attribute access doesn't work
filterCondition: "attributes['llm.model_name'] == 'gpt-4'"
```

**Workaround:** Use `latency_ms` as proxy for token usage, or fetch data and
filter client-side.

## Common Filter Patterns

### Failed LLM Calls

```graphql
filterCondition: "span_kind == 'LLM' and status_code == 'ERROR'"
```

### Slow Operations

```graphql
filterCondition: "latency_ms > 10000"
```

### Specific Tool

```graphql
filterCondition: "span_kind == 'TOOL' and name == 'submit_suggestion'"
```

### Successful Agents

```graphql
filterCondition: "span_kind == 'AGENT' and status_code == 'OK'"
```

### Tools or LLM Calls

```graphql
filterCondition: "span_kind == 'LLM' or span_kind == 'TOOL'"
```

## Validation

Validate complex filters before using:

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      validateSpanFilterCondition(
        condition: "span_kind == 'LLM' and latency_ms > 10000"
      ) {
        isValid
        errorMessage
      }
    }
  }
}
```

## See Also

- `query-patterns.md` - Advanced filtering techniques
- `query-fragments.md` - Combining filters with other patterns
- `examples/basic-queries.md` - Filter usage examples
