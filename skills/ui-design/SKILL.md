---
name: ui-design
description:
  TailwindCSS UI design patterns for Phoenix applications. Use when building UI
  components, styling pages, implementing responsive layouts, or working with
  design systems.
---

# UI Design Skill

Expert guidance for UI design patterns using TailwindCSS and Phoenix LiveView in
Elixir applications.

## What This Skill Covers

- **TailwindCSS**: Utility-first CSS with responsive design
- **Component Patterns**: Buttons, cards, forms, modals, tables, alerts, badges
- **Layout Patterns**: Navbar, sidebar, responsive grids
- **LiveView Integration**: Phx attributes, dynamic classes, JavaScript hooks
- **Accessibility**: ARIA attributes and keyboard navigation
- **Theme System**: Consistent color palette across light/dark modes

## When to Use This Skill

Use this skill when:

- Building new UI pages or components
- Implementing forms with validation states
- Creating modals, dropdowns, or alerts
- Styling components with Tailwind utilities
- Implementing responsive layouts
- Adding interactive elements (tabs, accordions, dropdowns)
- Ensuring accessibility in UI components
- Working with custom color themes

**Note**: For complex interactive components like flow diagrams, drag-and-drop
editors, or data visualizations, see the `live-svelte` skill instead. Tailwind
is for standard UI components; LiveSvelte handles advanced interactivity.

## Quick Reference

### Core Patterns

1. **Utility-First Approach**: Use Tailwind utility classes directly
2. **Theme System**: Define consistent color palette for primary, secondary, and
   status colors
3. **Consistent Spacing**: Use gap-_, p-_, space-y-\* for layout
4. **LiveView Integration**: Combine Tailwind with phx-click, phx-change,
   phx-submit
5. **Component Library**: Reusable Phoenix function components in
   `core_components.ex`

### Directory Structure

```
.claude/skills/ui-design/
├── SKILL.md                    # This file
├── examples/                   # Self-contained code examples
│   ├── buttons.heex            # Button variants and states
│   ├── forms.heex              # Form components and validation
│   ├── modals.heex             # Modal patterns
│   ├── tables.heex             # Table layouts
│   ├── layouts.heex            # Page layout patterns
│   └── hooks-patterns.js       # JavaScript hook examples
└── reference/                  # Detailed documentation
    ├── tailwind.md             # TailwindCSS utilities
    └── liveview-integration.md # LiveView + Tailwind patterns
```

## Related Documentation

- **Design System**: Check your project's design system documentation
- **Component Library**: Review your component patterns and widget library
- **Layout Patterns**: Study your application's layout conventions
- **User Flows**: Document interaction patterns for your features
- **Core Components**: See `lib/*_web/components/core_components.ex` for actual
  implementations

## Progressive Learning Path

1. **Start**: Read `reference/tailwind.md` for utility overview
2. **Examples**: Browse `examples/buttons.heex`, `examples/forms.heex` for
   common patterns
3. **Integration**: Read `reference/liveview-integration.md` for phx attributes
4. **Advanced**: Study actual components in your application
5. **Design System**: Review your project's design system documentation

## Common Tasks

### Create a Button

See: `examples/buttons.heex` and `reference/tailwind.md#buttons`

### Build a Form

See: `examples/forms.heex` and `reference/tailwind.md#forms`

### Implement a Modal

See: `examples/modals.heex` and `reference/tailwind.md#modals`

### Style a Table

See: `examples/tables.heex` and `reference/tailwind.md#tables`

### Create a Layout

See: `examples/layouts.heex` and `reference/tailwind.md#layouts`

## Related Skills

- **phoenix-liveview**: LiveView structure, PubSub, components
- **ash-framework**: Resource operations for data loading
- **testing**: UI testing with Chrome MCP tools
- **live-svelte**: Complex interactive components beyond Tailwind capabilities
  (flow diagrams, drag-and-drop, visualizations)

## Best Practice Conventions

- **Use Tailwind utilities**: Build components with utility classes
- **Define theme colors**: Establish primary, secondary, and status color
  palette
- **Consistent spacing**: Use predefined spacing scale (gap-2, gap-4, p-4, etc.)
- **Responsive design**: Use md:, lg: prefixes for breakpoints
- **Component reuse**: Extract reusable components in `core_components.ex`
- **Dark mode**: Use dark: prefix for dark mode variants

## Example Theme Colors

**Primary Colors:**

- `bg-blue-600 text-white` - Primary actions
- `bg-gray-700 text-white` - Secondary actions
- `bg-blue-500` - Accent/hover states

**Status Colors:**

- `bg-emerald-500 text-white` - Success
- `bg-amber-500 text-white` - Warning
- `bg-red-500 text-white` - Error
- `bg-blue-500 text-white` - Info

**Neutral Colors:**

- `bg-white dark:bg-gray-900` - Base background
- `bg-gray-100 dark:bg-gray-800` - Surface/cards
- `bg-gray-200 dark:bg-gray-700` - Borders, dividers
- `text-gray-900 dark:text-gray-100` - Primary text
- `text-gray-600 dark:text-gray-400` - Secondary text

## Button Patterns

```html
<!-- Primary Button -->
<button
  class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition-colors"
>
  Primary Action
</button>

<!-- Secondary Button -->
<button
  class="px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-900 rounded-lg font-semibold transition-colors dark:bg-gray-700 dark:hover:bg-gray-600 dark:text-gray-100"
>
  Secondary Action
</button>

<!-- Outline Button -->
<button
  class="px-4 py-2 border-2 border-gray-300 hover:border-gray-400 text-gray-700 rounded-lg font-semibold transition-colors dark:border-gray-600 dark:text-gray-300"
>
  Outline Action
</button>
```

## Form Input Patterns

```html
<!-- Text Input -->
<input
  type="text"
  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100"
  placeholder="Enter text..."
/>

<!-- Error State -->
<input
  type="text"
  class="w-full px-3 py-2 border border-red-500 rounded-lg focus:ring-2 focus:ring-red-500 dark:bg-gray-800"
/>
```

## Examples Overview

All examples are self-contained and based on actual project code:

- `buttons.heex` - Button variants, sizes, states, loading states
- `forms.heex` - Inputs, selects, textareas, checkboxes, validation
- `modals.heex` - Dialog patterns with LiveView
- `tables.heex` - Data tables with sorting and actions
- `layouts.heex` - Page structures with sidebar and navbar
- `hooks-patterns.js` - JavaScript hooks (ScrollToBottom, CopyToClipboard, etc.)

## External Resources

- **TailwindCSS Docs**: https://tailwindcss.com/docs
- **Heroicons**: https://heroicons.com (for icon usage)
