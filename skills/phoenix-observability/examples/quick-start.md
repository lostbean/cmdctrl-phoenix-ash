# Quick Start - Phoenix Observability

Get started querying Phoenix traces in 3 steps.

## Prerequisites

- Phoenix running at `http://localhost:6060`
- Your application exporting traces via agent_obs
- MCP GraphQL server configured (in `.mcp.json`)

Verify: `curl http://localhost:6060/graphql` should respond.

## Step 1: List Projects

Find your project ID:

```graphql
query {
  projects {
    edges {
      node {
        id
        name
        traceCount
      }
    }
  }
}
```

Copy the `id` for your project (e.g., `"UHJvamVjdDoy"` for "buzz-agent").

## Step 2: Recent LLM Calls

Query recent LLM activity:

```graphql
query {
  node(id: "YOUR_PROJECT_ID") {
    ... on Project {
      spans(
        first: 5
        filterCondition: "span_kind == 'LLM'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            statusCode
            startTime
          }
        }
      }
    }
  }
}
```

Replace `YOUR_PROJECT_ID` with the ID from step 1.

## Step 3: Explore More

You can now:

- **Filter spans**: Try `"span_kind == 'TOOL'"` or `"status_code == 'ERROR'"`
- **Sort differently**: Change `sort: {col: latencyMs, dir: desc}` for slowest
  first
- **Get more results**: Increase `first: 5` to `first: 20`

## Using Phoenix UI URLs

When you click on a span in the Phoenix UI, the URL contains useful IDs for
GraphQL queries.

**URL Format:**

```
http://localhost:6060/projects/{PROJECT_ID}/spans/{TRACE_ID}?selectedSpanNodeId={SPAN_ID}
```

**Extract IDs for GraphQL:**

1. **Project ID** - Base64 encoded, use directly:
   - URL: `UHJvamVjdDoy`
   - Query: `node(id: "UHJvamVjdDoy")`

2. **Trace ID** - OpenTelemetry format, use with `getTraceByOtelId`:
   - URL: `818a8ea6851e4c5948e1e898b6cffaf6`
   - Query: `getTraceByOtelId(traceId: "818a8ea6851e4c5948e1e898b6cffaf6")`

3. **Span ID** - URL-encoded Base64, decode `%3D` to `=` then use:
   - URL: `U3BhbjoyMzM2OA%3D%3D` → `U3BhbjoyMzM2OA==`
   - Query: `node(id: "U3BhbjoyMzM2OA==")`

**Example workflow:**

1. Find error in Phoenix UI → Click on span
2. Copy URL from browser
3. Extract trace ID from URL path
4. Query with `getTraceByOtelId` to get full trace context

## Next Steps

- **Learn filtering**: See `reference/filters.md` for filter syntax
- **More queries**: See `examples/basic-queries.md` for common patterns
- **Analyze agents**: See `examples/agent-analysis.md` for agent metrics
- **Debug errors**: See `examples/debugging.md` for error investigation

## Common First Questions

**Q: How do I find failed operations?**

```graphql
filterCondition: "status_code == 'ERROR'"
```

**Q: How do I get token usage?**

```graphql
query {
  node(id: "YOUR_PROJECT_ID") {
    ... on Project {
      tokenCountTotal
      tokenCountPrompt
      tokenCountCompletion
    }
  }
}
```

**Q: How do I filter by time?**

```graphql
timeRange: {
  start: "2025-11-17T18:00:00Z"
  end: "2025-11-17T19:00:00Z"
}
```

See `reference/query-fragments.md` for reusable patterns.
