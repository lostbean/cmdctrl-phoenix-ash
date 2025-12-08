/**
 * JavaScript Hooks for Phoenix LiveView
 *
 * Hooks provide client-side behavior for LiveView components.
 * Based on: assets/js/app.js
 *
 * Usage in LiveView templates:
 * <div phx-hook="HookName" id="unique-id">...</div>
 *
 * IMPORTANT: Elements with phx-hook MUST have a unique ID.
 */

// ============================================================================
// ACTUAL HOOKS FROM EXAMPLE PROJECT
// ============================================================================

/**
 * ScrollToBottom - Auto-scroll container to bottom
 *
 * Use case: Chat interfaces, message lists
 *
 * Example:
 * <div phx-hook="ScrollToBottom" id="chat-messages" class="overflow-y-auto">
 *   <!-- messages -->
 * </div>
 */
const ScrollToBottom = {
  mounted() {
    this.scrollToBottom()
  },

  updated() {
    this.scrollToBottom()
  },

  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

/**
 * CopyToClipboard - Copy text to clipboard
 *
 * Use case: Copy SQL queries, code snippets, API keys
 *
 * Server sends event with text to copy:
 * push_event(socket, "copy_to_clipboard", %{text: "SELECT * FROM users"})
 *
 * Example:
 * <div phx-hook="CopyToClipboard" id="copy-container">
 *   <button phx-click="copy_sql">Copy SQL</button>
 * </div>
 */
const CopyToClipboard = {
  mounted() {
    this.handleEvent("copy_to_clipboard", ({text}) => {
      navigator.clipboard.writeText(text).then(() => {
        // Notify server of successful copy
        this.pushEvent("copied", {})
      }).catch(err => {
        console.error('Failed to copy:', err)
      })
    })
  }
}

/**
 * DownloadData - Download data as file
 *
 * Use case: Export CSV, JSON, SQL results
 *
 * Server sends event with file data:
 * push_event(socket, "download_data", %{
 *   data: csv_content,
 *   filename: "results.csv",
 *   type: "text/csv"
 * })
 *
 * Example:
 * <div phx-hook="DownloadData" id="download-container">
 *   <button phx-click="export_csv">Download CSV</button>
 * </div>
 */
const DownloadData = {
  mounted() {
    this.handleEvent("download_data", ({data, filename, type}) => {
      const blob = new Blob([data], { type })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    })
  }
}

// ============================================================================
// ADDITIONAL USEFUL HOOKS
// ============================================================================

/**
 * AutoFocus - Focus element on mount or update
 *
 * Use case: Auto-focus input fields
 *
 * Example:
 * <input phx-hook="AutoFocus" id="search-input" type="text" />
 */
const AutoFocus = {
  mounted() {
    this.el.focus()
  },

  updated() {
    this.el.focus()
  }
}

/**
 * InfiniteScroll - Load more content when scrolling to bottom
 *
 * Use case: Paginated lists, feeds
 *
 * Example:
 * <div phx-hook="InfiniteScroll" id="items-list" class="overflow-y-auto">
 *   <!-- items -->
 * </div>
 */
const InfiniteScroll = {
  mounted() {
    this.pending = false

    this.el.addEventListener("scroll", () => {
      if (this.pending) return

      const scrollHeight = this.el.scrollHeight
      const scrollTop = this.el.scrollTop
      const clientHeight = this.el.clientHeight

      // Trigger when within 100px of bottom
      if (scrollTop + clientHeight >= scrollHeight - 100) {
        this.pending = true
        this.pushEvent("load_more", {}, (reply, ref) => {
          this.pending = false
        })
      }
    })
  }
}

/**
 * LocalStorage - Persist element value to localStorage
 *
 * Use case: Remember user preferences, form state
 *
 * Example:
 * <input
 *   phx-hook="LocalStorage"
 *   id="theme-toggle"
 *   data-storage-key="user-theme"
 *   type="checkbox"
 * />
 */
const LocalStorage = {
  mounted() {
    this.storageKey = this.el.dataset.storageKey
    if (!this.storageKey) {
      console.error('LocalStorage hook requires data-storage-key attribute')
      return
    }

    // Load saved value
    const savedValue = localStorage.getItem(this.storageKey)
    if (savedValue !== null) {
      if (this.el.type === 'checkbox') {
        this.el.checked = savedValue === 'true'
      } else {
        this.el.value = savedValue
      }
    }

    // Save on change
    this.el.addEventListener('change', () => {
      const value = this.el.type === 'checkbox'
        ? this.el.checked
        : this.el.value
      localStorage.setItem(this.storageKey, value)
    })
  }
}

/**
 * Tooltip - Show tooltips using data attributes
 *
 * Use case: Help text, additional information
 *
 * Requires: DaisyUI (already in project)
 *
 * Example:
 * <button
 *   phx-hook="Tooltip"
 *   id="help-button"
 *   data-tip="This is helpful information"
 *   class="btn"
 * >
 *   Help
 * </button>
 */
const Tooltip = {
  mounted() {
    // DaisyUI handles tooltips automatically with data-tip attribute
    // This hook is for custom behavior if needed
    const tip = this.el.dataset.tip
    if (!tip) {
      console.warn('Tooltip hook: no data-tip attribute found')
    }
  }
}

/**
 * ClickOutside - Detect clicks outside element
 *
 * Use case: Close dropdowns, modals
 *
 * Example:
 * <div phx-hook="ClickOutside" id="dropdown" phx-click-outside="close">
 *   <!-- dropdown content -->
 * </div>
 */
const ClickOutside = {
  mounted() {
    this.handleClick = (e) => {
      if (!this.el.contains(e.target)) {
        this.pushEvent("click_outside", {})
      }
    }

    document.addEventListener("click", this.handleClick)
  },

  destroyed() {
    document.removeEventListener("click", this.handleClick)
  }
}

/**
 * CodeHighlight - Syntax highlighting for code blocks
 *
 * Use case: Display SQL queries, code snippets
 *
 * Requires: highlight.js or similar library
 *
 * Example:
 * <pre phx-hook="CodeHighlight" id="sql-display">
 *   <code class="language-sql">{@sql}</code>
 * </pre>
 */
const CodeHighlight = {
  mounted() {
    this.highlight()
  },

  updated() {
    this.highlight()
  },

  highlight() {
    if (typeof hljs !== 'undefined') {
      hljs.highlightElement(this.el)
    }
  }
}

/**
 * AnimateValue - Animate number changes
 *
 * Use case: Dashboard metrics, counters
 *
 * Example:
 * <div phx-hook="AnimateValue" id="user-count" data-value={@user_count}>
 *   {@user_count}
 * </div>
 */
const AnimateValue = {
  mounted() {
    this.animateToValue(this.el.dataset.value)
  },

  updated() {
    this.animateToValue(this.el.dataset.value)
  },

  animateToValue(targetValue) {
    const target = parseInt(targetValue) || 0
    const current = parseInt(this.el.textContent) || 0

    if (current === target) return

    const duration = 500 // ms
    const steps = 20
    const stepValue = (target - current) / steps
    const stepDuration = duration / steps

    let currentStep = 0
    const interval = setInterval(() => {
      currentStep++
      const newValue = Math.round(current + (stepValue * currentStep))
      this.el.textContent = newValue

      if (currentStep >= steps) {
        clearInterval(interval)
        this.el.textContent = target
      }
    }, stepDuration)
  }
}

// ============================================================================
// EXPORT HOOKS
// ============================================================================

/**
 * Export all hooks for use in LiveSocket
 *
 * Usage in app.js:
 * import { Hooks } from './hooks'
 *
 * const liveSocket = new LiveSocket("/live", Socket, {
 *   hooks: Hooks
 * })
 */
export const Hooks = {
  // Example project hooks
  ScrollToBottom,
  CopyToClipboard,
  DownloadData,

  // Additional useful hooks
  AutoFocus,
  InfiniteScroll,
  LocalStorage,
  Tooltip,
  ClickOutside,
  CodeHighlight,
  AnimateValue
}

// ============================================================================
// HOOK PATTERNS
// ============================================================================

/**
 * Hook Lifecycle:
 *
 * - mounted() - Called when element is added to DOM
 * - updated() - Called when element is updated
 * - destroyed() - Called when element is removed from DOM
 * - disconnected() - Called when connection is lost
 * - reconnected() - Called when connection is restored
 */

/**
 * Hook API:
 *
 * - this.el - The hooked element
 * - this.pushEvent(event, payload, callback) - Send event to server
 * - this.handleEvent(event, callback) - Listen for server events
 * - this.upload(name, files) - Upload files
 * - this.uploadTo(element, name, files) - Upload files to specific element
 */

/**
 * Best Practices:
 *
 * 1. ✅ Always add unique ID to elements with phx-hook
 * 2. ✅ Clean up event listeners in destroyed()
 * 3. ✅ Use handleEvent for server → client communication
 * 4. ✅ Use pushEvent for client → server communication
 * 5. ❌ Don't mutate DOM directly - use LiveView updates
 * 6. ❌ Don't store state in hooks - use LiveView assigns
 */

/**
 * Common Pitfalls:
 *
 * ❌ WRONG: Missing ID
 * <div phx-hook="MyHook">...</div>
 *
 * ✅ CORRECT: Include unique ID
 * <div phx-hook="MyHook" id="my-element">...</div>
 *
 * ❌ WRONG: Direct DOM mutation
 * MyHook = {
 *   mounted() {
 *     this.el.innerHTML = "New content"
 *   }
 * }
 *
 * ✅ CORRECT: Use LiveView updates
 * def handle_event("update", _, socket) do
 *   {:noreply, assign(socket, :content, "New content")}
 * end
 *
 * ❌ WRONG: Not cleaning up listeners
 * MyHook = {
 *   mounted() {
 *     window.addEventListener("resize", this.handler)
 *   }
 * }
 *
 * ✅ CORRECT: Clean up in destroyed()
 * MyHook = {
 *   mounted() {
 *     this.handler = () => { /* ... */ }
 *     window.addEventListener("resize", this.handler)
 *   },
 *   destroyed() {
 *     window.removeEventListener("resize", this.handler)
 *   }
 * }
 */
