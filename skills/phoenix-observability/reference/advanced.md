# Advanced Configuration

Advanced Phoenix and agent_obs configuration for MyApp.

## Application Integration

### agent_obs Configuration

**Runtime Config** (`config/runtime.exs:29-39`):

```elixir
config :agent_obs,
  otlp_endpoint: System.get_env("PHOENIX_OTLP_ENDPOINT", "http://localhost:4317"),
  handlers: [AgentObs.Handlers.Phoenix]
```

**Application Config** (`config/config.exs:110-112`):

```elixir
config :agent_obs,
  enabled: true
```

### Environment Variables

```bash
# Change Phoenix OTLP endpoint
export PHOENIX_OTLP_ENDPOINT="http://localhost:4317"
```

## Telemetry Events

agent_obs exports these events to Phoenix:

| Event                          | Description               |
| ------------------------------ | ------------------------- |
| `[:agent_obs, :agent, :start]` | Agent execution started   |
| `[:agent_obs, :agent, :stop]`  | Agent execution completed |
| `[:agent_obs, :tool, :start]`  | Tool execution started    |
| `[:agent_obs, :tool, :stop]`   | Tool execution completed  |
| `[:agent_obs, :llm, :start]`   | LLM request started       |
| `[:agent_obs, :llm, :stop]`    | LLM request completed     |

### Key Files Using agent_obs

- `lib/my_app/llm/agent.ex:178` - `AgentObs.trace_agent/3`
- `lib/my_app/llm/agent/streaming_executor.ex:20` -
  `AgentObs.ReqLLM.trace_stream_text/3`
- `lib/my_app/llm/agent/tool_handler.ex:70` - `AgentObs.trace_tool/3`
- `lib/my_app/llm/agent/non_streaming_executor.ex:27` -
  `AgentObs.ReqLLM.trace_generate_text/3`

## MCP Server Advanced Options

### Authentication

Add headers for authenticated Phoenix instances:

```json
{
  "env": {
    "ENDPOINT": "http://localhost:6060/graphql",
    "HEADERS": "{\"Authorization\": \"Bearer YOUR_TOKEN\"}"
  }
}
```

### Multiple Phoenix Instances

Connect to multiple Phoenix instances:

```json
{
  "mcpServers": {
    "phoenix-dev": {
      "command": "npx",
      "args": ["-y", "mcp-graphql"],
      "env": {
        "ENDPOINT": "http://localhost:6060/graphql",
        "NAME": "phoenix-dev"
      }
    },
    "phoenix-prod": {
      "command": "npx",
      "args": ["-y", "mcp-graphql"],
      "env": {
        "ENDPOINT": "http://prod-phoenix.example.com/graphql",
        "NAME": "phoenix-prod",
        "HEADERS": "{\"Authorization\": \"Bearer TOKEN\"}"
      }
    }
  }
}
```

### Enable Mutations (Not Recommended)

```json
{
  "env": {
    "ENDPOINT": "http://localhost:6060/graphql",
    "ALLOW_MUTATIONS": "true"
  }
}
```

**Warning**: Only enable in development environments.

## Custom Project Names

Set project name in agent spans:

```elixir
AgentObs.trace_agent(agent_name, %{input: message}, fn ->
  :otel_span.set_attribute("project.name", "my-custom-project")
  # agent execution
end)
```

## Data Flow Architecture

```
Your Application Agent
  ↓ AgentObs.trace_*
agent_obs Library
  ↓ OpenTelemetry
Phoenix OTLP Endpoint (:4317)
  ↓ Storage
Phoenix Database
  ↓ Query
Phoenix GraphQL (:6060/graphql)
  ↓ MCP
Claude Code
```

## OpenTelemetry Context

- **Protocol**: OTLP (OpenTelemetry Protocol)
- **Transport**: gRPC
- **Default Endpoint**: `http://localhost:4317`
- **Exporter**: Configured in `config/runtime.exs`

## Phoenix Projects

Your application exports to:

- **default**: General traces (6 traces)
- **buzz-agent**: Model editor agent traces (53 traces, 17K+ spans)

Projects are created automatically when traces are exported.

## Troubleshooting

### Phoenix Not Exporting

1. Check agent_obs config: `config/runtime.exs:29-39`
2. Verify OTLP endpoint: `echo $PHOENIX_OTLP_ENDPOINT`
3. Check port 4317 accessibility
4. Review application logs for export errors
5. Restart your application after config changes

### No Traces in Project

1. Verify agent executions are running
2. Check Phoenix UI for incoming traces
3. Ensure OpenTelemetry exporter is active
4. Review agent_obs handler configuration

### Query Performance Issues

1. Use time ranges for large datasets
2. Add specific filters before querying
3. Limit page size for I/O fields
4. Use aggregates instead of fetching all records

## See Also

- [Phoenix Documentation](https://docs.arize.com/phoenix)
- [agent_obs on Hex](https://hex.pm/packages/agent_obs)
- [OpenTelemetry Elixir](https://opentelemetry.io/docs/languages/erlang/)
- [MCP GraphQL Server](https://github.com/blurrah/mcp-graphql)
