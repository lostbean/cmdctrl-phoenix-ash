# LiveSvelte Integration Details

## Build Pipeline

Your application uses a custom Node.js build script (`assets/build.js`) instead
of the Elixir esbuild package to support Svelte compilation.

### How It Works

1. `mix assets.build` runs `node assets/build.js`
2. esbuild bundles JavaScript with the `esbuild-svelte` plugin
3. Svelte components are compiled to JavaScript
4. Output goes to `priv/static/assets/js/`

### Development Mode

In development, the watcher in `config/dev.exs` runs:

```elixir
node: ["build.js", "--watch", cd: Path.expand("../assets", __DIR__)]
```

This provides:

- Automatic recompilation on Svelte file changes
- Sourcemaps for debugging
- Live reload integration

### Adding New Components

1. Create component in `assets/svelte/ComponentName.svelte`
2. Import in `assets/js/app.js`
3. Add to `getHooks()` component registry
4. Use in HEEx with `<.svelte name="ComponentName" />`

### Component Registry

```javascript
// assets/js/app.js
import { getHooks } from "live_svelte";

// Import all Svelte components
import HelloWorld from "../svelte/HelloWorld.svelte";
import WorkflowDiagram from "../svelte/WorkflowDiagram.svelte";

// Register with LiveSvelte
const svelteHooks = getHooks({
  HelloWorld,
  WorkflowDiagram,
  // Component name must match exactly
});
```

## LiveView Integration

### Props Passing

Props flow from LiveView assigns to Svelte:

```elixir
# LiveView
def render(assigns) do
  ~H"""
  <.svelte
    name="MyComponent"
    props={%{
      items: @items,
      selected_id: @selected_id,
      config: %{theme: "bumblebee"}
    }}
  />
  """
end
```

```svelte
<!-- Svelte component -->
<script>
  export let items = [];
  export let selected_id = null;
  export let config = {};
  export let live; // Always available
</script>
```

### Events: Svelte to LiveView

```svelte
<script>
  export let live;

  function handleClick(item) {
    // Push event to LiveView
    live.pushEvent("item_clicked", { id: item.id });
  }
</script>
```

```elixir
# LiveView handler
def handle_event("item_clicked", %{"id" => id}, socket) do
  # Handle the event
  {:noreply, assign(socket, :selected_id, id)}
end
```

### Events: LiveView to Svelte

```elixir
# LiveView
def handle_info(:highlight_node, socket) do
  {:noreply, push_event(socket, "highlight", %{node_id: "abc"})}
end
```

```svelte
<script>
  import { onMount } from "svelte";
  export let live;

  onMount(() => {
    // Listen for events from LiveView
    live.handleEvent("highlight", ({ node_id }) => {
      highlightNode(node_id);
    });
  });
</script>
```

## TypeScript Support

Components can use TypeScript:

```svelte
<script lang="ts">
  interface Item {
    id: string;
    name: string;
  }

  export let items: Item[] = [];
  export let live: LiveSvelte.Live;
</script>
```

Run type checking with:

```bash
npm run check --prefix assets
```
