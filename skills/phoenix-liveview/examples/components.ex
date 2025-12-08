defmodule Examples.Components do
  @moduledoc """
  Phoenix LiveView component patterns.

  This example shows:
  - Function components (stateless)
  - LiveComponents (stateful)
  - Component attributes and slots
  - Component communication
  - Shared behaviors

  Based on patterns from:
  - lib/my_app_web/components/core_components.ex
  - lib/my_app_web/live/components/*.ex
  - lib/my_app_web/widgets/*.ex
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  # ============================================================================
  # FUNCTION COMPONENTS - Stateless, reusable UI elements
  # ============================================================================

  @doc """
  Simple function component with attributes.

  Function components are pure - they take assigns and return HEEx.
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :variant, :string, values: ["info", "warning", "error"], default: "info"
  attr :class, :string, default: ""

  def alert(assigns) do
    ~H"""
    <div class={[
      "alert",
      alert_variant_class(@variant),
      @class
    ]}>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="h-6 w-6 shrink-0"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      </svg>
      <div>
        <h3 class="font-bold">{@title}</h3>
        <p :if={@subtitle} class="text-sm">{@subtitle}</p>
      </div>
    </div>
    """
  end

  defp alert_variant_class("info"), do: "alert-info"
  defp alert_variant_class("warning"), do: "alert-warning"
  defp alert_variant_class("error"), do: "alert-error"

  # Usage in templates:
  # <.alert title="Success!" subtitle="Operation completed" variant="info" />

  @doc """
  Function component with slots (inner content).
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-xl", @class]}>
      <div class="card-body">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # Usage:
  # <.card>
  #   <h2>Title</h2>
  #   <p>Content</p>
  # </.card>

  @doc """
  Function component with named slots.
  """
  attr :class, :string, default: ""
  slot :header, required: false
  slot :footer, required: false
  slot :inner_block, required: true

  def card_with_slots(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-xl", @class]}>
      <div :if={@header != []} class="card-header p-4 border-b">
        {render_slot(@header)}
      </div>

      <div class="card-body">
        {render_slot(@inner_block)}
      </div>

      <div :if={@footer != []} class="card-footer p-4 border-t">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  # Usage:
  # <.card_with_slots>
  #   <:header>
  #     <h2>Card Title</h2>
  #   </:header>
  #
  #   <p>Main content here</p>
  #
  #   <:footer>
  #     <button class="btn btn-primary">Action</button>
  #   </:footer>
  # </.card_with_slots>

  # ============================================================================
  # LIVECOMPONENT - Stateful components with lifecycle
  # ============================================================================

  defmodule ProgressWidget do
    @moduledoc """
    Stateful LiveComponent for progress tracking.

    LiveComponents have their own state and can handle events.
    Based on: lib/my_app_web/widgets/progress.ex
    """

    use MyAppWeb, :live_component

    # -------------------------------------------------------------------------
    # LIFECYCLE - update/2 is called when assigns change
    # -------------------------------------------------------------------------

    @impl true
    def update(assigns, socket) do
      # Subscribe to real-time updates on first mount
      if assigns[:is_live] && connected?(socket) do
        Phoenix.PubSub.subscribe(MyApp.PubSub, "progress:#{assigns.id}")
      end

      {:ok,
       socket
       |> assign(assigns)
       |> assign_new(:expanded, fn -> true end)
       |> assign_new(:percentage, fn -> 0 end)}
    end

    # -------------------------------------------------------------------------
    # RENDER - Generate component HTML
    # -------------------------------------------------------------------------

    @impl true
    def render(assigns) do
      ~H"""
      <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
          <%!-- Header --%>
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <%= if @is_live do %>
                <div class="loading loading-spinner loading-sm text-primary"></div>
              <% else %>
                <div class="text-success">✓</div>
              <% end %>

              <div>
                <h3 class="font-semibold text-sm">{@title}</h3>
                <p :if={@subtitle} class="text-xs text-base-content/60">
                  {@subtitle}
                </p>
              </div>
            </div>

            <%!-- Radial progress indicator --%>
            <div
              class="radial-progress text-primary text-xs"
              style={"--value:#{@percentage}; --size:2rem;"}
            >
              <span class="text-xs">{@percentage}%</span>
            </div>
          </div>

          <%!-- Progress bar --%>
          <div class="w-full bg-base-200 rounded-full h-2 mt-2">
            <div
              class="bg-primary h-2 rounded-full transition-all duration-300"
              style={"width: #{@percentage}%"}
            >
            </div>
          </div>

          <%!-- Expandable details --%>
          <%= if @expanded && @activities do %>
            <div class="mt-4 space-y-2">
              <%= for activity <- @activities do %>
                <div class="flex items-center gap-2 text-sm">
                  <span class={activity_badge(activity.status)}>
                    {activity.type}
                  </span>
                  <span>{activity.description}</span>
                </div>
              <% end %>
            </div>
          <% end %>

          <%!-- Toggle button (sends event to THIS component) --%>
          <button
            class="btn btn-ghost btn-xs mt-2"
            phx-click="toggle_expand"
            phx-target={@myself}
          >
            {if @expanded, do: "Hide Details", else: "Show Details"}
          </button>
        </div>
      </div>
      """
    end

    # -------------------------------------------------------------------------
    # EVENT HANDLERS - Handle events targeted at this component
    # -------------------------------------------------------------------------

    @impl true
    def handle_event("toggle_expand", _params, socket) do
      {:noreply, assign(socket, :expanded, !socket.assigns.expanded)}
    end

    # -------------------------------------------------------------------------
    # PUBSUB HANDLERS - Handle real-time updates
    # -------------------------------------------------------------------------

    @impl true
    def handle_info({:progress_update, percentage}, socket) do
      {:noreply, assign(socket, :percentage, percentage)}
    end

    @impl true
    def handle_info({:activity_added, activity}, socket) do
      activities = [activity | socket.assigns.activities || []]
      {:noreply, assign(socket, :activities, activities)}
    end

    # -------------------------------------------------------------------------
    # PRIVATE HELPERS
    # -------------------------------------------------------------------------

    defp activity_badge(:running), do: "badge badge-primary badge-xs"
    defp activity_badge(:completed), do: "badge badge-success badge-xs"
    defp activity_badge(:error), do: "badge badge-error badge-xs"
    defp activity_badge(_), do: "badge badge-outline badge-xs"
  end

  # Usage in LiveView:
  # <.live_component
  #   module={ProgressWidget}
  #   id="progress-1"
  #   title="Processing"
  #   subtitle="Agent is working"
  #   percentage={45}
  #   is_live={true}
  #   activities={@activities}
  # />

  # ============================================================================
  # COMPONENT COMMUNICATION PATTERNS
  # ============================================================================

  defmodule SidebarComponent do
    @moduledoc """
    LiveComponent that communicates with parent LiveView.

    Based on: lib/my_app_web/components/sidebar.ex
    """

    use MyAppWeb, :live_component

    @impl true
    def render(assigns) do
      ~H"""
      <aside class="w-64 bg-base-200 p-4">
        <nav class="space-y-2">
          <button
            class="btn btn-ghost w-full justify-start"
            phx-click="navigate_home"
            phx-target={@myself}
          >
            Home
          </button>

          <button
            class="btn btn-ghost w-full justify-start"
            phx-click="navigate_settings"
            phx-target={@myself}
          >
            Settings
          </button>
        </nav>
      </aside>
      """
    end

    @impl true
    def handle_event("navigate_home", _params, socket) do
      # ✅ CORRECT: Send message to parent LiveView
      send(self(), {:sidebar_event, :navigate_home})
      {:noreply, socket}
    end

    @impl true
    def handle_event("navigate_settings", _params, socket) do
      # ✅ CORRECT: Send message to parent LiveView
      send(self(), {:sidebar_event, :navigate_settings})
      {:noreply, socket}
    end
  end

  # In Parent LiveView:
  # @impl true
  # def handle_info({:sidebar_event, :navigate_home}, socket) do
  #   {:noreply, push_navigate(socket, to: ~p"/home")}
  # end

  # ============================================================================
  # SHARED BEHAVIORS PATTERN
  # ============================================================================

  defmodule SharedBehaviors do
    @moduledoc """
    Reusable behavior functions for LiveViews.

    Based on: lib/my_app_web/live/behaviors/agent_progress_handlers.ex
    """

    @doc """
    Handle PubSub event for progress update.

    This function can be called from any LiveView:

    @impl true
    def handle_info({:progress_update, data}, socket) do
      {:noreply, SharedBehaviors.handle_progress_update(socket, data)}
    end
    """
    def handle_progress_update(socket, %{percentage: percentage, message: message}) do
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget[:type] == :progress && widget[:is_live] do
            widget
            |> Map.put(:percentage, percentage)
            |> Map.put(:message, message)
          else
            widget
          end
        end)

      Phoenix.Component.assign(socket, :widgets, widgets)
    end

    @doc """
    Update specific widget by ID.
    """
    def update_widget(socket, widget_id, updates) do
      widgets =
        Enum.map(socket.assigns.widgets, fn widget ->
          if widget[:id] == widget_id do
            Map.merge(widget, updates)
          else
            widget
          end
        end)

      Phoenix.Component.assign(socket, :widgets, widgets)
    end
  end
end

# ============================================================================
# COMPONENT BEST PRACTICES
# ============================================================================

defmodule Examples.ComponentBestPractices do
  @moduledoc """
  Guidelines for component design.
  """

  # ✅ GOOD: Function component for simple UI
  # - Stateless
  # - Pure function
  # - Fast rendering
  def good_function_component(assigns) do
    ~H"""
    <div class="badge badge-primary">{@label}</div>
    """
  end

  # ✅ GOOD: LiveComponent for stateful features
  # - Needs local state
  # - Handles events
  # - Real-time updates
  defmodule GoodLiveComponent do
    use Phoenix.LiveComponent

    @impl true
    def update(assigns, socket) do
      {:ok, assign(socket, assigns)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <button phx-click="increment" phx-target={@myself}>
          Count: {@count}
        </button>
      </div>
      """
    end

    @impl true
    def handle_event("increment", _, socket) do
      {:noreply, update(socket, :count, &(&1 + 1))}
    end
  end

  # ❌ AVOID: LiveComponent for simple static UI
  # Unnecessarily complex - use function component instead
  defmodule OverlyComplexComponent do
    use Phoenix.LiveComponent

    @impl true
    def render(assigns) do
      ~H"""
      <div class="badge">{@label}</div>
      """
    end
  end
end
