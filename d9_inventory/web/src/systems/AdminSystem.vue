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
    <article class="panel">
      <h3>Admin Tools (Mock)</h3>
      <div class="row gap wrap">
        <button class="ghost" @click="store.pushLog('spawn_vehicle')">Spawn Vehicle</button>
        <button class="ghost" @click="store.pushLog('give_item')">Give Item</button>
        <button class="ghost" @click="store.pushLog('revive_all')">Revive All</button>
      </div>
    </article>

    <article class="panel">
      <h3>Event Logs</h3>
      <ul class="log-list">
        <li v-for="log in store.logs" :key="log.id">
          <strong>{{ log.action }}</strong>
          <small>{{ log.time }}</small>
        </li>
      </ul>
    </article>
  </section>
</template>
