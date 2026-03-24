-- ตรวจสอบการโอนไอเทมระหว่างผู้เล่น
RegisterNetEvent("esx_inventoryhud:tradePlayerItem")
AddEventHandler("esx_inventoryhud:tradePlayerItem", function(from, to, itemType, itemName, count, tradeType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(from)
    local xTarget = ESX.GetPlayerFromId(to)
    
    if not xPlayer or not xTarget then return end
    
    -- ตรวจสอบการโกง
    if src ~= from then
        print(('^1[ANTICHEAT] %s พยายามโกงการโอนไอเทม'):format(GetPlayerName(src)))
        return
    end
    
    -- ตรวจสอบระยะทาง
    if #(GetEntityCoords(GetPlayerPed(from)) - GetEntityCoords(GetPlayerPed(to))) > 5.0 then
        return
    end
    
    count = ESX.Math.Round(count)
    
    if itemType == 'item_standard' then
        local item = xPlayer.getInventoryItem(itemName)
        if item and item.count >= count then
            xPlayer.removeInventoryItem(itemName, count)
            xTarget.addInventoryItem(itemName, count)
            
            -- Log การโอน
            print(('^3[TRADE] %s ให้ %s จำนวน %s %s'):format(
                GetPlayerName(from), GetPlayerName(to), count, itemName
            ))
        end
    elseif itemType == 'item_weapon' then
        if xPlayer.hasWeapon(itemName) then
            local weapon = xPlayer.getWeapon(itemName)
            xPlayer.removeWeapon(itemName)
            xTarget.addWeapon(itemName, weapon.ammo)
        end
    end
end)

-- ระบบค้นหาผู้เล่น
RegisterNetEvent(GetName('sv','SearchPlayer'))
AddEventHandler(GetName('sv','SearchPlayer'), function(SecondName, Typename, Action, items, count, job, SearchData)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(SearchData.id)
    
    if not xPlayer or not xTarget then return end
    
    -- ตรวจสอบสิทธิ์ (เช่น ตำรวจเท่านั้นที่ค้นหาได้)
    if Typename == 'police' and xPlayer.job.name ~= 'police' then
        return
    end
    
    count = ESX.Math.Round(count)
    
    if Action == "TakeFromSecond" then
        -- เอาไอเทมจากผู้เล่นที่ถูกค้น
        local item = xTarget.getInventoryItem(items.name)
        if item and item.count >= count then
            xTarget.removeInventoryItem(items.name, count)
            xPlayer.addInventoryItem(items.name, count)
        end
    elseif Action == "PutIntoSecond" then
        -- เอาไอเทมคืนให้ผู้เล่นที่ถูกค้น
        local item = xPlayer.getInventoryItem(items.name)
        if item and item.count >= count then
            xPlayer.removeInventoryItem(items.name, count)
            xTarget.addInventoryItem(items.name, count)
        end
    end
    
    -- อัพเดท Inventory ฝั่ง Client DevDEK
    TriggerClientEvent(GetName('cl','SearchRefresh'), xTarget.source, SecondName, Typename, {
        inventory = xTarget.getInventory(),
        accounts = xTarget.getAccounts(),
        weapons = xTarget.getLoadout()
    })
end)