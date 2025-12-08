# LiveView + DaisyUI Integration

Guide to integrating DaisyUI components with Phoenix LiveView in your project.

## Overview

Phoenix LiveView and DaisyUI work seamlessly together. LiveView handles
server-side state and real-time updates, while DaisyUI provides the UI
components.

**Related Files:**

- DaisyUI Components: `daisyui.md`
- JavaScript Hooks: See skill examples directory
- LiveView Patterns: See phoenix-liveview skill
- Core Components: See your application's core components module

## Phoenix Attributes (phx-\*)

### phx-click (Click Events)

```html
<!-- Basic click event -->
<button class="btn btn-primary" phx-click="save_changes">Save</button>

<!-- Click with value -->
<button class="btn btn-ghost" phx-click="delete_item" phx-value-id="{@item.id}">
  Delete
</button>

<!-- Click with multiple values -->
<button
  phx-click="update_status"
  phx-value-id="{@item.id}"
  phx-value-status="active"
>
  Activate
</button>
```

**LiveView Handler:**

```elixir
def handle_event("save_changes", _params, socket) do
  {:noreply, socket}
end

def handle_event("delete_item", %{"id" => id}, socket) do
  {:noreply, socket}
end
```

### phx-change (Input Changes)

```html
<!-- Input with change event -->
<input
  type="text"
  class="input input-bordered"
  phx-change="search"
  name="query"
  value="{@search_query}"
/>

<!-- With debounce -->
<input
  type="search"
  class="input input-bordered input-sm"
  placeholder="Search..."
  phx-change="search"
  phx-debounce="300"
  name="query"
/>

<!-- Select with change -->
<select class="select select-bordered" phx-change="filter_status" name="status">
  <option value="all">All</option>
  <option value="active">Active</option>
</select>
```

**LiveView Handler:**

```elixir
def handle_event("search", %{"query" => query}, socket) do
  {:noreply, assign(socket, :search_query, query)}
end
```

### phx-submit (Form Submission)

```html
<!-- Form with submit -->
<.form for={@form} phx-submit="save" class="space-y-4">
  <.input field={@form[:name]} type="text" label="Name" />
  <.input field={@form[:email]} type="email" label="Email" />

  <div class="flex gap-2 justify-end">
    <button type="button" class="btn btn-ghost" phx-click="cancel">
      Cancel
    </button>
    <button type="submit" class="btn btn-primary">
      Save
    </button>
  </div>
</.form>
```

**LiveView Handler:**

```elixir
def handle_event("save", %{"form_data" => params}, socket) do
  # Process form data
  {:noreply, socket}
end
```

### phx-blur, phx-focus

```html
<!-- Focus events -->
<input
  type="text"
  class="input input-bordered"
  phx-focus="input_focused"
  phx-blur="input_blurred"
/>
```

### phx-keydown, phx-keyup

```html
<!-- Key events -->
<input
  type="text"
  class="input input-bordered"
  phx-keydown="key_pressed"
  phx-key="Enter"
/>

<!-- Escape key to close -->
<textarea phx-keydown="handle_key" phx-key="Escape"></textarea>
```

## Dynamic Classes

### Conditional Classes with String Interpolation

```html
<!-- Loading state -->
<button class={"btn #{if @loading, do: "loading", else: "btn-primary"}"}>
  Submit
</button>

<!-- Status badge -->
<span class={"badge #{if @active, do: "badge-success", else: "badge-ghost"}"}>
  {@status}
</span>

<!-- Multiple conditions -->
<button class={[
  "btn",
  @loading && "loading",
  @disabled && "btn-disabled",
  !@loading && !@disabled && "btn-primary"
]}>
  Submit
</button>
```

### Array Syntax for Dynamic Classes

```html
<!-- Cleaner array syntax -->
<div class={[
  "alert",
  @type == :info && "alert-info",
  @type == :success && "alert-success",
  @type == :error && "alert-error"
]}>
  {@message}
</div>

<!-- Table row highlighting (from core_components.ex) -->
<button class={[
  "w-full text-left px-3 py-2 rounded-lg transition-colors",
  @selected && "bg-primary/10 border border-primary/20",
  !@selected && "hover:bg-base-200"
]} phx-click="select">
  {@label}
</button>
```

### Map-Based Class Variants (from core_components.ex)

```elixir
# In component
def button(%{rest: rest} = assigns) do
  variants = %{
    "primary" => "btn-primary",
    "secondary" => "btn-secondary",
    nil => "btn-primary btn-soft"
  }

  assigns =
    assign_new(assigns, :class, fn ->
      ["btn", Map.fetch!(variants, assigns[:variant])]
    end)

  ~H"""
  <button class={@class} {@rest}>
    {render_slot(@inner_block)}
  </button>
  """
end
```

**Usage:**

```html
<.button variant="primary">Save</.button>
<.button variant="secondary">Cancel</.button>
```

## Buttons with LiveView

### Basic Button Events

```html
<!-- Save button -->
<button class="btn btn-primary" phx-click="save_changes">
  Save Changes
</button>

<!-- Button with loading state -->
<button
  class="btn btn-primary"
  phx-click="submit_form"
  disabled={@loading}
>
  <%= if @loading do %>
    <span class="loading loading-spinner loading-sm"></span>
    Processing...
  <% else %>
    Submit
  <% end %>
</button>

<!-- Button group with active state -->
<div class="join">
  <%= for tab <- @tabs do %>
    <button
      class={["btn join-item", @active_tab == tab && "btn-primary"]}
      phx-click="switch_tab"
      phx-value-tab={tab}
    >
      {tab}
    </button>
  <% end %>
</div>
```

### Disabled States

```html
<!-- Disabled based on socket state (from sidebar.ex) -->
<button
  class="btn btn-primary btn-sm w-full"
  phx-click="save_draft"
  disabled="{@draft_status"
  !=":active"
  or
  not
  @has_changes}
>
  Save version
</button>

<!-- Multiple disable conditions -->
<button
  class="btn btn-primary"
  disabled="{@loading"
  or
  @invalid
  or
  !@has_changes}
>
  Save
</button>
```

## Forms with LiveView

### Form Component Integration

```html
<!-- Using Phoenix.Component.form -->
<.form
  for={@form}
  phx-submit="save"
  phx-change="validate"
  class="space-y-4"
>
  <.input
    field={@form[:name]}
    type="text"
    label="Name"
  />

  <.input
    field={@form[:email]}
    type="email"
    label="Email"
    placeholder="you@example.com"
  />

  <.input
    field={@form[:role]}
    type="select"
    label="Role"
    options={["Admin", "Member", "Guest"]}
  />

  <div class="flex justify-end gap-2">
    <button type="button" class="btn btn-ghost" phx-click="cancel">
      Cancel
    </button>
    <button type="submit" class="btn btn-primary">
      Save
    </button>
  </div>
</.form>
```

### Validation States

```html
<!-- Input with error state (from core_components.ex) -->
<.input
  field={@form[:username]}
  type="text"
  label="Username"
/>

<!-- The core component automatically adds error styling when errors exist -->
<!-- Generated HTML: -->
<input
  type="text"
  class={[
    "w-full input",
    @errors != [] && "input-error"
  ]}
/>
```

### LiveView Handlers

```elixir
def handle_event("validate", %{"user" => params}, socket) do
  changeset =
    %User{}
    |> User.changeset(params)
    |> Map.put(:action, :validate)

  {:noreply, assign_form(socket, changeset)}
end

def handle_event("save", %{"user" => params}, socket) do
  case create_user(params, actor: socket.assigns.current_user) do
    {:ok, user} ->
      {:noreply,
       socket
       |> put_flash(:info, "User created successfully")
       |> push_navigate(to: ~p"/users/#{user.id}")}

    {:error, changeset} ->
      {:noreply, assign_form(socket, changeset)}
  end
end
```

## Modals with LiveView

### Modal Control Pattern

```html
<!-- Modal in template -->
<dialog id="confirmation_modal" class="modal" phx-hook="Modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Confirm Action</h3>
    <p class="py-4">Are you sure?</p>
    <div class="modal-action">
      <button class="btn btn-ghost" phx-click="close_modal">Cancel</button>
      <button class="btn btn-error" phx-click="confirm_action">Confirm</button>
    </div>
  </div>
</dialog>

<!-- Trigger -->
<button class="btn btn-primary" phx-click="show_confirmation">Delete</button>
```

**LiveView Handlers:**

```elixir
def handle_event("show_confirmation", _params, socket) do
  {:noreply, push_event(socket, "show_modal", %{id: "confirmation_modal"})}
end

def handle_event("close_modal", _params, socket) do
  {:noreply, push_event(socket, "close_modal", %{id: "confirmation_modal"})}
end

def handle_event("confirm_action", _params, socket) do
  # Perform action
  {:noreply,
   socket
   |> push_event("close_modal", %{id: "confirmation_modal"})
   |> put_flash(:info, "Action completed")}
end
```

### Modal with Form

```html
<dialog id="create_modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Create New Item</h3>

    <.form for={@form} phx-submit="create_item" class="py-4">
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:description]} type="textarea" label="Description" />

      <div class="modal-action">
        <button
          type="button"
          class="btn btn-ghost"
          phx-click="close_create_modal"
        >
          Cancel
        </button>
        <button type="submit" class="btn btn-primary">
          Create
        </button>
      </div>
    </.form>
  </div>
</dialog>
```

## Tables with LiveView

### Core Component Table

```html
<!-- From core_components.ex -->
<.table id="users" rows={@users}>
  <:col :let={user} label="Name">{user.name}</:col>
  <:col :let={user} label="Email">{user.email}</:col>
  <:col :let={user} label="Status">
    <span class={[
      "badge",
      user.active && "badge-success",
      !user.active && "badge-ghost"
    ]}>
      {if user.active, do: "Active", else: "Inactive"}
    </span>
  </:col>
  <:action :let={user}>
    <button
      class="btn btn-ghost btn-sm"
      phx-click="edit_user"
      phx-value-id={user.id}
    >
      Edit
    </button>
  </:action>
  <:action :let={user}>
    <button
      class="btn btn-ghost btn-sm"
      phx-click="delete_user"
      phx-value-id={user.id}
      data-confirm="Are you sure?"
    >
      Delete
    </button>
  </:action>
</.table>
```

### Clickable Rows

```html
<.table
  id="models"
  rows={@models}
  row_click={fn model -> JS.navigate(~p"/model/#{model.id}") end}
>
  <:col :let={model} label="Name">{model.name}</:col>
  <:col :let={model} label="Version">v{model.version}</:col>
</.table>
```

### LiveView Streams (Efficient Updates)

```html
<!-- Table with streams for efficient updates -->
<.table id="stream-table" rows={@streams.items}>
  <:col :let={{_id, item}} label="Name">{item.name}</:col>
  <:col :let={{_id, item}} label="Value">{item.value}</:col>
  <:action :let={{id, _item}}>
    <button
      class="btn btn-ghost btn-sm"
      phx-click="delete"
      phx-value-id={id}
    >
      Delete
    </button>
  </:action>
</.table>
```

**LiveView Setup:**

```elixir
def mount(_params, _session, socket) do
  {:ok, stream(socket, :items, load_items())}
end

def handle_event("delete", %{"id" => id}, socket) do
  delete_item(id)
  {:noreply, stream_delete(socket, :items, id)}
end
```

## JavaScript Hooks

### Common Hooks from Project

```html
<!-- Scroll to bottom (chat messages) -->
<div id="messages" phx-hook="ScrollToBottom" class="overflow-y-auto h-96">
  <%= for message <- @messages do %>
  <div>{message.text}</div>
  <% end %>
</div>

<!-- Copy to clipboard -->
<div phx-hook="CopyToClipboard">
  <button
    class="btn btn-ghost btn-sm"
    phx-click="copy_sql"
    phx-value-sql="{@sql}"
  >
    <.icon name="hero-clipboard" class="w-4 h-4" /> Copy SQL
  </button>
</div>

<!-- Download data -->
<div phx-hook="DownloadData">
  <button class="btn btn-primary" phx-click="download_csv">Download CSV</button>
</div>
```

**LiveView Handlers:**

```elixir
def handle_event("copy_sql", %{"sql" => sql}, socket) do
  {:noreply, push_event(socket, "copy_to_clipboard", %{text: sql})}
end

def handle_event("download_csv", _params, socket) do
  csv_data = generate_csv(socket.assigns.results)

  {:noreply,
   push_event(socket, "download_data", %{
     data: csv_data,
     filename: "results.csv",
     type: "text/csv"
   })}
end
```

**Full Hook Examples:** See skill examples directory

## Real-time Updates with PubSub

### Subscribe to Updates

```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "resources")
  end

  {:ok, assign(socket, :resources, load_resources())}
end

def handle_info({:resource_updated, resource}, socket) do
  # Update specific resource in assigns
  updated_resources =
    Enum.map(socket.assigns.resources, fn r ->
      if r.id == resource.id, do: resource, else: r
    end)

  {:noreply, assign(socket, :resources, updated_resources)}
end
```

### Live Updates UI Pattern

```html
<!-- Status indicator that updates in real-time -->
<div class="flex items-center gap-2">
  <span class={[
    "badge",
    @connection_status == :connected && "badge-success",
    @connection_status == :connecting && "badge-warning",
    @connection_status == :disconnected && "badge-error"
  ]}>
    {@connection_status}
  </span>

  <%= if @connection_status == :connecting do %>
    <span class="loading loading-spinner loading-sm"></span>
  <% end %>
</div>
```

## Live Navigation

### push_navigate vs push_patch

```html
<!-- push_navigate - Full LiveView mount (different LiveView) -->
<.link navigate={~p"/resources"} class="btn btn-primary">
  View Resources
</.link>

<!-- push_patch - Same LiveView, update params -->
<.link patch={~p"/model/#{@model.id}/version/#{@version}"} class="btn btn-ghost">
  View Version {@version}
</.link>
```

**In LiveView:**

```elixir
# navigate - triggers mount/3
def handle_event("go_to_resources", _params, socket) do
  {:noreply, push_navigate(socket, to: ~p"/resources")}
end

# patch - triggers handle_params/3
def handle_event("select_version", %{"version" => v}, socket) do
  {:noreply, push_patch(socket, to: ~p"/model/#{@model.id}/version/#{v}")}
end
```

## Flash Messages

### Setting Flash

```elixir
def handle_event("save", params, socket) do
  case save_data(params) do
    {:ok, _} ->
      {:noreply,
       socket
       |> put_flash(:info, "Saved successfully")
       |> push_navigate(to: ~p"/success")}

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Failed to save")}
  end
end
```

### Flash Component (from core_components.ex)

```html
<!-- In layout -->
<.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
```

The flash component uses DaisyUI alerts with toast positioning.

## Best Practices

### ✅ Do

- Use phx-debounce for search inputs (300ms typical)
- Show loading states for async operations
- Disable buttons during processing to prevent double-clicks
- Use phx-update="ignore" for static content (charts, maps)
- Subscribe to PubSub only when `connected?(socket)` is true
- Use LiveView streams for large, frequently updated lists
- Provide visual feedback for all user actions

### ❌ Don't

- Don't forget to handle loading and error states
- Don't bypass authorization with `authorize?: false`
- Don't use Alpine.js when LiveView can handle it
- Don't forget to unsubscribe from PubSub topics when unmounting
- Don't use inline onclick/onchange when phx-\* attributes work
- Don't reload the page when LiveView can handle updates

## Common Patterns from Project

### Context Switching

```html
<div class="join w-full">
  <.link
    navigate={~p"/model/#{@model_uuid}/version/#{@version_number}/view"}
    class="btn join-item flex-1"
  >
    View
  </.link>
  <button class="btn join-item btn-primary flex-1">Edit</button>
</div>
```

### Filters with Live Updates

```html
<label class="form-control">
  <div class="label">
    <span class="label-text text-xs uppercase">Search</span>
  </div>
  <input
    type="search"
    class="input input-bordered input-sm"
    placeholder="Search resources..."
    value="{@search_query}"
    phx-change="search"
    phx-debounce="300"
    name="query"
  />
</label>
```

### Dynamic Badge Status

```html
<span class={"badge #{draft_status_badge_class(@draft_status)}"}>
  {format_draft_status(@draft_status)}
</span>
```

```elixir
# Helper functions
defp draft_status_badge_class(:active), do: "badge-info"
defp draft_status_badge_class(:saved), do: "badge-success"
defp draft_status_badge_class(:discarded), do: "badge-error"
```

## Related Documentation

- **DaisyUI Components**: `daisyui.md` - Component reference
- **TailwindCSS**: `tailwind.md` - Utility classes
- **JavaScript Hooks**: See skill examples directory for hook implementations
- **LiveView Skill**: See phoenix-liveview skill for more patterns
- **Core Components**: See your application's core components module
- **Widget Architecture**: See your project's design documentation
