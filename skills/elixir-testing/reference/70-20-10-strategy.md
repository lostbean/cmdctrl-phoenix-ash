# 70/20/10 Testing Strategy

The 70/20/10 testing distribution provides optimal coverage while maintaining
fast feedback loops and manageable test maintenance.

## Overview

- **70% Unit Tests**: Fast, isolated, deterministic
- **20% Integration Tests**: Multi-component workflows
- **10% E2E Tests**: Critical user flows

This distribution is a guideline, not a hard rule. Adjust based on your
project's needs.

## Unit Tests (70%)

### What to Test

- Pure functions
- Data transformations
- Changeset validations
- Utility modules
- Business logic calculations
- Error handling
- Edge cases

### Characteristics

- **Speed**: < 10ms per test
- **Isolation**: No external dependencies
- **Determinism**: Same input = same output always
- **Coverage**: Aim for >80% of business logic

### Example

```elixir
defmodule MyApp.DataProcessing.SchemaInferenceTest do
  use ExUnit.Case, async: true  # Fast, parallel execution

  describe "infer_column_type/1" do
    test "identifies integer columns" do
      samples = ["1", "42", "999"]
      assert SchemaInference.infer_column_type(samples) == :integer
    end

    test "handles null values" do
      samples = ["1", nil, "3"]
      assert SchemaInference.infer_column_type(samples) == :integer
    end

    test "defaults to string for mixed types" do
      samples = ["1", "abc", "3"]
      assert SchemaInference.infer_column_type(samples) == :string
    end
  end
end
```

**See**: [examples/unit-test.exs](../examples/unit-test.exs)

### When to Use

✅ Testing pure functions ✅ Validating business logic ✅ Checking error
handling ✅ Testing calculations ✅ Verifying transformations

❌ Not for database operations ❌ Not for HTTP requests ❌ Not for
multi-component workflows ❌ Not for UI interactions

## Integration Tests (20%)

### What to Test

- Ash resource CRUD operations
- Database persistence
- Multi-step workflows (Reactor)
- Background jobs (Oban)
- Authorization policies
- PubSub broadcasting
- Service integration

### Characteristics

- **Speed**: 100-500ms per test
- **Scope**: Multiple components
- **Database**: Uses Ecto Sandbox
- **Coverage**: Critical workflows and policies

### Example

```elixir
defmodule MyApp.DataProcessing.EntityTest do
  use MyApp.DataCase, async: true  # DB tests can be async

  describe "create" do
    test "creates entity with valid attributes", %{actor: actor, datastore: datastore} do
      attrs = %{
        name: "Test Entity",
        datastore_id: datastore.id
      }

      assert {:ok, entity} =
        Entity
        |> Ash.Changeset.for_create(:create, attrs, actor: actor)
        |> Ash.create()

      assert entity.name == "Test Entity"
    end

    test "enforces organization isolation" do
      # Test that user from org1 cannot access org2 resources
      # ...
    end
  end
end
```

**See**: [examples/integration-test.exs](../examples/integration-test.exs)

### When to Use

✅ Testing Ash actions ✅ Verifying database constraints ✅ Testing
authorization policies ✅ Validating workflows ✅ Testing background jobs

❌ Not for pure functions ❌ Not for simple validations ❌ Not for end-user
scenarios ❌ Not for UI interactions

## E2E Tests (10%)

### What to Test

- Complete user workflows
- UI interactions
- Real-time updates
- Critical business paths
- Error recovery flows

### Characteristics

- **Speed**: 5-30 seconds per flow
- **Scope**: Full stack (UI → Backend → DB)
- **Tools**: Chrome DevTools MCP + Tidewave MCP
- **Coverage**: Happy paths and critical errors

### Example

```elixir
# E2E tests are typically run interactively via Claude Code
# See: DESIGN/testing/agentic-test-plan.md

# Example flow: User uploads CSV file

# 1. UI: Navigate and upload
navigate_page(%{url: "http://localhost:4000/data-sources"})
click(%{uid: "upload-button"})
# ... inject file via JavaScript ...
click(%{uid: "submit-upload"})
wait_for(%{text: "Upload complete", timeout: 30000})

# 2. Backend: Verify processing
tidewave.get_logs(%{tail: 50, grep: "Upload"})

# 3. Database: Verify persistence
tidewave.execute_sql_query(%{
  query: "SELECT status FROM uploads WHERE filename = $1",
  arguments: ["test.csv"]
})
```

**See**: [examples/mcp-testing.exs](../examples/mcp-testing.exs)

### When to Use

✅ Testing critical user journeys ✅ Validating UI interactions ✅ Testing
real-time updates ✅ Verifying multi-layer flows ✅ Smoke testing deployments

❌ Not for business logic ❌ Not for edge cases ❌ Not for unit-level testing ❌
Not for rapid feedback

## Applying the Strategy

### New Feature Development

1. **Start with unit tests** (TDD)
   - Write failing test
   - Implement minimal code
   - Make test pass
   - Refactor

2. **Add integration tests**
   - Test resource actions
   - Verify authorization
   - Test workflows

3. **Add E2E test (if critical)**
   - Test happy path only
   - Verify UI → Backend → DB flow

### Bug Fixes

1. **Write failing test at appropriate level**
   - Unit test if pure function bug
   - Integration test if workflow bug
   - E2E test if UI interaction bug

2. **Fix the bug**

3. **Verify test passes**

4. **Add edge case tests if needed**

### Distribution by Domain

```
Your Application Test Suite (~500 tests total):

Unit Tests (350 tests):
├── test/my_app/datastore/sql_validator_test.exs
├── test/my_app/datastore/helpers_test.exs
├── test/my_app/tools/schema_generator_test.exs
├── test/my_app/processing/data_transformer_test.exs
└── ... more pure function tests

Integration Tests (100 tests):
├── test/my_app/data_processing/entity_test.exs
├── test/my_app/processing/workflow_test.exs
├── test/my_app/agents/executor_integration_test.exs
├── test/integration/agent_workflow_test.exs
└── ... more workflow tests

E2E Tests (50 test flows):
└── DESIGN/testing/agentic-test-plan.md
    ├── Flow 1: Authentication & Registration
    ├── Flow 2: Data Source Upload
    ├── Flow 3: Empty Model Guidance
    └── ... more user flows
```

## Performance Targets

### Test Suite Speed

| Type        | Per Test | 100 Tests | Target % |
| ----------- | -------- | --------- | -------- |
| Unit        | < 10ms   | < 1s      | 70%      |
| Integration | < 500ms  | < 50s     | 20%      |
| E2E         | 5-30s    | 5-50min   | 10%      |

**Total suite**: Should run in < 2 minutes for rapid feedback

### CI/CD Optimization

```bash
# Fast CI (unit + integration only)
mix test --exclude llm_live --exclude e2e

# Full CI (includes live LLM tests)
mix test --include llm_live --exclude e2e

# E2E tests run separately (manual or nightly)
# (Executed via Claude Code with MCP tools)
```

## Coverage Targets

### By Test Type

- **Unit Tests**: >80% coverage of business logic
- **Integration Tests**: 100% of authorization policies
- **E2E Tests**: 100% of critical user paths

### By Domain

- **Pure Functions**: >90% coverage (unit tests)
- **Ash Resources**: >80% coverage (integration tests)
- **UI Flows**: Top 10 user journeys (E2E tests)

## Monitoring Test Health

### Metrics to Track

1. **Test distribution**

   ```bash
   mix test --dry-run | grep -c "test/" # Total tests
   # Calculate % by type
   ```

2. **Test speed**

   ```bash
   mix test --trace  # Shows slow tests
   ```

3. **Coverage**

   ```bash
   mix coveralls.html
   # View coverage by domain
   ```

4. **Flakiness**
   - Track intermittent failures
   - Fix or mark as flaky
   - Remove if too flaky

### Warning Signs

🔴 **Too many unit tests**:

- Suite > 80% unit tests
- Low integration coverage
- Mocks everywhere

🔴 **Too many E2E tests**:

- Suite > 20% E2E tests
- Slow CI/CD pipeline
- Brittle tests

🔴 **Too many integration tests**:

- Suite > 40% integration tests
- Slow feedback loop
- Complex test setup

## Related Documentation

- **Examples**: [../examples/](../examples/) - See test patterns in action
- **Async Patterns**: [async-patterns.md](async-patterns.md) - Optimize test
  speed
- **Mocking**: [mocking.md](mocking.md) - HTTP mocking with ReqCassette
- **Design Docs**: See {project_root}/DESIGN/reference/testing-strategy.md
- **Agentic Testing**: See {project_root}/DESIGN/testing/agentic-test-plan.md

## External Resources

- [Testing Elixir](https://pragprog.com/titles/lmelixir/testing-elixir/) -
  Testing pyramid concepts
- [ExUnit Best Practices](https://hexdocs.pm/ex_unit/ExUnit.html) - Official
  docs
- [The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) -
  Martin Fowler
