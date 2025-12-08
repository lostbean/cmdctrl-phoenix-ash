<!--
  Basic LiveSvelte Component Example (Svelte 5)

  This demonstrates the minimal structure for a Svelte component
  that integrates with Phoenix LiveView using Svelte 5 runes.
-->

<script>
  // Props passed from LiveView via the `props` attribute (Svelte 5 runes)
  let { title = "Default Title", items = [], live } = $props();

  // Local component state using $state rune
  let selectedIndex = $state(-1);

  // Push event to LiveView
  function selectItem(index) {
    selectedIndex = index;
    live.pushEvent("item_selected", {
      index,
      item: items[index],
    });
  }
</script>

<!-- Use DaisyUI classes for consistency with your application UI -->
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">{title}</h2>

    {#if items.length === 0}
      <p class="text-base-content/60">No items to display</p>
    {:else}
      <ul class="menu bg-base-200 rounded-box">
        {#each items as item, index}
          <li>
            <button
              class:active={selectedIndex === index}
              onclick={() => selectItem(index)}
            >
              {item.name}
            </button>
          </li>
        {/each}
      </ul>
    {/if}
  </div>
</div>
