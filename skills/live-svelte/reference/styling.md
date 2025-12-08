# Styling LiveSvelte Components

## Using DaisyUI Classes

Svelte components should use DaisyUI classes for consistency with the rest of
your application UI.

### Theme Colors

```svelte
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title text-primary">Title</h2>
    <p class="text-base-content">Description</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Primary</button>
      <button class="btn btn-secondary">Secondary</button>
    </div>
  </div>
</div>
```

### Status Colors

```svelte
<span class="badge badge-success">Active</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-error">Failed</span>
<span class="badge badge-info">Info</span>
```

## Component-Scoped Styles

Use `<style>` for component-specific styles:

```svelte
<div class="flow-container">
  <div class="node">Node content</div>
</div>

<style>
  .flow-container {
    position: relative;
    overflow: hidden;
  }

  .node {
    /* Custom node styling - can mix with Tailwind @apply */
    @apply bg-base-200 rounded-lg p-4;
  }
</style>
```

## CSS Variables from DaisyUI

Access theme colors via CSS variables:

```svelte
<style>
  .custom-element {
    background-color: oklch(var(--p)); /* Primary color */
    color: oklch(var(--pc)); /* Primary content */
    border-color: oklch(var(--b3)); /* Base-300 */
  }
</style>
```

## Responsive Design

Use Tailwind breakpoint prefixes:

```svelte
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {#each items as item}
    <div class="card bg-base-100 shadow-sm">
      {item.name}
    </div>
  {/each}
</div>
```

## Dynamic Classes

Svelte's class directive works with DaisyUI:

```svelte
<script>
  export let isActive = false;
  export let variant = "primary";
</script>

<button
  class="btn"
  class:btn-active={isActive}
  class:btn-primary={variant === "primary"}
  class:btn-secondary={variant === "secondary"}
>
  Click me
</button>
```

## Avoiding Style Conflicts

1. Prefer DaisyUI classes over custom CSS
2. Use component-scoped styles for unique needs
3. Don't override global styles from Svelte components
4. Use CSS custom properties for theming
