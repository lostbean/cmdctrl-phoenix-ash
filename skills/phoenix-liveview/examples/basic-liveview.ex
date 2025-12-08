defmodule Examples.BasicLiveView do
  @moduledoc """
  Basic LiveView structure and lifecycle.

  This example shows:
  - Mount with authentication
  - Render with HEEx templates
  - Event handling
  - Assigns management
  - Navigation

  Based on patterns from: lib/my_app_web/live/dashboard_live.ex
  """

  use MyAppWeb, :live_view

  # Authentication hook (required for all authenticated pages)
  on_mount {MyAppWeb.LiveUserAuth, :live_user_required}

  # ============================================================================
  # MOUNT - Initialize LiveView state
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    # ✅ CORRECT: Check authentication
    if is_nil(current_user) do
      {:ok, socket |> redirect(to: ~p"/sign-in")}
    else
      # Load data with actor context
      actor = build_actor(current_user)

      case load_page_data(actor) do
        {:ok, data} ->
          {:ok,
           socket
           |> assign(:page_title, "Dashboard")
           |> assign(:current_user, current_user)
           |> assign(:data, data)
           |> assign(:loading, false)}

        {:error, reason} ->
          {:ok,
           socket
           |> put_flash(:error, "Failed to load data: #{reason}")
           |> redirect(to: ~p"/home")}
      end
    end
  end

  # ============================================================================
  # RENDER - Generate HTML
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <%!-- Header --%>
      <header class="mb-8">
        <h1 class="text-3xl font-semibold">{@page_title}</h1>
        <p class="text-base-content/60">Welcome, {@current_user.name}</p>
      </header>

      <%!-- Flash Messages --%>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <%!-- Main Content --%>
      <%= if @loading do %>
        <div class="flex justify-center">
          <span class="loading loading-spinner loading-lg"></span>
        </div>
      <% else %>
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Data Summary</h2>
            <p>Total items: {@data.count}</p>

            <%!-- Action Buttons --%>
            <div class="card-actions justify-end mt-4">
              <button class="btn btn-primary" phx-click="refresh">
                Refresh
              </button>
              <.link navigate={~p"/detail"} class="btn btn-outline">
                View Details
              </.link>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # EVENT HANDLERS - User interactions
  # ============================================================================

  @impl true
  def handle_event("refresh", _params, socket) do
    # Set loading state
    socket = assign(socket, :loading, true)

    # Load fresh data
    actor = build_actor(socket.assigns.current_user)

    case load_page_data(actor) do
      {:ok, data} ->
        {:noreply,
         socket
         |> assign(:data, data)
         |> assign(:loading, false)
         |> put_flash(:info, "Data refreshed successfully")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "Failed to refresh: #{reason}")}
    end
  end

  # ============================================================================
  # PRIVATE HELPERS
  # ============================================================================

  defp load_page_data(actor) do
    # ✅ CORRECT: Always pass actor for authorization
    # ❌ WRONG: Never use authorize?: false in production
    case MyApp.SomeResource
         |> Ash.read(actor: actor) do
      {:ok, results} ->
        {:ok, %{count: length(results), items: results}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_actor(user) do
    %{
      user: user,
      organization_id: user.organization_id
    }
  end
end

# ============================================================================
# COMMON PATTERNS
# ============================================================================

defmodule Examples.LiveViewPatterns do
  @moduledoc """
  Common LiveView patterns used in MyApp.
  """

  # Pattern 1: Conditional Rendering
  def conditional_rendering(assigns) do
    ~H"""
    <%!-- Using if --%>
    <%= if @show_content do %>
      <div>Content visible</div>
    <% end %>

    <%!-- Using if/else --%>
    <%= if @loading do %>
      <span class="loading loading-spinner"></span>
    <% else %>
      <div>{@content}</div>
    <% end %>

    <%!-- Using :if attribute (Phoenix 1.7+) --%>
    <div :if={@condition}>Conditional element</div>
    """
  end

  # Pattern 2: List Rendering
  def list_rendering(assigns) do
    ~H"""
    <%!-- Enumerate with comprehension --%>
    <%= for item <- @items do %>
      <div class="card">
        <div class="card-body">
          <h3>{item.name}</h3>
        </div>
      </div>
    <% end %>

    <%!-- Empty state --%>
    <%= if Enum.empty?(@items) do %>
      <div class="text-center">
        <p>No items found</p>
      </div>
    <% end %>
    """
  end

  # Pattern 3: Dynamic Classes
  def dynamic_classes(assigns) do
    ~H"""
    <%!-- Conditional class --%>
    <button class={[
      "btn",
      if(@primary, do: "btn-primary", else: "btn-outline")
    ]}>
      Click me
    </button>

    <%!-- Multiple conditions --%>
    <div class={[
      "card",
      @highlighted && "border-primary",
      @error && "border-error",
      @disabled && "opacity-50"
    ]}>
      Content
    </div>
    """
  end

  # Pattern 4: Navigation
  def navigation_patterns(assigns) do
    ~H"""
    <%!-- Link component (client-side navigation) --%>
    <.link navigate={~p"/path"} class="btn">
      Navigate
    </.link>

    <%!-- Patch (update params without remount) --%>
    <.link patch={~p"/path?tab=settings"} class="btn">
      Settings
    </.link>

    <%!-- External link --%>
    <.link href="https://example.com" class="btn">
      External
    </.link>

    <%!-- Programmatic navigation in LiveView --%>
    <%!-- socket |> push_navigate(to: ~p"/path") --%>
    <%!-- socket |> push_patch(to: ~p"/path") --%>
    <%!-- socket |> redirect(to: ~p"/path") --%>
    """
  end
end

# ============================================================================
# ANTI-PATTERNS (What NOT to do)
# ============================================================================

defmodule Examples.LiveViewAntiPatterns do
  @moduledoc """
  Common mistakes to avoid.
  """

  # ❌ WRONG: Business logic in LiveView
  def handle_event("complex_operation", params, socket) do
    # DON'T: Put complex logic directly in event handler
    result = perform_complex_calculation(params)
    validated = validate_business_rules(result)
    transformed = transform_data(validated)

    {:noreply, assign(socket, :data, transformed)}
  end

  # ✅ CORRECT: Delegate to helper module
  def handle_event_correct("complex_operation", params, socket) do
    # DO: Use helper module for business logic
    case MyHelper.perform_operation(params, socket.assigns.user) do
      {:ok, result} ->
        {:noreply, assign(socket, :data, result)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  # ❌ WRONG: Missing actor context
  def load_data_wrong do
    # DON'T: Bypass authorization
    MyApp.SomeResource
    |> Ash.read(authorize?: false)
  end

  # ✅ CORRECT: Always pass actor
  def load_data_correct(user) do
    # DO: Always include actor
    actor = %{user: user, organization_id: user.organization_id}

    MyApp.SomeResource
    |> Ash.read(actor: actor)
  end

  # ❌ WRONG: Forgetting connected? check
  def mount_wrong(_params, _session, socket) do
    # DON'T: Subscribe without checking connection
    Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
    {:ok, socket}
  end

  # ✅ CORRECT: Check if socket is connected
  def mount_correct(_params, _session, socket) do
    # DO: Only subscribe on websocket connection
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
    end

    {:ok, socket}
  end
end
