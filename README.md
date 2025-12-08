# Elixir/Phoenix/Ash Toolkit - Claude Code Plugin

A comprehensive Claude Code plugin for Elixir/Phoenix/Ash development with
specialized agents, skills, and orchestrated workflows.

## Overview

This plugin provides a complete development toolkit optimized for the
Elixir/Phoenix/Ash stack:

- **6 Specialized Agents**: Architect, Implementer, Code Reviewer, Debugger,
  Explorer, QA Tester
- **8 Workflow Commands**: `/implement`, `/design`, `/co-design`, `/fix-issue`,
  `/refactor`, `/review`, `/qa`, `/create-component`
- **10 Framework Skills**: Ash Framework, Reactor/Oban, Phoenix LiveView, UI
  Design, Testing, and more
- **MCP Integration**: Tidewave (backend inspection) and Chrome DevTools
  (browser automation)

## Installation

Install the plugin using Claude Code:

```bash
claude plugin install lostbean/cmdctrl-phoenix-ash
```

Or add to your project's `.claude/settings.json`:

```json
{
  "plugins": ["lostbean/cmdctrl-phoenix-ash"]
}
```

## Quick Start

### For Feature Implementation

```bash
/implement Add user authentication with email verification
```

**Workflow**: architect → implementer → code-reviewer → qa-tester

The architect presents 3-5 solution options sorted by quality. You select one,
and the workflow continues automatically.

### For Bug Fixes

```bash
/fix-issue
```

**Workflow**: debugger → architect → implementer → code-reviewer → qa-tester

Select an issue file from `IMPLEMENTATION/TODOs/`, and the workflow
investigates, proposes solutions, implements, reviews, and tests the fix.

### For Code Review

```bash
/review lib/my_app/accounts/user.ex
```

Get a structured report with critical issues, suggestions, and positive
observations.

### For Collaborative Design

```bash
/co-design Add webhook support for external notifications
```

**Workflow**: explorer → architect (interactive) → specification creation

Interactive design refinement with context gathering and Q&A.

### For QA Testing

```bash
/qa Test user registration and email verification flow
```

Comprehensive E2E testing with browser automation and backend inspection.

## Architecture

### 4-Layer Composable System

```
Layer 1: Skills (Foundation)
    └── Reusable framework knowledge (Ash, Phoenix, Reactor, etc.)

Layer 2: Agents (Specialized Workers)
    └── Autonomous actors that reference skills

Layer 3: Commands (User Workflows)
    └── Orchestrate agents for complete workflows

Layer 4: DESIGN/ (Your Application)
    └── Application-specific design that links to skills
```

### Design Principles

1. **Single Source of Truth (DRY)**: Each concept documented once, referenced
   everywhere
2. **Progressive Disclosure**: High-level info first, deep details on demand
3. **Human in the Loop**: Present multiple options, user decides
4. **Simplicity (KISS)**: Prefer simple over clever

## Commands Reference

| Command             | Purpose                         | Workflow                                                       |
| ------------------- | ------------------------------- | -------------------------------------------------------------- |
| `/implement`        | Complete feature implementation | architect → implementer → code-reviewer → qa-tester            |
| `/design`           | Architecture design review      | architect                                                      |
| `/co-design`        | Interactive design refinement   | explorer → architect → specification                           |
| `/fix-issue`        | Bug investigation and fix       | debugger → architect → implementer → code-reviewer → qa-tester |
| `/refactor`         | Quality-driven refactoring      | architect → implementer → code-reviewer → qa-tester            |
| `/review`           | Code quality review             | code-reviewer                                                  |
| `/qa`               | End-to-end testing              | qa-tester                                                      |
| `/create-component` | Create skills/agents/commands   | guided creation                                                |

## Skills Reference

### Framework Skills

| Skill              | Use Case                                                  |
| ------------------ | --------------------------------------------------------- |
| `ash-framework`    | Resources, policies, actions, transactions, multi-tenancy |
| `reactor-oban`     | Workflows, background jobs, saga compensation             |
| `phoenix-liveview` | Real-time UI, components, PubSub                          |
| `live-svelte`      | Svelte components in LiveView                             |

### Development Skills

| Skill                   | Use Case                                                 |
| ----------------------- | -------------------------------------------------------- |
| `elixir-testing`        | Testing strategies (70/20/10), cassettes, async patterns |
| `ui-design`             | TailwindCSS, component patterns                          |
| `doc-hygiene`           | Documentation best practices, DRY principles             |
| `phoenix-observability` | LLM monitoring, trace analysis                           |

### Meta Skills

| Skill               | Use Case                                   |
| ------------------- | ------------------------------------------ |
| `manage-code-agent` | Creating/updating skills, agents, commands |
| `manual-qa`         | Manual QA testing workflows                |

## Agents Reference

| Agent           | Purpose                                    | Model  |
| --------------- | ------------------------------------------ | ------ |
| `architect`     | Design options generation, quality scoring | Sonnet |
| `implementer`   | Production code generation, testing        | Sonnet |
| `code-reviewer` | Code quality validation                    | Sonnet |
| `debugger`      | Issue investigation, root cause analysis   | Sonnet |
| `explorer`      | Codebase context gathering                 | Haiku  |
| `qa-tester`     | E2E testing via MCP tools                  | Haiku  |

## MCP Tools Integration

### Tidewave (Backend Inspection)

Requires Phoenix server running with Tidewave enabled:

- `execute_sql_query` - Database inspection
- `project_eval` - Elixir code evaluation
- `get_logs` - Application logs
- `get_docs` - Module documentation
- `get_source_location` - Find code locations

### Chrome DevTools (UI Testing)

Requires Chrome with debugging port enabled:

- `take_snapshot` - Page content capture
- `click`, `fill`, `fill_form` - UI interactions
- `navigate_page` - Navigation
- `list_console_messages` - JavaScript errors

## Project Structure Expectations

The plugin works best with this recommended structure:

```
your_project/
├── DESIGN/              # Application design docs
│   ├── Overview.md
│   ├── concepts/
│   ├── resources/
│   ├── workflows/
│   └── user_stories/    # E2E test specifications
│
├── IMPLEMENTATION/
│   └── TODOs/           # Issue tracking files
│
├── lib/
│   ├── my_app/          # Domain logic
│   └── my_app_web/      # Web layer
│
├── test/                # Test suites
│
└── CLAUDE.md            # Project-specific conventions
```

## Server Management Rules

**Critical**: When using MCP tools, the Phoenix server must remain running:

- ✅ Server stays running at localhost:4000
- ✅ Phoenix hot-reloads code automatically
- ❌ NEVER restart server or reset dev DB during session
- ✅ Test database resets are safe: `MIX_ENV=test mix ecto.reset`

See `references/dev-app-management.md` for complete guidelines.

## Quality Criteria

The architect scores solutions against these criteria (10 points total):

- **Design Alignment** (2 pts): Fits existing architecture
- **Best Practices** (2 pts): Follows Ash/Phoenix/Elixir idioms
- **Maintainability** (2 pts): KISS, DRY, clear separation
- **Security** (2 pts): Actor context, multi-tenancy, authorization
- **Test Coverage** (1 pt): Unit, integration, E2E tests
- **Sustainability** (1 pt): Scales, extensible, minimal debt

## Customization

### Adding Project-Specific Context

Create a `CLAUDE.md` file in your project root with:

- Core architecture patterns
- Domain-specific conventions
- Important constraints
- Key dependencies

### Adding Custom Skills

```bash
/create-component skill my-framework "Custom framework patterns"
```

### Adding Custom Commands

```bash
/create-component command deploy "Deployment workflow"
```

## Best Practices

### When Writing Code

1. **Always** provide actor context in Ash operations
2. **Always** use transactions for multi-step operations
3. **Always** write tests (70% unit, 20% integration, 10% E2E)
4. **Always** update DESIGN/ docs in same commit

### When Refactoring

1. Run `/review` to understand current state
2. Run `/design` to explore options
3. Run `/refactor` to execute
4. Verify with regression tests

## Contributing

Contributions welcome! Please:

1. Keep DRY principles
2. Add examples for new patterns
3. Cross-link related content
4. Test with real projects

## License

MIT License - See LICENSE file for details.

## Author

Edgar Gomes de Araujo

## Acknowledgments

Based on patterns developed for production Elixir/Phoenix/Ash applications.
