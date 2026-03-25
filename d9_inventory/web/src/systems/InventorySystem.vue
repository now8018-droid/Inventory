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
      <h3>Inventory Slots</h3>
      <div class="slot-grid">
        <button
          v-for="item in store.inventory"
          :key="item.id"
          class="slot-item"
          @click="store.selectItem(item.id)"
        >
          <strong>{{ item.name }}</strong>
          <span>x{{ item.amount }}</span>
          <small>{{ item.type }}</small>
        </button>
      </div>
    </article>

    <article class="panel" v-if="store.selectedItem">
      <h3>Item Editor</h3>
      <p>{{ store.selectedItem.description }}</p>
      <label>จำนวน</label>
      <input
        type="range"
        min="0"
        max="100"
        :value="store.selectedItem.amount"
        @input="store.updateItemAmount(store.selectedItem.id, Number($event.target.value))"
      />
      <p>จำนวนปัจจุบัน: {{ store.selectedItem.amount }}</p>
    </article>
  </section>
</template>
