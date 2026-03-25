import { computed, reactive } from 'vue'
import { seedItems } from '../utils/mockData'

const state = reactive({
  money: 23500,
  maxSlots: 60,
  selectedId: seedItems[0]?.id ?? null,
  items: seedItems,
})

export function useInventoryStore() {
  const selectedItem = computed(() =>
    state.items.find((item) => item.id === state.selectedId) ?? null,
  )

  const categories = computed(() =>
    Array.from(new Set(state.items.map((item) => item.category))),
  )

  const usedSlots = computed(() =>
    state.items.reduce((sum, item) => sum + item.quantity, 0),
  )

  const totalWeight = computed(() =>
    state.items.reduce((sum, item) => sum + item.quantity * item.weight, 0),
  )

  const selectItem = (id) => {
    state.selectedId = id
  }

  const consumeItem = (id) => {
    const item = state.items.find((entry) => entry.id === id)
    if (!item || item.quantity <= 0) return

    item.quantity -= 1
    if (item.quantity === 0) {
      state.selectedId = null
    }
  }

  return {
    ...state,
    selectedItem,
    categories,
    usedSlots,
    totalWeight,
    selectItem,
    consumeItem,
  }
}
