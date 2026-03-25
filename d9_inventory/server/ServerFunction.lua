ESX = ESX or exports["es_extended"]:getSharedObject()

-- ตรวจสอบ Vehicle Model จากป้ายทะเบียน
ESX.RegisterServerCallback(GetCurrentResourceName()..':getVehicleModelByPlate', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not plate then
        cb(nil)
        return
    end

    MySQL.Async.fetchScalar([[
        SELECT vehicle
        FROM owned_vehicles
        WHERE plate = @plate AND owner = @owner
        LIMIT 1
    ]], {
        ['@plate'] = plate,
        ['@owner'] = xPlayer.identifier
    }, function(vehicleRaw)
        if not vehicleRaw then
            cb(nil)
            return
        end

        local ok, vehicleData = pcall(json.decode, vehicleRaw)
        if not ok or type(vehicleData) ~= "table" then
            cb(nil)
            return
        end

        cb(vehicleData.model)
    end)
end)

-- ระบบบันทึกการใช้งาน
RegisterNetEvent('d9_inventory:logAction')
AddEventHandler('d9_inventory:logAction', function(action, itemName, count)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()
    
    -- บันทึกการใช้งานลง database หรือ file
    print(('^5[INVENTORY LOG] %s %s %s จำนวน %s'):format(
        GetPlayerName(src), action, itemName, count
    ))
end)
