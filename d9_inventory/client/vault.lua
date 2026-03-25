function Client:InitVault()
	function refreshVaultInventory()
		data = exports["monster_vault"]:getMonsterVaultLicense()
		ESX.TriggerServerCallback("monster_vault:getVaultInventory", function(inventory)
			setVaultInventoryData(inventory)
		end, data, true)
	end

	local vaultType

	function setVaultInventoryData(inventory)
		openVaultInventory()
		items = {}

		SendNUIMessage({
			action = "setInfoText",
			text = inventory.job,
		})

		items = inventory.itemlist
		vaultType = inventory.job

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

			items[k].notUse = SettingItem.DisableUse[items[k].name]
			items[k].notGive = SettingItem.DisableGive[items[k].name]
			items[k].notRemove = SettingItem.DisableRemove[items[k].name]
			items[k].template = Template.items[items[k].name] or 0
			items[k].info = Infoitem[items[k].name] or {}
			items[k].position = "secondinventory"
		end

		model.SecondType = 'vault'
		model.SecondDataType = inventory.job
		
		Eventnui("secondinventory", {
			items = items,
            type = 'vault'
		})

	end

	function openVaultInventory()
		local items, fastslot = Client:GetmyInventory()
		Eventnui("UpdateDataInventory", {
			items = items,
			-- fastslot = fastslot,
		})
		TriggerScreenblurFadeIn(100)
		SetNuiFocus(true, true)
		model.openui = true
	end

	RegisterNUICallback("PutIntoVault", function(value, cb)
		local data = value
		if IsPedSittingInAnyVehicle(playerPed) then
			return
		end

		if SettingItem.disablePutIntoVault and SettingItem.disablePutIntoVault[data.item.name] == nil
			or SettingItem.disablePutIntoVault[data.item.name] == false
			or SettingItem.BypassVault
				and SettingItem.BypassVault[vaultType]
				and SettingItem.BypassVault[vaultType][data.item.name]
		then
			if type(data.number) == "number" and math.floor(data.number) == data.number then
				local count = 0

				if data.item.type == "item_weapon" then
					count = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.item.name))
					exports["d9_vault"]:putin(data)
				else
					if data.number > data.item.count or data.number == 0 then
						count = tonumber(data.item.count)
					else
						count = tonumber(data.number)
					end
					exports["d9_vault"]:putin(data)
				end
			end
		else
		end

		Wait(250)
		loadPlayerInventory()

		cb("ok")
	end)
	RegisterNUICallback("TakeFromVault", function(value, cb)
		local data = value
		-- local data = value.itemdata
		if IsPedSittingInAnyVehicle(playerPed) then
			return
		end

		if type(data.number) == "number" and math.floor(data.number) == data.number then
			local count = 0
			if data.number > data.item.count or data.number == 0 then
				count = tonumber(data.item.count)
			else
				count = tonumber(data.number)
			end
			exports["d9_vault"]:takein(data)
		end

		Wait(250)
		loadPlayerInventory()
		cb("ok")
	end)

	RegisterNetEvent("d9_inventory:openVaultInventory")
	AddEventHandler("d9_inventory:openVaultInventory", function(data)
		setVaultInventoryData(data)
	end)

	openvault = function(items)
		for k, v in pairs(items) do
			local founditem = false
			for category, value in pairs(Config.Category) do
				for index, data in pairs(value) do
					if Config.Category[category][index] == items[k].name then
						items[k].category = category
						-- founditem = true
						-- break
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
	end

end