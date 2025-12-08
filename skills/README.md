# Skills Index

Quick reference for all available skills in this project.

## Framework Skills

| Skill                                           | Purpose                       | When to Use                                                            |
| ----------------------------------------------- | ----------------------------- | ---------------------------------------------------------------------- |
| [ash-framework](./ash-framework/SKILL.md)       | Ash Framework patterns        | Working with resources, policies, actions, transactions, multi-tenancy |
| [reactor-oban](./reactor-oban/SKILL.md)         | Reactor workflows & Oban jobs | Multi-step operations, background processing, saga compensation        |
| [phoenix-liveview](./phoenix-liveview/SKILL.md) | Phoenix LiveView real-time UI | Building interactive components, real-time updates, PubSub integration |
| [live-svelte](./live-svelte/SKILL.md)           | LiveSvelte component patterns | Building rich interactive components, visualizations, embedded Svelte  |

## Development Skills

| Skill                                                     | Purpose                       | When to Use                                                     |
| --------------------------------------------------------- | ----------------------------- | --------------------------------------------------------------- |
| [elixir-testing](./elixir-testing/SKILL.md)               | Testing strategies (70/20/10) | Writing/organizing tests, HTTP mocking, async patterns          |
| [ui-design](./ui-design/SKILL.md)                         | TailwindCSS patterns          | Building UI components, layouts, forms, modals                  |
| [doc-hygiene](./doc-hygiene/SKILL.md)                     | Documentation best practices  | Maintaining docs, DRY principles, cross-linking                 |
| [phoenix-observability](./phoenix-observability/SKILL.md) | Phoenix GraphQL observability | Analyzing LLM performance, debugging API calls, querying traces |

## Meta Skills

| Skill                                             | Purpose                         | When to Use                                                                     |
| ------------------------------------------------- | ------------------------------- | ------------------------------------------------------------------------------- |
| [manage-code-agent](./manage-code-agent/SKILL.md) | Managing Claude Code components | Creating/updating skills, agents, commands; ensuring quality and DRY principles |

## QA Skills

| Skill                             | Purpose                     | When to Use                                                |
| --------------------------------- | --------------------------- | ---------------------------------------------------------- |
| [manual-qa](./manual-qa/SKILL.md) | Manual QA testing workflows | End-to-end testing, regression testing, release validation |

## Skill Combinations

Common workflows and which skills to reference together:

### New Feature Implementation

- **Skills**: ash-framework + reactor-oban + elixir-testing
- **Use case**: Implement new domain resource with workflows and comprehensive
  tests
- **Example**: Adding order processing with payment workflows and notifications

### UI Component Development

- **Skills**: phoenix-liveview + ui-design + elixir-testing
- **Use case**: Build interactive LiveView component with TailwindCSS styling
- **Example**: Creating a data dashboard or interactive form

### Refactoring & Code Quality

- **Skills**: ash-framework + elixir-testing + doc-hygiene
- **Use case**: Improve code quality while maintaining tests and documentation
- **Example**: Refactoring complex business logic into smaller, testable
  functions

### Background Processing

- **Skills**: reactor-oban + ash-framework + elixir-testing
- **Use case**: Implement long-running jobs with proper error handling
- **Example**: Batch data processing, report generation, scheduled tasks

### Real-time Features

- **Skills**: phoenix-liveview + ash-framework + elixir-testing
- **Use case**: Build real-time collaborative features
- **Example**: Live notifications, chat features, collaborative editing

### Interactive Visualizations

- **Skills**: live-svelte + phoenix-liveview + ui-design
- **Use case**: Build complex interactive visualizations with Svelte embedded in
  LiveView
- **Example**: Interactive charts, flow diagrams, drag-and-drop editors

### Creating Claude Code Components

- **Skills**: manage-code-agent + doc-hygiene
- **Use case**: Create/update skills, agents, or commands following best
  practices
- **Example**: Creating a new framework skill or specialized subagent

### LLM Application Debugging & Observability

- **Skills**: phoenix-observability + elixir-testing
- **Use case**: Debug LLM application failures, analyze performance, investigate
  errors
- **Example**: Investigating slow LLM responses, high token usage, or API
  failures

## Quick Start

### For Framework Patterns

1. Start with the SKILL.md file for high-level overview
2. Review reference/\*.md files for deep dives on specific topics
3. Check examples/ directory for self-contained, runnable code
4. Cross-reference with DESIGN/ docs for application-specific usage

### For Testing

1. Understand the 70/20/10 strategy from
   [elixir-testing](./elixir-testing/SKILL.md)
2. Review test examples for patterns
3. Use cassette testing for LLM/HTTP interactions
4. Leverage MCP tools for E2E testing

### For Documentation

1. Follow [doc-hygiene](./doc-hygiene/SKILL.md) principles
2. Maintain single source of truth
3. Use progressive disclosure (overview → deep dive)
4. Add extensive cross-linking

### For Observability

1. Start with [phoenix-observability](./phoenix-observability/SKILL.md) for
   setup
2. Use basic queries to explore traces and spans
3. Analyze agent performance and LLM costs
4. Debug errors with full trace context
5. Combine with Tidewave MCP for logs and database inspection

## Skill Structure

All skills follow this consistent structure:

```
skill-name/
├── SKILL.md              # Main entry point with YAML frontmatter
├── examples/             # Self-contained, runnable code examples
│   ├── pattern-1.ex
│   ├── pattern-2.ex
│   └── ...
└── reference/            # Deep dive documentation
    ├── topic-1.md
    ├── topic-2.md
    └── ...
```

### YAML Frontmatter Format

```yaml
---
name: skill-name
description: |
  What this skill covers and when to use it.
  Include both the "what" and "when" in the description.
allowed-tools: Read, Write, Bash, Grep, Glob
---
```

## Progressive Disclosure Pattern

Skills use progressive disclosure to optimize for token efficiency and learning:

1. **SKILL.md** - High-level overview, quick start, navigation
2. **reference/\*.md** - Detailed topic guides with extensive examples
3. **examples/\*.ex** - Self-contained, runnable code
4. **Cross-links** - Navigate between related concepts

## Finding Information

- **Framework patterns**: Check `.claude/skills/{framework}/SKILL.md`
- **Code examples**: See `.claude/skills/{framework}/examples/`
- **Deep dives**: Read `.claude/skills/{framework}/reference/*.md`
- **App design**: Read `DESIGN/` documentation
- **Workflows**: See `DESIGN/workflows/`
- **Real code**: Browse `lib/`, `test/` directories

## Contributing to Skills

When updating skills:

1. **Keep DRY**: Each pattern documented once, referenced everywhere
2. **Use examples**: Show both ✅ correct and ❌ incorrect usage
3. **Cross-link**: Link to related skills, DESIGN/ docs, and external resources
4. **Be specific**: Base examples on real project code, not invented patterns
5. **Test completeness**: Ensure examples are self-contained and runnable
6. **Update together**: Keep SKILL.md, reference/, and examples/ in sync

## External Resources

- [Ash Framework Documentation](https://hexdocs.pm/ash/)
- [Phoenix LiveView Guides](https://hexdocs.pm/phoenix_live_view/)
- [Oban Documentation](https://hexdocs.pm/oban/)
- [TailwindCSS Utilities](https://tailwindcss.com/docs)
- [ExUnit Documentation](https://hexdocs.pm/ex_unit/)
- [ReqCassette for Testing](https://hexdocs.pm/req_cassette/)
- [Arize Phoenix Documentation](https://docs.arize.com/phoenix)
- [OpenTelemetry Elixir](https://opentelemetry.io/docs/languages/erlang/)

## Need Help?

1. Start with the relevant SKILL.md file
2. Check examples/ for code patterns
3. Read reference/\*.md for deep understanding
4. Cross-reference DESIGN/ for application context
5. Review actual code in lib/ and test/ directories
