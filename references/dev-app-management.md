# Development Application & Server Management

**Critical reference for managing the Phoenix development server and database
during Claude Code sessions.**

## Core Directives

### 1. Server Must Remain Running

✅ **Assume server is already running** at http://localhost:4000

The Phoenix development server should be started once at the beginning of your
session and **never restarted** during development or testing.

**Why**: Tidewave MCP connects to the running Phoenix server process. Restarting
breaks this connection and requires restarting Claude Code entirely.

### 2. Never Restart the Development Server

❌ **NEVER restart the server** during your session

**This breaks**:

- Tidewave MCP connection (all backend inspection tools)
- Active debugging sessions
- Requires full Claude Code restart to recover

**Phoenix hot-reloads automatically** - no restart needed for most changes.

### 3. Phoenix Hot-Reload Handles Most Changes

✅ **Code changes apply automatically** without restart

Phoenix LiveView hot-reloads:

- Code changes in `lib/` directories
- Template changes in `.heex` files
- CSS/JavaScript asset changes
- LiveView component updates
- Function definitions (on next invocation)

### 4. Ask User for Operations Requiring Restart

🤝 **If restart IS needed** - Ask user to do it and wait for confirmation

**Never perform these yourself**:

- Restarting the Phoenix server
- Resetting the development database
- Stopping/starting the application

### 5. Development vs Test Databases

**CRITICAL DISTINCTION**:

**Development Database** (applies to restrictions):

- Running at dev server (localhost:4000)
- Connected to Tidewave MCP
- **NEVER stop/start server or reset DB yourself** - ask user
- Ask user: "Please stop server, run `mix db.reset`, restart server"

**Test Database** (no restrictions):

- Used by test suite (`MIX_ENV=test`)
- **Free to reset**: `MIX_ENV=test mix db.reset`
- Tests manage their own database state
- No impact on dev server or MCP connection

## MCP Connection Architecture

```
Claude Code
    ├─→ Chrome DevTools MCP (browser port 9222)
    │   - UI testing and inspection
    │   - Independent of Phoenix server
    │
    └─→ Tidewave MCP ───→ Phoenix Server (localhost:4000/tidewave/mcp)
        - Backend inspection and evaluation
        - DEPENDS on running Phoenix server
        - Breaks if server restarts
```

**Key point**: Tidewave MCP is **stateful** and **persistent**. It maintains a
connection to the running Phoenix server process. Restarting Phoenix breaks this
connection.

## What Hot-Reload Handles

### Automatic (No Restart Needed)

✅ Code changes in `lib/**/*.ex` files ✅ Template changes in `lib/**/*.heex`
files ✅ CSS changes in `assets/css/` ✅ JavaScript changes in `assets/js/` ✅
LiveView component updates ✅ Function and module changes (applied on next call)
✅ Route changes in `router.ex` ✅ Most configuration changes

### When to Ask User for Restart (Rare)

🤝 **Database schema migrations** requiring application restart 🤝 **Environment
variable changes** in `.env` files 🤝 **Configuration changes** in
`config/runtime.exs` 🤝 **Dependency changes** requiring recompilation

**Example request for migration**:

```
I need to apply a database migration that requires restarting the Phoenix server. Please:
1. Stop the server (Ctrl+C twice in the iex terminal)
2. Run the appropriate migration command for your database
3. Restart with `iex -S mix phx.server`
4. Confirm when ready
```

### When to Ask User for Database Reset

🤝 **Development database reset** requires stopping the app

**Example request**:

```
I need to reset the development database. Please:
1. Stop the server (Ctrl+C twice)
2. Run `mix db.reset`
3. Restart with `iex -S mix phx.server`
4. Confirm when ready
```

**Test database reset** (no need to ask):

```bash
# This is safe to run yourself - doesn't affect dev server
MIX_ENV=test mix db.reset
```

## Using Tidewave MCP as Server Status Proxy

**If Tidewave MCP is available, so is the app! Go and use it at
http://localhost:4000**

Tidewave MCP runs on the same Phoenix server - if you can call Tidewave tools,
the app is running and ready.

### Checking Server Status

Use Tidewave tools to verify the application is available:

**Check logs**:

```elixir
mcp__tidewave__get_logs(tail: 50)
```

**Verify database connectivity**:

```elixir
mcp__tidewave__execute_sql_query("SELECT 1")
```

**Test application functions**:

```elixir
mcp__tidewave__project_eval("Application.started_applications()")
```

**If MCP tools fail**: The server may not be running - ask the user to check.

## MCP Tools Available

### Tidewave (Backend Inspection)

Connected via: http://localhost:4000/tidewave/mcp

**Tools**:

- `project_eval` - Run Elixir code in project context
- `execute_sql_query` - Query database directly
- `get_docs` - Get module/function documentation
- `get_source_location` - Find source file for module/function
- `get_logs` - View application logs
- `get_ecto_schemas` - List all Ecto schemas
- `search_package_docs` - Search dependency documentation

### Chrome DevTools (UI Testing)

Connected via: Browser debugging port 9222

**Tools**:

- `take_snapshot` - Text-based page snapshot (prefer over screenshot)
- `take_screenshot` - Visual screenshot
- `click`, `fill`, `fill_form` - UI interactions
- `navigate_page` - Page navigation
- `list_console_messages` - Check JS errors
- `list_network_requests` - Check network activity

## Workflow Examples

### Example 1: Implementing a Feature

```elixir
# 1. Make code change in your application's user module
# 2. Hot-reload applies automatically (no restart)
# 3. Test immediately with Tidewave:
mcp__tidewave__project_eval("MyApp.Accounts.User.list!()")
# 4. Changes work - no restart needed!
```

### Example 2: Testing UI Changes

```
# 1. Modify LiveView component in your application's LiveView module
# 2. Save file - hot-reload applies
# 3. Use Chrome MCP to test:
mcp__chrome-devtools__navigate_page(url: "http://localhost:4000/dashboard")
mcp__chrome-devtools__take_snapshot()
# 4. UI updated - no restart needed!
```

### Example 3: Debugging an Issue

```elixir
# 1. Reproduce issue using Chrome MCP (UI) or Tidewave (backend)
# 2. Check logs:
mcp__tidewave__get_logs(grep: "Error", tail: 100)
# 3. Make fix in code
# 4. Hot-reload applies automatically
# 5. Re-test immediately - no restart!
```

### Example 4: Running Tests (Test Database)

```bash
# Test database operations are safe - no restrictions
MIX_ENV=test mix db.reset  # Safe to run
MIX_ENV=test mix test      # Tests manage their own DB
```

## Recovery from Accidental Restart

**If you accidentally restart the Phoenix server**:

1. Tidewave MCP connection is lost
2. All MCP backend tools stop working
3. **User must restart Claude Code** to re-establish connection

**Prevention is key**: Just don't restart the server during your session.

## Quick Reference Card

| Operation        | Dev Database                                                       | Test Database                                    |
| ---------------- | ------------------------------------------------------------------ | ------------------------------------------------ |
| Reset database   | ❌ Ask user                                                        | ✅ Safe: `MIX_ENV=test mix db.reset`             |
| Restart server   | ❌ Ask user                                                        | ✅ N/A (tests don't run server)                  |
| Run migrations   | ❌ Ask user (if restart needed)                                    | ✅ Safe: `MIX_ENV=test mix ash_postgres.migrate` |
| Code changes     | ✅ Hot-reload automatic                                            | ✅ Recompiled on test run                        |
| Check if running | ✅ Use Tidewave MCP - if it works, app is at http://localhost:4000 | ✅ N/A                                           |

## Summary

**Golden Rules**:

1. **Never stop/start or reset the DB in local dev env** - ask the user
2. **If Tidewave MCP is available, so is the app!** Use it at
   http://localhost:4000
3. Hot-reload handles most changes automatically
4. Dev database = ask user, Test database (`MIX_ENV=test mix db.reset`) = do it
   yourself
5. If restart truly needed, ask user and wait for confirmation
