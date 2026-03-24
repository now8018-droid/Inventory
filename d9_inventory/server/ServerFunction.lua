-- ตรวจสอบ Vehicle Model จากป้ายทะเบียน
ESX.RegisterServerCallback(GetCurrentResourceName()..':getVehicleModelByPlate', function(source, cb, plate)
    -- ควรเชื่อมต่อกับระบบ database ของรถคุณ
    -- คืนค่า model hash ของรถ DevDEK
    cb(nil)
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