<script setup>
defineProps({
  store: {
    type: Object,
    required: true,
  },
})
</script>

<template>
  <section class="panel-grid">
    <article class="panel" v-for="stat in store.statusBars" :key="stat.key">
      <div class="row between">
        <h3>{{ stat.label }}</h3>
        <strong>{{ stat.value }}%</strong>
      </div>
      <div class="progress-track">
        <div class="progress-fill" :style="{ width: `${stat.value}%` }" />
      </div>
      <div class="row gap">
        <button class="ghost" @click="store.adjustStatus(stat.key, -10)">-10</button>
        <button class="ghost" @click="store.adjustStatus(stat.key, 10)">+10</button>
      </div>
    </article>
  </section>
</template>
