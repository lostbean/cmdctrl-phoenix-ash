<!--
  LiveView Events Example (Svelte 5)

  Demonstrates bi-directional event communication between
  Svelte components and Phoenix LiveView using Svelte 5 runes.
-->

<script>
  import { onMount } from "svelte";

  // Props using Svelte 5 $props rune
  let { live, initialCount = 0 } = $props();

  // State using Svelte 5 $state rune
  let count = $state(initialCount);
  let serverMessage = $state("");

  onMount(() => {
    // Listen for events FROM LiveView
    live.handleEvent("update_count", ({ new_count }) => {
      count = new_count;
    });

    live.handleEvent("server_message", ({ message }) => {
      serverMessage = message;
      // Clear after 3 seconds
      setTimeout(() => (serverMessage = ""), 3000);
    });
  });

  // Push events TO LiveView
  function increment() {
    count += 1;
    live.pushEvent("count_changed", { count });
  }

  function decrement() {
    count -= 1;
    live.pushEvent("count_changed", { count });
  }

  function syncWithServer() {
    // Request server to send back the authoritative count
    live.pushEvent("request_sync", {});
  }
</script>

<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Event Communication Demo</h2>

    <div class="flex items-center gap-4">
      <button class="btn btn-circle btn-outline" onclick={decrement}>
        -
      </button>
      <span class="text-2xl font-bold">{count}</span>
      <button class="btn btn-circle btn-outline" onclick={increment}>
        +
      </button>
    </div>

    <button class="btn btn-secondary btn-sm mt-4" onclick={syncWithServer}>
      Sync with Server
    </button>

    {#if serverMessage}
      <div class="alert alert-info mt-4">
        <span>{serverMessage}</span>
      </div>
    {/if}
  </div>
</div>
