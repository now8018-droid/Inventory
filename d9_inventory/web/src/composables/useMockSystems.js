import { computed, reactive } from 'vue'

const state = reactive({
  activeSystem: 'inventory',
  player: {
    name: 'D9_Night',
    job: 'Police',
    rank: 4,
    cash: 12500,
    bank: 210000,
  },
  systems: [
    { key: 'inventory', label: 'Inventory', description: 'แก้ไขไอเท็มและจำนวน', icon: '🎒' },
    { key: 'status', label: 'Status', description: 'จำลองแถบสถานะผู้เล่น', icon: '❤️' },
    { key: 'garage', label: 'Garage', description: 'ตรวจและซ่อมยานพาหนะ', icon: '🚗' },
    { key: 'missions', label: 'Missions', description: 'เมนูภารกิจจำลอง', icon: '🧭' },
    { key: 'economy', label: 'Economy', description: 'เมนูเศรษฐกิจและภาษี', icon: '💰' },
    { key: 'admin', label: 'Admin', description: 'เมนูแอดมินและ log', icon: '🛠️' },
  ],
  inventory: [
    { id: 1, name: 'Water', amount: 15, type: 'consumable', description: 'น้ำดื่มเพิ่มพลัง' },
    { id: 2, name: 'Bread', amount: 6, type: 'consumable', description: 'ขนมปังฟื้นฟูความหิว' },
    { id: 3, name: 'Bandage', amount: 10, type: 'medical', description: 'รักษาบาดแผลเบื้องต้น' },
    { id: 4, name: 'Ammo 9mm', amount: 45, type: 'ammo', description: 'กระสุนปืนพก' },
  ],
  selectedItemId: 1,
  status: {
    health: 90,
    armor: 55,
    hunger: 40,
    thirst: 48,
    stress: 25,
  },
  vehicles: [
    { plate: 'D9-001', model: 'Buffalo STX', engine: 68, fuel: 41 },
    { plate: 'D9-778', model: 'Sultan RS', engine: 92, fuel: 74 },
  ],
  missions: [
    { id: 1, title: 'Patrol City', description: 'ตรวจตราพื้นที่รอบเมือง 10 นาที', reward: 3500, active: false },
    { id: 2, title: 'Escort Convoy', description: 'คุ้มกันขบวนรถ VIP', reward: 5500, active: true },
  ],
  economy: {
    tax: 7,
  },
  logs: [
    { id: 1, action: 'system_boot', time: '10:20:00' },
    { id: 2, action: 'player_loaded', time: '10:22:18' },
  ],
})

export function useMockSystems() {
  const selectedItem = computed(() =>
    state.inventory.find((item) => item.id === state.selectedItemId) ?? null,
  )

  const currentSystem = computed(
    () => state.systems.find((item) => item.key === state.activeSystem) ?? state.systems[0],
  )

  const statusBars = computed(() => [
    { key: 'health', label: 'Health', value: state.status.health },
    { key: 'armor', label: 'Armor', value: state.status.armor },
    { key: 'hunger', label: 'Hunger', value: state.status.hunger },
    { key: 'thirst', label: 'Thirst', value: state.status.thirst },
    { key: 'stress', label: 'Stress', value: state.status.stress },
  ])

  const shopPreview = computed(() => {
    const taxRate = state.economy.tax / 100
    const base = [
      { name: 'Medkit', value: 1200 },
      { name: 'Lockpick', value: 600 },
      { name: 'Armor', value: 3000 },
    ]

    return base.map((item) => ({
      name: item.name,
      price: Math.round(item.value + item.value * taxRate),
    }))
  })

  const metrics = computed(() => [
    { label: 'Players Online', value: 128, hint: 'Mock realtime' },
    { label: 'Active Missions', value: state.missions.filter((m) => m.active).length, hint: 'ระบบภารกิจ' },
    { label: 'Garage Queue', value: state.vehicles.filter((v) => v.engine < 80).length, hint: 'รถต้องซ่อม' },
    { label: 'Market Tax', value: `${state.economy.tax}%`, hint: 'ภาษีปัจจุบัน' },
  ])

  const setActiveSystem = (key) => {
    state.activeSystem = key
  }

  const selectItem = (id) => {
    state.selectedItemId = id
  }

  const updateItemAmount = (id, amount) => {
    const item = state.inventory.find((entry) => entry.id === id)
    if (!item) return
    item.amount = amount
  }

  const adjustStatus = (key, delta) => {
    state.status[key] = Math.min(100, Math.max(0, state.status[key] + delta))
  }

  const repairVehicle = (plate) => {
    const car = state.vehicles.find((entry) => entry.plate === plate)
    if (!car) return
    car.engine = 100
    car.fuel = 100
  }

  const toggleMission = (id) => {
    const mission = state.missions.find((entry) => entry.id === id)
    if (!mission) return
    mission.active = !mission.active
  }

  const setTax = (value) => {
    state.economy.tax = value
  }

  const pushLog = (action) => {
    state.logs.unshift({
      id: Date.now(),
      action,
      time: new Date().toLocaleTimeString('th-TH', { hour12: false }),
    })
    state.logs = state.logs.slice(0, 10)
  }

  return {
    ...state,
    selectedItem,
    currentSystem,
    statusBars,
    shopPreview,
    metrics,
    setActiveSystem,
    selectItem,
    updateItemAmount,
    adjustStatus,
    repairVehicle,
    toggleMission,
    setTax,
    pushLog,
  }
}
