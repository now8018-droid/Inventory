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
    <article class="panel" v-for="car in store.vehicles" :key="car.plate">
      <div class="row between">
        <h3>{{ car.model }}</h3>
        <span>{{ car.plate }}</span>
      </div>
      <p>เครื่องยนต์ {{ car.engine }}% · น้ำมัน {{ car.fuel }}%</p>
      <button class="ghost" @click="store.repairVehicle(car.plate)">ซ่อม + เติมน้ำมัน</button>
    </article>
  </section>
</template>
