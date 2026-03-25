<script setup>
const props = defineProps({
  item: {
    type: Object,
    default: null,
  },
})

const emit = defineEmits(['consume'])
</script>

<template>
  <aside class="detail-panel">
    <template v-if="item">
      <img :src="item.icon" :alt="item.label" class="detail-icon" />
      <h2>{{ item.label }}</h2>
      <p>{{ item.description }}</p>

      <ul>
        <li><strong>หมวด:</strong> {{ item.category }}</li>
        <li><strong>จำนวน:</strong> {{ item.quantity }}</li>
        <li><strong>น้ำหนัก/ชิ้น:</strong> {{ item.weight }} kg</li>
      </ul>

      <button class="action-btn" @click="emit('consume', item.id)">
        ใช้งาน 1 ชิ้น
      </button>
    </template>

    <p v-else class="empty-state">เลือกไอเท็มเพื่อดูรายละเอียด</p>
  </aside>
</template>
