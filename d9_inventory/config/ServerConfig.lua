ServerConfig = {
    Debug = true,
    MaxInventoryWeight = 50000, -- น้ำหนักสูงสุด
    AntiCheat = {
        Enable = true,
        MaxDistance = 10.0, -- ระยะทางสูงสุดในการโอนไอเทม
        LogSuspicious = true
    },
    Logging = {
        Enable = true,
        LogTrades = true,
        LogDrops = true,
        LogUses = true
    },
    Restrictions = {
        -- ข้อจำกัดต่างๆ DevDEK
        MaxItemTransfer = 100, -- โอนไอเทมได้สูงสุดครั้งละกี่ชิ้น
        TradeCooldown = 1000 -- มิลลิวินาที
    }
}