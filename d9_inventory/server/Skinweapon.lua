RegisterNetEvent(GetName("sv", "SetSkinWeapon"))
AddEventHandler(GetName("sv", "SetSkinWeapon"), function(weapon, skin)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- ตรวจสอบว่าผู้เล่นมีไอเทมที่ต้องการหรือไม่
    -- โค้ดนี้ควรปรับให้เข้ากับระบบสกินของคุณ
end)

RegisterNetEvent(GetName("sv", "ClearSkinWeapon"))
AddEventHandler(GetName("sv", "ClearSkinWeapon"), function(weapon)
    local src = source
    -- ลบสกินอาวุธ
end)