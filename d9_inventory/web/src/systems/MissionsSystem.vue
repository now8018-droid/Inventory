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
    <article class="panel" v-for="mission in store.missions" :key="mission.id">
      <h3>{{ mission.title }}</h3>
      <p>{{ mission.description }}</p>
      <p>รางวัล: ${{ mission.reward.toLocaleString() }}</p>
      <button class="ghost" @click="store.toggleMission(mission.id)">
        {{ mission.active ? 'ปิดภารกิจ' : 'เริ่มภารกิจ' }}
      </button>
    </article>
  </section>
</template>
