<script setup>
defineProps({
  items: {
    type: Array,
    required: true,
  },
  selectedId: {
    type: Number,
    default: null,
  },
})

const emit = defineEmits(['select'])
</script>

<template>
  <section class="grid-wrap">
    <article
      v-for="item in items"
      :key="item.id"
      class="item-card"
      :class="{ selected: item.id === selectedId }"
      @click="emit('select', item.id)"
    >
      <img :src="item.icon" :alt="item.label" class="item-icon" />
      <h3>{{ item.label }}</h3>
      <p>{{ item.quantity }} ชิ้น</p>
    </article>

    <p v-if="items.length === 0" class="empty-state">ไม่พบไอเท็มที่ตรงเงื่อนไข</p>
  </section>
</template>
