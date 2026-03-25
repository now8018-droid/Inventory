local function isWithinDistance(fromSource, toSource, maxDistance)
    local fromPed = GetPlayerPed(fromSource)
    local toPed = GetPlayerPed(toSource)
    if fromPed <= 0 or toPed <= 0 then
        return false
    end

    local distance = #(GetEntityCoords(fromPed) - GetEntityCoords(toPed))
    return distance <= maxDistance
end

local function canSearchTarget(xPlayer, xTarget, typeName)
    if not xPlayer or not xTarget then
        return false
    end

    if typeName == 'police' and xPlayer.job.name ~= 'police' then
        return false
    end

    return isWithinDistance(xPlayer.source, xTarget.source, 5.0)
end

-- ตรวจสอบการโอนไอเทมระหว่างผู้เล่น
RegisterNetEvent("esx_inventoryhud:tradePlayerItem")
AddEventHandler("esx_inventoryhud:tradePlayerItem", function(from, to, itemType, itemName, count, tradeType)
    local src = source
    local xTarget = ESX.GetPlayerFromId(to)
    if not xTarget then return end
    
    -- ตรวจสอบการโกง
    if from and src ~= from then
        print(('^1[ANTICHEAT] %s พยายามโกงการโอนไอเทม'):format(GetPlayerName(src)))
        return
    end
    
    -- ตรวจสอบระยะทาง
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(to))) > 5.0 then
        return
    end
    
    count = ESX.Math.Round(count)

    if ProcessInventoryTransfer then
        ProcessInventoryTransfer(src, to, itemType, itemName, count)
    end
end)

-- ระบบค้นหาผู้เล่น
RegisterNetEvent(GetName('sv','SearchPlayer'))
AddEventHandler(GetName('sv','SearchPlayer'), function(SecondName, Typename, Action, items, count, job, SearchData)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not SearchData or not SearchData.id then return end
    local xTarget = ESX.GetPlayerFromId(SearchData.id)
    
    if not canSearchTarget(xPlayer, xTarget, Typename) then return end
    
    count = ESX.Math.Round(count)
    if count < 1 then return end
    
    if Action == "TakeFromSecond" then
        -- เอาไอเทมจากผู้เล่นที่ถูกค้น
        local item = xTarget.getInventoryItem(items.name)
        if item and item.count >= count then
            xTarget.removeInventoryItem(items.name, count)
            xPlayer.addInventoryItem(items.name, count)
            print(('[SEARCH] %s took %s x%s from %s'):format(GetPlayerName(src), items.name, count, GetPlayerName(xTarget.source)))
        end
    elseif Action == "PutIntoSecond" then
        -- เอาไอเทมคืนให้ผู้เล่นที่ถูกค้น
        local item = xPlayer.getInventoryItem(items.name)
        if item and item.count >= count then
            xPlayer.removeInventoryItem(items.name, count)
            xTarget.addInventoryItem(items.name, count)
            print(('[SEARCH] %s returned %s x%s to %s'):format(GetPlayerName(src), items.name, count, GetPlayerName(xTarget.source)))
        end
    end
    
    -- อัพเดท Inventory ฝั่ง Client DevDEK
    TriggerClientEvent(GetName('cl','SearchRefresh'), xTarget.source, SecondName, Typename, {
        inventory = xTarget.getInventory(),
        accounts = xTarget.getAccounts(),
        weapons = xTarget.getLoadout()
    })
end)
