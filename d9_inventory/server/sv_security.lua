ESX = exports["es_extended"]:getSharedObject()

Security = {
    cooldowns = {},
    transfers = {}
}

-- ตรวจสอบการโอนไอเทม
function Security.ValidateTransfer(source, target, itemType, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)
    
    -- ตรวจสอบพื้นฐาน
    if not xPlayer or not xTarget then
        Security.LogSuspicious(source, "INVALID_PLAYER", "Attempted transfer to non-existent player")
        return false
    end
    
    -- ตรวจสอบระยะทาง
    if not Security.CheckDistance(source, target, 10.0) then
        Security.LogSuspicious(source, "DISTANCE_VIOLATION", "Transfer beyond allowed distance")
        return false
    end
    
    -- ตรวจสอบจำนวน
    if count <= 0 or count > 1000 then
        Security.LogSuspicious(source, "INVALID_COUNT", "Suspicious item count: " .. count)
        return false
    end
    
    -- ตรวจสอบ Cooldown
    if not Security.CheckCooldown(source, 'transfer', 1000) then
        Security.LogSuspicious(source, "COOLDOWN_VIOLATION", "Transfer too fast")
        return false
    end
    
    -- ตรวจสอบไอเทม DevDEK
    if itemType == 'item_standard' then
        local item = xPlayer.getInventoryItem(itemName)
        if not item or item.count < count then
            Security.LogSuspicious(source, "ITEM_MISSING", "Attempted to transfer non-existent items")
            return false
        end
        
        -- ตรวจสอบน้ำหนัก
        if not Security.CheckWeight(xTarget, itemName, count) then
            xPlayer.showNotification('~r~ผู้เล่นเป้าหมายน้ำหนักไม่พอ')
            return false
        end
    end
    
    return true
end

-- ตรวจสอบระยะทาง
function Security.CheckDistance(source, target, maxDistance)
    local srcPed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(target)
    
    if not DoesEntityExist(srcPed) or not DoesEntityExist(targetPed) then
        return false
    end
    
    local distance = #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
    return distance <= maxDistance
end

-- ตรวจสอบ Cooldown
function Security.CheckCooldown(source, action, cooldownTime)
    local key = source .. '_' .. action
    local currentTime = GetGameTimer()
    
    if Security.cooldowns[key] and (currentTime - Security.cooldowns[key]) < cooldownTime then
        return false
    end
    
    Security.cooldowns[key] = currentTime
    return true
end

-- ตรวจสอบน้ำหนัก
function Security.CheckWeight(xPlayer, itemName, count)
    -- ต้องปรับให้เข้ากับระบบน้ำหนักของคุณ
    -- สมมติใช้ระบบ ESX เดิม
    local currentWeight = exports.es_extended:GetTotalWeight(xPlayer.identifier)
    local itemWeight = ESX.GetItemWeight(itemName)
    local maxWeight = ESX.GetConfig().MaxWeight
    
    return (currentWeight + (itemWeight * count)) <= maxWeight
end

-- บันทึกการกระทำน่าสงสัย
function Security.LogSuspicious(source, type, details)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local playerName = GetPlayerName(source)
    local identifier = xPlayer.identifier
    
    print(('^1[SECURITY] %s (%s) - %s: %s^0'):format(
        playerName, identifier, type, details
    ))
    
    -- บันทึกลง database
    MySQL.Async.execute([[
        INSERT INTO security_logs (identifier, player_name, log_type, details, server_time)
        VALUES (@identifier, @player_name, @log_type, @details, NOW())
    ]], {
        ['@identifier'] = identifier,
        ['@player_name'] = playerName,
        ['@log_type'] = type,
        ['@details'] = details
    })
end

-- ตรวจสอบการโกง
function Security.ScanForCheats(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- ตรวจสอบไอเทมที่ไม่ควรมี
    local bannedItems = {'admin_weapon', 'cheat_money'}
    for _, itemName in ipairs(bannedItems) do
        local item = xPlayer.getInventoryItem(itemName)
        if item and item.count > 0 then
            Security.TakeAction(source, "BANNED_ITEMS", "Player has banned items: " .. itemName)
            return
        end
    end
    
    -- ตรวจสอบเงินที่ผิดปกติ
    local money = xPlayer.getMoney()
    local blackMoney = xPlayer.getAccount('black_money').money
    
    if money > 100000000 or blackMoney > 50000000 then -- 100M / 50M
        Security.LogSuspicious(source, "SUSPICIOUS_MONEY", "Extreme money values")
    end
end

-- การดำเนินการเมื่อพบการโกง
function Security.TakeAction(source, reason, details)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    print(('^1[CHEAT DETECTED] %s (%s) - %s: %s^0'):format(
        GetPlayerName(source), xPlayer.identifier, reason, details
    ))
    
    -- ลบไอเทมที่โกง
    xPlayer.setMoney(0)
    xPlayer.setAccountMoney('black_money', 0)
    
    -- เตือนผู้เล่น
    TriggerClientEvent('chat:addMessage', source, {
        args = {'^1[SYSTEM]', 'ตรวจพบการทำงานผิดปกติ กรุณาติดต่อ Staff'}
    })
    
    -- Kick ผู้เล่น
    DropPlayer(source, "Anti-Cheat: " .. reason)
end

-- สแกนผู้เล่นทุก 5 นาที
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 นาที
        
        local players = ESX.GetPlayers()
        for i=1, #players do
            Security.ScanForCheats(players[i])
        end
    end
end)
