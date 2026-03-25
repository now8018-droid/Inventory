ESX = exports["es_extended"]:getSharedObject()

-- โหลดสกินอาวุธของผู้เล่นเมื่อเข้าเกม DevDEK
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    LoadPlayerWeaponSkins(xPlayer.source)
end)

function LoadPlayerWeaponSkins(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.Async.fetchAll('SELECT weapon_name, skin_component FROM user_weapon_skins WHERE owner = @owner', {
        ['@owner'] = xPlayer.identifier
    }, function(skins)
        TriggerClientEvent('d9_inventory:loadWeaponSkins', source, skins)
    end)
end

-- ตั้งค่าสกินอาวุธ
RegisterNetEvent(GetName("sv", "SetSkinWeapon"))
AddEventHandler(GetName("sv", "SetSkinWeapon"), function(weapon, skin)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- ตรวจสอบว่ามีอาวุธนี้หรือไม่
    if not xPlayer.hasWeapon(weapon) then
        xPlayer.showNotification('~r~คุณไม่มีอาวุธนี้')
        return
    end
    
    -- ตรวจสอบว่ามีไอเทมสกินหรือไม่
    local skinConfig = Skinweapon.General[weapon]
    if not skinConfig or not skinConfig[skin] then
        xPlayer.showNotification('~r~สกินนี้ไม่ถูกต้อง')
        return
    end
    
    local requiredItem = skinConfig[skin].require
    local item = xPlayer.getInventoryItem(requiredItem)
    
    if not item or item.count < 1 then
        xPlayer.showNotification('~r~คุณไม่มีไอเทม: ' .. requiredItem)
        return
    end
    
    -- บันทึกสกิน
    MySQL.Async.execute([[
        INSERT INTO user_weapon_skins (owner, weapon_name, skin_component) 
        VALUES (@owner, @weapon, @skin) 
        ON DUPLICATE KEY UPDATE skin_component = @skin
    ]], {
        ['@owner'] = xPlayer.identifier,
        ['@weapon'] = weapon,
        ['@skin'] = skin
    }, function(rowsChanged)
        if rowsChanged > 0 then
            -- ลบไอเทมสกิน
            xPlayer.removeInventoryItem(requiredItem, 1)
            xPlayer.showNotification('~g~ตั้งค่าสกินอาวุธสำเร็จ: ' .. skinConfig[skin].label)
            
            -- อัพเดทสกินให้ผู้เล่น
            TriggerClientEvent('d9_inventory:applyWeaponSkin', src, weapon, skin)
        end
    end)
end)

-- ลบสกินอาวุธ
RegisterNetEvent(GetName("sv", "ClearSkinWeapon"))
AddEventHandler(GetName("sv", "ClearSkinWeapon"), function(weapon)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    MySQL.Async.execute('DELETE FROM user_weapon_skins WHERE owner = @owner AND weapon_name = @weapon', {
        ['@owner'] = xPlayer.identifier,
        ['@weapon'] = weapon
    }, function(rowsChanged)
        if rowsChanged > 0 then
            xPlayer.showNotification('~g~ลบสกินอาวุธสำเร็จ')
            TriggerClientEvent('d9_inventory:clearWeaponSkin', src, weapon)
        end
    end)
end)

-- ดึงข้อมูลสกินทั้งหมด
ESX.RegisterServerCallback('d9_inventory:getPlayerSkins', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.Async.fetchAll('SELECT weapon_name, skin_component FROM user_weapon_skins WHERE owner = @owner', {
        ['@owner'] = xPlayer.identifier
    }, function(skins)
        local skinData = {}
        for i=1, #skins do
            skinData[skins[i].weapon_name] = skins[i].skin_component
        end
        cb(skinData)
    end)
end)