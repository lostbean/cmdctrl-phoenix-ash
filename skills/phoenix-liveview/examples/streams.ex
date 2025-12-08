defmodule Examples.Streams do
  @moduledoc """
  LiveView streams pattern (Phoenix LiveView 0.18+).

  NOTE: Streams are NOT heavily used in your application.
  The project primarily uses list-based widget assigns instead.

  This example shows:
  - Basic stream usage
  - Stream operations (insert, delete, update)
  - When to use streams vs. lists
  - Performance characteristics

  Streams are useful for:
  - Large collections (1000+ items)
  - Frequent updates to individual items
  - DOM recycling and optimization

  For most common patterns in your application, see assigns.ex instead.
  """

  use MyAppWeb, :live_view

  # ============================================================================
  # BASIC STREAM USAGE
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    # Initialize stream with items
    items = [
      %{id: 1, name: "Item 1", status: :active},
      %{id: 2, name: "Item 2", status: :pending},
      %{id: 3, name: "Item 3", status: :active}
    ]

    {:ok,
     socket
     |> stream(:items, items)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <h1 class="text-2xl font-bold mb-6">Stream Example</h1>

      <%!-- Render stream with phx-update="stream" --%>
      <div id="items-list" phx-update="stream" class="space-y-2">
        <div
          :for={{dom_id, item} <- @streams.items}
          id={dom_id}
          class="card bg-base-100 shadow p-4"
        >
          <div class="flex items-center justify-between">
            <div>
              <h3 class="font-semibold">{item.name}</h3>
              <p class="text-sm text-base-content/60">ID: {item.id}</p>
            </div>

            <div class="flex gap-2">
              <span class={["badge", status_badge(item.status)]}>
                {item.status}
              </span>

              <button
                class="btn btn-xs btn-error"
                phx-click="delete_item"
                phx-value-id={item.id}
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Add new item --%>
      <div class="mt-8">
        <button class="btn btn-primary" phx-click="add_item">
          Add Item
        </button>
      </div>
    </div>
    """
  end

  defp status_badge(:active), do: "badge-success"
  defp status_badge(:pending), do: "badge-warning"
  defp status_badge(_), do: "badge-ghost"

  # ============================================================================
  # STREAM OPERATIONS
  # ============================================================================

  # Insert new item at the end
  @impl true
  def handle_event("add_item", _params, socket) do
    new_id = :rand.uniform(10000)

    new_item = %{
      id: new_id,
      name: "Item #{new_id}",
      status: :pending
    }

    # Insert at end (default)
    {:noreply, stream_insert(socket, :items, new_item)}
  end

  # Insert at beginning
  def handle_event("add_item_top", _params, socket) do
    new_item = %{id: :rand.uniform(10000), name: "New Item", status: :active}

    # Insert at beginning
    {:noreply, stream_insert(socket, :items, new_item, at: 0)}
  end

  # Delete item
  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    id = String.to_integer(id)

    # Delete from stream (need the item struct)
    item = %{id: id}

    {:noreply, stream_delete(socket, :items, item)}
  end

  # Update item
  def handle_event("update_status", %{"id" => id, "status" => status}, socket) do
    id = String.to_integer(id)
    status = String.to_atom(status)

    # Load item, update it, and re-insert
    updated_item = %{id: id, name: "Item #{id}", status: status}

    # Re-inserting with same ID updates the existing item
    {:noreply, stream_insert(socket, :items, updated_item)}
  end

  # ============================================================================
  # STREAMS VS. LISTS - WHEN TO USE WHICH
  # ============================================================================

  defmodule StreamsVsLists do
    @moduledoc """
    Comparison of streams vs. list assigns.
    """

    # ✅ USE STREAMS WHEN:
    # - Large collections (1000+ items)
    # - Frequent updates to individual items
    # - Need DOM recycling for performance
    # - Paginated data with add/remove

    def use_streams_example(socket) do
      # Good for large, frequently updated lists
      stream(socket, :messages, [])
    end

    # ✅ USE LISTS WHEN:
    # - Small collections (< 100 items)
    # - Full replacement is common
    # - Need to transform entire list
    # - Simpler mental model

    def use_lists_example(socket) do
      # Good for small, infrequently updated lists
      # This is the COMMON PATTERN - widgets are list-based
      assign(socket, :widgets, [])
    end
  end

  # ============================================================================
  # TYPICAL PATTERN (List-based)
  # ============================================================================

  defmodule TypicalWidgetPattern do
    @moduledoc """
    Most applications use list-based widgets, NOT streams.

    This is the actual pattern used in:
    - lib/my_app_web/live/chat_interface_live.ex
    - lib/my_app_web/live/model_edit_live.ex
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      # ✅ Common pattern: use list assigns for widgets
      {:ok, assign(socket, :widgets, [])}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6">
        <%!-- Render widgets as list (NOT stream) --%>
        <%= for widget <- @widgets do %>
          {render_widget(assigns, widget)}
        <% end %>
      </div>
      """
    end

    # Add widget to list
    def handle_event("add_widget", %{"widget" => widget_data}, socket) do
      new_widget = %{
        id: generate_id(),
        type: :user_message,
        data: widget_data
      }

      # Append to list
      {:noreply, update(socket, :widgets, &(&1 ++ [new_widget]))}
    end

    # Update widget in list
    def handle_info({:widget_update, widget_id, updates}, socket) do
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget[:id] == widget_id do
            Map.merge(widget, updates)
          else
            widget
          end
        end)

      {:noreply, assign(socket, :widgets, widgets)}
    end

    # Replace widget in list
    def handle_info({:replace_widget, widget_id, new_widget}, socket) do
      widgets =
        socket.assigns.widgets
        |> Enum.reject(&(&1[:id] == widget_id))
        |> Kernel.++([new_widget])

      {:noreply, assign(socket, :widgets, widgets)}
    end

    defp render_widget(_assigns, widget) do
      Phoenix.HTML.raw("<div>Widget: #{widget.type}</div>")
    end

    defp generate_id, do: Ash.UUID.generate()
  end

  # ============================================================================
  # STREAM PERFORMANCE CHARACTERISTICS
  # ============================================================================

  defmodule StreamPerformance do
    @moduledoc """
    Understanding stream performance.
    """

    # Streams optimize DOM updates by:
    # 1. Only sending diffs (not full list)
    # 2. Recycling DOM nodes
    # 3. Preserving scroll position

    # Example: Adding 1 item to 10,000 item list
    #
    # With list assign:
    # - Sends all 10,001 items to client
    # - Re-renders entire list
    # - Loses scroll position
    #
    # With stream:
    # - Sends only new item
    # - Inserts single DOM node
    # - Preserves scroll position

    def large_list_with_stream(socket) do
      # ✅ Efficient for large lists
      items = generate_items(10_000)
      stream(socket, :items, items)
    end

    def large_list_with_assign(socket) do
      # ❌ Inefficient for large lists
      items = generate_items(10_000)
      assign(socket, :items, items)
    end

    defp generate_items(count) do
      Enum.map(1..count, fn i ->
        %{id: i, name: "Item #{i}", data: :rand.uniform(100)}
      end)
    end
  end

  # ============================================================================
  # STREAM PAGINATION PATTERN
  # ============================================================================

  defmodule StreamPagination do
    @moduledoc """
    Infinite scroll with streams.
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      # Load initial page
      {items, has_more} = load_page(1)

      {:ok,
       socket
       |> stream(:items, items)
       |> assign(:page, 1)
       |> assign(:has_more, has_more)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="container">
        <div id="items-stream" phx-update="stream" phx-viewport-bottom="load_more">
          <div :for={{dom_id, item} <- @streams.items} id={dom_id}>
            {item.name}
          </div>
        </div>

        <%= if @has_more do %>
          <div class="text-center py-4">
            <span class="loading loading-spinner"></span>
          </div>
        <% end %>
      </div>
      """
    end

    @impl true
    def handle_event("load_more", _params, socket) do
      if socket.assigns.has_more do
        next_page = socket.assigns.page + 1
        {items, has_more} = load_page(next_page)

        {:noreply,
         socket
         |> stream(:items, items, at: -1)
         |> assign(:page, next_page)
         |> assign(:has_more, has_more)}
      else
        {:noreply, socket}
      end
    end

    defp load_page(page_num) do
      # Simulate loading page
      items =
        Enum.map(1..20, fn i ->
          %{id: (page_num - 1) * 20 + i, name: "Item #{(page_num - 1) * 20 + i}"}
        end)

      has_more = page_num < 5
      {items, has_more}
    end
  end

  # ============================================================================
  # COMMON PITFALLS
  # ============================================================================

  defmodule StreamPitfalls do
    @moduledoc """
    Common mistakes with streams.
    """

    # ❌ WRONG: Forgetting phx-update="stream"
    def wrong_render_without_update(assigns) do
      ~H"""
      <%!-- DON'T: Missing phx-update="stream" --%>
      <div id="items">
        <div :for={{_id, item} <- @streams.items}>
          {item.name}
        </div>
      </div>
      """
    end

    # ✅ CORRECT: Include phx-update="stream"
    def correct_render_with_update(assigns) do
      ~H"""
      <%!-- DO: Include phx-update="stream" --%>
      <div id="items" phx-update="stream">
        <div :for={{dom_id, item} <- @streams.items} id={dom_id}>
          {item.name}
        </div>
      </div>
      """
    end

    # ❌ WRONG: Not setting ID on stream items
    def wrong_render_without_id(assigns) do
      ~H"""
      <div id="items" phx-update="stream">
        <%!-- DON'T: Missing id attribute --%>
        <div :for={{_dom_id, item} <- @streams.items}>
          {item.name}
        </div>
      </div>
      """
    end

    # ✅ CORRECT: Always use dom_id for id attribute
    def correct_render_with_id(assigns) do
      ~H"""
      <div id="items" phx-update="stream">
        <%!-- DO: Use dom_id for id --%>
        <div :for={{dom_id, item} <- @streams.items} id={dom_id}>
          {item.name}
        </div>
      </div>
      """
    end
  end

  # ============================================================================
  # RECOMMENDATION
  # ============================================================================

  @doc """
  ## Recommendation

  For your application development:

  ✅ **Use list assigns** (the current pattern) for:
  - Chat widgets (typically < 50 widgets per conversation)
  - Model edit widgets
  - UI components

  Consider streams only if:
  - Conversations regularly exceed 1000+ messages
  - Performance issues are measured
  - Need infinite scroll with 10,000+ items

  ## Why Most Applications Use Lists

  1. **Simplicity**: List operations are straightforward
  2. **Widget count**: Most chats have < 50 widgets
  3. **Full rebuilds**: Widget updates often replace entire widget
  4. **Mental model**: Easier to reason about

  See `assigns.ex` for the actual patterns used in MyApp.
  """
  def recommendation, do: :use_list_assigns
end
