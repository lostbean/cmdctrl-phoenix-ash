---
name: live-svelte
description: |
  LiveSvelte integration patterns for Phoenix applications. Use when working with Svelte
  components, LiveView integration, event handling, or implementing rich interactive UIs
  with Svelte embedded in LiveView.
---

# LiveSvelte Skill

Expert guidance for integrating Svelte components with Phoenix LiveView using
LiveSvelte and Svelte 5.

**Architecture Pattern**: LiveSvelte enables a component-based architecture
where Svelte handles rich interactive UI while LiveView manages server-side
data, passing props and handling events.

## What This Skill Covers

- **Component Structure**: PascalCase naming, file organization, TypeScript
- **LiveView Integration**: Props passing, event handling, the `live` interface
- **State Management**: When to use `$state()` vs `$derived()` vs LiveView props
- **Styling**: TailwindCSS utility patterns used in components
- **Build Pipeline**: esbuild with Svelte plugin, hot reload

## When to Use This Skill

Use this skill when:

- Creating or modifying Svelte components in `assets/svelte/`
- Understanding how LiveView and Svelte communicate
- Debugging prop passing or event handling issues
- Adding new UI features or pages
- Working with Svelte 5 runes syntax

## Quick Reference

### Component Location

Organize Svelte components in `assets/svelte/` with PascalCase names:

```
assets/svelte/
├── App.svelte               # Root or main component
├── Navigation.svelte        # Navigation component
├── Dashboard.svelte         # Dashboard view
├── DataTable.svelte         # Data table component
├── Chart.svelte             # Chart/visualization component
├── features/                # Feature-specific components
│   ├── UserProfile.svelte
│   ├── Settings.svelte
│   └── Reports.svelte
├── types.ts                 # TypeScript type definitions
└── utils.ts                 # Shared utilities
```

### LiveView Structure

Each page has a corresponding LiveView in `lib/my_app_web/live/`:

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:svelte_props, %{
        data: load_dashboard_data(),
        user: current_user(socket)
      })

    {:ok, socket}
  end
end
```

### Rendering in HEEx

```heex
<.svelte
  name="App"
  props={@svelte_props}
  class="h-screen w-screen"
/>
```

### Registering New Components

Add to `assets/js/app.js`:

```javascript
import NewComponent from "../svelte/NewComponent.svelte";

const svelteHooks = getHooks({
  App,
  NewComponent, // Add here
});
```

## Component Patterns (Svelte 5)

### Props from LiveView

```svelte
<script lang="ts">
  import type { DashboardData, User } from "./types";

  let {
    live,
    data,
    user,
  } = $props<{
    live: any;
    data: DashboardData;
    user: User;
  }>();
</script>
```

### Event Handlers (Delegate to LiveView)

```svelte
<script lang="ts">
  const handleFilterChange = (filter: string) => {
    live.pushEvent("filter_change", { filter });
  };

  const handleSave = () => {
    live.pushEvent("save_changes", { data: formData });
  };
</script>
```

### Derived State

```svelte
<script lang="ts">
  let filteredItems = $derived(
    items.filter((item) => item.status === selectedStatus)
  );
</script>
```

### Local UI State

```svelte
<script lang="ts">
  let showModal = $state(false);
  let isLoading = $state(false);
</script>
```

### Date Normalization

Server sends dates as strings; normalize them in Svelte:

```svelte
<script lang="ts">
  const normalizeThreads = (threads: any[]) => {
    return threads.map((t) => ({
      ...t,
      lastUpdated: typeof t.lastUpdated === "string"
        ? new Date(t.lastUpdated)
        : t.lastUpdated,
    }));
  };

  let normalizedThreads = $derived(normalizeThreads(threads));
</script>
```

## Styling Patterns

Use TailwindCSS with consistent patterns:

```svelte
<!-- Card -->
<div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">

<!-- Button (primary) -->
<button class="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">

<!-- Button (secondary) -->
<button class="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50">

<!-- Input -->
<input class="w-full px-3 py-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500/50">

<!-- Status badge -->
<span class="px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-50 text-emerald-600">
```

## Directory Structure

```
.claude/skills/live-svelte/
├── SKILL.md                     # This file
├── examples/                    # Code examples
│   ├── basic-component.svelte   # Minimal working component
│   ├── liveview-events.svelte   # Event handling patterns
│   └── styling-patterns.svelte  # TailwindCSS usage
└── reference/                   # Detailed documentation
    ├── decision-guide.md        # State management decisions
    ├── integration.md           # Build pipeline and hooks
    └── styling.md               # Styling conventions
```

## Common Patterns

### Conditional Rendering

```svelte
{#if view === "table"}
  <DataTable {data} onRowClick={handleRowClick} />
{:else if view === "grid"}
  <DataGrid {data} onCardClick={handleCardClick} />
{:else if view === "chart"}
  <ChartView {data} {live} />
{/if}
```

### Passing `live` to Child Components

Use `_live` as prop name to avoid ESLint "unused variable" warnings:

```svelte
<DataTable
  {data}
  onRowClick={handleRowClick}
  _live={live}
/>
```

### Loading States

```svelte
<script lang="ts">
  let isLoading = $state(false);

  const handleSubmit = async () => {
    isLoading = true;
    live.pushEvent("submit", { data });
    setTimeout(() => { isLoading = false; }, 500);
  };
</script>

<button disabled={isLoading}>
  {isLoading ? "Saving..." : "Save"}
</button>
```

## Real-Time Updates (Critical)

### The `phx-update="ignore"` Problem

**IMPORTANT**: LiveSvelte uses `phx-update="ignore"` which **blocks socket
assign propagation after initial mount**. Updating a socket assign in LiveView
will NOT update the Svelte component!

### Solution: Use `push_event` + Boxed State

```elixir
# In LiveView - push event instead of relying on assigns
def handle_info({:data_updated, new_data}, socket) do
  socket
  |> assign(:my_data, new_data)  # Keep for page refresh
  |> push_svelte_event("data_updated", %{data: new_data})  # Real-time update
end
```

```svelte
<script lang="ts">
  // Use BOXED STATE pattern for reactivity in handleEvent callbacks
  let dataOverrideBox = $state<{ value: typeof myData }>({ value: null });
  let activeData = $derived(dataOverrideBox.value ?? myData);

  onMount(() => {
    live.handleEvent("data_updated", (payload) => {
      // Replace ENTIRE object to trigger Svelte 5 reactivity
      dataOverrideBox = { value: payload.data };
    });
  });
</script>

<!-- Use activeData, not myData -->
<MyComponent data={activeData} />
```

### Why Boxed State?

Svelte 5's reactivity doesn't always trigger when updating `$state` from within
`handleEvent` callbacks registered in `onMount`. The boxed object pattern forces
reactivity by replacing the entire object reference:

```svelte
// ❌ WRONG - may not trigger re-render
let override = $state(null);
live.handleEvent("update", (d) => { override = d.data; });

// ✅ CORRECT - always triggers re-render
let overrideBox = $state<{ value: any }>({ value: null });
live.handleEvent("update", (d) => { overrideBox = { value: d.data }; });
```

### PubSub Timing Matters

When LiveView reloads data on a PubSub event, ensure the DB is updated FIRST:

```elixir
# ❌ Race condition - broadcast before DB update
broadcast_completion()
mark_completed_in_db()

# ✅ Correct - DB updated before broadcast
mark_completed_in_db()
broadcast_completion()
```

## Related Skills

- **ui-design**: TailwindCSS component patterns
- **phoenix-liveview**: LiveView event handling and assigns
- **elixir-testing**: Testing LiveView integration

## Related Documentation

- **Design Patterns**: Check your project's UI design documentation
- **UI Design Skill**: `.claude/skills/ui-design/SKILL.md`
- **LiveView Skill**: `.claude/skills/phoenix-liveview/SKILL.md`
