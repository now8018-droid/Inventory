<script setup>
defineProps({
  query: {
    type: String,
    required: true,
  },
  money: {
    type: Number,
    required: true,
  },
  weight: {
    type: Number,
    required: true,
  },
  capacityPercent: {
    type: Number,
    required: true,
  },
})

const emit = defineEmits(['update:query'])
</script>

<template>
  <header class="panel-header">
    <div>
      <h1>Inventory</h1>
      <p class="subtitle">จัดการไอเท็มของผู้เล่น</p>
    </div>

    <div class="stat-group">
      <span>$ {{ money.toLocaleString() }}</span>
      <span>{{ weight.toFixed(1) }} kg</span>
    </div>

    <input
      class="search-input"
      :value="query"
      placeholder="ค้นหาไอเท็ม..."
      @input="emit('update:query', $event.target.value)"
    />

    <div class="capacity-track">
      <div class="capacity-fill" :style="{ width: `${capacityPercent}%` }" />
    </div>
  </header>
</template>
