---
name: elixir-testing
description: |
  Elixir testing patterns and best practices for Phoenix/Ash applications using
  ExUnit, Ash Framework, and ReqCassette. Use this skill when writing or
  debugging tests, understanding test organization, or implementing test
  helpers.
---

# Elixir Testing Skill

Comprehensive guide to testing patterns in Phoenix/Ash applications using
ExUnit, Ash Framework, and ReqCassette for HTTP/LLM mocking.

## When to Use This Skill

- Writing new tests for features or bug fixes
- Debugging failing tests
- Understanding test organization and structure
- Implementing test helpers or fixtures
- Setting up cassette-based LLM testing
- Testing with actor-based authorization
- Working with async vs non-async tests

## Quick Start

### Test Distribution (70/20/10 Strategy)

- **70% Unit Tests**: Fast, isolated logic tests
- **20% Integration Tests**: Multi-component workflows, Ash actions
- **10% E2E Tests**: Critical user flows via MCP tools

See: [reference/70-20-10-strategy.md](reference/70-20-10-strategy.md)

### Common Commands

```bash
# Run all tests
mix test

# Run specific file
mix test test/my_app/analytics/agent_test.exs

# Run specific test by line number
mix test test/my_app/analytics/agent_test.exs:42

# Run failed tests only
mix test --failed

# Include live LLM tests (requires API key)
export ANTHROPIC_API_KEY="sk-ant-..."
mix test --include llm_live

# Record cassettes for LLM tests
RECORD_CASSETTES=1 mix test

# Run with coverage
mix coveralls
mix coveralls.html  # HTML report
```

## Key Testing Patterns

### 1. Unit Tests (70%)

Fast, isolated tests for pure functions, validations, and transformations.

**Example**: [examples/unit-test.exs](examples/unit-test.exs)

**When to use**:

- Pure functions
- Changeset validations
- Data transformations
- Utility modules
- Error handling logic

**Reference**: [reference/async-patterns.md](reference/async-patterns.md)

### 2. Integration Tests (20%)

Multi-component tests for Ash actions, workflows, and database operations.

**Example**: [examples/integration-test.exs](examples/integration-test.exs)

**When to use**:

- Ash resource CRUD operations
- Multi-step workflows (Reactor)
- Database queries
- Background jobs (Oban)
- PubSub broadcasting

**Reference**: See DESIGN/reference/testing-strategy.md

### 3. LLM Testing with Cassettes

Deterministic LLM testing using ReqCassette for recorded HTTP interactions.

**Example**: [examples/cassette-test.exs](examples/cassette-test.exs)

**When to use**:

- Agent execution tests
- Tool calling workflows
- LLM-powered features
- Fast, deterministic tests without API costs

**Reference**:

- [reference/mocking.md](reference/mocking.md)
- DESIGN/testing/llm-testing-strategy.md

### 4. Async Testing

Control test concurrency for optimal performance.

**Example**: [examples/async-false.exs](examples/async-false.exs)

**When to use `async: false`**:

- Database tests with shared state
- GenServer/PubSub tests
- Tests that modify global state
- Tests with timing dependencies

**Reference**: [reference/async-patterns.md](reference/async-patterns.md)

### 5. Test Helpers

Common patterns for creating test data and fixtures.

**Example**: [examples/test-helpers.ex](examples/test-helpers.ex)

**When to use**:

- Creating test organizations/users
- Building actor contexts
- Reusable test data patterns
- Factory-style helpers

**Reference**: See test/support/data_case.ex

## Project-Specific Patterns

### Actor-Based Authorization

Always provide actor context in tests that involve authorization:

```elixir
actor = build_test_actor(user, organization)
Resource
|> Ash.Changeset.for_create(:create, attrs, actor: actor)
|> Ash.create()
```

### Database Management

```bash
# Reset test database (Ash projects)
MIX_ENV=test mix ash.reset

# Reset development database (Ash projects)
mix ash.reset

# For non-Ash projects, use Ecto:
MIX_ENV=test mix ecto.reset
mix ecto.reset
```

### Capturing Expected Errors

Use `@tag capture_log: true` to silence expected error logs:

```elixir
@tag capture_log: true
test "handles invalid SQL gracefully" do
  assert {:error, _} = execute_invalid_query()
end
```

## Directory Structure

```
test/
├── my_app/                # Domain logic tests (unit + integration)
│   ├── accounts/
│   ├── orders/
│   ├── products/
│   └── services/
├── my_app_web/            # LiveView tests
│   ├── live/
│   └── controllers/
├── support/               # Test helpers
│   ├── data_case.ex       # Database test setup
│   ├── cassette_case.ex   # HTTP cassette setup (optional)
│   └── fixtures.ex        # Factory functions
├── integration/           # E2E integration tests
└── fixtures/
    └── cassettes/         # Recorded HTTP interactions
```

## Examples Overview

All examples are self-contained and runnable:

1. **[unit-test.exs](examples/unit-test.exs)** - Basic unit test with async
2. **[integration-test.exs](examples/integration-test.exs)** - Integration test
   with database
3. **[async-false.exs](examples/async-false.exs)** - When and why to use async:
   false
4. **[cassette-test.exs](examples/cassette-test.exs)** - LLM testing with
   ReqCassette
5. **[mcp-testing.exs](examples/mcp-testing.exs)** - E2E testing with MCP tools
6. **[test-helpers.ex](examples/test-helpers.ex)** - Common test helper patterns

## Reference Documentation

Detailed topic-specific guides:

- **[70-20-10-strategy.md](reference/70-20-10-strategy.md)** - Test distribution
  strategy
- **[async-patterns.md](reference/async-patterns.md)** - When to use async:
  true/false
- **[mocking.md](reference/mocking.md)** - HTTP mocking with ReqCassette

## External Resources

- **ExUnit**: https://hexdocs.pm/ex_unit
- **Ash Testing**: https://hexdocs.pm/ash/testing.html
- **ReqCassette**: https://hexdocs.pm/req_cassette/
- **ReqLLM**: https://hexdocs.pm/req_llm/

## Related Skills

- **[ash-framework](../ash-framework/SKILL.md)** - Ash resource patterns
- **[reactor-oban](../reactor-oban/SKILL.md)** - Workflow and job testing
- **[phoenix-liveview](../phoenix-liveview/SKILL.md)** - LiveView testing
  patterns

## Testing Checklist

Before marking a feature complete:

- [ ] Unit tests for core logic
- [ ] Integration tests for Ash actions
- [ ] Policy tests for authorization
- [ ] Background job tests (if applicable)
- [ ] LiveView tests (if UI changes)
- [ ] E2E test for critical path (recommended)
- [ ] All tests pass: `mix test`
- [ ] No warnings: `mix compile --warnings-as-errors`
- [ ] Code formatted: `mix format --check-formatted`

## Progressive Disclosure Path

1. **Start here**: Read this SKILL.md for overview
2. **Understand strategy**: Read
   [reference/70-20-10-strategy.md](reference/70-20-10-strategy.md)
3. **Learn patterns**: Review [examples/](examples/) for your use case
4. **Deep dive**: Read reference docs for specific topics
5. **See real code**: Check actual project tests in test/ directory
6. **Advanced topics**: Read DESIGN/testing/ documentation
