<!--
  DaisyUI Styling Example (Svelte 5)

  Shows how to use DaisyUI components and Bumblebee theme
  colors within Svelte components using Svelte 5 runes.
-->

<script>
  // Props using Svelte 5 $props rune
  let { live, status = "pending" } = $props(); // pending | active | error | success

  const statusConfig = {
    pending: { badge: "badge-warning", icon: "clock" },
    active: { badge: "badge-info", icon: "play" },
    error: { badge: "badge-error", icon: "x-circle" },
    success: { badge: "badge-success", icon: "check-circle" },
  };

  // Derived state using Svelte 5 $derived rune
  let config = $derived(statusConfig[status] || statusConfig.pending);
</script>

<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <!-- Badge with dynamic status -->
    <div class="flex items-center gap-2">
      <span class="badge {config.badge}">{status}</span>
    </div>

    <!-- Button variants -->
    <div class="card-actions mt-4">
      <button class="btn btn-primary">Primary Action</button>
      <button class="btn btn-secondary btn-outline">Secondary</button>
      <button class="btn btn-ghost">Ghost</button>
    </div>

    <!-- Form elements -->
    <div class="form-control mt-4">
      <label class="label">
        <span class="label-text">Input with DaisyUI</span>
      </label>
      <input
        type="text"
        placeholder="Type here..."
        class="input input-bordered w-full"
      />
    </div>

    <!-- Alert component -->
    <div class="alert alert-info mt-4">
      <span>DaisyUI alerts work seamlessly in Svelte!</span>
    </div>
  </div>
</div>

<style>
  /* Component-scoped styles that extend DaisyUI */
  .card {
    /* Add subtle animation on hover */
    transition: transform 0.2s ease;
  }

  .card:hover {
    transform: translateY(-2px);
  }
</style>
