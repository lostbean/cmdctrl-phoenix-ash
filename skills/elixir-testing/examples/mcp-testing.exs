defmodule MyApp.Example.MCPTestingTest do
  @moduledoc """
  Example of E2E testing using MCP tools (Chrome DevTools + Tidewave).

  MCP tools enable testing the complete application stack:
  - UI interactions (Chrome DevTools)
  - Backend verification (Tidewave Elixir/Ecto inspection)
  - Database queries (Tidewave SQL)
  - Real-time updates (PubSub monitoring)

  This is a conceptual example showing the pattern.
  Actual MCP tests are typically written as manual test plans
  and executed interactively via Claude Code.

  See: DESIGN/testing/agentic-test-plan.md for full E2E workflows
  """

  # Note: This is a pseudo-code example demonstrating the pattern
  # Real MCP tests run via Claude Code with chrome-devtools and tidewave

  # ============================================================================
  # ✅ CORRECT PATTERN: Three-Layer Verification
  # ============================================================================

  @doc """
  Example: Test complete upload workflow

  1. UI Layer: Interact with browser
  2. Backend Layer: Verify logs
  3. Database Layer: Check persistence
  """
  def test_upload_workflow do
    """
    # Step 1: UI Interaction (Chrome DevTools MCP)
    navigate_page(%{url: "http://localhost:4000/data-sources"})
    click(%{uid: "upload-button"})

    # Inject CSV file via JavaScript
    evaluate_script(%{
      function: \"\"\"
      () => {
        const file = new File(['col1,col2\\n1,2'], 'test.csv', {type: 'text/csv'});
        const input = document.querySelector('input[type=\"file\"]');
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        input.files = dataTransfer.files;
        input.dispatchEvent(new Event('change', {bubbles: true}));
        return {success: true};
      }
      \"\"\"
    })

    click(%{uid: "submit-upload"})
    wait_for(%{text: "Upload complete", timeout: 30000})
    take_snapshot()  # ✅ Text-based snapshot (faster than screenshot)

    # Step 2: Backend Verification (Tidewave MCP)
    tidewave.get_logs(%{tail: 50, grep: "Upload"})
    # ✅ Verify no errors in logs

    # Step 3: Database Verification (Tidewave SQL)
    tidewave.execute_sql_query(%{
      query: \"\"\"
      SELECT id, filename, status, data_source_version_id
      FROM uploads
      WHERE filename = $1
      ORDER BY inserted_at DESC
      LIMIT 1
      \"\"\",
      arguments: ["test.csv"]
    })
    # ✅ Expected: status = "completed", data_source_version_id is set
    """
  end

  # ============================================================================
  # ✅ CORRECT PATTERN: Real-Time Updates
  # ============================================================================

  @doc """
  Example: Test agent execution with progress updates

  Verify PubSub events reach UI in real-time
  """
  def test_agent_progress_updates do
    """
    # Subscribe to PubSub in backend
    tidewave.project_eval(%{
      code: \"\"\"
      pid = self()
      Phoenix.PubSub.subscribe(MyApp.PubSub, \"agent_state:test-state-id\")

      # Capture messages
      Task.async(fn ->
        receive do
          {:agent_event, event} -> send(pid, {:captured, event})
        after
          10_000 -> send(pid, {:timeout})
        end
      end)
      \"\"\"
    })

    # UI: Submit agent request
    navigate_page(%{url: "http://localhost:4000/chat/test-chat"})
    fill(%{uid: "chat-input", value: "Analyze customer data"})
    click(%{uid: "send-button"})

    # UI: Verify progress widget appears
    wait_for(%{text: "Processing", timeout: 2000})
    take_snapshot()
    # ✅ Should show progress circle and thinking messages

    # Backend: Verify event was broadcast
    tidewave.project_eval(%{
      code: \"\"\"
      receive do
        {:captured, event} -> event
      after
        5_000 -> :timeout
      end
      \"\"\"
    })
    # ✅ Expected: Event with type: "thinking_token" or "tool_call_start"
    """
  end

  # ============================================================================
  # ✅ CORRECT PATTERN: Authorization Testing
  # ============================================================================

  @doc """
  Example: Test multi-tenant isolation

  Verify users cannot access other organizations' data
  """
  def test_organization_isolation do
    """
    # Create two organizations via Tidewave
    tidewave.project_eval(%{
      code: \"\"\"
      {:ok, org1} = MyApp.Accounts.Organization
        |> Ash.Changeset.for_create(:create, %{name: "Org 1", slug: "org-1"})
        |> Ash.create(authorize?: false)

      {:ok, user1} = create_test_user(org1)

      {:ok, org2} = MyApp.Accounts.Organization
        |> Ash.Changeset.for_create(:create, %{name: "Org 2", slug: "org-2"})
        |> Ash.create(authorize?: false)

      {:ok, user2} = create_test_user(org2)

      {:ok, resource1} = create_test_resource(org1, user1)

      {user1.email, user2.email, resource1.id}
      \"\"\"
    })

    # Login as user1
    navigate_page(%{url: "http://localhost:4000/sign-in"})
    fill_form(%{
      elements: [
        %{uid: "email-input", value: user1_email},
        %{uid: "password-input", value: "password123"}
      ]
    })
    click(%{uid: "sign-in-button"})

    # ✅ User1 can see their resource
    wait_for(%{text: resource1_name})

    # Login as user2
    navigate_page(%{url: "http://localhost:4000/sign-out"})
    # ... (login as user2)

    # ✅ User2 CANNOT see org1's resource
    # Verify it's not in the list
    take_snapshot()
    # Expected: Resource list does not contain org1's resource

    # Backend verification
    tidewave.execute_sql_query(%{
      query: \"\"\"
      SELECT COUNT(*) FROM resources
      WHERE id = $1 AND organization_id = $2
      \"\"\",
      arguments: [resource1_id, org2_id]
    })
    # ✅ Expected: count = 0 (isolation enforced)
    """
  end

  # ============================================================================
  # ❌ ANTI-PATTERNS TO AVOID
  # ============================================================================

  # ❌ DON'T: Rely only on UI verification
  # Always verify backend state and database persistence
  #
  # Bad:
  # take_snapshot()  # ✅ Good
  # # ❌ Missing backend/DB verification
  #
  # Good:
  # take_snapshot()  # UI check
  # tidewave.get_logs(...)  # Backend check
  # tidewave.execute_sql_query(...)  # DB check

  # ❌ DON'T: Use screenshots when snapshots work
  # Snapshots are faster and more reliable for text content
  #
  # take_screenshot()  # ❌ Slower, harder to diff
  # take_snapshot()    # ✅ Faster, text-based, easier to verify

  # ❌ DON'T: Hard-code UUIDs or IDs
  # Generate them dynamically or extract from responses
  #
  # Bad:
  # navigate_page(%{url: "http://localhost:4000/model/12345"})
  # # ❌ Hard-coded ID won't exist in test
  #
  # Good:
  # result = tidewave.execute_sql_query(...)
  # model_id = result.rows[0].id
  # navigate_page(%{url: "http://localhost:4000/model/#{model_id}"})

  # ============================================================================
  # BEST PRACTICES
  # ============================================================================

  # ✅ Use wait_for with timeouts
  @doc """
  Wait for async operations to complete
  """
  def test_async_operation do
    """
    click(%{uid: "process-button"})

    # ✅ Wait for operation with reasonable timeout
    wait_for(%{text: "Processing complete", timeout: 30_000})

    # ❌ Don't assume instant completion
    # take_snapshot()  # Might capture intermediate state
    """
  end

  # ✅ Check for errors in logs
  @doc """
  Verify no unexpected errors occurred
  """
  def verify_no_errors do
    """
    # After any operation, check logs
    logs = tidewave.get_logs(%{tail: 50, grep: "error|ERROR"})

    # ✅ Assert no errors related to your operation
    # (Some unrelated errors might exist)
    assert not String.contains?(logs, "Upload failed")
    """
  end

  # ✅ Clean up test data
  @doc """
  Clean up after E2E tests
  """
  def cleanup_test_data do
    """
    # Delete test organization and cascade
    tidewave.execute_sql_query(%{
      query: \"\"\"
      DELETE FROM organizations
      WHERE slug LIKE 'test-%'
      \"\"\"
    })

    # Or reset entire database
    # mix ash.reset
    """
  end

  # ============================================================================
  # MCP TOOLS REFERENCE
  # ============================================================================

  @doc """
  Chrome DevTools MCP commands
  """
  def chrome_devtools_reference do
    """
    # Navigation
    navigate_page(%{url: "..."})
    navigate_page(%{type: "back"})
    navigate_page(%{type: "reload"})

    # Inspection
    take_snapshot()  # ✅ Prefer for text content
    take_screenshot(%{filePath: "/path/to/save.png"})
    list_console_messages()
    list_network_requests()

    # Interaction
    click(%{uid: "element-id"})
    fill(%{uid: "input-id", value: "text"})
    fill_form(%{elements: [...]})
    hover(%{uid: "element-id"})

    # Waiting
    wait_for(%{text: "Expected text", timeout: 5000})

    # Network
    emulate_network(%{throttlingOption: "Slow 3G"})
    """
  end

  @doc """
  Tidewave MCP commands
  """
  def tidewave_reference do
    """
    # SQL Queries
    tidewave.execute_sql_query(%{
      query: "SELECT * FROM users WHERE email = $1",
      arguments: ["user@example.com"]
    })

    # Elixir Evaluation
    tidewave.project_eval(%{
      code: \"\"\"
      MyApp.Accounts.User
      |> Ash.read!(authorize?: false)
      \"\"\"
    })

    # Logs
    tidewave.get_logs(%{tail: 50})
    tidewave.get_logs(%{tail: 50, grep: "error|Error"})

    # Documentation
    tidewave.get_docs(%{reference: "MyApp.Accounts.User"})

    # Schema
    tidewave.get_ecto_schemas()
    """
  end

  # ============================================================================
  # RUNNING MCP TESTS
  # ============================================================================

  # MCP tests are typically run interactively via Claude Code:
  #
  # 1. Start application: mix phx.server
  # 2. Open Claude Code with MCP servers enabled
  # 3. Execute test flows from DESIGN/testing/agentic-test-plan.md
  # 4. Verify results at each layer (UI, Backend, DB)
  #
  # See:
  # - DESIGN/testing/agentic-test-plan.md - Complete test flows
  # - .claude/context/mcp-tools-guide.md - MCP tools reference
  # - .claude/commands/qa-manual.md - Manual QA command
end
