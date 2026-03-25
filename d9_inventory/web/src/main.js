import { seedItems } from './utils/mockData.js'

const systems = [
  { id: 'inventory', label: 'Inventory', description: 'จัดการไอเท็มหลักและไอเท็มด่วน' },
  { id: 'status', label: 'Status', description: 'ตรวจสอบสถานะตัวละครโดยรวม' },
  { id: 'garage', label: 'Garage', description: 'ดูรถที่จัดเก็บในโรงรถ' },
]

const metrics = [
  { label: 'Weight', value: '67.5 / 120 kg' },
  { label: 'Slots', value: '43 / 70' },
  { label: 'Cash', value: '$23,900' },
]

const app = document.querySelector('#app')

app.innerHTML = `
  <main class="app-shell">
    <aside class="menu-panel">
      <div class="brand">
        <p class="brand-top">D9 Inventory</p>
        <h2>Game Control Panel</h2>
      </div>

      <nav class="menu-list">
        ${systems
          .map(
            (system, index) => `
              <button class="menu-item ${index === 0 ? 'active' : ''}" type="button">
                <div>
                  <strong>${system.label}</strong>
                  <small>${system.description}</small>
                </div>
              </button>
            `,
          )
          .join('')}
      </nav>
    </aside>

    <section class="workspace">
      <section class="overview-grid">
        <article class="player-card">
          <p class="label">Player</p>
          <h3>DevDEK#1001</h3>
          <div class="tags">
            <span>Police</span>
            <span>Rank 3</span>
            <span>Online</span>
          </div>
        </article>

        ${metrics
          .map(
            (metric) => `
              <article class="metric-card">
                <p class="label">${metric.label}</p>
                <h3>${metric.value}</h3>
              </article>
            `,
          )
          .join('')}
      </section>

      <section class="system-frame">
        <header class="system-header">
          <h1>Inventory</h1>
          <p>UI จากโฟลเดอร์ src พร้อมแสดงผลบนหน้าเว็บแล้ว</p>
        </header>

        <section class="panel">
          <h3>รายการไอเท็ม</h3>
          <div class="slot-grid">
            ${seedItems
              .map(
                (item) => `
                  <article class="slot-item">
                    <strong>${item.label}</strong>
                    <small>${item.description}</small>
                    <div class="row between">
                      <span>x${item.quantity}</span>
                      <span>${item.weight} kg</span>
                    </div>
                  </article>
                `,
              )
              .join('')}
          </div>
        </section>
      </section>
    </section>
  </main>
`
