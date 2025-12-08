# Forms Reference

Form handling patterns in Phoenix LiveView.

## Overview

Phoenix LiveView provides multiple approaches to form handling:

1. **Simple forms** - Basic text inputs with phx-submit
2. **Map-based forms** - Using `to_form/2` with plain maps
3. **Ash changeset forms** - Using AshPhoenix.Form with Ash resources
4. **File uploads** - LiveView upload system
5. **Dynamic forms** - Add/remove fields

## Simple Forms

### Basic Text Input

```elixir
defmodule ChatLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :input, "")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form phx-submit="send_message">
      <textarea
        name="message"
        class="textarea textarea-bordered w-full"
        placeholder="Type a message..."
        phx-debounce="200"
      >{@input}</textarea>

      <button type="submit" class="btn btn-primary">
        Send
      </button>
    </form>
    """
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket)
      when byte_size(message) > 0 do
    # Process message...
    {:noreply, assign(socket, :input, "")}
  end

  @impl true
  def handle_event("send_message", _params, socket) do
    # Empty message - do nothing
    {:noreply, socket}
  end
end
```

### Key Attributes

- `phx-submit` - Handle form submission
- `phx-change` - Handle input changes (optional)
- `phx-debounce` - Debounce input events (milliseconds)
- `phx-throttle` - Throttle input events

## Map-Based Forms

### Using to_form/2

Good for configuration forms and simple data:

```elixir
defmodule ConfigLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Create form from plain map
    form_data = %{
      "name" => "My Connection",
      "host" => "localhost",
      "port" => "5432"
    }

    {:ok,
     socket
     |> assign(:form, to_form(form_data, as: "config"))
     |> assign(:editing, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-4">
      <div class="form-control">
        <label class="label">
          <span class="label-text">Name</span>
        </label>
        <.input field={@form[:name]} type="text" class="input input-bordered" />
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text">Host</span>
        </label>
        <.input field={@form[:host]} type="text" class="input input-bordered" />
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text">Port</span>
        </label>
        <.input field={@form[:port]} type="text" class="input input-bordered" />
      </div>

      <button type="submit" class="btn btn-primary">
        Save Configuration
      </button>
    </.form>
    """
  end

  @impl true
  def handle_event("validate", %{"config" => params}, socket) do
    # Optional: validate on change
    form = to_form(params, as: "config")
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"config" => params}, socket) do
    # Save configuration...
    case save_config(params) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Configuration saved")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed: #{reason}")}
    end
  end

  defp save_config(_params), do: {:ok, %{}}
end
```

## Ash Changeset Forms

### Using AshPhoenix.Form

Recommended for creating/updating Ash resources:

```elixir
defmodule DataSourceLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    actor = build_actor(user)

    # Create form for Ash resource
    form =
      AshPhoenix.Form.for_create(
        MyApp.DataPipeline.DataSource,
        :create,
        api: MyApp.DataPipeline,
        actor: actor,
        as: "data_source"
      )

    {:ok,
     socket
     |> assign(:form, to_form(form))
     |> assign(:submitting, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form for={@form} phx-submit="create" phx-change="validate" class="space-y-4">
      <%!-- Name field --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text">Name *</span>
        </label>
        <.input
          field={@form[:name]}
          type="text"
          class="input input-bordered w-full"
          placeholder="My Data Source"
        />
        <.error :for={msg <- Enum.map(@form[:name].errors, &translate_error(&1))}>
          {msg}
        </.error>
      </div>

      <%!-- Source type select --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text">Source Type *</span>
        </label>
        <.input
          field={@form[:source_type]}
          type="select"
          options={[
            {"PostgreSQL Table", "postgres_table"},
            {"CSV File", "csv_file"}
          ]}
          class="select select-bordered w-full"
        />
      </div>

      <button type="submit" class="btn btn-primary" disabled={@submitting}>
        {if @submitting, do: "Creating...", else: "Create Data Source"}
      </button>
    </.form>
    """
  end

  @impl true
  def handle_event("validate", %{"data_source" => params}, socket) do
    user = socket.assigns.current_user
    actor = build_actor(user)

    form =
      AshPhoenix.Form.for_create(
        MyApp.DataPipeline.DataSource,
        :create,
        api: MyApp.DataPipeline,
        actor: actor,
        params: params,
        as: "data_source"
      )
      |> AshPhoenix.Form.validate(params)

    {:noreply, assign(socket, :form, to_form(form))}
  end

  @impl true
  def handle_event("create", %{"data_source" => params}, socket) do
    user = socket.assigns.current_user
    actor = build_actor(user)

    socket = assign(socket, :submitting, true)

    case MyApp.DataPipeline.DataSource
         |> Ash.Changeset.for_create(:create, params, actor: actor)
         |> Ash.create() do
      {:ok, data_source} ->
        {:noreply,
         socket
         |> put_flash(:info, "Data source created")
         |> push_navigate(to: ~p"/data-sources/#{data_source.id}")}

      {:error, changeset} ->
        form =
          AshPhoenix.Form.for_create(
            MyApp.DataPipeline.DataSource,
            :create,
            api: MyApp.DataPipeline,
            actor: actor,
            params: params,
            errors: changeset.errors,
            as: "data_source"
          )

        {:noreply,
         socket
         |> assign(:submitting, false)
         |> assign(:form, to_form(form))
         |> put_flash(:error, "Please fix the errors below")}
    end
  end

  defp build_actor(user) do
    %{user: user, organization_id: user.organization_id}
  end

  defp translate_error({msg, _opts}), do: msg
end
```

## File Uploads

### LiveView Upload System

```elixir
defmodule UploadLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:csv_file,
       accept: ~w(.csv),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-8">
      <h1 class="text-2xl font-bold mb-6">Upload CSV File</h1>

      <form phx-submit="upload" phx-change="validate_upload" class="space-y-4">
        <%!-- File input with drag & drop --%>
        <div
          class="border-2 border-dashed border-base-300 rounded-lg p-8 text-center"
          phx-drop-target={@uploads.csv_file.ref}
        >
          <.live_file_input upload={@uploads.csv_file} class="file-input file-input-bordered" />

          <p class="text-sm text-base-content/60 mt-2">
            or drag and drop CSV file here
          </p>
        </div>

        <%!-- Preview selected files --%>
        <%= for entry <- @uploads.csv_file.entries do %>
          <div class="card bg-base-200 p-4">
            <div class="flex items-center gap-2">
              <span class="flex-1">{entry.client_name}</span>
              <span class="text-sm">{format_bytes(entry.client_size)}</span>
              <button
                type="button"
                class="btn btn-ghost btn-xs"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
              >
                ✕
              </button>
            </div>

            <%!-- Progress bar --%>
            <progress class="progress progress-primary w-full mt-2" value={entry.progress} max="100">
              {entry.progress}%
            </progress>

            <%!-- Errors --%>
            <%= for err <- upload_errors(@uploads.csv_file, entry) do %>
              <p class="text-error text-sm mt-2">{error_to_string(err)}</p>
            <% end %>
          </div>
        <% end %>

        <button
          type="submit"
          class="btn btn-primary"
          disabled={@uploads.csv_file.entries == []}
        >
          Upload
        </button>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :csv_file, ref)}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :csv_file, fn %{path: path}, entry ->
        # Copy file to permanent location
        dest = Path.join("uploads", entry.client_name)
        File.cp!(path, dest)

        {:ok, %{name: entry.client_name, path: dest}}
      end)

    {:noreply,
     socket
     |> update(:uploaded_files, &(&1 ++ uploaded_files))
     |> put_flash(:info, "File uploaded successfully")}
  end

  defp format_bytes(bytes) when bytes >= 1_000_000,
    do: "#{Float.round(bytes / 1_000_000, 1)} MB"

  defp format_bytes(bytes) when bytes >= 1_000,
    do: "#{Float.round(bytes / 1_000, 1)} KB"

  defp format_bytes(bytes), do: "#{bytes} bytes"

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:not_accepted), do: "Invalid file type"
  defp error_to_string(_), do: "Upload error"
end
```

## Dynamic Forms

### Add/Remove Fields

```elixir
defmodule DynamicFieldsLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:fields, [%{id: 1, name: "", value: ""}])
     |> assign(:next_id, 2)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form phx-submit="save" class="space-y-4">
      <%= for field <- @fields do %>
        <div class="flex gap-2" id={"field-#{field.id}"}>
          <input
            type="text"
            name={"field[#{field.id}][name]"}
            value={field.name}
            placeholder="Field name"
            class="input input-bordered flex-1"
          />

          <input
            type="text"
            name={"field[#{field.id}][value]"}
            value={field.value}
            placeholder="Field value"
            class="input input-bordered flex-1"
          />

          <button
            type="button"
            class="btn btn-ghost"
            phx-click="remove_field"
            phx-value-id={field.id}
          >
            ✕
          </button>
        </div>
      <% end %>

      <div class="flex gap-2">
        <button type="button" class="btn btn-outline" phx-click="add_field">
          + Add Field
        </button>

        <button type="submit" class="btn btn-primary">
          Save
        </button>
      </div>
    </form>
    """
  end

  @impl true
  def handle_event("add_field", _params, socket) do
    new_field = %{id: socket.assigns.next_id, name: "", value: ""}

    {:noreply,
     socket
     |> update(:fields, &(&1 ++ [new_field]))
     |> update(:next_id, &(&1 + 1))}
  end

  @impl true
  def handle_event("remove_field", %{"id" => id}, socket) do
    id = String.to_integer(id)

    {:noreply, update(socket, :fields, &Enum.reject(&1, fn f -> f.id == id end))}
  end

  @impl true
  def handle_event("save", %{"field" => fields}, socket) do
    # Process fields...
    {:noreply, put_flash(socket, :info, "Fields saved")}
  end
end
```

## Validation Patterns

### Client-side Validation

Use HTML5 validation:

```heex
<input
  type="email"
  required
  pattern="[^@]+@[^@]+\.[^@]+"
  class="input input-bordered"
/>

<input
  type="number"
  min="0"
  max="100"
  class="input input-bordered"
/>
```

### Server-side Validation

Validate on change:

```elixir
@impl true
def handle_event("validate", %{"form" => params}, socket) do
  errors = validate_params(params)

  form =
    params
    |> Map.put("errors", errors)
    |> to_form(as: "form")

  {:noreply, assign(socket, :form, form)}
end

defp validate_params(params) do
  errors = []

  errors =
    if String.length(params["name"] || "") < 3 do
      [name: "must be at least 3 characters"] ++ errors
    else
      errors
    end

  errors =
    if String.length(params["email"] || "") == 0 do
      [email: "is required"] ++ errors
    else
      errors
    end

  errors
end
```

## Best Practices

### 1. Always Validate Input

```elixir
# ✅ Good - validate before processing
def handle_event("submit", %{"message" => msg}, socket)
    when byte_size(msg) > 0 do
  # Process message
end

def handle_event("submit", _params, socket) do
  # Invalid - do nothing or show error
  {:noreply, socket}
end
```

### 2. Use phx-debounce

```heex
<!-- ✅ Good - debounce search input -->
<input
  type="text"
  phx-change="search"
  phx-debounce="300"
/>

<!-- ❌ Bad - fires on every keystroke -->
<input
  type="text"
  phx-change="search"
/>
```

### 3. Show Loading State

```elixir
@impl true
def handle_event("submit", params, socket) do
  socket = assign(socket, :submitting, true)

  case process_form(params) do
    {:ok, result} ->
      {:noreply, assign(socket, :submitting, false)}

    {:error, reason} ->
      {:noreply,
       socket
       |> assign(:submitting, false)
       |> put_flash(:error, reason)}
  end
end
```

### 4. Display Validation Errors

```heex
<div class="form-control">
  <.input field={@form[:email]} type="email" />

  <.error :for={msg <- Enum.map(@form[:email].errors, &translate_error(&1))}>
    {msg}
  </.error>
</div>
```

## Common Pitfalls

### 1. Not Handling Empty Input

```elixir
# ❌ Wrong - crashes on empty string
def handle_event("submit", %{"age" => age_str}, socket) do
  age = String.to_integer(age_str)  # Crashes if empty!
  {:noreply, assign(socket, :age, age)}
end

# ✅ Correct - validate first
def handle_event("submit", %{"age" => age_str}, socket)
    when byte_size(age_str) > 0 do
  case Integer.parse(age_str) do
    {age, _} -> {:noreply, assign(socket, :age, age)}
    :error -> {:noreply, put_flash(socket, :error, "Invalid age")}
  end
end
```

### 2. Forgetting to Reset Form

```elixir
# ❌ Wrong - form keeps old values
def handle_event("submit", params, socket) do
  save_data(params)
  {:noreply, socket}
end

# ✅ Correct - reset form after success
def handle_event("submit", params, socket) do
  case save_data(params) do
    :ok ->
      {:noreply,
       socket
       |> assign(:form, to_form(%{}, as: "form"))
       |> put_flash(:info, "Saved!")}

    {:error, reason} ->
      {:noreply, put_flash(socket, :error, reason)}
  end
end
```

### 3. Missing Actor Context

```elixir
# ❌ Wrong - no actor context
def handle_event("create", params, socket) do
  MyApp.Resource
  |> Ash.Changeset.for_create(:create, params)
  |> Ash.create()
end

# ✅ Correct - include actor
def handle_event("create", params, socket) do
  user = socket.assigns.current_user
  actor = %{user: user, organization_id: user.organization_id}

  MyApp.Resource
  |> Ash.Changeset.for_create(:create, params, actor: actor)
  |> Ash.create()
end
```

## Related Resources

### Project Files

- See your application's LiveView modules for form examples
- See your application's settings modules for configuration forms
- See your application's core components module

### Design Documentation

- See your project's design documentation for UI component patterns
- See your project's design documentation for user flow patterns

### Skill Examples

- See skill examples directory for self-contained form examples
- See skill examples directory for basic LiveView patterns

### External Documentation

- [Phoenix.LiveView Forms](https://hexdocs.pm/phoenix_live_view/form-bindings.html)
- [Phoenix.Component.form/1](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1)
- [LiveView Uploads](https://hexdocs.pm/phoenix_live_view/uploads.html)
- [AshPhoenix.Form](https://hexdocs.pm/ash_phoenix/AshPhoenix.Form.html)
