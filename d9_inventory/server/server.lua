Server = {}
ESX = ESX or exports["es_extended"]:getSharedObject()
local TRANSFER_MAX_DISTANCE = (Config and Config.DistanceGive) or 3.0
local TRANSFER_MAX_AMOUNT = (ServerConfig and ServerConfig.Restrictions and ServerConfig.Restrictions.MaxItemTransfer) or 1000
local MSG = {
    TOO_FAR = '~r~ผู้เล่นอยู่ไกลเกินไป',
    INVALID_AMOUNT = '~r~จำนวนไอเทมไม่ถูกต้อง',
    AMOUNT_EXCEEDED = '~r~จำนวนสูงสุดต่อครั้งคือ %s',
    NOT_ENOUGH_ITEM = '~r~คุณมีไอเทมไม่เพียงพอ',
    GIVE_ITEM_OK = '~g~ให้ไอเทมสำเร็จ',
    RECEIVE_ITEM = '~g~ได้รับไอเทมจาก %s',
    NOT_ENOUGH_MONEY = '~r~เงินสดไม่เพียงพอ',
    GIVE_MONEY_OK = '~g~ให้เงินสดสำเร็จ',
    RECEIVE_MONEY = '~g~ได้รับเงินสดจาก %s',
    NOT_ENOUGH_BLACK_MONEY = '~r~เงินดำไม่เพียงพอ',
    GIVE_BLACK_MONEY_OK = '~g~ให้เงินดำสำเร็จ',
    RECEIVE_BLACK_MONEY = '~g~ได้รับเงินดำจาก %s',
    NO_WEAPON = '~r~คุณไม่มีอาวุธชิ้นนี้',
    GIVE_WEAPON_OK = '~g~ให้อาวุธสำเร็จ',
    RECEIVE_WEAPON = '~g~ได้รับอาวุธจาก %s',
    NO_PLATE = '~r~ไม่พบข้อมูลป้ายทะเบียนรถ',
    WELFARE_BLOCK = '~r~รถคันนี้ไม่สามารถเทรดผ่าน Trade Car Welfare ได้',
}
local TRANSFER_ERROR_MESSAGE = {
    DISTANCE = function()
        return MSG.TOO_FAR
    end,
    INVALID_AMOUNT = function()
        return MSG.INVALID_AMOUNT
    end,
    AMOUNT_EXCEEDED = function()
        return MSG.AMOUNT_EXCEEDED:format(TRANSFER_MAX_AMOUNT)
    end
}
local TRANSFER_ACTION_LABEL = {
    item_standard = "ITEM",
    item_account = "ACCOUNT",
    item_weapon = "WEAPON",
    item_key = "VEHICLE_KEY",
}

local function notifyPlayer(xPlayer, message)
    if xPlayer and xPlayer.showNotification then
        xPlayer.showNotification(message)
    end
end

local function logTransfer(actionType, sourceId, targetId, itemName, amount, outcome)
    local actionLabel = TRANSFER_ACTION_LABEL[actionType] or tostring(actionType or "UNKNOWN")
    local sourceName = GetPlayerName(sourceId) or ("src:%s"):format(sourceId or "nil")
    local targetName = GetPlayerName(targetId) or ("tgt:%s"):format(targetId or "nil")
    print(('[TRANSFER][%s][%s] %s -> %s | %s x%s'):format(
        outcome or "INFO",
        actionLabel,
        sourceName,
        targetName,
        tostring(itemName or "unknown"),
        tostring(amount or 0)
    ))
end

local function getDistanceBetweenPlayers(source, target)
    local srcPed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(target)

    if srcPed <= 0 or targetPed <= 0 then
        return math.huge
    end

    return #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
end

local VALIDATION_RULES = {
    function(ctx)
        if not ctx.xPlayer or not ctx.xTarget then
            return false, 'INVALID_PLAYER'
        end
        return true
    end,
    function(ctx)
        if ctx.source == ctx.target then
            return false, 'SELF_TRANSFER'
        end
        return true
    end,
    function(ctx)
        if ctx.amount < 1 then
            return false, 'INVALID_AMOUNT'
        end
        return true
    end,
    function(ctx)
        if ctx.amount > TRANSFER_MAX_AMOUNT then
            return false, 'AMOUNT_EXCEEDED'
        end
        return true
    end,
    function(ctx)
        if getDistanceBetweenPlayers(ctx.source, ctx.target) > TRANSFER_MAX_DISTANCE then
            return false, 'DISTANCE'
        end
        return true
    end,
    function(ctx)
        if Security and Security.ValidateTransfer then
            if not Security.ValidateTransfer(ctx.source, ctx.target, ctx.itemType, ctx.itemName, ctx.amount) then
                return false, 'SECURITY_BLOCK'
            end
        end
        return true
    end
}

local function validateTransfer(source, target, itemType, itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)

    if type(amount) ~= 'number' then
        amount = tonumber(amount) or 0
    end

    local ctx = {
        source = source,
        target = target,
        itemType = itemType,
        itemName = itemName,
        amount = ESX.Math.Round(amount),
        xPlayer = xPlayer,
        xTarget = xTarget,
    }
    for i = 1, #VALIDATION_RULES do
        local ok, reason = VALIDATION_RULES[i](ctx)
        if not ok then
            return false, reason
        end
    end

    return true, ctx.amount, xPlayer, xTarget
end

local function transferStandardItem(xPlayer, xTarget, itemName, amount)
    local item = xPlayer.getInventoryItem(itemName)
    if not item or item.count < amount then
        notifyPlayer(xPlayer, MSG.NOT_ENOUGH_ITEM)
        return
    end

    xPlayer.removeInventoryItem(itemName, amount)
    xTarget.addInventoryItem(itemName, amount)
    notifyPlayer(xPlayer, MSG.GIVE_ITEM_OK)
    notifyPlayer(xTarget, MSG.RECEIVE_ITEM:format(GetPlayerName(xPlayer.source)))
    logTransfer('item_standard', xPlayer.source, xTarget.source, itemName, amount, "SUCCESS")
end

local function transferAccountMoney(xPlayer, xTarget, itemName, amount)
    if itemName == 'money' then
        if xPlayer.getMoney() < amount then
            notifyPlayer(xPlayer, MSG.NOT_ENOUGH_MONEY)
            return
        end
        xPlayer.removeMoney(amount)
        xTarget.addMoney(amount)
        notifyPlayer(xPlayer, MSG.GIVE_MONEY_OK)
        notifyPlayer(xTarget, MSG.RECEIVE_MONEY:format(GetPlayerName(xPlayer.source)))
        logTransfer('item_account', xPlayer.source, xTarget.source, itemName, amount, "SUCCESS")
        return
    end

    if itemName == 'black_money' then
        local account = xPlayer.getAccount('black_money')
        if not account or account.money < amount then
            notifyPlayer(xPlayer, MSG.NOT_ENOUGH_BLACK_MONEY)
            return
        end
        xPlayer.removeAccountMoney('black_money', amount)
        xTarget.addAccountMoney('black_money', amount)
        notifyPlayer(xPlayer, MSG.GIVE_BLACK_MONEY_OK)
        notifyPlayer(xTarget, MSG.RECEIVE_BLACK_MONEY:format(GetPlayerName(xPlayer.source)))
        logTransfer('item_account', xPlayer.source, xTarget.source, itemName, amount, "SUCCESS")
    end
end

local function transferWeapon(xPlayer, xTarget, itemName)
    if not xPlayer.hasWeapon(itemName) then
        notifyPlayer(xPlayer, MSG.NO_WEAPON)
        return
    end

    local weaponData = xPlayer.getWeapon(itemName) or {}
    local weaponAmmo = weaponData.ammo or 0
    xPlayer.removeWeapon(itemName)
    xTarget.addWeapon(itemName, weaponAmmo)

    notifyPlayer(xPlayer, MSG.GIVE_WEAPON_OK)
    notifyPlayer(xTarget, MSG.RECEIVE_WEAPON:format(GetPlayerName(xPlayer.source)))
    logTransfer('item_weapon', xPlayer.source, xTarget.source, itemName, weaponAmmo, "SUCCESS")
end

local function transferVehicleKey(xPlayer, xTarget, plate, isWelfare)
    if not plate or plate == '' then
        notifyPlayer(xPlayer, MSG.NO_PLATE)
        return
    end

    if isWelfare == false then
        notifyPlayer(xPlayer, MSG.WELFARE_BLOCK)
        return
    end

    if GiveVehicleKeyToPlayer then
        GiveVehicleKeyToPlayer(xPlayer.source, xTarget.source, plate)
        logTransfer('item_key', xPlayer.source, xTarget.source, plate, 1, "SUCCESS")
        return
    end

    TriggerEvent('d9_inventory:giveVehicleKey', xTarget.source, plate)
    logTransfer('item_key', xPlayer.source, xTarget.source, plate, 1, "SUCCESS")
end

local TRANSFER_EXECUTOR = {
    item_standard = function(xPlayer, xTarget, itemName, amount)
        transferStandardItem(xPlayer, xTarget, itemName, amount)
    end,
    item_account = function(xPlayer, xTarget, itemName, amount)
        transferAccountMoney(xPlayer, xTarget, itemName, amount)
    end,
    item_weapon = function(xPlayer, xTarget, itemName)
        transferWeapon(xPlayer, xTarget, itemName)
    end,
    item_key = function(xPlayer, xTarget, itemName, amount, customData, isWelfare)
        transferVehicleKey(xPlayer, xTarget, customData or itemName, isWelfare)
    end
}

local function buildPlayerInventoryPayload(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then
        return nil
    end

    local inventoryMap = {}
    for _, item in pairs(xPlayer.getInventory() or {}) do
        inventoryMap[item.name] = item.count
    end

    return {
        inventory = inventoryMap,
        accounts = xPlayer.getAccounts(),
        weapons = xPlayer.getLoadout(),
        money = xPlayer.getMoney(),
    }
end

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(playerId)
    TriggerClientEvent("esx_inventoryhud:GetVehicleKey", playerId)
    TriggerClientEvent("esx_inventoryhud:GetAccessories", playerId)
end)

RegisterNetEvent("esx_inventoryhud:getOwnerVehicle")
AddEventHandler("esx_inventoryhud:getOwnerVehicle", function()
    TriggerClientEvent("esx_inventoryhud:GetVehicleKey", source)
end)

RegisterNetEvent("esx_inventoryhud:getOwnerAccessories")
AddEventHandler("esx_inventoryhud:getOwnerAccessories", function()
    TriggerClientEvent("esx_inventoryhud:GetAccessories", source)
end)

RegisterNetEvent(GetName("sv", "giveItem"))
AddEventHandler(GetName("sv", "giveItem"), function(target, itemType, itemName, amount, customData, isWelfare)
    ProcessInventoryTransfer(source, target, itemType, itemName, amount, customData, isWelfare)
end)

function ProcessInventoryTransfer(source, target, itemType, itemName, amount, customData, isWelfare)
    local isValid, amountOrReason, xPlayer, xTarget = validateTransfer(source, target, itemType, itemName, amount)
    if not isValid then
        local msgBuilder = TRANSFER_ERROR_MESSAGE[amountOrReason]
        if msgBuilder then
            notifyPlayer(xPlayer, msgBuilder())
        end
        logTransfer(itemType, source, target, itemName, amount, amountOrReason)
        return false
    end

    local finalAmount = amountOrReason

    local executor = TRANSFER_EXECUTOR[itemType]
    if not executor then
        logTransfer(itemType, source, target, itemName, amount, "UNSUPPORTED_TYPE")
        return false
    end
    executor(xPlayer, xTarget, itemName, finalAmount, customData, isWelfare)
    return true
end

ESX.RegisterServerCallback(GetName("sv", "getPlayerInventory"), function(source, cb, target)
    cb(buildPlayerInventoryPayload(target))
end)

ESX.RegisterServerCallback("esx_inventoryhud:getPlayerInventory", function(source, cb, target)
    cb(buildPlayerInventoryPayload(target))
end)

ESX.RegisterServerCallback(GetName("callback", "Vehicle"), function(source, cb)
    if GetOwnedVehiclesForPlayer then
        GetOwnedVehiclesForPlayer(source, cb)
        return
    end
    cb({})
end)

ESX.RegisterServerCallback(GetName("callback", "Accessories"), function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({})
        return
    end

    MySQL.Async.fetchScalar('SELECT skin FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(skinRaw)
        if not skinRaw then
            cb({})
            return
        end

        local ok, skin = pcall(json.decode, skinRaw)
        if not ok or type(skin) ~= 'table' then
            cb({})
            return
        end

        if skin.mask_1 and skin.mask_1 >= 0 then
            cb({
                mask = json.encode({
                    mask_1 = skin.mask_1,
                    mask_2 = skin.mask_2 or 0,
                })
            })
            return
        end

        cb({})
    end)
end)

RegisterNetEvent("esx_inventoryhud:DelAccessories")
AddEventHandler("esx_inventoryhud:DelAccessories", function(accessoryLabel)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if accessoryLabel ~= 'mask' then
        return
    end

    if xPlayer then
        MySQL.Async.fetchScalar('SELECT skin FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(skinRaw)
            if not skinRaw then return end

            local ok, skin = pcall(json.decode, skinRaw)
            if not ok or type(skin) ~= 'table' then return end

            skin.mask_1 = -1
            skin.mask_2 = 0

            MySQL.Async.execute('UPDATE users SET skin = @skin WHERE identifier = @identifier', {
                ['@skin'] = json.encode(skin),
                ['@identifier'] = xPlayer.identifier
            })
        end)
    end

    TriggerClientEvent("esx_inventoryhud:setmask", src, {
        mask_1 = -1,
        mask_2 = 0,
    })
end)
