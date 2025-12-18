---
name: manual-qa
description: |
  Execute comprehensive manual QA testing using browser automation and backend
  inspection tools.
---

# Manual QA Testing Skill

Execute comprehensive manual quality assurance testing for web applications
using MCP tools for browser automation (Chrome DevTools) and backend inspection
(Tidewave or similar).

## Purpose

This skill provides generic testing patterns and workflows for validating web
applications through:

- **UI Layer Testing**: Browser automation, visual verification, user
  interaction flows
- **Backend Layer Testing**: Database queries, application state inspection, log
  analysis
- **Integration Testing**: End-to-end workflow validation across all layers

## When to Use This Skill

Use this skill when you need to:

- Test user flows comprehensively from UI to database
- Verify application behavior across multiple layers
- Validate error handling and edge cases
- Execute regression testing after changes
- Create issue reports with detailed evidence

## Core Testing Workflow

### 1. Understand the Flow

Read the flow description to understand:

- Purpose and expected behavior
- Prerequisites and setup requirements
- Test steps and verification points
- Edge cases to validate

### 2. Verify Prerequisites

**Server Management** (Check your project's development guidelines):

- Verify application URL (typically http://localhost:4000)
- Never stop/start server or reset dev DB without asking user
- Test DB resets are typically OK: `MIX_ENV=test mix ecto.reset` or
  `MIX_ENV=test mix ash.reset`

**Before testing, confirm**:

- Database is in correct state (seeded or clean)
- Test data is prepared (embedded in flow description)
- User accounts exist (if needed)

### 3. Execute Test Steps

For each test step:

- Use browser automation for UI interactions
- Take snapshots/screenshots at key points
- Verify expected UI elements and feedback
- Check backend state via database queries
- Review application logs for errors

### 4. Three-Layer Verification

After each significant action, verify across all layers:

**UI Layer:**

- Visual elements display correctly
- User feedback appears (success/error messages)
- Loading states shown appropriately
- No JavaScript console errors

**Backend Layer:**

- Database records created/updated correctly
- Status fields reflect expected state
- No errors in application logs
- Relationships maintained properly

**Integration Layer:**

- Complete workflow functions end-to-end
- State synchronized across layers
- Real-time updates work (if applicable)

### 5. Check Git History Before Reporting Issues

**CRITICAL**: Before creating any issue report, search recent commits:

```bash
git log --oneline --grep="<relevant keywords>" -i -20
git show <commit-hash> --stat
```

This prevents false positives from:

- Bugs that were already fixed
- Stale TODO files
- Old log entries

### 6. Create Issue Reports

When issues are found (after git history check):

1. Use the issue template from `assets/issue-template.md`
2. Include evidence (snapshot excerpts, log entries, database state)
3. Provide reproduction steps
4. Suggest remediation options
5. Assess severity and priority

### 7. Report Back

Provide concise summary:

- Test steps completed
- Issues found (with file paths)
- Edge cases validated
- Recommendations

## Available Tools

This skill requires access to:

### Browser Automation (Chrome DevTools MCP)

- `navigate_page` - Navigate to URLs
- `take_snapshot` - Text-based page inspection
- `take_screenshot` - Visual evidence capture
- `click`, `fill`, `fill_form` - User interactions
- `wait_for` - Wait for elements/text
- `list_console_messages` - Check JavaScript errors
- `emulate_network` - Test network conditions

### Backend Inspection (Tidewave MCP or equivalent)

- `execute_sql_query` - Direct database queries
- `project_eval` - Execute application code
- `get_logs` - View application logs
- `get_docs` - Reference documentation

## Testing Patterns

See `references/testing-patterns.md` for detailed patterns on:

- Happy path testing
- Edge case validation
- Error condition handling
- Cross-feature integration
- Performance observations

## Verification Checklists

See `references/verification-layers.md` for comprehensive checklists for each
layer.

## MCP Tools Reference

See `references/mcp-tools-guide.md` for detailed tool usage examples.

## Multi-File Upload Automation

See `references/multi-file-upload-automation.md` for the pattern to automate
multi-file CSV uploads using the `evaluate_script` MCP tool with DataTransfer
API. This is required when testing features that allow selecting multiple files
at once (vs calling `upload_file` multiple times which replaces the selection).

## Issue Template

See `assets/issue-template.md` for the standardized issue report format.

## Best Practices

### Be Thorough But Efficient

- Focus on the assigned flow
- Don't test unrelated features
- Use embedded test data when provided
- Document findings as you go

### Use Context Wisely

- Take snapshots at key points (not every step)
- Query database for verification (not exploration)
- Check logs for errors (not info messages)
- Create issue reports (don't accumulate findings)

### Communicate Clearly

- Report issues with specific evidence
- Include reproduction steps
- Suggest remediation when possible
- Prioritize findings appropriately

## Common Pitfalls to Avoid

❌ **Don't bypass git history checks** - Always search commits before reporting
issues

❌ **Don't test beyond assigned scope** - Focus on the specific flow assigned

❌ **Don't accumulate findings without reporting** - Create issue files
immediately

❌ **Don't make assumptions** - Verify behavior at all three layers

❌ **Don't skip verification steps** - Complete checks even if UI looks correct

## Example Usage

Given a flow description for user authentication:

1. Read flow file to understand expected behavior
2. Verify prerequisites (clean database, running app)
3. Navigate to application URL
4. Execute registration steps with test data
5. Verify UI feedback (success message, redirect)
6. Check database (user record created)
7. Check logs (no errors)
8. Test edge cases (duplicate email, weak password)
9. Search git history before creating any issue
10. Report findings with evidence

## Success Criteria

A successful test execution includes:

- ✅ All test steps completed
- ✅ All three layers verified
- ✅ Edge cases validated
- ✅ Git history checked for any issues found
- ✅ Issue reports created with evidence
- ✅ Clear summary provided

## Notes

- This skill is generic and can be used for any web application with MCP tool
  access
- Flow descriptions should be self-contained with embedded test data
- **Server management**: See "Verify Prerequisites" section and check your
  project's development guidelines for server management rules
- Prioritize issues by severity: Critical → High → Medium → Low
