defmodule Examples.PubSub do
  @moduledoc """
  Real-time updates with Phoenix.PubSub.

  This example shows:
  - PubSub subscriptions in LiveView
  - Event broadcasting patterns
  - Widget update flows
  - Multi-level event granularity

  Based on patterns from:
  - lib/my_app_web/live/chat_interface_live.ex
  - lib/my_app_web/live/behaviors/agent_progress_handlers.ex
  - DESIGN/realtime/progress-system.md
  - DESIGN/architecture/event-driven.md
  """

  use MyAppWeb, :live_view

  # ============================================================================
  # BASIC PUBSUB PATTERN
  # ============================================================================

  @impl true
  def mount(%{"chat_id" => chat_id}, _session, socket) do
    current_user = socket.assigns[:current_user]

    # ✅ CORRECT: Only subscribe on websocket connection
    if connected?(socket) do
      # Subscribe to chat-level events
      Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{chat_id}")
    end

    # Load initial data
    {:ok, chat} = load_chat(chat_id, current_user)

    {:ok,
     socket
     |> assign(:chat, chat)
     |> assign(:widgets, [])}
  end

  # ❌ WRONG: Subscribing without connected? check
  def mount_wrong(%{"chat_id" => chat_id}, _session, socket) do
    # DON'T: This will subscribe during initial HTTP request too
    Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{chat_id}")

    {:ok, socket}
  end

  # ============================================================================
  # HANDLING PUBSUB EVENTS
  # ============================================================================

  # Pattern 1: Simple event handling
  @impl true
  def handle_info({:chat_updated, chat_id}, socket) do
    # Reload chat data
    {:ok, updated_chat} = load_chat(chat_id, socket.assigns.current_user)

    {:noreply, assign(socket, :chat, updated_chat)}
  end

  # Pattern 2: Event with data payload
  @impl true
  def handle_info({:new_message, message_data}, socket) do
    # Add message to widgets list
    widgets = socket.assigns.widgets ++ [message_data]

    {:noreply, assign(socket, :widgets, widgets)}
  end

  # Pattern 3: Conditional subscription (subscribe after creation)
  @impl true
  def handle_event("send_message", %{"text" => text}, socket) do
    chat = socket.assigns.chat

    # Create chat if it doesn't exist
    {chat, chat_was_created} =
      if chat do
        {chat, false}
      else
        case create_chat(socket.assigns.current_user) do
          {:ok, new_chat} -> {new_chat, true}
          _ -> {nil, false}
        end
      end

    if chat do
      # ✅ CORRECT: Subscribe after creating chat
      if chat_was_created && connected?(socket) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{chat.id}")
      end

      # Send message...
      {:noreply, assign(socket, :chat, chat)}
    else
      {:noreply, put_flash(socket, :error, "Failed to create chat")}
    end
  end

  # ============================================================================
  # MULTI-LEVEL EVENT GRANULARITY
  # ============================================================================

  defmodule MultiLevelEvents do
    @moduledoc """
    Pattern for subscribing to events at different granularity levels.

    Based on: DESIGN/realtime/progress-system.md
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(%{"chat_id" => chat_id}, _session, socket) do
      if connected?(socket) do
        # Level 1: Chat-level events (coarse-grained)
        Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{chat_id}")

        # Level 2: Version-level events (medium-grained)
        version_id = socket.assigns.version.id
        Phoenix.PubSub.subscribe(MyApp.PubSub, "version:#{version_id}")
      end

      {:ok, socket}
    end

    # Handle coarse-grained event
    @impl true
    def handle_info({:prompt_completed, prompt_id, _meta}, socket) do
      # Reload all prompts and rebuild widgets
      {:ok, prompts} = load_prompts(socket.assigns.chat.id)
      widgets = build_widgets(prompts)

      {:noreply, assign(socket, :widgets, widgets)}
    end

    # Handle fine-grained event (agent state created)
    @impl true
    def handle_info({:agent_state_created, agent_state_id, prompt_id}, socket) do
      # Subscribe to even more detailed events
      if connected?(socket) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "agent_state:#{agent_state_id}")
      end

      # Update widget with agent_state_id for tracking
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget[:id] == "progress-#{prompt_id}" do
            Map.put(widget, :agent_state_id, agent_state_id)
          else
            widget
          end
        end)

      {:noreply, assign(socket, :widgets, widgets)}
    end

    # Handle ultra-fine-grained event (tool execution)
    @impl true
    def handle_info({:tool_call_start, %{tool: tool_name, timestamp: ts}}, socket) do
      # Update progress widget with tool activity
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget[:type] == :progress && widget[:is_live] do
            activity = %{
              tool: tool_name,
              status: :running,
              timestamp: ts
            }

            activities = [activity | (widget[:activities] || [])]

            widget
            |> Map.put(:activities, activities)
            |> Map.put(:progress, estimate_progress(tool_name))
          else
            widget
          end
        end)

      {:noreply, assign(socket, :widgets, widgets)}
    end

    defp estimate_progress("execute_sql"), do: 60
    defp estimate_progress("validate_schema"), do: 30
    defp estimate_progress(_), do: 50
  end

  # ============================================================================
  # BROADCASTING FROM WORKERS
  # ============================================================================

  defmodule BroadcastingPatterns do
    @moduledoc """
    How to broadcast events from background workers.

    Based on: DESIGN/architecture/event-driven.md
    """

    def execute_agent_workflow(chat_id, prompt_id) do
      # Broadcast workflow started
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "analytics_chat:#{chat_id}",
        {:agent_state_created, generate_state_id(), prompt_id}
      )

      # Execute tools and broadcast progress
      agent_state_id = generate_state_id()

      # Broadcast thinking
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "agent_state:#{agent_state_id}",
        {:thinking_token, %{content: "Analyzing schema...", timestamp: DateTime.utc_now()}}
      )

      # Broadcast tool execution
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "agent_state:#{agent_state_id}",
        {:tool_call_start,
         %{tool: "execute_sql", args: %{sql: "SELECT..."}, timestamp: DateTime.utc_now()}}
      )

      # Simulate work
      result = execute_tool("execute_sql")

      # Broadcast completion
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "agent_state:#{agent_state_id}",
        {:tool_call_end,
         %{tool: "execute_sql", result: result, timestamp: DateTime.utc_now()}}
      )

      # Broadcast final completion
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "analytics_chat:#{chat_id}",
        {:prompt_completed, prompt_id, %{status: :completed}}
      )
    end

    defp generate_state_id, do: Ash.UUID.generate()
    defp execute_tool(_tool_name), do: %{rows: [], columns: []}
  end

  # ============================================================================
  # WIDGET UPDATE PATTERNS
  # ============================================================================

  defmodule WidgetUpdatePatterns do
    @moduledoc """
    Efficient patterns for updating widgets based on events.
    """

    # Pattern 1: Update specific widget by ID
    def update_widget_by_id(widgets, widget_id, updates) do
      Enum.map(widgets, fn widget ->
        if widget[:id] == widget_id do
          Map.merge(widget, updates)
        else
          widget
        end
      end)
    end

    # Pattern 2: Update widgets matching criteria
    def update_widgets_matching(widgets, criteria_fn, updates) do
      Enum.map(widgets, fn widget ->
        if criteria_fn.(widget) do
          Map.merge(widget, updates)
        else
          widget
        end
      end)
    end

    # Pattern 3: Replace widget (remove old, add new)
    def replace_widget(widgets, widget_id, new_widget) do
      widgets
      |> Enum.reject(&(&1[:id] == widget_id))
      |> Kernel.++([new_widget])
    end

    # Pattern 4: Batch update (multiple events)
    def batch_update_widgets(widgets, events) do
      Enum.reduce(events, widgets, fn event, acc_widgets ->
        apply_event_to_widgets(acc_widgets, event)
      end)
    end

    defp apply_event_to_widgets(widgets, {:progress_update, widget_id, percentage}) do
      update_widget_by_id(widgets, widget_id, %{progress: percentage})
    end

    defp apply_event_to_widgets(widgets, {:activity_added, widget_id, activity}) do
      Enum.map(widgets, fn widget ->
        if widget[:id] == widget_id do
          activities = [activity | (widget[:activities] || [])]
          Map.put(widget, :activities, activities)
        else
          widget
        end
      end)
    end
  end

  # ============================================================================
  # EVENT THROTTLING
  # ============================================================================

  defmodule EventThrottling do
    @moduledoc """
    Throttle high-frequency events to avoid overwhelming UI.
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:last_update, DateTime.utc_now())
       |> assign(:pending_updates, [])}
    end

    # Throttle thinking tokens (can be very frequent)
    @impl true
    def handle_info({:thinking_token, data}, socket) do
      now = DateTime.utc_now()
      last_update = socket.assigns.last_update

      # Only update UI every 500ms
      if DateTime.diff(now, last_update, :millisecond) >= 500 do
        widgets = apply_thinking_update(socket.assigns.widgets, data)

        {:noreply,
         socket
         |> assign(:widgets, widgets)
         |> assign(:last_update, now)}
      else
        # Buffer the update
        pending = [data | socket.assigns.pending_updates]
        {:noreply, assign(socket, :pending_updates, pending)}
      end
    end

    defp apply_thinking_update(widgets, _data), do: widgets
  end

  # ============================================================================
  # BEST PRACTICES
  # ============================================================================

  defmodule BestPractices do
    @moduledoc """
    PubSub best practices.
    """

    # ✅ DO: Use hierarchical topic names
    def good_topic_names do
      [
        "analytics_chat:#{chat_id}",
        # Coarse-grained
        "agent_state:#{state_id}",
        # Fine-grained
        "version:#{version_id}",
        # Medium-grained
        "organization:#{org_id}"
        # Organization-wide
      ]
    end

    # ❌ DON'T: Use flat, ambiguous names
    def bad_topic_names do
      [
        "chat_updates",
        # Which chat?
        "progress",
        # Too generic
        "events"
        # What kind?
      ]
    end

    # ✅ DO: Structure event data consistently
    def good_event_structure do
      {:event_name,
       %{
         # Map with named fields
         data: "payload",
         timestamp: DateTime.utc_now(),
         metadata: %{}
       }}
    end

    # ❌ DON'T: Use positional arguments
    def bad_event_structure do
      {:event_name, "data", DateTime.utc_now(), %{}}
    end

    # ✅ DO: Handle errors gracefully
    @impl true
    def handle_info({:data_updated, data}, socket) do
      case apply_update(socket, data) do
        {:ok, updated_socket} ->
          {:noreply, updated_socket}

        {:error, reason} ->
          Logger.warning("Failed to apply update: #{inspect(reason)}")
          {:noreply, socket}
      end
    end

    defp apply_update(_socket, _data), do: {:error, :not_implemented}
  end

  # ============================================================================
  # COMMON PITFALLS
  # ============================================================================

  defmodule CommonPitfalls do
    @moduledoc """
    PubSub anti-patterns to avoid.
    """

    # ❌ WRONG: Not checking connected?
    def wrong_subscription(_params, _session, socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
      {:ok, socket}
    end

    # ✅ CORRECT: Always check connected?
    def correct_subscription(_params, _session, socket) do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
      end

      {:ok, socket}
    end

    # ❌ WRONG: Forgetting to unsubscribe
    # Phoenix handles this automatically, but be aware

    # ❌ WRONG: Broadcasting to wrong topic
    def broadcast_wrong do
      Phoenix.PubSub.broadcast(MyApp.PubSub, "wrong_topic", {:event})
    end

    # ✅ CORRECT: Use correct topic pattern
    def broadcast_correct(chat_id) do
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "analytics_chat:#{chat_id}",
        {:event}
      )
    end
  end

  # Private helpers
  defp load_chat(_chat_id, _user), do: {:ok, %{}}
  defp load_prompts(_chat_id), do: {:ok, []}
  defp build_widgets(_prompts), do: []
  defp create_chat(_user), do: {:ok, %{id: Ash.UUID.generate()}}
end
