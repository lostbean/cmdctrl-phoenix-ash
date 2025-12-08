# LiveView Components Reference

Component patterns and best practices for Phoenix LiveView.

## Overview

Phoenix LiveView provides two types of components:

1. **Function Components** - Stateless, pure rendering functions
2. **LiveComponents** - Stateful components with lifecycle and event handling

## Function Components

### Basic Pattern

Function components are simple functions that return HEEx templates:

```elixir
defmodule MyAppWeb.Components do
  use Phoenix.Component

  attr :title, :string, required: true
  attr :class, :string, default: ""

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-100", @class]}>
      <div class="card-body">
        <h2 class="card-title">{@title}</h2>
      </div>
    </div>
    """
  end
end
```

### Attributes

Define attributes with `attr`:

```elixir
attr :name, :string, required: true
attr :age, :integer, default: 0
attr :class, :string, default: ""
attr :active, :boolean, default: false
attr :items, :list, default: []
attr :metadata, :map, default: %{}
attr :status, :atom, values: [:pending, :completed], default: :pending
```

### Slots

Use slots for content injection:

```elixir
slot :header
slot :footer
slot :inner_block, required: true

def panel(assigns) do
  ~H"""
  <div class="panel">
    <div :if={@header != []} class="panel-header">
      {render_slot(@header)}
    </div>

    <div class="panel-body">
      {render_slot(@inner_block)}
    </div>

    <div :if={@footer != []} class="panel-footer">
      {render_slot(@footer)}
    </div>
  </div>
  """
end
```

Usage:

```heex
<.panel>
  <:header>
    <h2>Panel Title</h2>
  </:header>

  <p>Main content</p>

  <:footer>
    <button class="btn">Action</button>
  </:footer>
</.panel>
```

## LiveComponents

### Basic Structure

LiveComponents have their own lifecycle and can handle events:

```elixir
defmodule MyAppWeb.ProgressWidget do
  use MyAppWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="progress-widget">
      <p>{@label}: {@percentage}%</p>
      <button phx-click="increment" phx-target={@myself}>
        Increment
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :percentage, &(&1 + 10))}
  end
end
```

Usage:

```heex
<.live_component
  module={MyAppWeb.ProgressWidget}
  id="progress-1"
  label="Upload Progress"
  percentage={45}
/>
```

### Lifecycle Callbacks

```elixir
# Called when component mounts
def mount(socket) do
  {:ok, assign(socket, :count, 0)}
end

# Called when assigns change (required)
def update(assigns, socket) do
  {:ok, assign(socket, assigns)}
end

# Called for component events (phx-target={@myself})
def handle_event(event, params, socket) do
  {:noreply, socket}
end

# Called for PubSub messages
def handle_info(message, socket) do
  {:noreply, socket}
end
```

### Component Communication

LiveComponents communicate with parent via `send/2`:

```elixir
defmodule MyAppWeb.Sidebar do
  use MyAppWeb, :live_component

  @impl true
  def handle_event("navigate", %{"path" => path}, socket) do
    # Send message to parent LiveView
    send(self(), {:sidebar_event, :navigate, path})
    {:noreply, socket}
  end
end
```

Parent LiveView handles the message:

```elixir
@impl true
def handle_info({:sidebar_event, :navigate, path}, socket) do
  {:noreply, push_navigate(socket, to: path)}
end
```

## When to Use Which

### Use Function Components When:

- ✅ Stateless UI rendering
- ✅ Reusable UI patterns
- ✅ No event handling needed
- ✅ No PubSub subscriptions

Example: Badges, cards, alerts, layouts

### Use LiveComponents When:

- ✅ Component has its own state
- ✅ Handles user events
- ✅ Subscribes to PubSub
- ✅ Complex lifecycle needs

Example: Progress widgets, modals, forms with validation

## Common Patterns

### Widget Components

LiveComponents can be used for widgets:

```elixir
defmodule MyAppWeb.Widgets.Progress do
  use MyAppWeb.Widgets.Widget

  @impl true
  def update(assigns, socket) do
    # Subscribe to real-time updates
    if assigns[:is_live] && connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "progress:#{assigns.id}")
    end

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_info({:progress_update, percentage}, socket) do
    {:noreply, assign(socket, :percentage, percentage)}
  end
end
```

### Shared Behaviors

Behavior modules can encapsulate reusable logic:

```elixir
defmodule MyAppWeb.Live.Behaviors.ProgressHandlers do
  def handle_update_token(socket, data) do
    # Update widgets...
    Phoenix.Component.assign(socket, :widgets, updated_widgets)
  end
end
```

Used in LiveViews:

```elixir
@impl true
def handle_info({:update_token, data}, socket) do
  {:noreply, ProgressHandlers.handle_update_token(socket, data)}
end
```

## Best Practices

### 1. Keep Components Focused

✅ **Good**: Single responsibility

```elixir
def user_badge(assigns) do
  ~H"""
  <span class="badge">{@user.name}</span>
  """
end
```

❌ **Bad**: Too many responsibilities

```elixir
def user_section(assigns) do
  ~H"""
  <div>
    <span>{@user.name}</span>
    <div>{@user.profile}</div>
    <ul>{@user.posts}</ul>
    <!-- Too much! -->
  </div>
  """
end
```

### 2. Use assign_new for Defaults

```elixir
def update(assigns, socket) do
  {:ok,
   socket
   |> assign(assigns)
   |> assign_new(:expanded, fn -> true end)
   |> assign_new(:theme, fn -> "light" end)}
end
```

### 3. Document Attributes

```elixir
@doc """
Alert component for displaying notifications.

## Examples

    <.alert type="success" message="Saved!" />
    <.alert type="error" message="Failed" />
"""
attr :type, :string, required: true
attr :message, :string, required: true

def alert(assigns) do
  # ...
end
```

### 4. Component IDs

LiveComponents MUST have unique IDs:

```heex
<!-- ✅ Good -->
<.live_component module={Widget} id="widget-#{@item.id}" />

<!-- ❌ Bad - duplicate IDs will cause issues -->
<.live_component module={Widget} id="widget" />
```

## Common Pitfalls

### 1. Forgetting phx-target

```elixir
# Component events need phx-target={@myself}

# ❌ Wrong - event goes to parent
<button phx-click="increment">+</button>

# ✅ Correct - event goes to component
<button phx-click="increment" phx-target={@myself}>+</button>
```

### 2. Missing Component ID

```elixir
# ❌ Wrong - no ID
<.live_component module={Widget} label="Test" />

# ✅ Correct - includes ID
<.live_component module={Widget} id="widget-1" label="Test" />
```

### 3. Over-using LiveComponents

```elixir
# ❌ Wrong - LiveComponent for simple UI
defmodule SimpleLabel do
  use Phoenix.LiveComponent
  # Just renders text - use function component!
end

# ✅ Correct - Function component
def simple_label(assigns) do
  ~H"""
  <span class="label">{@text}</span>
  """
end
```

## Related Resources

### Project Files

- See your application's core components module
- See your application's widget modules
- See your application's LiveView component modules

### Design Documentation

- See your project's design documentation for widget architecture
- See your project's design documentation for component patterns
- See your project's design documentation for UI component library

### Skill Examples

- See skill examples directory for self-contained component examples
- See skill examples directory for component usage in LiveViews

### External Documentation

- [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [Phoenix.LiveComponent](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html)
- [HEEx Templates](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2)
