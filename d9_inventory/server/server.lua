Server = {}

-- Event พื้นฐาน
RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    TriggerClientEvent("esx_inventoryhud:getOwnerVehicle", playerId)
    TriggerClientEvent("esx_inventoryhud:getOwnerAccessories", playerId)
end)

-- รับไอเทมจากผู้เล่นอื่น
RegisterNetEvent(GetName("sv", "giveItem"))
AddEventHandler(GetName("sv", "giveItem"), function(target, itemType, itemName, amount, customData)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)
    
    if not xPlayer or not xTarget then return end
    
    -- ตรวจสอบระยะทาง
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target))) > 10.0 then
        xPlayer.showNotification('~r~ผู้เล่นอยู่ไกลเกินไป')
        return
    end
    
    amount = ESX.Math.Round(amount)
    
    if itemType == 'item_standard' then
        local item = xPlayer.getInventoryItem(itemName)
        if item.count >= amount then
            xPlayer.removeInventoryItem(itemName, amount)
            xTarget.addInventoryItem(itemName, amount)
            xPlayer.showNotification('~g~ให้ไอเทมสำเร็จ')
            xTarget.showNotification('~g~ได้รับไอเทมจาก ' .. GetPlayerName(source))
        else
            xPlayer.showNotification('~r~คุณมีไอเทมไม่เพียงพอ')
        end
    elseif itemType == 'item_account' then
        if itemName == 'money' then
            if xPlayer.getMoney() >= amount then
                xPlayer.removeMoney(amount)
                xTarget.addMoney(amount)
                xPlayer.showNotification('~g~ให้เงินสำเร็จ')
                xTarget.showNotification('~g~ได้รับเงินจาก ' .. GetPlayerName(source))
            end
        elseif itemName == 'black_money' then
            if xPlayer.getAccount('black_money').money >= amount then
                xPlayer.removeAccountMoney('black_money', amount)
                xTarget.addAccountMoney('black_money', amount)
                xPlayer.showNotification('~g~ให้เงินดำสำเร็จ')
                xTarget.showNotification('~g~ได้รับเงินดำจาก ' .. GetPlayerName(source))
            end
        end
    elseif itemType == 'item_weapon' then
        if xPlayer.hasWeapon(itemName) then
            local weaponAmmo = xPlayer.getWeapon(itemName).ammo or 0
            xPlayer.removeWeapon(itemName)
            xTarget.addWeapon(itemName, weaponAmmo)
            xPlayer.showNotification('~g~ให้อาวุธสำเร็จ')
            xTarget.showNotification('~g~ได้รับอาวุธจาก ' .. GetPlayerName(source))
        end
    end
end)

-- ค้นหาข้อมูลผู้เล่น
ESX.RegisterServerCallback(GetName("sv", "getPlayerInventory"), function(source, cb, target)
    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then return cb(nil) end
    
    local inventory = {}
    local accounts = xPlayer.getAccounts()
    local weapons = xPlayer.getLoadout()
    
    -- แปลง inventory DevDEK
    for k,v in pairs(xPlayer.getInventory()) do
        inventory[v.name] = v.count
    end
    
    cb({
        inventory = inventory,
        accounts = accounts,
        weapons = weapons,
        money = xPlayer.getMoney()
    })
end)

-- ระบบ Vehicle Keys
ESX.RegisterServerCallback(GetName("callback", "Vehicle"), function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
 -- ควรเชื่อมต่อกับระบบคีย์รถของคุณ Devdek
    cb({})
end)

-- ระบบ Accessories
ESX.RegisterServerCallback(GetName("callback", "Accessories"), function(source, cb)
    -- ควรเชื่อมต่อกับระบบเสื้อผ้า/หน้ากาก
    cb({})
end)