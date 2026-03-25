<script setup>
defineProps({
  store: {
    type: Object,
    required: true,
  },
})
</script>

<template>
  <section class="panel-grid two-col">
    <article class="panel">
      <h3>Tax & Fees</h3>
      <label>ภาษีตลาด (%)</label>
      <input type="range" min="0" max="25" :value="store.economy.tax" @input="store.setTax(Number($event.target.value))" />
      <p>ค่าปัจจุบัน {{ store.economy.tax }}%</p>
    </article>

    <article class="panel">
      <h3>Shop Price Simulator</h3>
      <div class="row between" v-for="item in store.shopPreview" :key="item.name">
        <span>{{ item.name }}</span>
        <strong>${{ item.price.toLocaleString() }}</strong>
      </div>
    </article>
  </section>
</template>
