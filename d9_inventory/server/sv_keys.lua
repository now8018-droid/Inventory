ESX = exports["es_extended"]:getSharedObject()

function GetOwnedVehiclesForPlayer(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({})
        return
    end

    MySQL.Async.fetchAll('SELECT plate, vehicle FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = xPlayer.identifier
    }, function(result)
        local vehicles = {}
        for i = 1, #result do
            local vehicleProps = json.decode(result[i].vehicle or "{}") or {}
            local model = vehicleProps.model
            local label = result[i].plate

            -- NOTE:
            -- GetDisplayNameFromVehicleModel / GetLabelText เป็น native ฝั่ง client
            -- ฝั่ง server เรียกไม่ได้ (จะเป็น nil) จึงใช้ fallback เป็น model/plate แทน
            if model then
                label = tostring(model)
            end

            vehicles[#vehicles + 1] = {
                plate = result[i].plate,
                model = model,
                label = label
            }
        end
        cb(vehicles)
    end)
end

local function done(callback, success, reason)
    if callback then
        callback(success, reason)
    end
end

-- ให้กุญแจรถ
function GiveVehicleKeyToPlayer(src, target, plate, callback)
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(target)

    if not xPlayer or not xTarget then
        done(callback, false, "INVALID_PLAYER")
        return
    end

    if type(plate) ~= "string" or plate == "" then
        xPlayer.showNotification('~r~ทะเบียนรถไม่ถูกต้อง')
        done(callback, false, "INVALID_PLATE")
        return
    end
    
    -- ตรวจสอบว่าเป็นเจ้าของรถจริง
    MySQL.Async.fetchScalar('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(owner)
        if owner == xPlayer.identifier then
            -- เพิ่มกุญแจให้ผู้เล่นเป้าหมาย
            MySQL.Async.execute('INSERT INTO vehicle_keys (identifier, plate, given_by) VALUES (@identifier, @plate, @given_by)', {
                ['@identifier'] = xTarget.identifier,
                ['@plate'] = plate,
                ['@given_by'] = xPlayer.identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    xPlayer.showNotification('~g~ให้กุญแจรถหมายเลข ' .. plate .. ' สำเร็จ')
                    xTarget.showNotification('~g~ได้รับกุญแจรถหมายเลข ' .. plate .. ' จาก ' .. GetPlayerName(src))
                    done(callback, true, "SUCCESS")
                else
                    xPlayer.showNotification('~r~ไม่สามารถให้กุญแจรถได้')
                    done(callback, false, "INSERT_FAILED")
                end
            end)
        else
            xPlayer.showNotification('~r~คุณไม่ใช่เจ้าของรถคันนี้')
            done(callback, false, "NOT_OWNER")
        end
    end)
end

RegisterNetEvent('d9_inventory:giveVehicleKey')
AddEventHandler('d9_inventory:giveVehicleKey', function(target, plate)
    GiveVehicleKeyToPlayer(source, target, plate)
end)

-- ใช้กุญแจล็อครถ Devdek
RegisterNetEvent('d9_inventory:useVehicleKey')
AddEventHandler('d9_inventory:useVehicleKey', function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    -- ตรวจสอบว่ามีกุญแจหรือเป็นเจ้าของ
    MySQL.Async.fetchScalar('SELECT 1 FROM owned_vehicles WHERE plate = @plate AND owner = @owner', {
        ['@plate'] = plate,
        ['@owner'] = xPlayer.identifier
    }, function(owned)
        if owned then
            TriggerClientEvent('d9_inventory:lockVehicle', src, plate)
            return
        end
        
        -- ตรวจสอบกุญแจที่ได้รับ
        MySQL.Async.fetchScalar('SELECT 1 FROM vehicle_keys WHERE plate = @plate AND identifier = @identifier', {
            ['@plate'] = plate,
            ['@identifier'] = xPlayer.identifier
        }, function(hasKey)
            if hasKey then
                TriggerClientEvent('d9_inventory:lockVehicle', src, plate)
            else
                xPlayer.showNotification('~r~คุณไม่มีกุญแจรถคันนี้')
            end
        end)
    end)
end)
