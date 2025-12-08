# Real-time Updates Reference

Real-time event broadcasting and widget updates using Phoenix.PubSub.

## Overview

Phoenix.PubSub enables real-time communication between:

- Background workers (Oban jobs) and LiveViews
- Workflow execution and UI progress updates
- Multi-user collaboration features

## PubSub Architecture

### Topic Hierarchy

Topics should follow a hierarchical naming pattern for different granularity
levels:

```
resource:{id}              → Coarse-grained resource-level events
workflow:{id}              → Workflow-level events (completion, errors)
process:{id}               → Process execution events
version:{id}               → Version update events
organization:{id}          → Organization-wide events
```

### Event Granularity Levels

**Level 1: Coarse-Grained** (Resource/Workflow level)

- When: User needs to know workflow completed
- Events: `{:workflow_completed, workflow_id, metadata}`
- Action: Reload full state, rebuild widgets

**Level 2: Medium-Grained** (Process state level)

- When: User wants to see progress phases
- Events: `{:process_created, process_id, workflow_id}`
- Action: Subscribe to fine-grained events

**Level 3: Fine-Grained** (Step level)

- When: User wants detailed step execution visibility
- Events: `{:step_started, data}`, `{:step_progress, data}`,
  `{:step_completed, data}`
- Action: Update progress widget incrementally

## Subscription Patterns

### Basic Subscription

```elixir
@impl true
def mount(%{"resource_id" => resource_id}, _session, socket) do
  # ✅ ALWAYS check connected? before subscribing
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "resource:#{resource_id}")
  end

  {:ok, assign(socket, :resource_id, resource_id)}
end
```

### Multi-Level Subscription

```elixir
@impl true
def mount(%{"workflow_id" => workflow_id}, _session, socket) do
  if connected?(socket) do
    # Subscribe to workflow-level events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "workflow:#{workflow_id}")

    # Subscribe to version events if needed
    version_id = socket.assigns.version.id
    Phoenix.PubSub.subscribe(MyApp.PubSub, "version:#{version_id}")
  end

  {:ok, socket}
end
```

### Conditional Subscription

Subscribe after resource creation:

```elixir
def handle_event("create_workflow", _params, socket) do
  case create_new_workflow(socket.assigns.user) do
    {:ok, workflow} ->
      # Subscribe immediately after creation
      if connected?(socket) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "workflow:#{workflow.id}")
      end

      {:noreply, assign(socket, :workflow, workflow)}

    {:error, reason} ->
      {:noreply, put_flash(socket, :error, reason)}
  end
end
```

## Event Handling

### Workflow Progress Events

```elixir
# Process created - subscribe to detailed events
@impl true
def handle_info({:process_created, process_id, workflow_id}, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "process:#{process_id}")
  end

  # Update widget to track this process
  widgets =
    Enum.map(socket.assigns.widgets, fn widget ->
      if widget[:id] == "progress-#{workflow_id}" do
        Map.put(widget, :process_id, process_id)
      else
        widget
      end
    end)

  {:noreply, assign(socket, :widgets, widgets)}
end

# Progress update - show incremental progress
@impl true
def handle_info({:progress_update, %{content: content, timestamp: ts}}, socket) do
  widgets =
    Enum.map(socket.assigns.widgets, fn widget ->
      if widget[:type] == :progress && widget[:is_live] do
        updates = [%{content: content, timestamp: ts} | (widget[:updates] || [])]
        Map.put(widget, :updates, updates)
      else
        widget
      end
    end)

  {:noreply, assign(socket, :widgets, widgets)}
end

# Step execution started
@impl true
def handle_info({:step_started, %{step: step_name, timestamp: ts}}, socket) do
  activity = %{
    step: step_name,
    status: :running,
    timestamp: ts,
    description: describe_step(step_name)
  }

  widgets =
    Enum.map(socket.assigns.widgets, fn widget ->
      if widget[:type] == :progress && widget[:is_live] do
        activities = [activity | (widget[:activities] || [])]

        widget
        |> Map.put(:activities, activities)
        |> Map.put(:percentage, estimate_progress(step_name))
      else
        widget
      end
    end)

  {:noreply, assign(socket, :widgets, widgets)}
end

# Step execution completed
@impl true
def handle_info({:step_completed, %{step: step_name, result: result}}, socket) do
  widgets =
    Enum.map(socket.assigns.widgets, fn widget ->
      if widget[:type] == :progress && widget[:is_live] do
        # Mark most recent matching activity as completed
        activities =
          Enum.map(widget[:activities] || [], fn activity ->
            if activity.step == step_name && activity.status == :running do
              %{activity | status: :completed, result: result}
            else
              activity
            end
          end)

        Map.put(widget, :activities, activities)
      else
        widget
      end
    end)

  {:noreply, assign(socket, :widgets, widgets)}
end

# Workflow completed
@impl true
def handle_info({:workflow_completed, workflow_id, _meta}, socket) do
  # Reload full state and rebuild widgets
  {:ok, workflows} = load_workflows(socket.assigns.resource.id)
  widgets = build_widgets_from_workflows(workflows)

  {:noreply, assign(socket, :widgets, widgets)}
end

defp describe_step("validate"), do: "Validating input"
defp describe_step("process"), do: "Processing data"
defp describe_step(step), do: "Running #{step}"

defp estimate_progress("validate"), do: 30
defp estimate_progress("process"), do: 60
defp estimate_progress(_), do: 50

defp load_workflows(_resource_id), do: {:ok, []}
defp build_widgets_from_workflows(_workflows), do: []
```

## Broadcasting Events

### From Oban Workers

```elixir
defmodule MyApp.Jobs.WorkflowExecutionWorker do
  use Oban.Worker

  @impl true
  def perform(%{args: %{"resource_id" => resource_id, "workflow_id" => workflow_id}}) do
    process_id = Ash.UUID.generate()

    # Broadcast process created
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "resource:#{resource_id}",
      {:process_created, process_id, workflow_id}
    )

    # Execute workflow
    execute_workflow(process_id, resource_id, workflow_id)

    :ok
  end

  defp execute_workflow(process_id, resource_id, workflow_id) do
    # Broadcast progress update
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "process:#{process_id}",
      {:progress_update, %{content: "Starting workflow...", timestamp: DateTime.utc_now()}}
    )

    # Broadcast step execution
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "process:#{process_id}",
      {:step_started, %{step: "validate", args: %{}, timestamp: DateTime.utc_now()}}
    )

    # Execute step...
    result = %{status: :success, data: %{}}

    # Broadcast completion
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "process:#{process_id}",
      {:step_completed, %{step: "validate", result: result, timestamp: DateTime.utc_now()}}
    )

    # Broadcast final completion
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "resource:#{resource_id}",
      {:workflow_completed, workflow_id, %{status: :completed}}
    )
  end
end
```

## Widget Update Patterns

### Update Specific Widget

```elixir
def update_widget_by_id(widgets, widget_id, updates) do
  Enum.map(widgets, fn widget ->
    if widget[:id] == widget_id do
      Map.merge(widget, updates)
    else
      widget
    end
  end)
end

# Usage
widgets = update_widget_by_id(socket.assigns.widgets, "progress-1", %{percentage: 75})
assign(socket, :widgets, widgets)
```

### Replace Widget

```elixir
def replace_widget(widgets, widget_id, new_widget) do
  widgets
  |> Enum.reject(&(&1[:id] == widget_id))
  |> Kernel.++([new_widget])
end

# Usage - replace progress with result
widgets =
  socket.assigns.widgets
  |> replace_widget("progress-#{workflow_id}", result_widget)

assign(socket, :widgets, widgets)
```

### Update Matching Widgets

```elixir
def update_live_progress_widgets(widgets, updates) do
  Enum.map(widgets, fn widget ->
    if widget[:type] == :progress && widget[:is_live] do
      Map.merge(widget, updates)
    else
      widget
    end
  end)
end
```

## Performance Optimization

### Event Throttling

Limit high-frequency event updates:

```elixir
defmodule ThrottledUpdates do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:last_update, DateTime.utc_now())
     |> assign(:throttle_ms, 500)}
  end

  @impl true
  def handle_info({:progress_update, data}, socket) do
    now = DateTime.utc_now()
    last_update = socket.assigns.last_update
    throttle_ms = socket.assigns.throttle_ms

    if DateTime.diff(now, last_update, :millisecond) >= throttle_ms do
      widgets = apply_progress_update(socket.assigns.widgets, data)

      {:noreply,
       socket
       |> assign(:widgets, widgets)
       |> assign(:last_update, now)}
    else
      # Skip update - too frequent
      {:noreply, socket}
    end
  end

  defp apply_progress_update(widgets, _data), do: widgets
end
```

### Batch Updates

Process multiple events together:

```elixir
def handle_info({:batch_events, events}, socket) do
  widgets =
    Enum.reduce(events, socket.assigns.widgets, fn event, acc_widgets ->
      apply_event(acc_widgets, event)
    end)

  {:noreply, assign(socket, :widgets, widgets)}
end

defp apply_event(widgets, {:progress_update, id, pct}) do
  update_widget_by_id(widgets, id, %{percentage: pct})
end

defp apply_event(widgets, {:activity_added, id, activity}) do
  Enum.map(widgets, fn widget ->
    if widget[:id] == id do
      activities = [activity | (widget[:activities] || [])]
      Map.put(widget, :activities, activities)
    else
      widget
    end
  end)
end
```

## Best Practices

### 1. Always Check connected?

```elixir
# ✅ Correct
if connected?(socket) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
end

# ❌ Wrong - subscribes during initial HTTP request too
Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
```

### 2. Use Hierarchical Topics

```elixir
# ✅ Good - clear hierarchy
"workflow:#{workflow_id}"
"process:#{process_id}"
"version:#{version_id}"

# ❌ Bad - flat, ambiguous
"updates"
"progress"
"events"
```

### 3. Structure Event Data

```elixir
# ✅ Good - map with named fields
{:step_started, %{
  step: "validate",
  args: %{data: data},
  timestamp: DateTime.utc_now()
}}

# ❌ Bad - positional arguments
{:step_started, "validate", %{data: data}, DateTime.utc_now()}
```

### 4. Handle Events Gracefully

```elixir
@impl true
def handle_info({:data_update, data}, socket) do
  case apply_update(socket, data) do
    {:ok, updated_socket} ->
      {:noreply, updated_socket}

    {:error, reason} ->
      Logger.warning("Failed to apply update: #{inspect(reason)}")
      # Don't crash - just skip the update
      {:noreply, socket}
  end
end
```

## Common Pitfalls

### 1. Forgetting connected? Check

```elixir
# ❌ Wrong
def mount(_params, _session, socket) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
  {:ok, socket}
end

# ✅ Correct
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
  end

  {:ok, socket}
end
```

### 2. Broadcasting to Wrong Topic

```elixir
# ❌ Wrong - typo in topic name
Phoenix.PubSub.broadcast(MyApp.PubSub, "resource_#{resource_id}", event)

# ✅ Correct - use correct topic pattern
Phoenix.PubSub.broadcast(MyApp.PubSub, "resource:#{resource_id}", event)
```

### 3. Not Handling All Event Types

```elixir
# ❌ Wrong - missing error handling
@impl true
def handle_info({:step_completed, data}, socket) do
  # Only handles success case
  {:noreply, update_widget(socket, data)}
end

# ✅ Correct - handle errors too
@impl true
def handle_info({:step_completed, data}, socket) do
  if data[:error] do
    {:noreply, handle_error(socket, data)}
  else
    {:noreply, update_widget(socket, data)}
  end
end
```

## Related Resources

### Project Files

- **LiveView Interfaces**: `lib/my_app_web/live/`
- **Progress Handlers**: `lib/my_app_web/live/behaviors/progress_handlers.ex`
- **Background Workers**: `lib/my_app/jobs/`

### Design Documentation

- **Progress System** - Detailed progress architecture
- **Event-Driven Architecture** - Event patterns
- **Widget Architecture** - Widget system

### Skill Examples

- **[pubsub.ex](../examples/pubsub.ex)** - Self-contained PubSub examples
- **[basic-liveview.ex](../examples/basic-liveview.ex)** - Basic LiveView
  patterns

### External Documentation

- [Phoenix.PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
