<script setup>
defineProps({
  systems: {
    type: Array,
    required: true,
  },
  activeSystem: {
    type: String,
    required: true,
  },
})

const emit = defineEmits(['select'])
</script>

<template>
  <aside class="menu-panel">
    <div class="brand">
      <p class="brand-top">D9 Simulator</p>
      <h2>UI Control Center</h2>
    </div>

    <nav class="menu-list">
      <button
        v-for="system in systems"
        :key="system.key"
        class="menu-item"
        :class="{ active: system.key === activeSystem }"
        @click="emit('select', system.key)"
      >
        <span>{{ system.icon }}</span>
        <div>
          <strong>{{ system.label }}</strong>
          <small>{{ system.description }}</small>
        </div>
      </button>
    </nav>
  </aside>
</template>
