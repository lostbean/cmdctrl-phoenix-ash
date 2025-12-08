#!/usr/bin/env bash
# Hook: SessionStart - Load project context on session start
# Outputs context that will be added to the conversation

set -euo pipefail

# Read hook input from stdin (required but not used here)
INPUT=$(cat)

# Detect project info from mix.exs if available
PROJECT_NAME="Elixir/Phoenix/Ash Project"
if [ -f "mix.exs" ]; then
  DETECTED_NAME=$(grep -oP 'app:\s*:\K\w+' mix.exs 2>/dev/null | head -1 || echo "")
  if [ -n "$DETECTED_NAME" ]; then
    PROJECT_NAME="$DETECTED_NAME"
  fi
fi

# Output context that will be injected into the session
cat <<EOF
## Session Context

**Project**: ${PROJECT_NAME}
**Stack**: Phoenix LiveView, Ash Framework, Oban, Reactor

### Quick Links
- Design: DESIGN/Overview.md (if exists)
- Skills: skills/README.md
- Commands: See /help for available commands

### Available Commands
- /implement - Full feature implementation workflow
- /design - Architecture design review
- /co-design - Interactive design refinement
- /fix-issue - Bug investigation and resolution
- /refactor - Quality-driven refactoring
- /review - Code quality review
- /qa - End-to-end testing
- /create-component - Create skills, agents, commands

### Core Principles
- Actor context in all Ash operations
- Multi-tenancy enforcement
- Transaction boundaries for multi-step operations
- 70/20/10 test strategy (unit/integration/E2E)
EOF
