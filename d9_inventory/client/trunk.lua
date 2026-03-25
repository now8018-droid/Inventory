function Client:Inittrunk()
	local trunkData = nil

	function loadPlayerInventory()
		local items, fastslot = Client:GetmyInventory()
		Eventnui("setting", {
			items = items,
			fastslot = fastslot,
			selectfastslot = self.selectfastslot,
		})
		-- TriggerScreenblurFadeIn(100)
		-- SetNuiFocus(true, true)
		-- model.openui = true
	end

	RegisterNetEvent("esx_inventoryhud:refreshTrunkInventory")
	AddEventHandler("esx_inventoryhud:refreshTrunkInventory", function(data, blackMoney, inventory, weapons)
		setTrunkInventoryData(data, blackMoney, inventory, weapons)
	end)

	RegisterNetEvent("esx_inventoryhud:openTrunkInventory")
	AddEventHandler("esx_inventoryhud:openTrunkInventory", function(items, data)
		-- TriggerScreenblurFadeIn(300)
		-- SendNUIMessage({
		-- 	action = "setSecondInventoryItems",
		-- 	itemList = items,
		-- 	data = data,
		-- })
		setTrunkInventoryData(items, data)
	end)

	local PutIntoTrunk = false
	RegisterNUICallback("PutIntoTrunk", function(data, cb)
		TriggerEvent('d9_trunk:cl:OnPut', data)
		cb(true)
	end)

	RegisterNUICallback("TakeFromTrunk", function(data, cb)
		-- print(ESX.DumpTable(data.number))
		TriggerEvent('d9_trunk:cl:OnTake', data)
		cb(true)
	end)

	-- local TakeFromTrunk = false
	-- RegisterNUICallback("TakeFromTrunk", function(data, cb)
	-- 	local var = {
	-- 		name = data.item.name,
	-- 		count = data.count,
	-- 	}
	-- 	-- print('----------------------------------------------------')
	-- 	-- print('TakeFromTrunk')
	-- 	if IsPedSittingInAnyVehicle(playerPed) then
	-- 		return
	-- 	end
	-- 	if not TakeFromTrunk then
	-- 		TakeFromTrunk = true
	-- 		local rdm = math.random(0, 1000) --ดึงของพร้อมกัน
	-- 		Wait(rdm)
	-- 		if type(data.number) == "number" and math.floor(data.number) == data.number then
	-- 			TriggerEvent("xzero_trunk:CL:OnTake", data)
	-- 			-- TriggerServerEvent("meeta_carinventory:getItem", data.item.id, trunkData.plate, data.item.type, data.item.name, tonumber(data.number), data.item.label, trunkData.max)
	-- 		end
	-- 		local player = GetPlayerPed(-1)
	-- 		local dict = "mp_am_hold_up"
	-- 		RequestAnimDict(dict)
	-- 		while not HasAnimDictLoaded(dict) do
	-- 			Citizen.Wait(0)
	-- 		end
	-- 		TaskPlayAnim(player, dict, "purchase_beerbox_shopkeeper", 8.0, 2.0, -1, 48, 2, 0, 0, 0)
	-- 		Wait(500)
	-- 		loadPlayerInventory()
	-- 		cb("ok")
	-- 		TakeFromTrunk = false
	-- 	else
	-- 		--closeInventory()
	-- 	end
	-- end)

	function setTrunkInventoryData(Inventory, info)
		openVaultInventory()
		local items = {}
		items = Inventory
		for i = 1, #items, 1 do
			items[i].position = "secondinventory"
		end

		for k, v in pairs(items) do
			local founditem = false
			for category, value in pairs(Config.Category) do

				for index, data in pairs(value) do
					if Config.Category[category][index] == items[k].name then
						items[k].category = category
						founditem = true
					end
				end
			end

			if founditem == false then
				if items[k].type == "item_key" or items[k].type == "item_keyhouse" then
					items[k].category = "key"
				elseif items[k].type == "item_weapon" then
					items[k].category = "weapon"
				elseif items[k].type == "item_accessories" then
					items[k].category = "clothes"
				else
					items[k].category = "all"
				end
			end
		end

		Eventnui("secondinventory", {
			items = items,
			type = "trunk",
			dataveh = info
		})
	end

end
