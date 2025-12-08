# MCP Tools Reference Guide

Quick reference for common MCP tools used in manual QA testing.

---

## Chrome DevTools MCP

Browser automation and UI testing tools.

### Navigation

```javascript
// Navigate to URL
navigate_page({
  url: "http://localhost:4000/path",
  timeout: 10000, // optional, default 30s
});

// Navigate browser history
navigate_page({ type: "back" });
navigate_page({ type: "forward" });

// Reload page
navigate_page({ type: "reload" });
navigate_page({ type: "reload", ignoreCache: true });

// Wait for specific text/element
wait_for({
  text: "Loading complete",
  timeout: 5000, // optional, default 30s
});
```

### Page Inspection

```javascript
// Take text-based snapshot (preferred for verification)
take_snapshot();

// Take visual screenshot (for evidence)
take_screenshot({
  filePath: "./test-evidence/step-1.png", // optional
});

// Full page screenshot
take_snapshot({ fullPage: true });

// Screenshot specific element
take_screenshot({
  uid: "element-id",
  filePath: "./evidence/widget.png",
});

// List open browser tabs
list_pages();

// Switch to different tab
select_page({ pageIdx: 0 });

// Open new tab
new_page({ url: "http://localhost:4000/page" });

// Close tab
close_page({ pageIdx: 1 });
```

### User Interactions

```javascript
// Click element
click({ uid: "button-id" });

// Double-click element
click({ uid: "element-id", dblClick: true });

// Hover over element
hover({ uid: "element-id" });

// Fill single input
fill({
  uid: "input-id",
  value: "text to enter",
});

// Fill multiple inputs (form)
fill_form({
  elements: [
    { uid: "email-input", value: "user@example.com" },
    { uid: "password-input", value: "password123" },
    { uid: "name-input", value: "Test User" },
  ],
});

// Upload file (requires file path on disk)
upload_file({
  uid: "file-input-id",
  filePath: "/path/to/file.csv",
});
```

### Console & Network

```javascript
// List console messages
list_console_messages({
  types: ["error", "warn", "info"], // optional filter
  includePreservedMessages: true, // optional, for messages across navigations
});

// Get specific console message details
get_console_message({ msgid: 123 });

// List network requests
list_network_requests({
  resourceTypes: ["xhr", "fetch", "document"], // optional filter
  includePreservedRequests: true, // optional
});

// Get specific network request details
get_network_request({ reqid: 456 });
```

### Network Emulation

```javascript
// Emulate slow network
emulate_network({
  networkConditions: "Slow 3G",
});

// Other options:
// - "No emulation" (default)
// - "Offline"
// - "Slow 3G"
// - "Fast 3G"
// - "Slow 4G"
// - "Fast 4G"

// Throttle CPU
emulate({
  cpuThrottlingRate: 4, // 4x slower, range 1-20
});

// Reset emulation
emulate_network({ networkConditions: "No emulation" });
emulate({ cpuThrottlingRate: 1 });
```

### JavaScript Execution

```javascript
// Execute JavaScript in page context
evaluate_script({
  function: `() => {
    return document.title;
  }`,
});

// With arguments (referencing elements)
evaluate_script({
  function: `(el) => {
    return el.innerText;
  }`,
  args: [{ uid: "element-id" }],
});

// Example: Inject CSV file for upload
evaluate_script({
  function: `() => {
    const fileInput = document.querySelector('input[type="file"]');
    const csvContent = 'id,name\\n1,Test\\n2,Demo';
    const file = new File([csvContent], 'test.csv', { type: 'text/csv' });
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file);
    fileInput.files = dataTransfer.files;
    fileInput.dispatchEvent(new Event('change', { bubbles: true }));
    return { success: true, fileName: file.name };
  }`,
});
```

### Dialogs

```javascript
// Handle browser dialogs (alert, confirm, prompt)
handle_dialog({
  action: "accept", // or "dismiss"
});

// With prompt input
handle_dialog({
  action: "accept",
  promptText: "User input text",
});
```

---

## Tidewave MCP (or Backend Inspection MCP)

Backend inspection and database query tools for Elixir/Phoenix applications.

### Database Queries

```elixir
// Execute SQL query
tidewave.execute_sql_query({
  query: "SELECT * FROM users WHERE email = $1",
  arguments: ["user@example.com"]
})

// Query with multiple parameters
tidewave.execute_sql_query({
  query: """
  SELECT u.id, u.email, o.name as org_name
  FROM users u
  JOIN organizations o ON u.organization_id = o.id
  WHERE u.email = $1 AND o.slug = $2
  """,
  arguments: ["user@example.com", "org-slug"]
})

// Check record counts
tidewave.execute_sql_query({
  query: "SELECT COUNT(*) as count FROM table_name"
})

// Verify relationships
tidewave.execute_sql_query({
  query: """
  SELECT
    (SELECT COUNT(*) FROM users) as users,
    (SELECT COUNT(*) FROM organizations) as orgs,
    (SELECT COUNT(*) FROM memberships) as memberships
  """
})
```

### Elixir Code Execution

```elixir
// Execute Elixir code in project context
tidewave.project_eval({
  code: """
  # Query using Ash
  MyApp.Accounts.User
  |> Ash.Query.filter(email == "test@example.com")
  |> Ash.read_one!(authorize?: false)
  """
})

// Create test data
tidewave.project_eval({
  code: """
  {:ok, org} = MyApp.Accounts.Organization
  |> Ash.Changeset.for_create(:create, %{
    name: "Test Org",
    slug: "test-org-\#{:rand.uniform(9999)}"
  })
  |> Ash.create(authorize?: false)

  org.id
  """
})

// Access IEx helpers
tidewave.project_eval({
  code: """
  # Get all exported functions
  exports(MyApp.Accounts.User)
  """
})
```

### Application Logs

```elixir
// View recent logs
tidewave.get_logs({
  tail: 50 // number of lines
})

// Filter logs with regex
tidewave.get_logs({
  tail: 100,
  grep: "error|Error|ERROR" // case-insensitive regex
})

// Check for specific operations
tidewave.get_logs({
  tail: 30,
  grep: "upload|complete|success"
})

// Check warnings
tidewave.get_logs({
  tail: 50,
  grep: "warn|WARN|warning"
})
```

### Documentation & Source

```elixir
// Get module/function documentation
tidewave.get_docs({
  reference: "MyApp.Accounts.User"
})

// Function documentation
tidewave.get_docs({
  reference: "MyApp.Accounts.User.create"
})

// With arity
tidewave.get_docs({
  reference: "MyApp.Accounts.User.create/2"
})

// Get source location
tidewave.get_source_location({
  reference: "MyApp.Accounts.User"
})

// Dependency location
tidewave.get_source_location({
  reference: "dep:ash"
})
```

### Schema Inspection

```elixir
// List all Ecto schemas in project
tidewave.get_ecto_schemas()

// Search package documentation
tidewave.search_package_docs({
  q: "authentication",
  packages: ["phoenix", "ash"] // optional filter
})
```

---

## Common Testing Workflows

### Verify Application Running

```elixir
// Quick health check
tidewave.execute_sql_query({
  query: "SELECT 1"
})
// Expected: Successful response
```

### Sign In Flow

```javascript
// Navigate to login
navigate_page({ url: "http://localhost:4000/sign-in" });

// Fill credentials
fill_form({
  elements: [
    { uid: "email-input", value: "user@example.com" },
    { uid: "password-input", value: "password123" },
  ],
});

// Submit
click({ uid: "sign-in-button" });

// Wait for redirect
wait_for({ text: "Dashboard", timeout: 10000 });

// Verify session in database
tidewave.execute_sql_query({
  query: "SELECT id, email FROM users WHERE email = $1",
  arguments: ["user@example.com"],
});
```

### Upload CSV File

```javascript
// Click upload button
click({ uid: "upload-button" });

// Inject file via JavaScript
evaluate_script({
  function: `() => {
    const fileInput = document.querySelector('input[type="file"]');
    const csvContent = 'id,name,value\\n1,Test,100\\n2,Demo,200';
    const file = new File([csvContent], 'test.csv', { type: 'text/csv' });
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file);
    fileInput.files = dataTransfer.files;
    fileInput.dispatchEvent(new Event('change', { bubbles: true }));
    return { success: true };
  }`,
});

// Submit upload
click({ uid: "submit-upload-button" });

// Wait for completion
wait_for({ text: "Upload Complete", timeout: 30000 });

// Verify in database
tidewave.execute_sql_query({
  query:
    "SELECT id, filename, status FROM uploads ORDER BY inserted_at DESC LIMIT 1",
});
```

### Three-Layer Verification

```javascript
// UI Layer
take_snapshot();
list_console_messages({ types: ["error"] });

// Backend Layer
tidewave.execute_sql_query({
  query: "SELECT * FROM records WHERE id = $1",
  arguments: [record_id],
});
tidewave.get_logs({ tail: 20, grep: "error" });

// Integration Layer
// Continue to next step to verify workflow
click({ uid: "next-step-button" });
wait_for({ text: "Next Step Loaded" });
```

### Performance Testing

```javascript
// Monitor page load time
const startTime = Date.now();
navigate_page({ url: "http://localhost:4000/page" });
wait_for({ text: "Page Loaded" });
const loadTime = Date.now() - startTime;
// Report if > 2000ms
```

### Network Failure Simulation

```javascript
// Start action
click({ uid: "submit-button" });

// Immediately go offline
emulate_network({ networkConditions: "Offline" });

// Wait a bit
await sleep(2000);

// Restore connection
emulate_network({ networkConditions: "No emulation" });

// Verify error handling and recovery
wait_for({ text: "Connection Error" });
```

---

## Tips & Best Practices

### Element Selection

- Use meaningful `uid` values from snapshots
- UIDs are stable identifiers from accessibility tree
- If element not found, take snapshot to get current UIDs

### Waiting Strategies

```javascript
// ✅ Good: Wait for specific text
wait_for({ text: "Loading Complete" });

// ❌ Bad: Arbitrary sleep
await sleep(5000); // Use only when absolutely necessary
```

### Error Checking

```javascript
// Always check console after interactions
list_console_messages({ types: ["error", "warn"] });

// Always check logs after backend operations
tidewave.get_logs({ tail: 20, grep: "error" });
```

### Query Parameterization

```elixir
// ✅ Good: Use parameters
tidewave.execute_sql_query({
  query: "SELECT * FROM users WHERE email = $1",
  arguments: ["user@example.com"]
})

// ❌ Bad: String interpolation (SQL injection risk)
tidewave.execute_sql_query({
  query: `SELECT * FROM users WHERE email = '${email}'`
})
```

### Taking Evidence

```javascript
// For visual issues
take_screenshot({ filePath: "./evidence/bug-ui.png" });

// For element inspection
take_snapshot(); // Includes all element text and UIDs

// For specific area
take_screenshot({
  uid: "error-message-container",
  filePath: "./evidence/error-msg.png",
});
```

---

## Troubleshooting

### "Element not found" Error

1. Take fresh snapshot to see current UIDs
2. Verify element actually exists
3. Check if element is in modal/dialog
4. Wait for page to fully load before interaction

### "Timeout waiting for text" Error

1. Check if text is spelled exactly right (case-sensitive)
2. Increase timeout if operation is slow
3. Verify action actually triggered
4. Check console for JavaScript errors

### Database Query Fails

1. Verify application is running (`SELECT 1` test)
2. Check table/column names are correct
3. Verify query syntax (PostgreSQL)
4. Use `get_ecto_schemas()` to see available tables

### Logs Not Showing Expected Messages

1. Increase tail limit (`tail: 100`)
2. Check grep pattern (use `|` for OR: `"error|Error|ERROR"`)
3. Verify operation actually executed
4. Check if logs configured correctly in application

---

## Summary

- **Chrome DevTools MCP**: Browser automation, UI testing, network emulation
- **Tidewave MCP**: Database queries, Elixir evaluation, log inspection
- **Use both together**: Verify UI and backend in sync
- **Take evidence**: Screenshots, snapshots, query results, logs
- **Check errors**: Console messages, application logs, database state
