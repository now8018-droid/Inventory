<script setup>
import { computed } from 'vue'
import SystemMenu from './components/SystemMenu.vue'
import SystemOverview from './components/SystemOverview.vue'
import InventorySystem from './systems/InventorySystem.vue'
import StatusSystem from './systems/StatusSystem.vue'
import GarageSystem from './systems/GarageSystem.vue'
import MissionsSystem from './systems/MissionsSystem.vue'
import EconomySystem from './systems/EconomySystem.vue'
import AdminSystem from './systems/AdminSystem.vue'
import { useMockSystems } from './composables/useMockSystems'

const store = useMockSystems()

const viewMap = {
  inventory: InventorySystem,
  status: StatusSystem,
  garage: GarageSystem,
  missions: MissionsSystem,
  economy: EconomySystem,
  admin: AdminSystem,
}

const activeView = computed(() => viewMap[store.activeSystem] ?? InventorySystem)
</script>

<template>
  <main class="app-shell">
    <SystemMenu
      :systems="store.systems"
      :active-system="store.activeSystem"
      @select="store.setActiveSystem"
    />

    <section class="workspace">
      <SystemOverview :metrics="store.metrics" :player="store.player" />

      <section class="system-frame">
        <header class="system-header">
          <h1>{{ store.currentSystem.label }}</h1>
          <p>{{ store.currentSystem.description }}</p>
        </header>

        <component :is="activeView" :store="store" />
      </section>
    </section>
  </main>
</template>
