Client = {
	KeyVehicle = {},
	Accessories = {},
	infoweapon = {},
	MyWeapon = {},
	fastWeapons = {},
	allfastslot = {},
	selectfastslot = nil,
	cooldown = false,
	fashion = {},

	meleeatk = false,

}

local function awaitServerCallback(name, ...)
	local p = promise.new()
	ESX.TriggerServerCallback(name, function(result)
		p:resolve(result)
	end, ...)
	return Citizen.Await(p)
end

function Client:GetAccessories()
	local result = awaitServerCallback(GetName("callback", "Accessories"))
	self.Accessories = result or {}
	return self.Accessories
end

RegisterNetEvent("esx_inventoryhud:GetAccessories")
AddEventHandler("esx_inventoryhud:GetAccessories", function()
	Client:GetAccessories()
end)

-- function Client:GetWeapon()
-- 	local result = lib.callback.await(GetName("callback", "Weapon"))
-- 	self.MyWeapon = result
-- 	return self.MyWeapon
-- end

function Client:GetVehicle()
	local result = awaitServerCallback(GetName("callback", "Vehicle"))
	self.KeyVehicle = result
	return self.KeyVehicle
end

RegisterNetEvent("esx_inventoryhud:GetVehicleKey")
AddEventHandler("esx_inventoryhud:GetVehicleKey", function()
	Client:GetVehicle()
end)

RegisterNetEvent("d9_inventory:lockVehicle")
AddEventHandler("d9_inventory:lockVehicle", function(plate)
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local vehicle = ESX.Game.GetClosestVehicle(coords)

	if vehicle == 0 then
		ESX.ShowNotification("~r~ไม่พบรถใกล้ตัว")
		return
	end

	local vehiclePlate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
	if vehiclePlate ~= ESX.Math.Trim(plate or "") then
		ESX.ShowNotification("~r~คุณไม่ได้อยู่ใกล้รถทะเบียนนี้")
		return
	end

	local isLocked = GetVehicleDoorLockStatus(vehicle) == 2
	SetVehicleDoorsLocked(vehicle, isLocked and 1 or 2)
	SetVehicleDoorsLockedForAllPlayers(vehicle, not isLocked)
	PlayVehicleDoorCloseSound(vehicle, 1)
	ESX.ShowNotification(isLocked and "~g~ปลดล็อครถแล้ว" or "~y~ล็อครถแล้ว")
end)

local updateDebounce = nil

function Client:UpdateInventory()
    if updateDebounce then
        updateDebounce.cancelled = true
    end

    local thisTimer = {}
    updateDebounce = thisTimer

    CreateThread(function()
        Wait(500)
        if thisTimer.cancelled then return end

        xWeapon:RefreshSkin()
        local items, fastslot = Client:GetmyInventory()
        Eventnui("updateitem", {
            items = items,
            fastslot = fastslot,
        })

        print("Inventory Updated")
        updateDebounce = nil
    end)
end

function Client:InitRegis()
	AddEventHandler("esx:onPlayerDeath", function(data)
		IsDead = true
	end)

	AddEventHandler("playerSpawned", function()
		IsDead = false
	end)

	RegisterNetEvent("bt_attacher:onAttach", function(item_name)
		self.fashion[item_name] = true
		Client:UpdateInventory()
	end)

	RegisterNetEvent("bt_attacher:onDetach", function(item_name)
		self.fashion[item_name] = nil
		Client:UpdateInventory()
	end)

		RegisEvent("esx_inventoryhud:setmask", function(skin)
			if type(skin) == "table" then
				self.Accessories.mask = json.encode({
					mask_1 = skin.mask_1 or -1,
					mask_2 = skin.mask_2 or 0,
				})
			else
				self.Accessories.mask = skin
			end
			Client:UpdateInventory()
		end)

	RegisEvent("wonder_invnetory:updatekey", function(skin)
		Client:GetVehicle()
	end)

	RegisterNetEvent("esx:addWeapon")
	AddEventHandler("esx:addWeapon", function(weaponName, ammo)
		local playerPed = PlayerPedId()
		local weaponHash = GetHashKey(weaponName)
		GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
		Client:UpdateInventory()
	end)

	RegisterNetEvent("esx:addWeaponComponent")
	AddEventHandler("esx:addWeaponComponent", function(weaponName, weaponComponent)
		local playerPed = PlayerPedId()
		local weaponHash = GetHashKey(weaponName)
		local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
		GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
		Client:UpdateInventory()
	end)

	RegisterNetEvent("esx:removeWeapon")
	AddEventHandler("esx:removeWeapon", function(weaponName, ammo)
		local playerPed = PlayerPedId()
		local weaponHash = GetHashKey(weaponName)
		RemoveWeaponFromPed(playerPed, weaponHash)
		if ammo then
			local pedAmmo = GetAmmoInPedWeapon(playerPed, weaponHash)
			local finalAmmo = math.floor(pedAmmo - ammo)
			SetPedAmmo(playerPed, weaponHash, finalAmmo)
		else
			SetPedAmmo(playerPed, weaponHash, 0) -- remove leftover ammo
		end
		Client:UpdateInventory()
	end)

	RegisterNetEvent("esx:removeWeaponComponent")
	AddEventHandler("esx:removeWeaponComponent", function(weaponName, weaponComponent)
		local playerPed = PlayerPedId()
		local weaponHash = GetHashKey(weaponName)
		local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

		RemoveWeaponComponentFromPed(playerPed, weaponHash, componentHash)
	end)

	RegisterNetEvent("esx:setAccountMoney")
	AddEventHandler("esx:setAccountMoney", function(account)
		for k, v in ipairs(ESX.PlayerData.accounts) do
			if "black_money" == account.name then
				ESX.PlayerData.accounts[k] = account
				break
			end
		end

		Wait(100)
		-- Client:UpdateInventory()
		Eventnui("updateonlyitemcount", {
			type = "item_account",
			position = "inventory",
			name = account.name,
			count = account.money,
		})
	end)

	RegisterNetEvent("esx:removeInventoryItem")
	AddEventHandler("esx:removeInventoryItem", function(item, count)
		for k, v in ipairs(ESX.PlayerData.inventory) do
			if v.name == item.name then
				pcall(function()
					exports.nc_discordlogs:Discord({
						webhook = "drop",
						title = "ทิ้งสิ่งของ",
						description = ('ผู้เล่น %s ทิ้ง %s จำนวน %s '):format(GetPlayerName(PlayerId()), item.name, count),
						color = "ff0000"
					})
				end)
				ESX.PlayerData.inventory[k] = item
				break
			end
		end

		-- Wait(100)
		-- Client:UpdateInventory()
		Eventnui("updateonlyitemcount", {
			type = "item_standard",
			position = "inventory",
			name = item,
			count = count,
		})
	end)
	RegisterNetEvent("esx:addInventoryItem")
	AddEventHandler("esx:addInventoryItem", function(item, count)
		for k, v in ipairs(ESX.PlayerData.inventory) do
			if v.name == item.name then
				ESX.PlayerData.inventory[k] = item
				break
			end
		end

		-- Wait(100)
		-- Client:UpdateInventory()
		Eventnui("updateonlyitemcount", {
			type = "item_standard",
			position = "inventory",
			name = item,
			count = count,
		})
	end)


	RegisterNetEvent("esx_inventoryhud:refreshInventory")
	AddEventHandler("esx_inventoryhud:refreshInventory", function()
		Client:UpdateInventory()
	end)

	RegisterNetEvent("es:activateMoney")
	AddEventHandler("es:activateMoney", function(money)
		ESX.PlayerData.money = money
		Wait(100)
		Client:UpdateInventory()
	end)

	RegisterNetEvent("esx:playerLoaded")
	AddEventHandler("esx:playerLoaded", function(xPlayer)
		TriggerServerEvent("esx_inventoryhud:getOwnerVehicle")
		TriggerServerEvent("esx_inventoryhud:getOwnerAccessories")
		ESX.PlayerData = xPlayer
	end)

	AddEventHandler("onResourceStart", function(resource)
		if resource == GetCurrentResourceName() then
			while ESX == nil do
				Citizen.Wait(0)
			end
			TriggerServerEvent("esx_inventoryhud:getOwnerVehicle")
			TriggerServerEvent("esx_inventoryhud:getOwnerAccessories")
		end
	end)

	RegisterNetEvent("d9_mailbox:cl:update")
	AddEventHandler("d9_mailbox:cl:update", function(data)
		if not data then
			return
		end
		Eventnui("updateMailbox", {
			data = data,
		})
	end)
end
