-- @class model

-- @field openui boolean
-- @field Isgive boolean
-- @field SecondType string

model = {
	openui = false,
	Isgive = false,
	SecondType = nil,
	SecondDataType = nil,
	SearchData = {}
}

local ENABLE_INVENTORY_SCREENBLUR = false
local LAST_SKIP_NOTIFY_AT = 0

-- @function checkItemCount
-- @param item_name string
-- @return number
-- function model:checkItemCount(item_name)
-- 	local data = {}
-- 	local playerData = ESX.GetPlayerData()
-- 	local inventory = playerData.inventory
-- 	for i = 1, #inventory do
-- 		local item = inventory[i]
-- 		if item_name == item.name then
-- 			return item.count
-- 		end
-- 	end
-- 	return 0
-- end
function model:BuildInventoryCount()
	local counts = {}
	local playerData = ESX.GetPlayerData()
	local inventory = playerData.inventory or {}
	for i = 1, #inventory do
		local item = inventory[i]
		if item and item.name then
			counts[item.name] = item.count or 0
		end
	end
	return counts
end

function model:checkItemCount(item_name)
	local counts = self._inventoryCounts
	if counts then
		return counts[item_name] or 0
	end
	local playerData = ESX.GetPlayerData()
	local inventory = playerData.inventory or {}
	for i = 1, #inventory do
		local item = inventory[i]
		if item_name == item.name then
			return item.count or 0
		end
	end
	return 0
end

-- @function checkHasItem
-- @param item_name string
-- @return boolean
function model:checkHasItem(item_name)
	local data = {}
	local playerData = ESX.GetPlayerData()
	local inventory = playerData.inventory
	for i = 1, #inventory do
		local item = inventory[i]
		if item_name == item.name then
			if item.count > 0 then
				return true
			end
		end
	end
	return false
end

-- @function checkHasWeapon
-- @param weapon_name string
-- @return boolean
function model:checkHasWeapon(weapon_name)
	for i = 1, #dataloadout do
		local item = dataloadout[i]
		if string.upper(weapon_name) == item.name then
			return true
		end
	end
	return false
end

-- @function getLabelWeapon
-- @param weapon string
-- @return string
function model:getLabelWeapon(weapon)
	local wea = ESX.GetWeaponList()
	local datawea = {}
	for i = 1, #wea do
		if string.upper(weapon) == wea[i].name then
			return wea[i].label
		end
	end
	return weapon
end

-- @function shouldSkipAccount
-- @param accountName string
-- @return boolean
function model:shouldSkipAccount(accountName)
	if not self._excludeAccountLookup then
		self._excludeAccountLookup = {}
		for _, value in ipairs(Config.ExcludeAccountsList) do
			self._excludeAccountLookup[value] = true
		end
	end
	return self._excludeAccountLookup[accountName] == true
end

-- @function OpenInventiry
function model:OpenInventiry()
	local items, fastslot = Client:GetmyInventory()
	local skipped = Client._inventorySkippedCount or 0
	local renderLimit = Client._inventoryRenderLimit or 250
	if skipped > 0 then
		local now = GetGameTimer()
		if now - LAST_SKIP_NOTIFY_AT > 10000 then
			LAST_SKIP_NOTIFY_AT = now
			ESX.ShowNotification(("~y~Performance mode: showing first %s items (%s hidden)"):format(renderLimit, skipped))
		end
	end
	if ENABLE_INVENTORY_SCREENBLUR then
		TriggerScreenblurFadeIn(50)
	end
	SetNuiFocus(true, true)
	Eventnui("openInventory", {
		items = items,
		fastslot = fastslot,
		-- myskin = model:Getmyskin()
	})
	self.openui = true
end

-- @function OnInventoryClose
exports("OnInventoryClose", function()
	model:CloseInventiry()
end)

-- backward compatibility alias (new name -> old typo)
function model:CloseInventory()
	return self:CloseInventiry()
end

-- @function CloseInventiry
function model:CloseInventiry()
	if GetResourceState("d9_trunk") == "started" then
		pcall(function()
			exports.d9_trunk:LeaveTrunk()
		end)
	end

	if ENABLE_INVENTORY_SCREENBLUR then
		TriggerScreenblurFadeOut(50)
	end
	Eventnui("closeInventory", {})
	self.openui = false
	self.SearchData = {}
	SetNuiFocus(false, false)
end

RegisterNetEvent("esx_inventoryhud:close")
AddEventHandler("esx_inventoryhud:close", function()
	model:CloseInventiry()
end)

-- @function Useitem
-- @param data table
function model:Useitem(data)

	if SettingItem.DisableUse[data.name] then
		return
	end

	if SettingItem.Useclose[data.name] then
		model:CloseInventiry()
	end

	pcall(function()
		exports.nc_discordlogs:Discord({
			webhook = "use",
			title = "ใช้สิ่งของ",
			description = ('ผู้เล่น %s ใช้ %s'):format(GetPlayerName(PlayerId()), data.name),
			color = "ff0000"
		})
	end)

	if data.type == "item_standard" then
		TriggerServerEvent("esx:useItem", data.name)
	elseif data.name == "id_card" then
		pcall(function()
			exports["jsp_idcard"]:triggerIdCardDisplayToNearby()
		end)
		model:CloseInventiry()
	elseif data.type == "item_key" then
		--exports.nc_vehiclekey:ToggleLockVehicle(data.label)
	elseif data.name == "mask" then
		TriggerEvent("skinchanger:getSkin", function(skin)
			if skin["mask_1"] == -1 then
				-- print('-1')
				local dict = "veh@bicycle@roadfront@base"
				local anim = "put_on_helmet"

				RequestAnimDict(dict)
				while not HasAnimDictLoaded(dict) do
					Citizen.Wait(0)
				end

				TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 2.0, -1, 48, 2, 0, 0, 0)

				Wait(1000)

				local accessorySkin = {}
				accessorySkin["mask_1"] = data.itemnum
				accessorySkin["mask_2"] = data.itemskin
				TriggerEvent("skinchanger:loadClothes", skin, accessorySkin)
			else
				if IsPedInAnyVehicle(PlayerPedId(), true) == false then
					local dict = "veh@bike@common@front@base"
					local anim = "take_off_helmet_walk"

					RequestAnimDict(dict)
					while not HasAnimDictLoaded(dict) do
						Citizen.Wait(0)
					end

					TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 2.0, -1, 48, 2, 0, 0, 0)

					Wait(800)
				end

				local accessorySkin = {}
				accessorySkin["mask_1"] = -1
				accessorySkin["mask_2"] = 0
				TriggerEvent("skinchanger:loadClothes", skin, accessorySkin)
			end
		end)
	end
end

function model:Giveitem(data)
	local Target = tonumber(data.id)
	local playerPed = PlayerPedId()
	log(SettingItem.DisableGive , SettingItem.DisableGive[data.item.name])
	if SettingItem.DisableGive and SettingItem.DisableGive[data.item.name] then
		model:CloseInventiry()
		return
	end

	local players, nearbyPlayer = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), Config.DistanceGive)
	local foundPlayer = false
	for i = 1, #players, 1 do
		if players[i] ~= PlayerId() then
			if GetPlayerServerId(players[i]) == Target then
				foundPlayer = true
			end
		end
	end

	if foundPlayer then
		ESX.Streaming.RequestAnimDict("gestures@m@car@low@casual@ps", function()
			TaskPlayAnim(
				PlayerPedId(),
				"gestures@m@car@low@casual@ps",
				"gesture_you_soft",
				8.0,
				-8.0,
				-1,
				48,
				0,
				false,
				false,
				false
			)
		end)

		local playertarget = GetPlayerPed(GetPlayerFromServerId(Target))
		if
			playertarget
			and not IsPedInAnyVehicle(playerPed, false)
			and not IsPedInAnyVehicle(playertarget, false)
			and IsPedOnFoot(playerPed)
			and IsPedOnFoot(playertarget)
			and not IsPedUsingAnyScenario(playerPed)
		then
			if data.item.type == 'item_key' then
				ESX.TriggerServerCallback(GetCurrentResourceName()..':getVehicleModelByPlate', function(hashModel)
						if hashModel then
							local modelName = GetDisplayNameFromVehicleModel(hashModel)
							local modelNameLower = string.lower(modelName)
							local nameCar = string.gsub(modelNameLower, "%s+", "_")
							TriggerServerEvent(GetName("sv", "giveItem"), Target, data.item.type, data.item.name, tonumber(data.number), data.item.label, Config.CarWelFare[nameCar])
						else
						TriggerEvent('pNotify:SendNotification', {
							text = 'ไม่พบข้อมูลรถ.!!!!',
							type = 'info',
							timeout = 2500,
							layout = 'centerRight',
							queue = 'global'
						})
					end
				end, data.item.label)
			else
				TriggerServerEvent(GetName("sv", "giveItem"), Target, data.item.type, data.item.name, tonumber(data.number))
			end
		end
	else
		ESX.ShowNotification("~r~ไม่พบผู้เล่นในระยะที่กำหนด")
	end

end

-- @function DropItem
-- @param data table
function model:DropItem(data)
	local playerPed = PlayerPedId()
	if IsPedSittingInAnyVehicle(playerPed) then
		return
	end

	if SettingItem.DisableRemove and SettingItem.DisableRemove[data.item.name] then
		return 
	end


	if data.item.type == "item_accessories" then
		TriggerServerEvent("esx_inventoryhud:DelAccessories", data.item.label)
	elseif type(data.number) == "number" and math.floor(data.number) == data.number then
		TriggerServerEvent("esx:removeInventoryItem", data.item.type, data.item.name, math.floor(data.number))
	end
end

-- @function GetWeapon
function model:GetWeapon()
	ESX.TriggerServerCallback("esx_inventoryhud:getPlayerInventory", function(data)
	end)
end


function model:CheckDisableSecond(SecondName, Typename, item)
	local cfg = SettingItem.DisableSecond[SecondName] and SettingItem.DisableSecond[SecondName][Typename]
	if not cfg then return false end
	local isListed = cfg.list[item.name] == true
	if cfg.type == "blacklist" then
		return isListed
	elseif cfg.type == "whitelist" then
		return not isListed
	end
	return false
end
