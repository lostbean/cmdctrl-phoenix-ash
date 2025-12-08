/**
 * JavaScript Hook Patterns for Phoenix LiveView
 * Based on: assets/js/app.js
 * See also: ../reference/liveview-integration.md
 */

// ========================================
// SCROLL TO BOTTOM HOOK (Actual Project Pattern)
// ========================================

/**
 * Automatically scrolls an element to the bottom on mount and update.
 * Common use case: Chat message containers
 *
 * Usage in .heex:
 * <div id="messages" phx-hook="ScrollToBottom" class="overflow-y-auto">
 *   <%= for message <- @messages do %>
 *     <div><%= message.text %></div>
 *   <% end %>
 * </div>
 */
const ScrollToBottom = {
  mounted() {
    this.scrollToBottom();
  },
  updated() {
    this.scrollToBottom();
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight;
  },
};

// ========================================
// COPY TO CLIPBOARD HOOK (Actual Project Pattern)
// ========================================

/**
 * Copies text to clipboard when LiveView sends "copy_to_clipboard" event.
 * Sends "copied" event back to LiveView on success.
 *
 * Usage in LiveView:
 * def handle_event("copy_sql", %{"sql" => sql}, socket) do
 *   {:noreply, push_event(socket, "copy_to_clipboard", %{text: sql})}
 * end
 *
 * Usage in .heex:
 * <div phx-hook="CopyToClipboard">
 *   <button phx-click="copy_sql" phx-value-sql={@sql}>Copy SQL</button>
 * </div>
 */
const CopyToClipboard = {
  mounted() {
    this.handleEvent("copy_to_clipboard", ({ text }) => {
      navigator.clipboard.writeText(text).then(() => {
        this.pushEvent("copied", {});
      });
    });
  },
};

// ========================================
// DOWNLOAD DATA HOOK (Actual Project Pattern)
// ========================================

/**
 * Downloads data as a file when LiveView sends "download_data" event.
 * Supports CSV, JSON, or any text-based format.
 *
 * Usage in LiveView:
 * def handle_event("download_csv", _, socket) do
 *   csv_data = generate_csv(socket.assigns.results)
 *   {:noreply, push_event(socket, "download_data", %{
 *     data: csv_data,
 *     filename: "results.csv",
 *     type: "text/csv"
 *   })}
 * end
 *
 * Usage in .heex:
 * <div phx-hook="DownloadData">
 *   <button phx-click="download_csv">Download CSV</button>
 * </div>
 */
const DownloadData = {
  mounted() {
    this.handleEvent("download_data", ({ data, filename, type }) => {
      const blob = new Blob([data], { type });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });
  },
};

// ========================================
// AUTO FOCUS HOOK
// ========================================

/**
 * Automatically focuses an input element on mount.
 * Useful for modals, search boxes, or forms.
 *
 * Usage in .heex:
 * <input type="text" phx-hook="AutoFocus" class="input" />
 */
const AutoFocus = {
  mounted() {
    this.el.focus();
  },
};

// ========================================
// MODAL HOOK
// ========================================

/**
 * Controls modal show/hide with LiveView events.
 * Uses native <dialog> element.
 *
 * Usage in LiveView:
 * def handle_event("show_modal", _, socket) do
 *   {:noreply, push_event(socket, "show_modal", %{id: "my_modal"})}
 * end
 *
 * Usage in .heex:
 * <dialog id="my_modal" class="modal" phx-hook="Modal">
 *   <div class="modal-box">...</div>
 * </dialog>
 */
const Modal = {
  mounted() {
    this.handleEvent("show_modal", ({ id }) => {
      const modal = document.getElementById(id);
      if (modal) modal.showModal();
    });

    this.handleEvent("close_modal", ({ id }) => {
      const modal = document.getElementById(id);
      if (modal) modal.close();
    });
  },
};

// ========================================
// TEXTAREA AUTO RESIZE HOOK
// ========================================

/**
 * Auto-resizes textarea as user types.
 * Expands up to max height, then shows scrollbar.
 *
 * Usage in .heex:
 * <textarea
 *   phx-hook="AutoResize"
 *   data-min-rows="2"
 *   data-max-rows="10"
 *   class="textarea"
 * ></textarea>
 */
const AutoResize = {
  mounted() {
    this.minRows = parseInt(this.el.dataset.minRows || "2");
    this.maxRows = parseInt(this.el.dataset.maxRows || "10");
    this.resize();

    this.el.addEventListener("input", () => this.resize());
  },

  resize() {
    // Reset height to recalculate
    this.el.style.height = "auto";

    const lineHeight = parseInt(getComputedStyle(this.el).lineHeight);
    const minHeight = lineHeight * this.minRows;
    const maxHeight = lineHeight * this.maxRows;

    let newHeight = this.el.scrollHeight;

    if (newHeight < minHeight) {
      newHeight = minHeight;
    } else if (newHeight > maxHeight) {
      newHeight = maxHeight;
      this.el.style.overflowY = "auto";
    } else {
      this.el.style.overflowY = "hidden";
    }

    this.el.style.height = newHeight + "px";
  },
};

// ========================================
// TOOLTIP HOOK
// ========================================

/**
 * Shows tooltip on hover using data-tooltip attribute.
 *
 * Usage in .heex:
 * <button phx-hook="Tooltip" data-tooltip="Click to save">
 *   Save
 * </button>
 */
const Tooltip = {
  mounted() {
    const tooltip = this.el.dataset.tooltip;
    if (!tooltip) return;

    this.el.addEventListener("mouseenter", () => {
      // Create tooltip element
      this.tooltipEl = document.createElement("div");
      this.tooltipEl.textContent = tooltip;
      this.tooltipEl.className =
        "absolute z-50 px-2 py-1 text-sm bg-base-300 rounded shadow-lg";

      // Position tooltip
      const rect = this.el.getBoundingClientRect();
      this.tooltipEl.style.top = rect.top - 30 + "px";
      this.tooltipEl.style.left = rect.left + "px";

      document.body.appendChild(this.tooltipEl);
    });

    this.el.addEventListener("mouseleave", () => {
      if (this.tooltipEl) {
        this.tooltipEl.remove();
        this.tooltipEl = null;
      }
    });
  },

  destroyed() {
    if (this.tooltipEl) {
      this.tooltipEl.remove();
    }
  },
};

// ========================================
// INFINITE SCROLL HOOK
// ========================================

/**
 * Triggers "load-more" event when user scrolls near bottom.
 * Useful for paginated lists.
 *
 * Usage in LiveView:
 * def handle_event("load-more", _, socket) do
 *   {:noreply, load_more_items(socket)}
 * end
 *
 * Usage in .heex:
 * <div phx-hook="InfiniteScroll" data-threshold="200" class="overflow-y-auto">
 *   <%= for item <- @items do %>
 *     <div><%= item.name %></div>
 *   <% end %>
 * </div>
 */
const InfiniteScroll = {
  mounted() {
    this.threshold = parseInt(this.el.dataset.threshold || "200");
    this.pending = false;

    this.el.addEventListener("scroll", () => {
      if (this.pending) return;

      const scrollTop = this.el.scrollTop;
      const scrollHeight = this.el.scrollHeight;
      const clientHeight = this.el.clientHeight;

      if (scrollTop + clientHeight >= scrollHeight - this.threshold) {
        this.pending = true;
        this.pushEvent("load-more", {});

        // Reset pending after 1 second to allow next trigger
        setTimeout(() => {
          this.pending = false;
        }, 1000);
      }
    });
  },
};

// ========================================
// LOCAL STORAGE HOOK
// ========================================

/**
 * Syncs element value with localStorage.
 * Useful for remembering user preferences.
 *
 * Usage in .heex:
 * <input
 *   phx-hook="LocalStorage"
 *   data-key="search_query"
 *   type="text"
 * />
 */
const LocalStorage = {
  mounted() {
    const key = this.el.dataset.key;
    if (!key) return;

    // Load saved value
    const savedValue = localStorage.getItem(key);
    if (savedValue) {
      this.el.value = savedValue;
    }

    // Save on change
    this.el.addEventListener("input", () => {
      localStorage.setItem(key, this.el.value);
    });
  },
};

// ========================================
// REGISTER ALL HOOKS
// ========================================

/**
 * Export all hooks for use in LiveSocket configuration.
 *
 * Usage in app.js:
 * import { Hooks } from "./hooks"
 *
 * const liveSocket = new LiveSocket("/live", Socket, {
 *   hooks: Hooks
 * })
 */
export const Hooks = {
  ScrollToBottom,
  CopyToClipboard,
  DownloadData,
  AutoFocus,
  Modal,
  AutoResize,
  Tooltip,
  InfiniteScroll,
  LocalStorage,
};

// ========================================
// HOOK LIFECYCLE CALLBACKS
// ========================================

/**
 * Available lifecycle callbacks for hooks:
 *
 * mounted() - Called when element is added to DOM
 * updated() - Called when element is updated by LiveView
 * destroyed() - Called when element is removed from DOM
 * disconnected() - Called when page loses connection
 * reconnected() - Called when page reconnects
 *
 * Available methods in hooks:
 *
 * this.el - The DOM element
 * this.pushEvent(event, payload) - Send event to LiveView
 * this.pushEventTo(selector, event, payload) - Send to specific component
 * this.handleEvent(event, callback) - Listen for events from LiveView
 * this.upload(name, files) - Upload files
 * this.uploadTo(selector, name, files) - Upload to specific component
 */

// ========================================
// EXAMPLE: COMBINED HOOK PATTERN
// ========================================

/**
 * Example of a hook that combines multiple features.
 * This pattern is useful for complex interactive elements.
 */
const AdvancedSearchBox = {
  mounted() {
    // Auto-focus on mount
    this.el.focus();

    // Load from localStorage
    const savedQuery = localStorage.getItem("search_query");
    if (savedQuery) {
      this.el.value = savedQuery;
      // Trigger search with saved value
      this.pushEvent("search", { query: savedQuery });
    }

    // Debounced search on input
    let timeout;
    this.el.addEventListener("input", () => {
      clearTimeout(timeout);
      const query = this.el.value;

      // Save to localStorage
      localStorage.setItem("search_query", query);

      // Debounce search event
      timeout = setTimeout(() => {
        this.pushEvent("search", { query });
      }, 300);
    });

    // Clear on escape key
    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.el.value = "";
        localStorage.removeItem("search_query");
        this.pushEvent("search", { query: "" });
      }
    });
  },
};
