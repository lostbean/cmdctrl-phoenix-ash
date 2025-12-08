defmodule Examples.Forms do
  @moduledoc """
  Form handling patterns in Phoenix LiveView.

  This example shows:
  - Simple forms with phx-submit
  - Forms with validation
  - Multi-field forms
  - Dynamic forms
  - File uploads

  Based on patterns from:
  - lib/{app_name}_web/live/chat_interface_live.ex
  - lib/{app_name}_web/live/settings/config_live.ex
  - lib/{app_name}_web/live/resources_live.ex
  """

  use MyAppWeb, :live_view

  # ============================================================================
  # SIMPLE FORM - Text input with phx-submit
  # ============================================================================

  defmodule SimpleChatForm do
    @moduledoc """
    Simple text input form for chat messages.
    Based on: lib/{app_name}_web/live/chat_interface_live.ex
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:input, "")
       |> assign(:messages, [])}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="chat-container p-8">
        <%!-- Messages --%>
        <div class="space-y-4 mb-8">
          <%= for message <- @messages do %>
            <div class="chat chat-start">
              <div class="chat-bubble">{message}</div>
            </div>
          <% end %>
        </div>

        <%!-- Input Form --%>
        <form phx-submit="send_message" class="w-full">
          <div class="flex gap-2">
            <textarea
              name="message"
              class="textarea textarea-bordered flex-1"
              rows="2"
              placeholder="Type a message..."
              phx-debounce="200"
            >{@input}</textarea>

            <button type="submit" class="btn btn-primary">
              Send
            </button>
          </div>
        </form>
      </div>
      """
    end

    # ✅ CORRECT: Validate input before processing
    @impl true
    def handle_event("send_message", %{"message" => message}, socket)
        when byte_size(message) > 0 do
      messages = socket.assigns.messages ++ [message]

      {:noreply,
       socket
       |> assign(:messages, messages)
       |> assign(:input, "")}
    end

    # Handle empty message (do nothing)
    @impl true
    def handle_event("send_message", _params, socket) do
      {:noreply, socket}
    end
  end

  # ============================================================================
  # FORM WITH TO_FORM - Map-based forms
  # ============================================================================

  defmodule DatabaseConfigForm do
    @moduledoc """
    Form using to_form/2 for configuration data.
    Based on: lib/{app_name}_web/live/settings/database_config_live.ex
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      # Create form from plain map
      form_data = %{
        "name" => "Production Database",
        "host" => "localhost",
        "port" => "5432",
        "database" => "mydb"
      }

      {:ok,
       socket
       |> assign(:form, to_form(form_data, as: "database"))
       |> assign(:editing, false)
       |> assign(:saving, false)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="max-w-2xl mx-auto p-8">
        <h1 class="text-2xl font-bold mb-6">Database Configuration</h1>

        <%= if @editing do %>
          <%!-- Edit Mode --%>
          <.form
            for={@form}
            id="database-form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-4"
          >
            <div class="form-control">
              <label class="label">
                <span class="label-text">Name</span>
              </label>
              <.input
                field={@form[:name]}
                type="text"
                class="input input-bordered w-full"
                placeholder="Database name"
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text">Host</span>
              </label>
              <.input
                field={@form[:host]}
                type="text"
                class="input input-bordered w-full"
                placeholder="localhost"
              />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Port</span>
                </label>
                <.input
                  field={@form[:port]}
                  type="text"
                  class="input input-bordered w-full"
                  placeholder="5432"
                />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text">Database</span>
                </label>
                <.input
                  field={@form[:database]}
                  type="text"
                  class="input input-bordered w-full"
                  placeholder="mydb"
                />
              </div>
            </div>

            <div class="flex gap-2 justify-end">
              <button
                type="button"
                class="btn btn-ghost"
                phx-click="cancel"
                disabled={@saving}
              >
                Cancel
              </button>

              <button type="submit" class="btn btn-primary" disabled={@saving}>
                {if @saving, do: "Saving...", else: "Save"}
              </button>
            </div>
          </.form>
        <% else %>
          <%!-- View Mode --%>
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <dl class="space-y-2">
                <div>
                  <dt class="text-sm font-semibold">Name</dt>
                  <dd class="text-base-content/70">{@form.params["name"]}</dd>
                </div>
                <div>
                  <dt class="text-sm font-semibold">Host</dt>
                  <dd class="text-base-content/70">{@form.params["host"]}</dd>
                </div>
              </dl>

              <div class="card-actions justify-end mt-4">
                <button class="btn btn-primary" phx-click="start_edit">
                  Edit
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
      """
    end

    # Start editing
    @impl true
    def handle_event("start_edit", _params, socket) do
      {:noreply, assign(socket, :editing, true)}
    end

    # Cancel editing
    @impl true
    def handle_event("cancel", _params, socket) do
      {:noreply, assign(socket, :editing, false)}
    end

    # Validate on change (optional)
    @impl true
    def handle_event("validate", %{"database" => params}, socket) do
      # Could add validation logic here
      form = to_form(params, as: "database")
      {:noreply, assign(socket, :form, form)}
    end

    # Save form
    @impl true
    def handle_event("save", %{"database" => params}, socket) do
      socket = assign(socket, :saving, true)

      # Save to database
      case save_database_config(params, socket.assigns.current_user) do
        {:ok, _database} ->
          {:noreply,
           socket
           |> assign(:saving, false)
           |> assign(:editing, false)
           |> put_flash(:info, "Configuration saved successfully")}

        {:error, reason} ->
          {:noreply,
           socket
           |> assign(:saving, false)
           |> put_flash(:error, "Failed to save: #{reason}")}
      end
    end

    defp save_database_config(_params, _user), do: {:ok, %{}}
  end

  # ============================================================================
  # ASH CHANGESET FORMS - Using Ash resources
  # ============================================================================

  defmodule AshChangesetForm do
    @moduledoc """
    Form using Ash changesets for validation.
    """

    use MyAppWeb, :live_view

    @impl true
    def mount(_params, _session, socket) do
      user = socket.assigns.current_user
      actor = build_actor(user)

      # Create empty changeset
      changeset =
        MyApp.Resources.Resource
        |> Ash.Changeset.for_create(:create, %{}, actor: actor)

      form = AshPhoenix.Form.for_create(MyApp.Resources.Resource, :create,
        api: MyApp.Resources,
        actor: actor,
        as: "resource"
      )

      {:ok,
       socket
       |> assign(:form, to_form(form))
       |> assign(:submitting, false)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="max-w-2xl mx-auto p-8">
        <h1 class="text-2xl font-bold mb-6">New Resource</h1>

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
              placeholder="My Resource"
            />
            <.error :for={msg <- Enum.map(@form[:name].errors, &translate_error(&1))}>
              {msg}
            </.error>
          </div>

          <%!-- Description field --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text">Description</span>
            </label>
            <.input
              field={@form[:description]}
              type="textarea"
              class="textarea textarea-bordered w-full"
              rows="3"
              placeholder="Optional description"
            />
          </div>

          <%!-- Resource type select --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text">Type *</span>
            </label>
            <.input
              field={@form[:resource_type]}
              type="select"
              options={[
                {"Standard", "standard"},
                {"Premium", "premium"},
                {"Custom", "custom"}
              ]}
              class="select select-bordered w-full"
            />
          </div>

          <%!-- Submit --%>
          <div class="flex gap-2 justify-end">
            <.link navigate={~p"/resources"} class="btn btn-ghost">
              Cancel
            </.link>

            <button type="submit" class="btn btn-primary" disabled={@submitting}>
              {if @submitting, do: "Creating...", else: "Create Resource"}
            </button>
          </div>
        </.form>
      </div>
      """
    end

    # Validate on change
    @impl true
    def handle_event("validate", %{"resource" => params}, socket) do
      user = socket.assigns.current_user
      actor = build_actor(user)

      form =
        AshPhoenix.Form.for_create(MyApp.Resources.Resource, :create,
          api: MyApp.Resources,
          actor: actor,
          params: params,
          as: "resource"
        )
        |> AshPhoenix.Form.validate(params)

      {:noreply, assign(socket, :form, to_form(form))}
    end

    # Submit form
    @impl true
    def handle_event("create", %{"resource" => params}, socket) do
      user = socket.assigns.current_user
      actor = build_actor(user)

      socket = assign(socket, :submitting, true)

      case MyApp.Resources.Resource
           |> Ash.Changeset.for_create(:create, params, actor: actor)
           |> Ash.create() do
        {:ok, resource} ->
          {:noreply,
           socket
           |> put_flash(:info, "Resource created successfully")
           |> push_navigate(to: ~p"/resources/#{resource.id}")}

        {:error, changeset} ->
          form =
            AshPhoenix.Form.for_create(MyApp.Resources.Resource, :create,
              api: MyApp.Resources,
              actor: actor,
              params: params,
              errors: changeset.errors,
              as: "resource"
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

  # ============================================================================
  # DYNAMIC FORMS - Add/remove fields
  # ============================================================================

  defmodule DynamicFieldsForm do
    @moduledoc """
    Form with dynamically added/removed fields.
    """

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
      <div class="max-w-2xl mx-auto p-8">
        <h1 class="text-2xl font-bold mb-6">Dynamic Fields</h1>

        <form phx-submit="save" class="space-y-4">
          <%= for field <- @fields do %>
            <div class="flex gap-2 items-start" id={"field-#{field.id}"}>
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
                class="btn btn-ghost btn-sm"
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
              Save All
            </button>
          </div>
        </form>
      </div>
      """
    end

    @impl true
    def handle_event("add_field", _params, socket) do
      new_field = %{id: socket.assigns.next_id, name: "", value: ""}
      fields = socket.assigns.fields ++ [new_field]

      {:noreply,
       socket
       |> assign(:fields, fields)
       |> assign(:next_id, socket.assigns.next_id + 1)}
    end

    @impl true
    def handle_event("remove_field", %{"id" => id}, socket) do
      id = String.to_integer(id)
      fields = Enum.reject(socket.assigns.fields, &(&1.id == id))

      {:noreply, assign(socket, :fields, fields)}
    end

    @impl true
    def handle_event("save", %{"field" => fields}, socket) do
      # Process fields...
      IO.inspect(fields, label: "Saved fields")

      {:noreply, put_flash(socket, :info, "Fields saved")}
    end
  end

  # ============================================================================
  # FILE UPLOAD - LiveView uploads
  # ============================================================================

  defmodule FileUploadForm do
    @moduledoc """
    Form with file upload support.
    """

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
          <%!-- File input --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text">Select CSV File</span>
            </label>

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
              <div class="flex items-center gap-2 mt-2">
                <span class="flex-1">{entry.client_name}</span>
                <span class="text-sm text-base-content/60">
                  {format_bytes(entry.client_size)}
                </span>
                <button
                  type="button"
                  class="btn btn-ghost btn-xs"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                >
                  ✕
                </button>
              </div>

              <%!-- Upload progress --%>
              <progress
                class="progress progress-primary w-full"
                value={entry.progress}
                max="100"
              >
                {entry.progress}%
              </progress>

              <%!-- Upload errors --%>
              <%= for err <- upload_errors(@uploads.csv_file, entry) do %>
                <p class="text-error text-sm">{error_to_string(err)}</p>
              <% end %>
            <% end %>
          </div>

          <button
            type="submit"
            class="btn btn-primary"
            disabled={@uploads.csv_file.entries == []}
          >
            Upload
          </button>
        </form>

        <%!-- Uploaded files --%>
        <%= if @uploaded_files != [] do %>
          <div class="mt-8">
            <h2 class="text-lg font-semibold mb-4">Uploaded Files</h2>
            <ul class="space-y-2">
              <%= for file <- @uploaded_files do %>
                <li class="card bg-base-200 p-4">
                  {file.name} - {file.size} bytes
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
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

          {:ok, %{name: entry.client_name, size: entry.client_size, path: dest}}
        end)

      {:noreply,
       socket
       |> update(:uploaded_files, &(&1 ++ uploaded_files))
       |> put_flash(:info, "File uploaded successfully")}
    end

    defp format_bytes(bytes) do
      cond do
        bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)} MB"
        bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)} KB"
        true -> "#{bytes} bytes"
      end
    end

    defp error_to_string(:too_large), do: "File is too large"
    defp error_to_string(:not_accepted), do: "Invalid file type"
    defp error_to_string(_), do: "Upload error"
  end
end
