# Testing Patterns Reference

## Test Scenario Categories

### 1. Happy Paths

Test primary user journeys with valid inputs and expected conditions:

- **Complete workflows** - From entry point to successful completion
- **Standard operations** - Common use cases with typical data
- **Sequential actions** - Multiple steps building on each other

**Example:**

```
New user signup → upload data → create model → query data
```

**Verification Focus:**

- All steps complete successfully
- UI provides clear feedback at each step
- Backend state consistent with user actions
- No errors in logs or console

### 2. Edge Cases

Test boundary conditions and unusual but valid scenarios:

- **Empty inputs** - Missing optional fields
- **Maximum lengths** - Field limits, large files
- **Minimum values** - Zero quantities, single items
- **Special characters** - Unicode, symbols in text fields
- **Concurrent operations** - Multiple actions simultaneously

**Example:**

```javascript
// Test with empty optional field
fill_form({
  elements: [
    { uid: "name-input", value: "Test User" },
    { uid: "description-input", value: "" }, // Empty optional field
  ],
});
```

**Verification Focus:**

- Application handles edge cases gracefully
- No crashes or undefined behavior
- Appropriate defaults applied
- Clear guidance for required fields

### 3. Error Conditions

Test error handling with invalid inputs and failure scenarios:

- **Invalid credentials** - Wrong passwords, unknown users
- **Missing permissions** - Access without required role
- **Database errors** - Connection failures, constraint violations
- **Network issues** - Timeouts, disconnections
- **Invalid formats** - Malformed data, wrong file types

**Example:**

```javascript
// Test invalid password
fill({ uid: "password-input", value: "wrong_password" });
click({ uid: "submit-button" });
wait_for({ text: "Invalid credentials" });
```

**Verification Focus:**

- Errors caught and handled appropriately
- User-friendly error messages displayed
- No sensitive information leaked
- Recovery path provided (retry, help, support)
- No partial state corruption

### 4. Cross-Feature Integration

Test interactions between different features:

- **Upload → Query** - Use newly uploaded data immediately
- **Edit → View** - Changes reflect in read-only views
- **Role Change → Access** - Permission updates take effect
- **Organization Switch** - Isolation maintained

**Example:**

```
Upload CSV → Create model → Link data → Generate entities → Query with new model
```

**Verification Focus:**

- Features work together seamlessly
- State synchronized across features
- No orphaned data or broken relationships
- Appropriate caching invalidation

## Testing Techniques

### Embedded Test Data

For file uploads, embed test data directly in scripts:

```javascript
evaluate_script({
  function: `() => {
    const fileInput = document.querySelector('input[type="file"]');
    const csvContent = 'id,name,value\\n1,Test,100\\n2,Demo,200';
    const file = new File([csvContent], 'test.csv', { type: 'text/csv' });
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file);
    fileInput.files = dataTransfer.files;
    fileInput.dispatchEvent(new Event('change', { bubbles: true }));
    return { success: true, fileName: file.name };
  }`,
});
```

**Benefits:**

- No manual file selection required
- Consistent test data
- Fully automated testing

### Network Condition Testing

Simulate various network conditions:

```javascript
// Test with slow network
emulate_network({ throttlingOption: "Slow 3G" });
// ... perform action ...
emulate_network({ throttlingOption: "No emulation" });

// Test offline mode
emulate_network({ throttlingOption: "Offline" });
// ... verify error handling ...
emulate_network({ throttlingOption: "No emulation" });
```

**Use Cases:**

- Upload progress indicators
- Timeout handling
- Reconnection logic
- Offline mode behavior

### Concurrent Operation Testing

Test simultaneous actions:

```javascript
// Start first upload
click({ uid: "upload-button-1" });
// Don't wait - immediately start second
await sleep(500);
click({ uid: "upload-button-2" });

// Verify both complete correctly
await sleep(15000);
// Check database for both records
```

**Verification:**

- No race conditions
- No data corruption
- Proper queuing or parallel processing
- Clear UI feedback for both operations

## Verification Patterns

### Snapshot Verification

Take snapshots to verify UI state:

```javascript
// After action
click({ uid: "submit-button" });
wait_for({ text: "Success" });
take_snapshot();
```

**Look for:**

- Expected elements present
- Success/error messages
- Correct data displayed
- No unexpected warnings

### Database Verification

Query database to verify backend state:

```elixir
// Verify record created
tidewave.execute_sql_query({
  query: "SELECT id, status, created_at FROM records WHERE name = $1",
  arguments: ["Test Record"]
})
// Expected: 1 record with status = "active"
```

**Check:**

- Record exists with correct values
- Status fields accurate
- Relationships intact
- No orphaned records

### Log Verification

Check application logs for errors:

```elixir
// Check for errors
tidewave.get_logs({ tail: 20, grep: "error|Error|ERROR" })
// Expected: No errors related to the action

// Verify operation logged
tidewave.get_logs({ tail: 20, grep: "upload|complete" })
// Expected: Operation success message
```

**Focus on:**

- No unexpected errors
- Expected operations logged
- Warning messages appropriate
- No stack traces (unless testing error handling)

### Console Error Checking

Check for JavaScript errors:

```javascript
list_console_messages({ types: ["error", "warn"] });
```

**Expected:**

- No JavaScript errors during normal operation
- Warnings only for expected conditions
- No unhandled promise rejections

## Performance Testing

### Page Load Time

Monitor page load performance:

```javascript
navigate_page({ url: "http://localhost:4000/dashboard" });
wait_for({ text: "Dashboard", timeout: 2000 });
// If timeout exceeded, page load is too slow
```

**Thresholds:**

- < 1s: Excellent
- 1-2s: Good
- 2-3s: Acceptable
- \> 3s: Issue

### Query Response Time

Monitor query execution time:

```javascript
const startTime = Date.now();
fill({ uid: "query-input", value: "Count customers" });
click({ uid: "submit-button" });
wait_for({ text: "Result", timeout: 45000 });
const elapsedTime = Date.now() - startTime;
// Report if > 10s for simple queries
```

**Note in report if:**

- Simple queries take > 5s
- Complex queries take > 30s
- Progress indicators don't appear

### Memory Leaks

Check for memory growth over time:

```javascript
// Monitor memory at start
evaluate_script({ function: "() => performance.memory.usedJSHeapSize" });

// Perform multiple operations
// ... repeat actions 10 times ...

// Check memory again
evaluate_script({ function: "() => performance.memory.usedJSHeapSize" });

// Report if significant growth (>50MB for simple operations)
```

## Common Anti-Patterns to Avoid

### ❌ Don't: Test Features Not in Scope

```javascript
// BAD: Testing authentication when flow is about data upload
navigate_page({ url: "/login" });
fill_form({ ... });
// Not relevant to data upload flow
```

✅ **Instead:** Focus only on the assigned flow

### ❌ Don't: Skip Verification Layers

```javascript
// BAD: Only checking UI
click({ uid: "save-button" });
wait_for({ text: "Saved" });
// Missing database and log checks
```

✅ **Instead:** Verify all three layers (UI, Backend, Integration)

### ❌ Don't: Create Issues Without Git History Check

```javascript
// BAD: Found error in logs, immediately create issue
tidewave.get_logs({ tail: 20, grep: "error" });
// Create issue without checking if already fixed
```

✅ **Instead:** Always search git commits first:

```bash
git log --oneline --grep="error keyword" -i -20
```

### ❌ Don't: Use Excessive Snapshots

```javascript
// BAD: Taking snapshot after every click
click({ uid: "button-1" });
take_snapshot(); // 1
click({ uid: "button-2" });
take_snapshot(); // 2
click({ uid: "button-3" });
take_snapshot(); // 3
```

✅ **Instead:** Take snapshots at meaningful checkpoints

### ❌ Don't: Modify Application During Testing

```javascript
// BAD: Fixing code during QA
// Found bug, let me fix it...
edit_file({ ... });
```

✅ **Instead:** Create issue report and continue testing

## Test Data Management

### Using Seeded Data

When test instructions specify using seeded demo data:

```elixir
// Verify demo data exists
tidewave.execute_sql_query({
  query: "SELECT email FROM users WHERE email = $1",
  arguments: ["admin@example.com"]
})
// Expected: Returns demo admin user
```

### Creating Test Data Programmatically

When test requires new data:

```elixir
tidewave.project_eval({
  code: """
  # Create test record
  {:ok, record} = App.Resource
  |> Ash.Changeset.for_create(:create, %{
    name: "Test Record",
    value: 100
  })
  |> Ash.create(authorize?: false)

  record.id
  """
})
```

### Embedded CSV Data

For file uploads:

```javascript
const csvContent = "id,name,value\\n1,Test,100\\n2,Demo,200";
const file = new File([csvContent], "test.csv", { type: "text/csv" });
// ... upload file ...
```

## Reporting Findings

### Issue Severity Classification

**Critical (P0):**

- Application crashes
- Data loss or corruption
- Security vulnerabilities
- Core functionality completely broken

**High (P1):**

- Major features not working
- Poor error messages blocking users
- Significant UX issues
- Performance problems making app unusable

**Medium (P2):**

- Minor features not working
- Workarounds available
- Cosmetic issues affecting UX
- Edge cases with unclear handling

**Low / Enhancement:**

- Nice-to-have improvements
- Minor cosmetic issues
- Optimization opportunities
- Documentation gaps

### Evidence Collection

For each issue:

1. **Screenshot/Snapshot:** Visual evidence of problem
2. **Database State:** Query results showing incorrect data
3. **Log Entries:** Error messages from current logs
4. **Reproduction Steps:** Exact sequence to reproduce
5. **Git History:** Results of commit search

### Remediation Suggestions

Provide actionable suggestions:

```markdown
### Option 1: Add Validation Check

Add validation in the form component to check for duplicate emails before
submission.

- Pros: Immediate user feedback, prevents unnecessary API calls
- Cons: Additional client-side code
- Files affected: `lib/app_web/live/registration_live.ex`
- Estimated effort: 2 hours
- Risk: Low
```

## Summary

Use these patterns to:

- Test comprehensively across happy paths, edge cases, errors, and integration
- Verify behavior at UI, backend, and integration layers
- Embed test data for full automation
- Check git history before reporting issues
- Classify issues by severity
- Provide evidence and remediation suggestions
