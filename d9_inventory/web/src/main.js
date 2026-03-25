import { seedItems } from './utils/mockData.js'

const style = document.createElement('style')
style.textContent = `
  :root {
    font-family: Inter, 'Segoe UI', Roboto, sans-serif;
    color: #e2e8f0;
    background: #020617;
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: radial-gradient(circle at top, #1e293b 0%, #020617 65%); }
  #app { min-height: 100vh; }
  .app-shell { min-height: 100vh; display: grid; grid-template-columns: 320px 1fr; }
  .menu-panel { border-right: 1px solid #1e293b; background: rgba(2, 6, 23, 0.95); padding: 24px; }
  .brand-top { color: #38bdf8; letter-spacing: .08em; text-transform: uppercase; margin: 0; }
  .brand h2 { margin-top: 6px; }
  .menu-list { display: grid; gap: 10px; margin-top: 20px; }
  .menu-item { width: 100%; text-align: left; border: 1px solid #334155; background: #0f172a; color: inherit; border-radius: 12px; padding: 12px; display: flex; gap: 10px; }
  .menu-item.active { border-color: #38bdf8; background: #082f49; }
  .menu-item small { color: #94a3b8; display: block; }
  .workspace { padding: 24px; display: grid; gap: 20px; }
  .overview-grid { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 12px; }
  .player-card,.metric-card,.panel,.system-header { border: 1px solid #334155; border-radius: 14px; background: rgba(15, 23, 42, 0.86); padding: 14px; }
  .player-card { grid-column: span 2; }
  .label { margin: 0; color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: .08em; }
  .tags { display: flex; gap: 8px; flex-wrap: wrap; }
  .tags span { background: #1e293b; padding: 6px 8px; border-radius: 999px; }
  .system-frame { display: grid; gap: 12px; }
  .system-header h1 { margin: 0 0 6px; }
  .system-header p { margin: 0; color: #cbd5e1; }
  .slot-grid { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 10px; }
  .slot-item { border: 1px solid #475569; background: #1e293b; color: inherit; border-radius: 10px; padding: 10px; text-align: left; display: grid; gap: 4px; }
  .row { display: flex; align-items: center; }
  .row.between { justify-content: space-between; }
  @media (max-width: 1280px) {
    .overview-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .player-card { grid-column: span 2; }
  }
  @media (max-width: 920px) {
    .app-shell { grid-template-columns: 1fr; }
    .menu-panel { border-right: 0; border-bottom: 1px solid #1e293b; }
  }
`
document.head.appendChild(style)

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
        ${systems.map((system, index) => `
            <button class="menu-item ${index === 0 ? 'active' : ''}" type="button">
              <div><strong>${system.label}</strong><small>${system.description}</small></div>
            </button>
        `).join('')}
      </nav>
    </aside>

    <section class="workspace">
      <section class="overview-grid">
        <article class="player-card">
          <p class="label">Player</p>
          <h3>DevDEK#1001</h3>
          <div class="tags"><span>Police</span><span>Rank 3</span><span>Online</span></div>
        </article>

        ${metrics.map((metric) => `
          <article class="metric-card"><p class="label">${metric.label}</p><h3>${metric.value}</h3></article>
        `).join('')}
      </section>

      <section class="system-frame">
        <header class="system-header">
          <h1>Inventory</h1>
          <p>UI จากโฟลเดอร์ src พร้อมแสดงผลบนหน้าเว็บแล้ว</p>
        </header>
        <section class="panel">
          <h3>รายการไอเท็ม</h3>
          <div class="slot-grid">
            ${seedItems.map((item) => `
              <article class="slot-item">
                <strong>${item.label}</strong>
                <small>${item.description}</small>
                <div class="row between"><span>x${item.quantity}</span><span>${item.weight} kg</span></div>
              </article>
            `).join('')}
          </div>
        </section>
      </section>
    </section>
  </main>
`
