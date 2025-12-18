---
name: reactor-oban
description: |
  Reactor workflows and Oban background jobs for Elixir applications - use this
  skill when working with multi-step transactional workflows (sagas), background
  job processing, compensation patterns, or integrating workflows with jobs.
  Essential for building reliable asynchronous operations with automatic
  rollback and actor context propagation.
---

# Reactor & Oban Skill

**Master Reactor workflows and Oban background jobs for building reliable,
transactional operations in Elixir applications.**

## What are Reactor and Oban?

### Reactor (Ash.Reactor)

Reactor provides **transactional saga orchestration** for complex, multi-step
business processes. It ensures sequences of operations either complete
successfully or roll back gracefully through automatic compensation.

**Key Features:**

- **Saga Pattern**: Each step has compensating actions for rollback
- **Step Dependencies**: Explicit ordering with `result/1`
- **Automatic Compensation**: Rollback in reverse order on failure
- **Actor Propagation**: Thread user context through all steps
- **Retry Logic**: Built-in retries with exponential backoff
- **Parallel Execution**: Independent steps run concurrently

### Oban

Oban is a **robust job processing library** for Elixir that uses PostgreSQL for
persistence and coordination. Time-consuming operations should run as background
jobs.

**Key Features:**

- **Persistent Queue**: Jobs survive application restarts
- **Multiple Queues**: Priority-based job processing
- **Automatic Retries**: Exponential backoff on failures
- **Scheduled Jobs**: Delayed and cron-based execution
- **Observability**: Telemetry events for monitoring
- **Actor Reconstruction**: Build actor context from job args

## When to Use This Skill

Use this skill when you need to:

- ✅ **Build multi-step workflows** - Operations requiring 3+ steps with
  compensation
- ✅ **Process background jobs** - Long-running operations (agent execution,
  uploads, materialization)
- ✅ **Implement saga patterns** - Transactional workflows with automatic
  rollback
- ✅ **Handle actor context in workflows** - Thread user identity through
  Reactor steps
- ✅ **Integrate workflows with jobs** - Run Reactor workflows inside Oban
  workers
- ✅ **Design compensation actions** - Undo operations on workflow failure
- ✅ **Handle async operations** - File uploads, SQL execution, connection
  operations
- ✅ **Schedule recurring tasks** - Cron jobs and delayed execution

## Core Architecture Pattern

**CRITICAL: Workflows Run INSIDE Jobs**

```elixir
# ✅ CORRECT: Reactor workflow inside Oban worker
defmodule MyApp.Jobs.Workers.MyWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    inputs = %{resource_id: args["resource_id"]}
    context = %{actor: build_actor(args), attempt: args["attempt"]}

    # Workflow runs INSIDE the job
    case Reactor.run(MyWorkflow, inputs, context) do
      {:ok, result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end

# ❌ WRONG: Job inside Reactor workflow
step :trigger_worker do
  run fn inputs, context ->
    %{id: inputs.id}
    |> SomeWorker.new()
    |> Oban.insert()  # Breaks compensation!
  end
end
```

**Why This Matters:**

- **Compensation Works**: Reactor can roll back all steps in single process
- **Resource Efficiency**: One job slot, not multiple nested jobs
- **Simpler Error Handling**: Single failure path, no orphaned jobs
- **Clear Ownership**: Job controls workflow lifecycle

## Quick Reference

### Common Tasks

| Task                     | Reference                                                           | Example                                               |
| ------------------------ | ------------------------------------------------------------------- | ----------------------------------------------------- |
| Build basic workflow     | [reference/sagas.md](reference/sagas.md)                            | [basic-workflow.ex](examples/basic-workflow.ex)       |
| Add compensation steps   | [reference/sagas.md](reference/sagas.md#compensation)               | [saga-compensation.ex](examples/saga-compensation.ex) |
| Pass actor in workflows  | [reference/actor-workflows.md](reference/actor-workflows.md)        | [actor-propagation.ex](examples/actor-propagation.ex) |
| Create Oban worker       | [reference/oban-patterns.md](reference/oban-patterns.md)            | [oban-worker.ex](examples/oban-worker.ex)             |
| Schedule background jobs | [reference/oban-patterns.md](reference/oban-patterns.md#scheduling) | [oban-scheduling.ex](examples/oban-scheduling.ex)     |
| Handle workflow errors   | [reference/sagas.md](reference/sagas.md#error-handling)             | [error-handling.ex](examples/error-handling.ex)       |

### Critical Patterns

1. **Workflow Inside Job**: Execute `Reactor.run/3` from Oban worker `perform/1`
2. **Actor in Context**: Pass actor via workflow context, access with
   `Map.get(context, :actor)`
3. **Compensation Order**: Runs in REVERSE order of step execution
4. **Idempotent Steps**: Design steps to be safely retryable
5. **No Nested Jobs**: Never enqueue Oban jobs from within workflow steps

## Project-Specific Conventions

### Workflow Naming

- **Location**: `lib/my_app/*/workflows/*.ex`
- **Naming**: Descriptive names ending in `Workflow` (e.g.,
  `ProcessOrderWorkflow`, `ImportDataWorkflow`)
- **Module**: Use `use Reactor` or `use Ash.Reactor` depending on integration
  needs

### Worker Naming

- **Location**: `lib/my_app/workers/*.ex` or organized by domain
- **Naming**: Descriptive names ending in `Worker` (e.g., `ProcessUploadWorker`,
  `SendEmailWorker`)
- **Module**: Use `use Oban.Worker, queue: :queue_name, max_attempts: N`

### Queue Organization

Use multiple named queues with different priorities for your application needs:

```elixir
# config/config.exs
config :my_app, Oban,
  queues: [
    critical: 20,     # Time-sensitive operations
    default: 10,      # Standard background jobs
    low_priority: 5,  # Batch processing, cleanup tasks
    mailers: 5        # Email sending
  ]
```

### Actor Reconstruction

Jobs store actor as map with string keys, reconstruct for Ash operations:

```elixir
# Storing actor in job args
%{
  "user_id" => user.id,
  "organization_id" => user.organization_id,
  "role" => user.role
}
|> MyWorker.new()
|> Oban.insert()

# Reconstructing actor in worker
def perform(%Oban.Job{args: args}) do
  actor = %{
    id: args["user_id"],
    organization_id: args["organization_id"],
    role: String.to_existing_atom(args["role"])
  }
  # Use actor for Ash operations
end
```

## Common Workflow Patterns

### 1. Multi-Step Data Processing

**Example**: Processing uploaded data with multiple transformation steps

1. Load and validate input record
2. Validate data format and requirements
3. Transform data to target schema
4. Create or update related records
5. Process data in parallel (for batch operations)
6. Update status and metadata
7. Finalize and notify

**Key Pattern**: Multiple steps with full compensation chain, parallel
processing where applicable

### 2. Asynchronous Request Processing

**Example**: Processing complex user requests that require multiple operations

1. Mark request as processing
2. Load required context and dependencies
3. Execute primary operation
4. Process results
5. Handle conditional logic based on results
6. Save processed data
7. Mark request as completed
8. Broadcast completion notification

**Key Pattern**: Synchronous execution flow, conditional steps, real-time
updates

### 3. Batch Processing Workflow

**Example**: Processing multiple items with external operations

1. Load batch record
2. Prepare item list
3. Allocate resources (connections, namespaces, etc.)
4. Create or update parent records
5. Process items in parallel
6. Aggregate results
7. Update batch status and metadata
8. Clean up resources

**Key Pattern**: Parallel processing with `map`, resource management, proper
ordering

## File Organization

```
.claude/skills/reactor-oban/
├── SKILL.md              ← You are here
├── examples/             ← Self-contained runnable code
│   ├── basic-workflow.ex
│   ├── saga-compensation.ex
│   ├── actor-propagation.ex
│   ├── oban-worker.ex
│   ├── oban-scheduling.ex
│   └── error-handling.ex
└── reference/            ← Deep dives with links
    ├── sagas.md
    ├── oban-patterns.md
    └── actor-workflows.md
```

## External Resources

### Official Documentation

- **Reactor**: https://hexdocs.pm/reactor/
- **Ash.Reactor**: https://hexdocs.pm/ash/reactor.html
- **Oban**: https://hexdocs.pm/oban/
- **Oban.Worker**: https://hexdocs.pm/oban/Oban.Worker.html

### Project Documentation

- **Project documentation**: Check your project's design docs for workflow
  patterns
- **Architecture guides**: Review advanced workflow and job processing patterns
- **Team conventions**: Review project README and development guides
- **Official docs**: hexdocs.pm/reactor and hexdocs.pm/oban

## Learning Path

### Beginner: Understanding Basics

1. Read [reference/sagas.md](reference/sagas.md) - What are sagas?
2. Study [examples/basic-workflow.ex](examples/basic-workflow.ex) - Simple
   workflow
3. Read [reference/oban-patterns.md](reference/oban-patterns.md) - Background
   jobs
4. Run [examples/oban-worker.ex](examples/oban-worker.ex) - Basic worker

### Intermediate: Building Features

1. Study [examples/saga-compensation.ex](examples/saga-compensation.ex) -
   Compensation patterns
2. Read [reference/actor-workflows.md](reference/actor-workflows.md) - Actor in
   workflows
3. Study [examples/actor-propagation.ex](examples/actor-propagation.ex) - Real
   examples
4. Build a simple workflow with compensation

### Advanced: Complex Workflows

1. Study existing workflows in your codebase
2. Review complex multi-step operations
3. Read project architecture docs for advanced patterns
4. Implement multi-step workflow with parallel execution

## Troubleshooting

### Workflow Failures

**Error**: Workflow fails partway through

**Check**:

1. Do all steps have compensation actions?
2. Is compensation idempotent (safe to run multiple times)?
3. Are errors being returned correctly (`{:error, reason}`)?
4. Is actor being passed through context?

See: [reference/sagas.md#debugging](reference/sagas.md)

### Job Failures

**Error**: Job keeps retrying and failing

**Check**:

1. Is actor being reconstructed correctly from args?
2. Are resources loaded with proper authorization?
3. Should this error be retried or marked as permanent?
4. Is timeout appropriate for the operation?

See: [reference/oban-patterns.md#error-handling](reference/oban-patterns.md)

### Actor Context Lost

**Error**: Authorization failures in workflow steps

**Check**:

1. Is actor in workflow inputs AND context?
2. Is actor being accessed with `Map.get(context, :actor)`?
3. Is actor map structure correct (id, organization_id, role)?

See: [reference/actor-workflows.md](reference/actor-workflows.md)

## Anti-Patterns to Avoid

### ❌ Job Inside Workflow

```elixir
# WRONG: Enqueueing jobs from within workflows
step :trigger_background_job do
  run fn inputs, context ->
    %{resource_id: inputs.id}
    |> SomeWorker.new()
    |> Oban.insert()  # Breaks compensation!
  end
end
```

**Why it's bad**: Breaks compensation, uses multiple worker slots, complex error
handling

### ❌ Blocking on External Events

```elixir
# WRONG: Using receive blocks in workflow steps
step :wait_for_completion do
  run fn inputs, context ->
    Phoenix.PubSub.subscribe(MyApp.PubSub, "topic:#{inputs.id}")
    receive do
      {:completed, result} -> {:ok, result}
    after
      60_000 -> {:error, "timeout"}
    end
  end
end
```

**Why it's bad**: Blocks worker process, brittle timeout management, hard to
test

### ❌ Bypassing Authorization

```elixir
# WRONG: Using authorize?: false in workflows
step :create_resource do
  run fn inputs, context ->
    Resource
    |> Ash.Changeset.for_create(:create, inputs.data)
    |> Ash.create(authorize?: false)  # NEVER DO THIS
  end
end
```

**Why it's bad**: Breaks multi-tenant isolation, security vulnerability

## Getting Help

1. **Search examples**: Find pattern similar to your use case
2. **Read reference docs**: Deep dive into specific topic
3. **Check project docs**: Review your application's design documentation
4. **Review actual code**: Examine existing workflows in your codebase
5. **Official docs**: hexdocs.pm/reactor and hexdocs.pm/oban for framework
   details

## Related Skills

- **ash-framework**: Actor context, resources, policies (essential companion
  skill)
- **manual-qa**: Testing workflows and background jobs
- **testing-strategy**: How to test sagas and async operations

---

**Remember**: Workflows run inside jobs, not the other way around. Always pass
actor context, never bypass authorization.
