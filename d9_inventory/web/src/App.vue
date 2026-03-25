<script setup>
import { computed, ref } from 'vue'
import InventoryHeader from './components/InventoryHeader.vue'
import InventoryGrid from './components/InventoryGrid.vue'
import ItemDetail from './components/ItemDetail.vue'
import { useInventoryStore } from './stores/inventory'

const store = useInventoryStore()
const query = ref('')
const activeCategory = ref('all')

const categories = computed(() => ['all', ...store.categories])

const filteredItems = computed(() => {
  const keyword = query.value.trim().toLowerCase()

  return store.items.filter((item) => {
    const categoryMatch =
      activeCategory.value === 'all' || item.category === activeCategory.value

    const keywordMatch =
      keyword.length === 0 ||
      item.label.toLowerCase().includes(keyword) ||
      item.description.toLowerCase().includes(keyword)

    return categoryMatch && keywordMatch
  })
})

const capacityPercent = computed(() =>
  Math.min(100, Math.round((store.usedSlots / store.maxSlots) * 100)),
)
</script>

<template>
  <main class="inventory-layout">
    <section class="inventory-panel">
      <InventoryHeader
        v-model:query="query"
        :money="store.money"
        :weight="store.totalWeight"
        :capacity-percent="capacityPercent"
      />

      <div class="chip-row">
        <button
          v-for="category in categories"
          :key="category"
          class="chip"
          :class="{ active: category === activeCategory }"
          @click="activeCategory = category"
        >
          {{ category }}
        </button>
      </div>

      <InventoryGrid
        :items="filteredItems"
        :selected-id="store.selectedId"
        @select="store.selectItem"
      />
    </section>

    <ItemDetail :item="store.selectedItem" @consume="store.consumeItem" />
  </main>
</template>
