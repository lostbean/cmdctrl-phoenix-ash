# HTTP Mocking with ReqCassette

ReqCassette provides deterministic HTTP testing by recording and replaying HTTP
interactions. This is especially useful for LLM testing where API calls are
expensive and non-deterministic.

## Overview

ReqCassette records HTTP request/response pairs to JSON files (cassettes) and
replays them in subsequent test runs.

### Benefits

✅ **Deterministic**: Same input = same output always ✅ **Fast**: < 1 second vs
8+ seconds for live API ✅ **Free**: No API costs after initial recording ✅
**Offline**: No internet required for tests ✅ **Reproducible**: Same results
across all environments

### Trade-offs

❌ Can become stale (need to re-record periodically) ❌ Only works with
non-streaming HTTP ❌ Requires initial recording with API key ❌ Cassettes can
be large for complex responses

## Quick Start

### 1. Setup Test Module

```elixir
defmodule MyAgentTest do
  use MyApp.CassetteCase  # Provides cassette helpers

  @moduletag :llm_cassette  # Runs by default

  test "agent execution", context do
    with_cassette(context, fn req_opts ->
      {:ok, result} = Client.execute_agent(messages, req_opts)
      assert result.finish_reason == "stop"
    end)
  end
end
```

### 2. Record Cassettes

```bash
# Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Record cassettes
RECORD_CASSETTES=1 mix test test/path/to/test.exs

# Output:
# Recording to: test/fixtures/cassettes/my_agent_test__agent_execution.json
```

### 3. Replay Cassettes (Default)

```bash
# No API key needed
mix test test/path/to/test.exs

# Output:
# Replaying from: test/fixtures/cassettes/my_agent_test__agent_execution.json
```

## Architecture

### How ReqCassette Works

```
┌─────────────────────────────────────────────────┐
│ Test Code                                       │
│  with_cassette(context, fn req_opts -> ...)     │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│ ReqCassette.Plug                                │
│  - Checks mode (record vs replay)               │
│  - Normalizes request (sort required fields)    │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌───────────────┐         ┌──────────────┐
│ Record Mode   │         │ Replay Mode  │
│ - Make API    │         │ - Load JSON  │
│ - Save JSON   │         │ - Return     │
└───────────────┘         └──────────────┘
```

### Integration with ReqLLM

```elixir
# ReqLLM client receives req_opts from test
def execute_agent(messages, opts \\ []) do
  req_opts = Keyword.get(opts, :req_http_options, [])

  # ReqCassette plug intercepts request
  Req.new(req_opts)
  |> Req.post(url: api_url, json: body)
end
```

**See**: [examples/cassette-test.exs](../examples/cassette-test.exs)

## Cassette Naming

### Automatic Naming (Recommended)

```elixir
# CassetteCase automatically generates names
test "creates entity", context do
  with_cassette(context, fn req_opts ->
    # Cassette: my_test__creates_entity.json
  end)
end
```

Format: `{module_name}__{test_name}.json`

### Custom Naming (Advanced)

```elixir
# Override cassette name if needed
test "special case", %{cassette_opts: opts} = context do
  custom_opts = Keyword.put(opts, :cassette_name, "custom_name")
  ReqCassette.with_cassette("custom_name", custom_opts, fn plug ->
    # ...
  end)
end
```

## Request Normalization

ReqCassette normalizes requests to ensure consistent matching:

### Field Ordering

```elixir
# These are treated as identical:
{
  "required": ["second", "first"]  # Original
}

{
  "required": ["first", "second"]  # Normalized (sorted)
}
```

**Why**: Tool schemas may have fields in different orders but are semantically
identical.

### Custom Normalization

```elixir
# In CassetteCase setup
cassette_opts = [
  cassette_dir: "test/fixtures/cassettes",
  mode: mode,
  filter_request_headers: ["authorization", "x-api-key"],
  filter_request: &normalize_required_fields/1  # Custom function
]
```

## Cassette Format

### Structure (v1.0)

```json
{
  "version": "1.0",
  "interactions": [
    {
      "request": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "headers": {
          "content-type": "application/json",
          "anthropic-version": "2023-06-01"
        },
        "body": {
          "model": "claude-3-5-sonnet-20241022",
          "messages": [{ "role": "user", "content": "What is 2 + 2?" }]
        }
      },
      "response": {
        "status": 200,
        "headers": {
          "content-type": "application/json"
        },
        "body": {
          "id": "msg_123",
          "content": [{ "type": "text", "text": "2 + 2 equals 4." }],
          "usage": {
            "input_tokens": 12,
            "output_tokens": 8
          }
        }
      }
    }
  ]
}
```

### Multiple Interactions

A single cassette can contain multiple request/response pairs:

```json
{
  "version": "1.0",
  "interactions": [
    {"request": {...}, "response": {...}},  // First API call
    {"request": {...}, "response": {...}}   // Tool execution → second call
  ]
}
```

**Use case**: Agent makes multiple LLM calls in one test (initial query + tool
execution)

## Recording Modes

### Record Mode

```bash
RECORD_CASSETTES=1 mix test
```

**Behavior**:

- Makes real HTTP requests
- Saves responses to JSON files
- Appends to existing cassettes (doesn't overwrite)

**When to use**:

- First time running test
- Updating prompts or tools
- Upgrading model versions
- Recording new interactions

### Replay Mode (Default)

```bash
mix test
```

**Behavior**:

- Loads responses from JSON files
- No HTTP requests made
- Deterministic, fast execution

**When to use**:

- Normal test execution
- CI/CD pipelines
- Local development
- Any time after initial recording

### Match Errors

If request doesn't match cassette:

```
** (MatchError) Cassette mismatch:
Expected request not found in cassette
```

**Cause**: Request changed (different prompt, model, or params)

**Solution**: Re-record cassette

## Test Tagging Strategy

### :llm_cassette (Default)

Cassette-based tests that run by default:

```elixir
@moduletag :llm_cassette

test "agent execution", context do
  with_cassette(context, fn req_opts ->
    # Fast, deterministic, no API key
  end)
end
```

**Characteristics**:

- Runs with `mix test` (no flags)
- Fast (< 1 second)
- No API key required
- Deterministic results

### :llm_live (Opt-in)

Live API tests for validation:

```elixir
@moduletag :llm_live

test "streaming vs non-streaming parity" do
  # Real API call, requires key
end
```

**Characteristics**:

- Excluded by default
- Requires `mix test --include llm_live`
- Slow (~8 seconds)
- API key required
- Non-deterministic

**When to use**:

- Validate against latest model
- Test streaming behavior
- Verify new prompts before recording
- Debugging cassette issues

## Best Practices

### ✅ DO

```elixir
# 1. Use descriptive test names (they become filenames)
test "agent handles customer query about orders", context do
  with_cassette(context, fn req_opts ->
    # Cassette: my_test__agent_handles_customer_query_about_orders.json
  end)
end

# 2. Test behavior, not exact text
test "generates valid response", context do
  with_cassette(context, fn req_opts ->
    {:ok, result} = execute_agent(prompt, req_opts)

    assert is_binary(result.text)  # ✅ Structure
    assert result.finish_reason in ["stop", "termination_tool"]  # ✅ Behavior
  end)
end

# 3. Use fixed test data (no timestamps/UUIDs)
test "analyzes data", context do
  with_cassette(context, fn req_opts ->
    # ✅ Fixed date
    prompt = "Analyze sales data from 2024-01-01"
    execute_agent(prompt, req_opts)
  end)
end

# 4. Commit cassettes to version control
# test/fixtures/cassettes/*.json should be committed

# 5. Review cassette diffs before committing
git diff test/fixtures/cassettes/
```

### ❌ DON'T

```elixir
# 1. Don't use streaming in cassette tests
test "bad streaming test", context do
  with_cassette(context, fn req_opts ->
    opts = Keyword.merge(req_opts, stream: true)  # ❌ Won't record
    execute_agent(prompt, opts)
  end)
end

# 2. Don't use random data
test "non-deterministic", context do
  with_cassette(context, fn req_opts ->
    prompt = "Current time: #{DateTime.utc_now()}"  # ❌ Changes each run
    execute_agent(prompt, req_opts)
  end)
end

# 3. Don't assert exact LLM output
test "exact output", context do
  with_cassette(context, fn req_opts ->
    {:ok, result} = execute_agent("Test", req_opts)
    assert result.text == "Exactly this"  # ❌ Brittle
  end)
end

# 4. Don't forget to tag cassette tests
defmodule UntaggedTest do
  use MyApp.CassetteCase
  # ❌ Missing @moduletag :llm_cassette
end

# 5. Don't leave cassettes uncommitted
# Always commit cassettes so CI and team can use them
```

## Maintenance Workflows

### When to Re-record

Re-record cassettes when:

1. **Prompt changes**
   - System prompt modified
   - User prompt template changed
   - Tool descriptions updated

2. **Tool changes**
   - New tool added
   - Tool parameters changed
   - Tool behavior modified

3. **Model upgrade**
   - Upgrading to new model version
   - Changing temperature/top_p
   - Modifying max_tokens

4. **Expected behavior changes**
   - Want different LLM behavior
   - Fixing incorrect responses
   - Updating to latest model capabilities

### How to Re-record

```bash
# Option 1: Re-record specific test
rm test/fixtures/cassettes/my_test__specific_test.json
RECORD_CASSETTES=1 mix test test/my_app/my_test.exs:42

# Option 2: Re-record all cassettes for a file
rm test/fixtures/cassettes/my_test__*.json
RECORD_CASSETTES=1 mix test test/my_app/my_test.exs

# Option 3: Re-record all cassettes (rare)
rm -rf test/fixtures/cassettes/
RECORD_CASSETTES=1 mix test --only llm_cassette
```

### Review Process

1. **Re-record**

   ```bash
   RECORD_CASSETTES=1 mix test
   ```

2. **Review changes**

   ```bash
   git diff test/fixtures/cassettes/
   ```

3. **Verify expected**
   - Are changes related to your modification?
   - Are responses still appropriate?
   - No leaked secrets or PII?

4. **Run tests**

   ```bash
   mix test  # Verify replay works
   ```

5. **Commit**
   ```bash
   git add test/fixtures/cassettes/
   git commit -m "Update cassettes for new prompt structure"
   ```

## Troubleshooting

### Cassette Not Found

**Error**:

```
** (File.Error) could not read file test/fixtures/cassettes/test_name.json
```

**Solution**:

```bash
RECORD_CASSETTES=1 mix test test/path/to/test.exs
```

### Cassette Mismatch

**Error**:

```
** (MatchError) Cassette mismatch: Expected request not found
```

**Causes**:

- Request changed (different prompt, params)
- Request normalization issue (field ordering)

**Solutions**:

1. Re-record:

   ```bash
   rm cassette.json
   RECORD_CASSETTES=1 mix test
   ```

2. Check request differences:
   ```bash
   # Enable debug logging
   export CASSETTE_DEBUG=1
   mix test
   ```

### Flaky Tests

**Symptom**: Test passes sometimes, fails others

**Likely causes**:

- Using random data (UUIDs, timestamps)
- Dependent on external state
- Async timing issues

**Solutions**:

1. Use fixed test data
2. Ensure test isolation
3. Check for race conditions

### Large Cassettes

**Issue**: Cassette files become very large (>1MB)

**Causes**:

- Multiple API calls in one test
- Large context windows
- Complex tool outputs

**Solutions**:

1. Split into multiple tests
2. Reduce context size in test
3. Use cassette compression (if needed)

## Advanced Patterns

### Conditional Recording

```elixir
# Record in CI, replay locally
test "conditional recording", context do
  mode = if System.get_env("CI"), do: :record, else: :replay
  opts = Keyword.put(context.cassette_opts, :mode, mode)

  ReqCassette.with_cassette(context.cassette_name, opts, fn plug ->
    # ...
  end)
end
```

### Shared Cassettes

```elixir
# Multiple tests share same cassette
describe "shared cassette" do
  @shared_cassette "shared_agent_responses"

  test "test 1", %{cassette_opts: opts} do
    ReqCassette.with_cassette(@shared_cassette, opts, fn plug ->
      # ...
    end)
  end

  test "test 2", %{cassette_opts: opts} do
    ReqCassette.with_cassette(@shared_cassette, opts, fn plug ->
      # Same cassette, different interaction
    end)
  end
end
```

### Custom Matchers

```elixir
# Match requests with custom logic
cassette_opts = [
  cassette_dir: "test/fixtures/cassettes",
  match_requests_on: [:method, :url, :body]  # Ignore headers
]
```

## Related Documentation

- **Examples**: See skill examples directory
- **Strategy**: [70-20-10-strategy.md](70-20-10-strategy.md)
- **Design**: See your project's testing strategy documentation
- **Cassettes**: See your test fixtures directory

## External Resources

- **ReqCassette**: https://hexdocs.pm/req_cassette/
- **ReqLLM**: https://hexdocs.pm/req_llm/
- **Req**: https://hexdocs.pm/req/
- **VCR (Ruby)**: https://github.com/vcr/vcr (Similar concept)
- **Example**:
  https://github.com/lostbean/req_cassette/blob/main/test/req_cassette/agent_replay_test.exs
