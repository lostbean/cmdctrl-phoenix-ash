# When to Use LiveSvelte vs LiveView

## Decision Matrix

| Requirement               | Use LiveView + DaisyUI | Use LiveSvelte     |
| ------------------------- | ---------------------- | ------------------ |
| Simple forms              | Yes                    | No                 |
| Basic CRUD                | Yes                    | No                 |
| Data tables               | Yes                    | Maybe (if complex) |
| Flow diagrams             | No                     | Yes                |
| Drag-and-drop             | Maybe (with hooks)     | Yes                |
| Real-time charts          | Maybe                  | Yes                |
| Complex animations        | No                     | Yes                |
| Third-party viz libraries | No                     | Yes                |

## LiveView Strengths

- Server-rendered HTML (SEO, accessibility)
- Automatic state sync with server
- Simple mental model
- Less JavaScript to maintain
- Works with DaisyUI out of the box

## LiveSvelte Strengths

- Rich client-side interactivity
- Complex state management
- Access to Svelte ecosystem
- Fine-grained reactivity
- Better performance for frequent updates

## Hybrid Approach (Recommended)

Use LiveView for page structure and data loading, embed Svelte components only
where rich interactivity is required:

```heex
<div class="p-4">
  <h1 class="text-2xl font-bold"><%= @model.name %></h1>

  <%!-- Standard LiveView form --%>
  <.form for={@form} phx-submit="save">
    <.input field={@form[:name]} label="Name" />
    <.button>Save</.button>
  </.form>

  <%!-- Svelte component for complex visualization --%>
  <.svelte
    name="WorkflowDiagram"
    props={%{nodes: @nodes, edges: @edges}}
    class="mt-4 h-96 border rounded"
  />
</div>
```

## Red Flags for LiveSvelte

Avoid LiveSvelte if:

- The component is primarily displaying data
- User interactions are simple clicks/inputs
- You need server-side validation on every keystroke
- The team isn't familiar with Svelte
- You're building a simple admin interface

## Green Flags for LiveSvelte

Consider LiveSvelte if:

- Building visual editors or diagramming tools
- Need drag-and-drop with visual feedback
- Complex animation or transition requirements
- Integrating with D3.js or similar libraries
- High-frequency client-side state changes
