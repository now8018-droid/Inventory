<script setup>
defineProps({
  player: {
    type: Object,
    required: true,
  },
  metrics: {
    type: Array,
    required: true,
  },
})
</script>

<template>
  <section class="overview-grid">
    <article class="player-card">
      <p class="label">Player</p>
      <h3>{{ player.name }}</h3>
      <p>{{ player.job }} · Rank {{ player.rank }}</p>
      <div class="tags">
        <span>เงินสด ${{ player.cash.toLocaleString() }}</span>
        <span>แบงค์ ${{ player.bank.toLocaleString() }}</span>
      </div>
    </article>

    <article v-for="metric in metrics" :key="metric.label" class="metric-card">
      <p class="label">{{ metric.label }}</p>
      <h3>{{ metric.value }}</h3>
      <small>{{ metric.hint }}</small>
    </article>
  </section>
</template>
