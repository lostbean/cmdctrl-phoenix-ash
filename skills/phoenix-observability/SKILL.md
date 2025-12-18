---
name: phoenix-observability
description: |
  Phoenix GraphQL observability for LLM and application traces. Use when
  analyzing LLM performance, debugging API calls, querying traces and spans, or
  investigating OpenTelemetry telemetry data.
---

# Phoenix Observability Skill

Query and analyze LLM and application observability data from Arize Phoenix via
GraphQL.

## Try It Now

**3 steps to query Phoenix:**

1. **List projects**: Query all projects to get project ID
2. **Recent LLM calls**: Query latest LLM spans with tokens
3. **Explore**: Filter by status, sort by latency, analyze costs

See `examples/quick-start.md` for copy-paste queries.

## What This Skill Covers

- **GraphQL Queries**: Query traces, spans via MCP tools
- **LLM Debugging**: Analyze tool calls, errors, performance
- **LLM Metrics**: Token usage, latency, costs
- **Error Investigation**: Debug failures, trace propagation

## When to Use This Skill

- Analyzing LLM application performance and behavior
- Debugging failed executions or API calls
- Investigating LLM costs and token usage
- Querying traces for specific time ranges
- Building observability dashboards

## Quick Reference

**Phoenix**: LLM observability platform at `http://localhost:6060` **Traces**:
Complete execution paths for LLM applications **Spans**: Individual operations
(LLM calls, function executions) **MCP Tools**:
`mcp__phoenix-graphql__query_graphql`

## Progressive Learning Path

1. **Quick start** → `examples/quick-start.md` (3 queries to try now)
2. **Learn filters** → `reference/filters.md` (UPPERCASE enums, operators)
3. **Basic queries** → `examples/basic-queries.md` (filtering, sorting,
   pagination)
4. **Choose use case**:
   - Application analysis → `examples/app-analysis.md`
   - LLM metrics → `examples/llm-metrics.md`
   - Debugging → `examples/debugging.md`
5. **Deep dive** → `reference/schema.md`, `reference/query-patterns.md`
6. **Advanced** → `reference/advanced.md` (agent_obs integration, telemetry)

## Common Tasks

| Task                     | File                           |
| ------------------------ | ------------------------------ |
| Query recent spans       | `examples/basic-queries.md`    |
| Analyze app performance  | `examples/app-analysis.md`     |
| Debug failed calls       | `examples/debugging.md`        |
| Check LLM token usage    | `examples/llm-metrics.md`      |
| Understand filter syntax | `reference/filters.md`         |
| Reuse query patterns     | `reference/query-fragments.md` |

## Related Skills

- **ash-framework**: Application resources and data flow
- **reactor-oban**: Background jobs and workflows
- **elixir-testing**: Testing with telemetry assertions

## Integration Setup

To export traces to Phoenix, use OpenTelemetry libraries:

- **Config**: Configure OpenTelemetry exporter in `config/runtime.exs`
- **Projects**: Define project names for organizing traces
- **Details**: See `reference/advanced.md` for OpenTelemetry integration,
  telemetry events, configuration

## Workflow Patterns

**Debugging failures**: Error filter → trace details → span context → correlate
logs (Tidewave MCP)

**Performance analysis**: Time range → filter by kind → analyze latency →
identify bottlenecks

**Cost monitoring**: LLM spans → sum tokens → calculate costs → optimize

## Troubleshooting

**Phoenix not running**: `curl http://localhost:6060/graphql` - See
`reference/setup.md`

**Empty results**: Check time ranges, verify traces in Phoenix UI, try without
filters

**Query errors**: Use UPPERCASE enums (`'LLM'` not `'llm'`) - See
`reference/filters.md`

**No traces**: Check OpenTelemetry config in `config/runtime.exs` - See
`reference/advanced.md`

**MCP issues**: Verify `.mcp.json` configuration - See `reference/setup.md`

## Key Reminders

⚠️ **UPPERCASE for enums**: `span_kind == 'LLM'` not `'llm'` (see
`reference/filters.md`) ⚠️ **Time ranges help**: Filter recent data for better
performance ⚠️ **Aggregates are efficient**: Use `recordCount`,
`tokenCountTotal` instead of fetching all spans

## See Also

- [Phoenix Documentation](https://docs.arize.com/phoenix)
- [OpenTelemetry Elixir](https://opentelemetry.io/docs/languages/erlang/)
- `reference/advanced.md` - Telemetry events, OpenTelemetry integration
