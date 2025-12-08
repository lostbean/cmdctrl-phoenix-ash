# Setup and Verification

Quick setup guide for Phoenix observability.

## Prerequisites

Phoenix must be running separately from MyApp. Install and start Phoenix
following the
[Phoenix installation guide](https://docs.arize.com/phoenix/setup/quickstart).

**Quickest way**:

```bash
pip install arize-phoenix
python -m phoenix.server.main serve
```

Phoenix runs on `http://localhost:6060` by default.

## Verification Steps

### 1. Check Phoenix is Running

```bash
curl http://localhost:6060/graphql
```

Should respond (not connection refused). Visit `http://localhost:6060` in
browser to see Phoenix UI.

### 2. Check MCP Configuration

The MCP server is configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "phoenix-graphql": {
      "command": "npx",
      "args": ["-y", "mcp-graphql"],
      "env": {
        "ENDPOINT": "http://localhost:6060/graphql",
        "NAME": "phoenix-graphql",
        "ALLOW_MUTATIONS": "false"
      }
    }
  }
}
```

### 3. Test MCP Tools

Use introspection (will exceed token limits but confirms connection):

```
mcp__phoenix-graphql__introspect_schema
```

Or test with a simple query (see `examples/quick-start.md`).

### 4. Verify Traces

Run an agent in your application, then check Phoenix UI at
`http://localhost:6060` for new traces.

## Configuration Files

Your application exports traces via agent_obs:

- **Runtime config**: `config/runtime.exs:29-39`
- **App config**: `config/config.exs:110-112`

Default export endpoint: `http://localhost:4317` (Phoenix OTLP)

## Next Steps

- **Quick start**: See `examples/quick-start.md` for first queries
- **Advanced config**: See `reference/advanced.md` for environment variables,
  authentication, multiple instances
- **Troubleshooting**: See SKILL.md if Phoenix isn't receiving traces

## Common Issues

**Phoenix not running**: Install and start Phoenix first **Connection refused**:
Check Phoenix is on port 6060 **No traces**: Verify agent_obs config in
`config/runtime.exs` **MCP errors**: Ensure `npx` is available

For detailed troubleshooting, see SKILL.md.
