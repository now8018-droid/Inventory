const icon = 'https://dummyimage.com/96x96/1f2937/ffffff.png&text=ITEM'

export const seedItems = [
  {
    id: 1,
    label: 'Water',
    description: 'น้ำดื่มสำหรับฟื้นฟูความเหนื่อยล้า',
    category: 'consumable',
    quantity: 10,
    weight: 0.3,
    icon,
  },
  {
    id: 2,
    label: 'Bread',
    description: 'อาหารพื้นฐานสำหรับฟื้นฟูพลังงาน',
    category: 'consumable',
    quantity: 7,
    weight: 0.4,
    icon,
  },
  {
    id: 3,
    label: 'Pistol Ammo',
    description: 'กระสุนปืนพก 9mm',
    category: 'ammo',
    quantity: 60,
    weight: 0.02,
    icon,
  },
  {
    id: 4,
    label: 'Repair Kit',
    description: 'ใช้ซ่อมแซมยานพาหนะฉุกเฉิน',
    category: 'tool',
    quantity: 2,
    weight: 1.1,
    icon,
  },
]
