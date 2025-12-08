# TailwindCSS Utility Reference

Guide to TailwindCSS utilities for your Phoenix LiveView application.

## Overview

TailwindCSS is a utility-first CSS framework. **Prefer DaisyUI semantic
classes** over raw utilities when components exist, but use Tailwind utilities
for layout, spacing, sizing, and custom styling.

**Related Files:**

- DaisyUI Components: `daisyui.md`
- LiveView Integration: `liveview-integration.md`
- Examples: See skill examples directory
- Design System: See your project's design documentation
- External: https://tailwindcss.com/docs

## Layout

### Flexbox

```html
<!-- Flex container -->
<div class="flex">...</div>
<div class="flex flex-col">...</div>
<!-- Column direction -->
<div class="flex flex-row">...</div>
<!-- Row direction (default) -->

<!-- Alignment -->
<div class="flex items-center">...</div>
<!-- Vertical center -->
<div class="flex justify-center">...</div>
<!-- Horizontal center -->
<div class="flex items-center justify-between">...</div>

<!-- Wrapping -->
<div class="flex flex-wrap">...</div>
<div class="flex flex-nowrap">...</div>

<!-- Flex grow/shrink -->
<div class="flex-1">...</div>
<!-- Grow to fill space -->
<div class="flex-none">...</div>
<!-- Don't grow/shrink -->
```

**Common Project Patterns:**

```html
<!-- Sidebar layout (from sidebar.ex) -->
<div class="flex h-screen">
  <aside class="w-80 flex flex-col">...</aside>
  <main class="flex-1 overflow-y-auto">...</main>
</div>

<!-- Header with actions -->
<header class="flex items-center justify-between gap-6">
  <div>...</div>
  <div class="flex-none">...</div>
</header>
```

### Grid

```html
<!-- Grid container -->
<div class="grid grid-cols-1">...</div>
<div class="grid grid-cols-2">...</div>
<div class="grid grid-cols-3">...</div>

<!-- Responsive grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- Cards or items -->
</div>

<!-- Grid spanning -->
<div class="col-span-2">...</div>
<!-- Span 2 columns -->
<div class="row-span-2">...</div>
<!-- Span 2 rows -->
```

**Common Project Patterns:**

```html
<!-- Two-column layout -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
  <div class="lg:col-span-2">Main content</div>
  <div class="lg:col-span-1">Sidebar</div>
</div>

<!-- Card grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4">
  <div class="card">...</div>
  <div class="card">...</div>
</div>
```

## Spacing

### Padding

```html
<div class="p-4">...</div>
<!-- All sides -->
<div class="px-4">...</div>
<!-- Horizontal (left/right) -->
<div class="py-4">...</div>
<!-- Vertical (top/bottom) -->
<div class="pt-4">...</div>
<!-- Top only -->
<div class="pr-4">...</div>
<!-- Right only -->
<div class="pb-4">...</div>
<!-- Bottom only -->
<div class="pl-4">...</div>
<!-- Left only -->
```

### Margin

```html
<div class="m-4">...</div>
<!-- All sides -->
<div class="mx-auto">...</div>
<!-- Horizontal centering -->
<div class="mt-4">...</div>
<!-- Top -->
<div class="mb-4">...</div>
<!-- Bottom -->
<div class="ml-2">...</div>
<!-- Left -->
<div class="mr-2">...</div>
<!-- Right -->
```

### Gap (Flex/Grid spacing)

```html
<div class="flex gap-2">...</div>
<!-- 0.5rem gap -->
<div class="flex gap-4">...</div>
<!-- 1rem gap -->
<div class="flex gap-6">...</div>
<!-- 1.5rem gap -->

<div class="grid gap-4">...</div>
<!-- Grid gap -->
<div class="flex gap-x-2 gap-y-4">...</div>
<!-- Different horizontal/vertical gaps -->
```

### Space Between (Stack spacing)

```html
<div class="space-y-2">
  <!-- Vertical spacing between children -->
  <div>Item 1</div>
  <div>Item 2</div>
</div>

<div class="space-x-4">
  <!-- Horizontal spacing -->
  <span>Item 1</span>
  <span>Item 2</span>
</div>
```

**Spacing Scale:**

- `1` = 0.25rem (4px)
- `2` = 0.5rem (8px)
- `3` = 0.75rem (12px)
- `4` = 1rem (16px)
- `6` = 1.5rem (24px)
- `8` = 2rem (32px)

**Project Pattern from sidebar.ex:**

```html
<div class="px-6 py-4 border-b border-base-200 space-y-4">
  <!-- Content with vertical spacing -->
</div>
```

## Sizing

### Width

```html
<div class="w-full">...</div>
<!-- 100% width -->
<div class="w-1/2">...</div>
<!-- 50% width -->
<div class="w-1/3">...</div>
<!-- 33.333% width -->
<div class="w-80">...</div>
<!-- 20rem (320px) -->
<div class="w-auto">...</div>
<!-- Auto width -->

<!-- Max width -->
<div class="max-w-xs">...</div>
<!-- 20rem max -->
<div class="max-w-sm">...</div>
<!-- 24rem max -->
<div class="max-w-md">...</div>
<!-- 28rem max -->
<div class="max-w-lg">...</div>
<!-- 32rem max -->
<div class="max-w-4xl">...</div>
<!-- 56rem max -->

<!-- Min width -->
<div class="min-w-0">...</div>
<!-- 0px min (allows shrinking) -->
```

### Height

```html
<div class="h-screen">...</div>
<!-- 100vh -->
<div class="h-full">...</div>
<!-- 100% -->
<div class="h-auto">...</div>
<!-- Auto height -->

<!-- Max/min height -->
<div class="max-h-96">...</div>
<!-- 24rem max -->
<div class="min-h-screen">...</div>
<!-- 100vh min -->
```

**Project Pattern:**

```html
<!-- Fixed sidebar with scrollable content (from sidebar.ex) -->
<aside class="w-80 flex flex-col h-screen">
  <div class="flex-1 overflow-y-auto">...</div>
</aside>
```

## Typography

### Font Size

```html
<p class="text-xs">...</p>
<!-- 0.75rem -->
<p class="text-sm">...</p>
<!-- 0.875rem -->
<p class="text-base">...</p>
<!-- 1rem (default) -->
<p class="text-lg">...</p>
<!-- 1.125rem -->
<p class="text-xl">...</p>
<!-- 1.25rem -->
<p class="text-2xl">...</p>
<!-- 1.5rem -->
<p class="text-3xl">...</p>
<!-- 1.875rem -->
```

### Font Weight

```html
<p class="font-normal">...</p>
<!-- 400 -->
<p class="font-medium">...</p>
<!-- 500 -->
<p class="font-semibold">...</p>
<!-- 600 -->
<p class="font-bold">...</p>
<!-- 700 -->
```

### Text Color

```html
<!-- Base colors (DaisyUI theme) -->
<p class="text-base-content">...</p>
<!-- Default text -->
<p class="text-base-content/60">...</p>
<!-- 60% opacity -->
<p class="text-base-content/70">...</p>
<!-- 70% opacity -->

<!-- Status colors -->
<p class="text-success">...</p>
<p class="text-error">...</p>
<p class="text-warning">...</p>
<p class="text-info">...</p>

<!-- Custom colors (use sparingly) -->
<p class="text-primary">...</p>
<p class="text-secondary">...</p>
```

### Text Alignment

```html
<p class="text-left">...</p>
<p class="text-center">...</p>
<p class="text-right">...</p>
```

### Text Transform

```html
<p class="uppercase">...</p>
<p class="lowercase">...</p>
<p class="capitalize">...</p>
```

**Project Pattern from sidebar.ex:**

```html
<p class="text-xs uppercase text-base-content/60 mb-2">Section Title</p>
<p class="font-semibold text-lg">Main Title</p>
<p class="text-xs text-base-content/60">Subtitle</p>
```

## Borders

### Border Width

```html
<div class="border">...</div>
<!-- 1px all sides -->
<div class="border-2">...</div>
<!-- 2px all sides -->
<div class="border-t">...</div>
<!-- Top only -->
<div class="border-r">...</div>
<!-- Right only -->
<div class="border-b">...</div>
<!-- Bottom only -->
<div class="border-l">...</div>
<!-- Left only -->
```

### Border Color

```html
<div class="border border-base-300">...</div>
<div class="border border-primary">...</div>
<div class="border border-error">...</div>
```

### Border Radius

```html
<div class="rounded">...</div>
<!-- 0.25rem -->
<div class="rounded-lg">...</div>
<!-- 0.5rem -->
<div class="rounded-xl">...</div>
<!-- 0.75rem -->
<div class="rounded-2xl">...</div>
<!-- 1rem -->
<div class="rounded-full">...</div>
<!-- 9999px (circle) -->
<div class="rounded-box">...</div>
<!-- DaisyUI theme radius -->
```

**Project Pattern:**

```html
<!-- Sidebar sections (from sidebar.ex) -->
<div class="px-6 py-4 border-b border-base-200">...</div>

<!-- Avatar -->
<span class="w-10 rounded-full bg-primary">...</span>

<!-- Menu items -->
<ul class="menu bg-base-100 rounded-box">
  ...
</ul>
```

## Backgrounds

### Background Color

```html
<div class="bg-base-100">...</div>
<!-- Background (white) -->
<div class="bg-base-200">...</div>
<!-- Secondary background -->
<div class="bg-base-300">...</div>
<!-- Tertiary background -->

<div class="bg-primary">...</div>
<div class="bg-success">...</div>
<div class="bg-error">...</div>
```

### Background Opacity

```html
<div class="bg-primary/10">...</div>
<!-- 10% opacity -->
<div class="bg-base-200/50">...</div>
<!-- 50% opacity -->
```

## Shadows

```html
<div class="shadow-sm">...</div>
<!-- Small shadow -->
<div class="shadow">...</div>
<!-- Default shadow -->
<div class="shadow-md">...</div>
<!-- Medium shadow -->
<div class="shadow-lg">...</div>
<!-- Large shadow -->
<div class="shadow-xl">...</div>
<!-- Extra large shadow -->
<div class="shadow-2xl">...</div>
<!-- 2XL shadow -->
```

**Project Pattern:**

```html
<!-- Cards -->
<div class="card bg-base-100 shadow-xl">...</div>

<!-- Dropdown -->
<ul class="dropdown-content menu shadow-lg">
  ...
</ul>

<!-- Stats -->
<div class="stats shadow-sm">...</div>
```

## Overflow

```html
<div class="overflow-auto">...</div>
<!-- Scroll if needed -->
<div class="overflow-hidden">...</div>
<!-- Hide overflow -->
<div class="overflow-scroll">...</div>
<!-- Always scroll -->

<!-- Specific axes -->
<div class="overflow-x-auto">...</div>
<!-- Horizontal scroll -->
<div class="overflow-y-auto">...</div>
<!-- Vertical scroll -->
```

**Project Pattern:**

```html
<!-- Scrollable sidebar content -->
<div class="flex-1 overflow-y-auto">...</div>

<!-- Responsive table -->
<div class="overflow-x-auto">
  <table class="table">
    ...
  </table>
</div>
```

## Position

```html
<div class="static">...</div>
<!-- Default -->
<div class="relative">...</div>
<!-- Relative positioning -->
<div class="absolute">...</div>
<!-- Absolute positioning -->
<div class="fixed">...</div>
<!-- Fixed to viewport -->
<div class="sticky">...</div>
<!-- Sticky positioning -->

<!-- Positioning utilities -->
<div class="top-0">...</div>
<div class="right-0">...</div>
<div class="bottom-0">...</div>
<div class="left-0">...</div>
```

## Display

```html
<div class="block">...</div>
<div class="inline-block">...</div>
<div class="inline">...</div>
<div class="flex">...</div>
<div class="grid">...</div>
<div class="hidden">...</div>
<!-- Display: none -->
```

## Responsive Design

### Breakpoint Prefixes

- `sm:` - 640px and up
- `md:` - 768px and up
- `lg:` - 1024px and up
- `xl:` - 1280px and up
- `2xl:` - 1536px and up

**Common Patterns:**

```html
<!-- Responsive grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">...</div>

<!-- Hide on mobile -->
<div class="hidden md:block">...</div>

<!-- Responsive spacing -->
<div class="px-4 md:px-6 lg:px-8">...</div>

<!-- Responsive flex direction -->
<div class="flex flex-col md:flex-row">...</div>

<!-- Responsive sizing -->
<div class="w-full md:w-1/2 lg:w-1/3">...</div>
```

## Hover, Focus, and States

```html
<!-- Hover -->
<button class="hover:bg-primary">...</button>

<!-- Focus -->
<input class="focus:ring focus:outline-none" />

<!-- Active -->
<button class="active:scale-95">...</button>

<!-- Disabled -->
<button class="disabled:opacity-50">...</button>
```

## Common Utility Combinations

### Truncate Text

```html
<p class="truncate">Long text that will be truncated...</p>
<p class="text-sm text-base-content/60 truncate">...</p>
```

### Centering

```html
<!-- Horizontal center with margin -->
<div class="max-w-4xl mx-auto">...</div>

<!-- Flex center -->
<div class="flex items-center justify-center">...</div>

<!-- Absolute center -->
<div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
  ...
</div>
```

### Full Height Layout

```html
<div class="flex flex-col h-screen">
  <header>...</header>
  <main class="flex-1 overflow-y-auto">...</main>
  <footer>...</footer>
</div>
```

## Best Practices

### ✅ Do

- Use DaisyUI semantic classes for components
- Use Tailwind for layout (flex, grid), spacing, sizing
- Use responsive prefixes for mobile-first design
- Group related utilities logically
- Use opacity modifiers for subtle colors (`text-base-content/60`)

### ❌ Don't

- Don't recreate DaisyUI components with raw utilities
- Don't use arbitrary values excessively (`w-[347px]`)
- Don't forget responsive design
- Don't use inline styles when utilities exist
- Don't mix spacing scales inconsistently

## Project-Specific Patterns

### Sidebar Section (from sidebar.ex)

```html
<div class="px-6 py-4 border-b border-base-200 space-y-4">
  <p class="text-xs uppercase text-base-content/60 mb-2">Section</p>
  <div>Content</div>
</div>
```

### Card with Actions

```html
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Title</h2>
    <p>Content</p>
    <div class="card-actions justify-end mt-4">
      <button class="btn btn-ghost">Cancel</button>
      <button class="btn btn-primary">Save</button>
    </div>
  </div>
</div>
```

### User Avatar with Info

```html
<div class="flex items-center gap-3">
  <span class="avatar">
    <span
      class="w-10 rounded-full bg-neutral text-neutral-content flex items-center justify-center"
    >
      JD
    </span>
  </span>
  <div class="flex-1 min-w-0">
    <p class="font-medium truncate">john@example.com</p>
    <p class="text-xs text-base-content/60">Member</p>
  </div>
</div>
```

## Related Documentation

- **DaisyUI Components**: `daisyui.md` - Prefer semantic components
- **LiveView Integration**: `liveview-integration.md` - Dynamic classes
- **Examples**: See skill examples directory for layout patterns
- **Design System**: See your project's design system documentation
- **External Docs**: https://tailwindcss.com/docs
