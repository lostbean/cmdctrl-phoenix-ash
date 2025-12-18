---
description: End-to-end testing using browser automation and backend inspection
argument-hint: "[test flow description]"
---

# QA Command

End-to-end testing using browser automation and backend inspection.

## Overview

This command analyzes your testing request and spawns the appropriate number of
qa-tester agents to execute comprehensive testing.

## Usage

```bash
/qa                                                    # Interactive selection
/qa Test authentication and registration              # Natural language
/qa Verify dashboard with large datasets              # Natural language
/qa Reproduce upload progress stuck at 99%            # Bug reproduction
```

## How It Works

**Test Request**: $ARGUMENTS

### When No Arguments Provided (Interactive Mode)

Discover and select user stories interactively:

**1. Discover user stories** using simple bash tools:

```bash
# Find all user story files
ls DESIGN/user_stories/*.json | grep -v summary.json | sort
```

**2. Parse story details** with jq:

```bash
# Extract epic name and description
for file in $(ls DESIGN/user_stories/*.json | grep -v summary.json); do
  jq -r '.epic' "$file"
  jq -r '.description' "$file"
done
```

**3. Show interactive menu** using AskUserQuestion:

- First option: "All user stories" (runs all 8 stories sequentially)
- Then each story: "{epic}: {description}"

**4. Execute selected stories** with qa-tester agents sequentially

### When Arguments Provided (Natural Language Mode)

Map natural language to user stories using keyword matching:

```bash
# Find matching stories by keyword in file content
grep -i "authentication" DESIGN/user_stories/*.json -l | grep -v summary.json

# Or match by epic name with jq
for file in $(ls DESIGN/user_stories/*.json | grep -v summary.json); do
  jq -r '.epic' "$file" | grep -iq "$KEYWORD" && echo "$file"
done
```

**Keyword mappings**:

Map keywords from the user's natural language request to your project's user
story files. Keywords should match the epic names and feature descriptions in
your user story JSON files.

### Testing Process

For each selected user story:

- qa-tester agents use Chrome DevTools MCP for browser automation
- qa-tester agents use Tidewave MCP for backend inspection
- Tests validate UI, backend, and integration layers
- **qa-tester agents report findings** (not create issue files directly)
- **Orchestrator reviews findings and creates issue files** in
  `IMPLEMENTATION/TODOs/qa-issue-*.md`
- **Orchestrator creates final report** in
  `IMPLEMENTATION/QA-REPORTS/qa-report-{date}-{N}.md`

The number of agents spawned depends on the scope - comprehensive testing uses
multiple agents for better context efficiency, while targeted requests use a
single agent.

**IMPORTANT**: Agents run in **SEQUENCE** (not parallel) to avoid race
conditions when sharing the Chrome MCP browser instance. Each agent gets fresh
context but waits for the previous agent to complete before starting.

### Orchestrator Responsibilities

The `/qa` command orchestrator handles coordination and file creation:

**Before Testing:**

1. Parse user request (interactive menu or natural language)
2. Map request to user stories
3. Create todo list for tracking progress
4. Spawn qa-tester agents sequentially

**During Testing:** 5. Monitor agent progress via completion messages 6. Track
issues reported by each agent 7. Ensure agents run sequentially (not in
parallel)

**After Testing:** 8. **Review all agent findings** from completion messages 9.
**Create issue files** in `IMPLEMENTATION/TODOs/` for confirmed bugs:

- Parse agent reports for failures
- Check for duplicate issues before creating
- Add source reference: `Source: qa-report-{date}-{N}.md (US-XXX Test Y.Z)`
- Include reproduction steps, evidence, git context

10. **Create final QA report** in `IMPLEMENTATION/QA-REPORTS/`:
    - Aggregate all findings from agents
    - List all issue files created
    - Provide summary and recommendations
11. Present summary to user with issue counts and report location

**Key principle**: qa-tester agents focus on TESTING and REPORTING. The
orchestrator handles FILE CREATION and AGGREGATION.

## Why Sequential Execution?

**Problem**: Race conditions when multiple agents share the Chrome MCP browser

When multiple agents try to control the same browser instance simultaneously:

- Navigation conflicts (Agent A navigates while Agent B clicks)
- Element selection errors (page state changes between agents)
- Form submission race conditions
- Unpredictable test results

**Solution**: Run agents sequentially

Benefits:

- ✅ Each agent has exclusive browser control
- ✅ Fresh context prevents token bloat
- ✅ Predictable, reproducible test results
- ✅ Clear progress tracking via TodoWrite
- ⚠️ Trade-off: Slower total execution (but more reliable)

## Examples

### Example 1: Interactive Selection (No Arguments)

```bash
/qa
```

**What happens:**

1. Command discovers user stories from `DESIGN/user_stories/` using `ls` and
   `jq`
2. Shows interactive menu via AskUserQuestion:

   ```
   Which user stories would you like to test?

   ○ All user stories ({N} stories, estimated time)
   ○ {Epic 1}: {Description}
   ○ {Epic 2}: {Description}
   ○ {Epic 3}: {Description}
   (Stories discovered dynamically from DESIGN/user_stories/)
   ```

3. User selects one or more stories
4. Spawns qa-tester agents sequentially (one per story)
5. Aggregates findings and creates final report

**You see:**

- Interactive selection menu
- Todo list tracking progress through selected stories
- Each agent runs sequentially
- Final aggregated report in IMPLEMENTATION/QA-REPORTS/

### Example 2: Natural Language Selection

```bash
/qa Test authentication and registration
```

**What happens:**

1. Command matches keywords ("authentication", "registration") to user stories
2. Finds matching user story file based on epic name
3. Spawns qa-tester agent with test cases from the user story
4. Agent executes all acceptance criteria from the JSON specification
5. Reports findings

**You see:**

- Direct execution (no menu)
- Single user story tested
- Issue files if problems found

### Example 3: Test Scenario

```bash
/qa Verify dashboard handles 1000+ row results
```

**What happens:**

1. Orchestrator spawns single test agent
2. Agent creates large dataset and tests performance
3. Agent reports findings to orchestrator
4. Orchestrator presents performance analysis

### Example 4: Reproduce Bug

```bash
/qa Reproduce upload progress stuck at 99%
```

**What happens:**

1. Orchestrator spawns single test agent
2. Agent attempts to reproduce the bug
3. Agent reports whether bug exists or is fixed
4. Issue file created if bug still exists

## Testing Layers

The qa-tester validates at three layers:

### 1. UI Layer

- Elements render correctly
- User interactions work
- Error messages displayed
- Loading states show
- Responsive design works

### 2. Backend Layer

- Database records created
- Actor context enforced
- Multi-tenancy isolated
- Transactions atomic
- Logs show no errors

### 3. Integration Layer

- End-to-end flow completes
- PubSub updates work
- Background jobs execute
- External integrations work
- Edge cases handled

## Prerequisites

### Application Running

**See**: `../references/dev-app-management.md` for complete rules.

- If Tidewave MCP available, app is at http://localhost:4000
- Never stop/start server or reset dev DB - ask user
- Test DB resets OK: `MIX_ENV=test mix db.reset`

### Database State

**For All Flows:**

```bash
mix ash.reset
# Do NOT seed - Flow 1 needs clean DB
# Will seed after Flow 1
```

**For Specific Flows (2-7):**

```bash
mix ash.reset
mix run priv/repo/seeds.exs
```

## File Conventions

### Issue Files

**The orchestrator** (main /qa command handler) creates issue files in
`IMPLEMENTATION/TODOs/`:

```
IMPLEMENTATION/TODOs/qa-issue-{NNN}-{brief-description}.md
```

**Process:**

1. **qa-tester agents** report findings in their completion messages
2. **Orchestrator** reviews all agent reports
3. **Orchestrator creates issue files** for confirmed bugs
4. Issue files reference the source report:
   `Source: qa-report-2025-11-17-1.md (US-007 Test 3.2)`

**Naming Rules:**

- Use **zero-padded** three-digit numbers: 001, 002, 003, etc.
- Brief description uses kebab-case
- Check for duplicates before creating new issues

**Examples:**

- `IMPLEMENTATION/TODOs/qa-issue-001-duplicate-email-not-validated.md`
- `IMPLEMENTATION/TODOs/qa-issue-002-empty-model-banner-incorrect.md`
- `IMPLEMENTATION/TODOs/qa-issue-003-invalid-credentials-persist.md`

Issues include full reproduction steps, evidence (snapshots, logs), git commit
context, and source reference.

### QA Reports

**The orchestrator** (main /qa command handler) creates final reports in
`IMPLEMENTATION/QA-REPORTS/`:

```
IMPLEMENTATION/QA-REPORTS/qa-report-{date}-{N}.md
```

**Creation Rules:**

- Only created AFTER all testing is complete
- Orchestrator aggregates findings from all qa-tester agents
- NOT created by qa-tester agents directly
- Numbered sequentially per day: -1, -2, -3, etc.

**Examples:**

- `IMPLEMENTATION/QA-REPORTS/qa-report-2025-11-17-1.md`
- `IMPLEMENTATION/QA-REPORTS/qa-report-2025-11-17-2.md`
- `IMPLEMENTATION/QA-REPORTS/qa-report-2025-11-18-1.md`

**Report Contents:**

- Test coverage summary
- All issues found with references
- Evidence and git context
- Recommendations for improvements

## Troubleshooting

### Cannot Navigate to Page

**Problem**: QA tester cannot access URL

**Solution**:

1. Use Tidewave MCP - if it works, app is at http://localhost:4000
2. Use Tidewave tools: `get_logs`, `execute_sql_query`, `project_eval`
3. If server not running or needs restart - ask user
4. If dev DB needs reset - ask user

### Test Credentials Don't Work

**Problem**: Cannot log in with demo credentials

**Solution**:

1. Verify database was seeded
2. Check credentials are correct (based on your seed file)
3. Re-seed if needed: `mix run priv/repo/seeds.exs`

### Database State Incorrect

**Problem**: Tests expect data that doesn't exist

**Solution**:

1. Use Tidewave MCP `execute_sql_query` to check DB state
2. Verify expected data for flow: Clean DB (Flow 1) or Seeded (Flows 2-7)
3. If dev DB needs reset - ask user to stop server, run `mix db.reset`, restart
4. Never reset dev DB yourself

### Browser Automation Fails

**Problem**: Chrome DevTools commands timeout or fail

**Solution**:

1. Check if page finished loading
2. Wait for elements to appear
3. Check console for JavaScript errors
4. Take screenshot to debug visually

### False Positive Issues

**Problem**: QA tester creates issue for expected behavior

**Solution**:

1. Read issue file carefully
2. If expected behavior, delete issue file
3. Provide feedback to improve test expectations

## Integration with Other Commands

**QA → Fix Flow:**

```bash
/qa
# Issues found and files created
/fix-issue
# Fix each issue systematically
```

**Implement → QA Flow:**

```bash
/implement Add email verification
/qa Test user registration and email verification
# Validate new feature works
```

**Refactor → QA Flow:**

```bash
/refactor lib/your_app_web/live/dashboard_live.ex
/qa Test dashboard flow
# Ensure refactoring didn't break functionality
```

## Best Practices

### Test Early and Often

**Good:**

```bash
# After each feature
/implement Add webhook support
/qa Test webhook flow
```

**Too Late:**

```bash
# After 10 features
/qa
# Now have 50 issues to fix
```

### Test Specific Flows

**Good:**

```bash
/qa Test dashboard with empty results
```

**Too Broad:**

```bash
/qa Test everything
```

### Reproduce Before Fixing

**Good:**

```bash
/qa Reproduce upload progress issue
# Confirm issue exists
/fix-issue
```

**Premature:**

```bash
# Fix issue without confirming it exists
/fix-issue
```

### Test After Fixing

**Good:**

```bash
/fix-issue
# Fix applied
/qa Test the fixed flow
# Validate fix works
```

**Missing:**

```bash
/fix-issue
# Fix applied but never validated
```

## Success Criteria

QA testing succeeds when:

- ✅ All flows tested completely
- ✅ UI, backend, and integration validated
- ✅ Edge cases checked
- ✅ Issues documented with evidence
- ✅ Git history checked before creating issues
- ✅ Comprehensive report provided

## Test Users (Seeded Database)

After running seeds, test users are available based on your project's seed file
(e.g., admin, editor, viewer roles with configured credentials).

## Tools Used

**Chrome DevTools MCP**: Browser automation

- Navigate pages
- Fill forms
- Click elements
- Take snapshots/screenshots
- Check console errors
- Inspect network requests

**Tidewave MCP**: Backend inspection

- Execute Elixir code
- Run SQL queries
- Check logs
- Inspect database state
- Verify background jobs

**phoenix-observability skill**: Agent and LLM observability

- Query agent execution traces
- Analyze LLM performance metrics
- Debug tool call sequences
- Investigate agent failures
- Monitor token usage and costs

## Test Automation Patterns

**Multi-File Upload Automation**: When testing features that allow uploading
multiple CSV files at once (like data source creation with multiple tables), use
the `evaluate_script` MCP tool with the DataTransfer API instead of calling
`upload_file` multiple times.

See the `manual-qa` skill reference:
`.claude/skills/manual-qa/references/multi-file-upload-automation.md`

This guide provides:

- Complete working example with DataTransfer API
- Step-by-step instructions for qa-tester agents
- Phoenix LiveView event handling considerations
- Troubleshooting tips for common issues

**Why not use upload_file repeatedly?** The `upload_file` tool only supports one
file at a time. Calling it multiple times replaces the previous selection
instead of appending files, which breaks multi-file upload testing.

## Remember

> **Test thoroughly. Document clearly. Validate completely.**

Good QA catches issues before users do. Test early, test often, test
comprehensively.

**Find bugs early. Document completely. Prevent regressions.**
