---
name: phoenix-liveview
description:
  Phoenix LiveView patterns and real-time UI development. Use when implementing
  LiveView pages, handling PubSub events, building components, managing
  real-time updates, or working with dynamic interfaces.
---

# Phoenix LiveView Skill

Expert guidance for Phoenix LiveView patterns in Elixir applications.

## What This Skill Covers

- **LiveView Structure**: Mount, render, event handling, and PubSub integration
- **Real-time Updates**: Widget-based architecture with PubSub subscriptions
- **Components**: Function components and LiveComponents
- **Forms**: Form handling with phx-submit, phx-change, and validation
- **Assigns Management**: Socket state and progressive rendering
- **JavaScript Hooks**: Client-side interactions (ScrollToBottom,
  CopyToClipboard, etc.)

## When to Use This Skill

Use this skill when:

- Creating new LiveView pages or components
- Implementing real-time features with PubSub
- Building widgets for chat interfaces
- Handling forms and user input
- Managing LiveView state and assigns
- Integrating JavaScript hooks
- Debugging LiveView lifecycle issues

## Quick Reference

### Core Patterns

1. **Data-Driven UI**: Use data structures to drive component rendering
2. **Helper Modules**: Business logic lives in helpers, not LiveViews
3. **PubSub for Real-time**: Subscribe to relevant topics for live updates
4. **Actor Context**: Always pass actor for authorization (in multi-tenant apps)
5. **LiveComponent Communication**: Use `send(self(), ...)` pattern

### Directory Structure

```
.claude/skills/phoenix-liveview/
├── SKILL.md                    # This file
├── examples/                   # Self-contained code examples
│   ├── basic-liveview.ex       # Simple LiveView structure
│   ├── components.ex           # Function components & LiveComponents
│   ├── streams.ex              # LiveView streams (limited use in project)
│   ├── pubsub.ex               # Real-time PubSub patterns
│   ├── forms.ex                # Form handling patterns
│   └── assigns.ex              # Assign management patterns
├── scripts/
│   └── hooks.js                # Reusable JavaScript hooks
└── reference/                  # Detailed documentation
    ├── components.md           # Component patterns
    ├── real-time.md            # PubSub and real-time updates
    └── forms.md                # Form handling
```

## Related Documentation

### Project Documentation

- **Project Docs**: Check your application's conventions and patterns
- **Official Docs**: Phoenix LiveView guides and hexdocs

### Architecture Documentation

- **Design Docs**: Review your project's design documentation for:
  - Component architecture and patterns
  - Helper module organization
  - Real-time update strategies
  - Event-driven patterns
  - UI component library

## Progressive Learning Path

1. **Start**: Read `examples/basic-liveview.ex` for LiveView structure
2. **Components**: Read `examples/components.ex` and `reference/components.md`
3. **Real-time**: Read `examples/pubsub.ex` and `reference/real-time.md`
4. **Forms**: Read `examples/forms.ex` and `reference/forms.md`
5. **Advanced**: Study actual LiveViews in your application's codebase

## Common Tasks

### Create a New LiveView

See: `examples/basic-liveview.ex`

### Add Real-time Updates

See: `examples/pubsub.ex` and `reference/real-time.md`

### Build a Form

See: `examples/forms.ex` and `reference/forms.md`

### Extract a Component

See: `examples/components.ex` and `reference/components.md`

## Related Skills

- **ash-framework**: Resource operations, actor context, changesets
- **reactor-oban**: Background jobs, workflows
- **ui-design**: DaisyUI components, styling patterns
- **testing**: LiveView testing strategies

## Best Practice Conventions

- **Never bypass authorization**: Always pass `actor: user` to Ash operations
  (in multi-tenant apps)
- **Use helpers for logic**: LiveViews should be thin presentation layers
- **Data-driven UI**: Use structured data to drive dynamic interfaces
- **PubSub subscriptions**: Only subscribe when `connected?(socket)` is true
- **Component communication**: Use `send(self(), ...)` from LiveComponents to
  parent

## Critical: PubSub Broadcast Timing

When broadcasting events that trigger data reloads in LiveView, ensure the
database is updated BEFORE broadcasting:

```elixir
# ❌ WRONG - Race condition! LiveView reloads stale data
with {:ok, result} <- do_work() do
  broadcast_completion()  # Fires immediately
  update_db_status()      # DB updated AFTER broadcast
end

# ✅ CORRECT - DB consistent before broadcast
with {:ok, result} <- do_work(),
     :ok <- update_db_status() do  # DB updated first
  broadcast_completion()           # LiveView reloads fresh data
end
```

This is especially important for background jobs (Oban workers) that broadcast
completion events - the handler that marks records as "completed" must run
BEFORE broadcasting.

## LiveSvelte Integration Warning

When using LiveSvelte, socket assigns do NOT propagate after initial mount due
to `phx-update="ignore"`. Use `push_event` for real-time updates:

```elixir
def handle_info({:data_updated, data}, socket) do
  socket
  |> assign(:data, data)  # For page refresh
  |> push_svelte_event("data_updated", %{data: data})  # For real-time
end
```

See `.claude/skills/live-svelte/SKILL.md` for the Svelte-side handling pattern.

## Examples Overview

All examples are self-contained and based on actual project code:

- `basic-liveview.ex` - Minimal LiveView with mount, render, events
- `components.ex` - Function components and LiveComponent patterns
- `streams.ex` - LiveView streams (note: limited use in this project)
- `pubsub.ex` - Real-time updates via Phoenix.PubSub
- `forms.ex` - Form handling with validation and submission
- `assigns.ex` - Assign management and state patterns
