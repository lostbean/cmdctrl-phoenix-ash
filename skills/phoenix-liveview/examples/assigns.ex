defmodule Examples.Assigns do
  @moduledoc """
  LiveView assigns management patterns.

  This example shows:
  - Basic assign patterns
  - Assign updates (assign, update, assign_new)
  - Computed assigns
  - Nested data structures
  - Performance optimization

  Based on patterns from LiveViews in lib/my_app_web/live/
  """

  use MyAppWeb, :live_view

  # ============================================================================
  # BASIC ASSIGN PATTERNS
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    # Pattern 1: Multiple assigns with pipe
    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:loading, false)
      |> assign(:current_tab, "overview")
      |> assign(:items, [])

    # Pattern 2: Single assign with map (less common, but valid)
    socket =
      assign(socket, %{
        page_title: "Dashboard",
        loading: false,
        current_tab: "overview",
        items: []
      })

    {:ok, socket}
  end

  # ============================================================================
  # ASSIGN UPDATE PATTERNS
  # ============================================================================

  defmodule AssignUpdatePatterns do
    @moduledoc """
    Different ways to update assigns.
    """

    use MyAppWeb, :live_view

    # Pattern 1: assign/3 - Replace value
    def replace_value(socket, new_value) do
      # ✅ Simple replacement
      assign(socket, :count, new_value)
    end

    # Pattern 2: update/3 - Update based on current value
    def increment_counter(socket) do
      # ✅ Update using function
      update(socket, :count, &(&1 + 1))
    end

    # Pattern 3: assign_new/3 - Only assign if not already set
    def set_default(socket) do
      # ✅ Sets :page_size only if not already assigned
      assign_new(socket, :page_size, fn -> 20 end)
    end

    # Pattern 4: Multiple updates
    def update_multiple(socket, new_data) do
      socket
      |> assign(:data, new_data)
      |> assign(:loading, false)
      |> assign(:last_updated, DateTime.utc_now())
      |> update(:refresh_count, &(&1 + 1))
    end
  end

  # ============================================================================
  # LISTS AND COLLECTIONS
  # ============================================================================

  defmodule ListManagement do
    @moduledoc """
    Managing lists in assigns.
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:widgets, [])
       |> assign(:selected_ids, MapSet.new())}
    end

    # Add to list
    def handle_event("add_widget", %{"widget" => widget_data}, socket) do
      new_widget = %{
        id: generate_id(),
        type: widget_data["type"],
        data: widget_data
      }

      # ✅ CORRECT: Append to list
      {:noreply, update(socket, :widgets, &(&1 ++ [new_widget]))}
    end

    # Remove from list
    def handle_event("remove_widget", %{"id" => id}, socket) do
      # ✅ CORRECT: Filter list
      {:noreply, update(socket, :widgets, &Enum.reject(&1, fn w -> w.id == id end))}
    end

    # Update item in list
    def handle_event("update_widget", %{"id" => id, "data" => data}, socket) do
      # ✅ CORRECT: Map over list to update matching item
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget.id == id do
            %{widget | data: data}
          else
            widget
          end
        end)

      {:noreply, assign(socket, :widgets, widgets)}
    end

    # Toggle selection (using MapSet for efficiency)
    def handle_event("toggle_select", %{"id" => id}, socket) do
      selected_ids =
        if MapSet.member?(socket.assigns.selected_ids, id) do
          MapSet.delete(socket.assigns.selected_ids, id)
        else
          MapSet.put(socket.assigns.selected_ids, id)
        end

      {:noreply, assign(socket, :selected_ids, selected_ids)}
    end

    defp generate_id, do: Ash.UUID.generate()
  end

  # ============================================================================
  # NESTED DATA STRUCTURES
  # ============================================================================

  defmodule NestedData do
    @moduledoc """
    Working with nested maps and structs.
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:user, %{
         name: "John Doe",
         preferences: %{
           theme: "dark",
           notifications: true
         },
         stats: %{
           login_count: 0,
           last_login: nil
         }
       })}
    end

    # Update nested value - Method 1: Replace whole structure
    def update_theme_v1(socket, new_theme) do
      user = socket.assigns.user

      updated_user = %{
        user
        | preferences: %{user.preferences | theme: new_theme}
      }

      assign(socket, :user, updated_user)
    end

    # Update nested value - Method 2: Use update/3 with function
    def update_theme_v2(socket, new_theme) do
      update(socket, :user, fn user ->
        %{user | preferences: %{user.preferences | theme: new_theme}}
      end)
    end

    # Update nested value - Method 3: Use put_in
    def update_theme_v3(socket, new_theme) do
      update(socket, :user, fn user ->
        put_in(user.preferences.theme, new_theme)
      end)
    end

    # Increment nested counter
    def record_login(socket) do
      update(socket, :user, fn user ->
        %{
          user
          | stats: %{
              user.stats
              | login_count: user.stats.login_count + 1,
                last_login: DateTime.utc_now()
            }
        }
      end)
    end
  end

  # ============================================================================
  # COMPUTED ASSIGNS
  # ============================================================================

  defmodule ComputedAssigns do
    @moduledoc """
    Deriving values from other assigns.
    """

    use MyAppWeb, :live_view

    @impl true
    def render(assigns) do
      # ✅ CORRECT: Compute in render function
      assigns = assign(assigns, :total_items, length(assigns.items))
      assigns = assign(assigns, :has_items, assigns.total_items > 0)

      ~H"""
      <div class="stats">
        <div class="stat">
          <div class="stat-title">Total Items</div>
          <div class="stat-value">{@total_items}</div>
        </div>

        <%= if @has_items do %>
          <div class="stat">
            <div class="stat-title">Status</div>
            <div class="stat-value">Active</div>
          </div>
        <% end %>
      </div>
      """
    end

    # ❌ WRONG: Don't store computed values in mount
    def mount_wrong(_params, _session, socket) do
      items = [1, 2, 3]

      socket =
        socket
        |> assign(:items, items)
        # DON'T: This becomes stale when items change
        |> assign(:total_items, length(items))

      {:ok, socket}
    end

    # ✅ CORRECT: Compute when needed or use helper
    def mount_correct(_params, _session, socket) do
      {:ok, assign(socket, :items, [1, 2, 3])}
    end

    # Helper function for computed value
    defp total_items(assigns) do
      length(assigns.items)
    end

    # Use in template: {total_items(assigns)}
  end

  # ============================================================================
  # PERFORMANCE OPTIMIZATION
  # ============================================================================

  defmodule PerformancePatterns do
    @moduledoc """
    Optimize assigns for performance.
    """

    use MyAppWeb, :live_view

    # ❌ WRONG: Rebuilding entire list every time
    def handle_info_wrong({:new_item, item}, socket) do
      # DON'T: This triggers full re-render
      all_items = load_all_items_from_db()
      {:noreply, assign(socket, :items, all_items)}
    end

    # ✅ CORRECT: Only update what changed
    def handle_info_correct({:new_item, item}, socket) do
      # DO: Append to existing list
      {:noreply, update(socket, :items, &(&1 ++ [item]))}
    end

    # ✅ CORRECT: Use temporary assigns for large data
    def handle_event("load_report", _params, socket) do
      # Large data that's only needed for this render
      report_data = generate_large_report()

      {:noreply, assign(socket, :report, report_data) |> assign(:temp_data, true)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <%= if assigns[:report] do %>
        <div class="report">
          {render_report(@report)}
        </div>
      <% end %>
      """
    end

    # Clean up temporary assigns after render (optional optimization)
    @impl true
    def handle_info(:cleanup_temp, socket) do
      socket =
        if socket.assigns[:temp_data] do
          socket
          |> assign(:report, nil)
          |> assign(:temp_data, false)
        else
          socket
        end

      {:noreply, socket}
    end

    defp load_all_items_from_db, do: []
    defp generate_large_report, do: %{}
    defp render_report(_report), do: "Report content"
  end

  # ============================================================================
  # COMMON PATTERNS
  # ============================================================================

  defmodule CommonPatterns do
    @moduledoc """
    Common assign patterns used in many applications.
    """

    use MyAppWeb, :live_view

    # Pattern: Widget list management
    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:widgets, [])
       |> assign(:page_title, "Chat")
       |> assign(:loading, false)}
    end

    # Pattern: Add user message and progress widget
    def handle_event("send_message", %{"message" => text}, socket) do
      # Create user message widget
      user_widget = %{
        id: "message-#{generate_id()}",
        type: :user_message,
        content: text,
        timestamp: DateTime.utc_now()
      }

      # Create progress widget
      progress_widget = %{
        id: "progress-#{generate_id()}",
        type: :agent_progress,
        is_live: true,
        percentage: 0,
        status: "Processing..."
      }

      # Add both widgets
      {:noreply, update(socket, :widgets, &(&1 ++ [user_widget, progress_widget]))}
    end

    # Pattern: Replace progress widget with result widget
    def handle_info({:prompt_completed, prompt_id}, socket) do
      # Remove progress widget
      widgets =
        socket.assigns.widgets
        |> Enum.reject(&(&1[:id] == "progress-#{prompt_id}"))

      # Add result widget
      result_widget = %{
        id: "result-#{prompt_id}",
        type: :agent_response,
        data: load_result(prompt_id)
      }

      widgets = widgets ++ [result_widget]

      {:noreply, assign(socket, :widgets, widgets)}
    end

    # Pattern: Update widget by ID
    def handle_info({:progress_update, widget_id, percentage}, socket) do
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget[:id] == widget_id do
            Map.put(widget, :percentage, percentage)
          else
            widget
          end
        end)

      {:noreply, assign(socket, :widgets, widgets)}
    end

    # Pattern: Actor context
    def load_data_with_actor(socket) do
      user = socket.assigns.current_user

      actor = %{
        user: user,
        organization_id: user.organization_id
      }

      case MyApp.SomeResource |> Ash.read(actor: actor) do
        {:ok, data} ->
          assign(socket, :data, data)

        {:error, _} ->
          socket
      end
    end

    defp generate_id, do: Ash.UUID.generate()
    defp load_result(_prompt_id), do: %{}
  end

  # ============================================================================
  # ANTI-PATTERNS TO AVOID
  # ============================================================================

  defmodule AntiPatterns do
    @moduledoc """
    Common mistakes with assigns.
    """

    # ❌ WRONG: Mutating assigns directly
    def wrong_mutation(socket) do
      # DON'T: This doesn't work - assigns is immutable
      socket.assigns.count = socket.assigns.count + 1
      socket
    end

    # ✅ CORRECT: Use assign/update
    def correct_update(socket) do
      # DO: Use assign or update
      update(socket, :count, &(&1 + 1))
    end

    # ❌ WRONG: Storing functions in assigns
    def wrong_function_storage(socket) do
      # DON'T: Functions can't be serialized
      assign(socket, :callback, fn x -> x + 1 end)
    end

    # ✅ CORRECT: Store data, compute in render
    def correct_data_storage(socket) do
      # DO: Store data, use helper functions
      assign(socket, :increment_by, 1)
    end

    # ❌ WRONG: Over-assigning unchanged data
    def wrong_over_assign(socket) do
      # DON'T: This triggers unnecessary re-render
      socket
      |> assign(:static_config, load_config())
      # Same every time!
      |> assign(:constants, %{max: 100})

      # Same every time!
    end

    # ✅ CORRECT: Assign static data once in mount
    def correct_static_assign(socket) do
      # DO: Assign static data once
      socket
      |> assign_new(:static_config, fn -> load_config() end)
      |> assign_new(:constants, fn -> %{max: 100} end)
    end

    defp load_config, do: %{}
  end
end
