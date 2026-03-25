ESX = exports["es_extended"]:getSharedObject()
local ResourceName = GetCurrentResourceName()

GetName = function(a, b)
    return string.format("%s:%s:%s", ResourceName, a, b)
end

-- เริ่มต้นระบบ DevDEK
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('^2[D9 Inventory] Server Started^0')
    end
end)