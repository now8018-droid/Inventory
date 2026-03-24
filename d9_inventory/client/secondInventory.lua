function Client:InitSecondInventory()
	-- @param SecondType string
	-- @param Typename string
	-- @param inventory table
	-- @param itemlist table
	exports("setSecondaryInventory", function(SecondType, Typename, inventory, infotext)
		Client:setSecondaryInventory(SecondType, Typename, inventory, infotext)
	end)

	exports("RefreshSecondInventory", function(SecondType, Typename, inventory, infotext)
		Client:RefreshSecondInventory(SecondType, Typename, inventory, infotext)
	end)

	-- @param SecondType string
	-- @param Typename string
	-- @param itemlist table
	-- @param infotext string
	function Client:setSecondaryInventory(SecondType, Typename, itemlist, infotext)
		model.SecondType = SecondType
		model.SecondDataType = Typename

		items = {}
		items = itemlist

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

		local firstInventory, fastslot = Client:GetmyInventory()

        log('infotext')
        log(DumpTable(infotext))
		Eventnui("setSecondaryInventory", {
			InfoText = infotext,
			FirstInventory = firstInventory,
			SecondInventory = items,
			type = SecondType,
			disableSecond = SettingItem.DisableSecond[SecondType] and SettingItem.DisableSecond[SecondType][model.SecondDataType] or false,
		})
		TriggerScreenblurFadeIn(100)
		SetNuiFocus(true, true)
		model.openui = true
	end

	function Client:RefreshSecondInventory(SecondType, Typename, inventory, infotext)
		model.SecondType = SecondType
		model.SecondDataType = Typename

		items = {}
		items = inventory

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
		end

		Eventnui("RefreshSecondInventory", {
			InfoText = infotext,
			SecondInventory = items,
			type = SecondType,
			disableSecond = SettingItem.DisableSecond[SecondType] and SettingItem.DisableSecond[SecondType][model.SecondDataType]
				or false,
		})
	end

	exports("SearchPlayer", function(type, target, infotext)
		Client:SearchPlayer(type, target, infotext)
	end)


	function Client:SearchPlayer(type, target, infotext)
		print(target)
		model.SecondType = 'search'
		model.SecondDataType = type
		ESX.TriggerServerCallback("esx_inventoryhud:getPlayerInventory", function(data)

			local SecondType = 'search'
			local items = {}
			local inventory = data.inventory
			local accounts = data.accounts
			local weapons = data.weapons
			log(DumpTable(inventory))
			for key, value in pairs(accounts) do
				if not model:shouldSkipAccount(accounts[key].name) then
					local canDrop = accounts[key].name ~= "bank"
					if accounts[key].money > 0 then
						local accountData = {
							label = accounts[key].label,
							count = accounts[key].money,
							type = "item_account",
							name = accounts[key].name,
							notGive = false,
							notRemove = canDrop,
							rare = false,
							limit = -1,
							position = "secondinventory",
						}
						table.insert(items, accountData)
					end
				end
			end
		
			for key, value in pairs(weapons) do
				local weaponHash = GetHashKey(weapons[key].name)
				local playerPed = PlayerPedId()
				if weapons[key].name ~= "WEAPON_UNARMED" then
					local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)

					table.insert(items, {
						label = weapons[key].label,
						count = ammo,
						limit = -1,
						type = "item_weapon",
						name = weapons[key].name,
						notUse = false,
						notRemove = SettingItem.DisableRemove[weapons[key].name],
						notGive = SettingItem.DisableGive[weapons[key].name],
						rare = false,
						position = "secondinventory",
						skin = dataskin or nil,
					})
				end
			end
		
			if inventory ~= nil then
				local playerData = ESX.GetPlayerData()
				local datainven = playerData.inventory
				for k, v in pairs(datainven) do
					if inventory[v.name] and inventory[v.name] >= 1 then
						v.type = "item_standard"
						v.count = inventory[v.name]
						v.notUse = SettingItem.DisableUse[v.name]
						v.notGive = SettingItem.DisableGive[v.name]
						v.notRemove = SettingItem.DisableRemove[v.name]
						v.rare = false
						v.position = "secondinventory"
						table.insert(items, v)
					end
				end
			end


			for k, v in pairs(items) do
				local founditem = false
				for category, value in pairs(Config.Category) do
					for index, data in pairs(value) do
						if Config.Category[category][index] == items[k].name then
							items[k].category = category
							founditem = true
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
		
				-- items[k].fashion = fashion[items[k].name] or nil
				items[k].info = self.infoitem[items[k].name] or nil
				items[k].template = Template.items[items[k].name] or 0
		
				if items[k].name == "garden_water_can" then
					local waterCanCurrrent, waterCanMax = exports["jsp_garden"]:GetWaterCan()
					items[k].info = {
						detail = ('ใช้สำหรับรดน้ำต้นไม้ในสวน (น้ำคงเหลือ: %s/%s)'):format(waterCanCurrrent, waterCanMax),
						where = {'ร้านค้าทั่วไป'},
						rare = 1,
					}
				end
			end

			model.SearchData.id = target
			local firstInventory, fastslot = Client:GetmyInventory()
			Eventnui("setSecondaryInventory", {
				InfoText = infotext,
				FirstInventory = firstInventory,
				SecondInventory = items,
				type = SecondType,
				disableSecond = SettingItem.DisableSecond[SecondType] and SettingItem.DisableSecond[SecondType][model.SecondDataType] or false,
			})
			TriggerScreenblurFadeIn(100)
			SetNuiFocus(true, true)
			model.openui = true

			log(SecondType,Typename)
		end, target)
	end

	function Client:RefreshSearch(SecondType, Typename ,data, infotext)
		local SecondType = 'search'
		local items = {}
		local inventory = data.inventory
		local accounts = data.accounts
		local weapons = data.weapons
		log(DumpTable(inventory))
		for key, value in pairs(accounts) do
			if not model:shouldSkipAccount(accounts[key].name) then
				local canDrop = accounts[key].name ~= "bank"
				if accounts[key].money > 0 then
					local accountData = {
						label = accounts[key].label,
						count = accounts[key].money,
						type = "item_account",
						name = accounts[key].name,
						notGive = false,
						notRemove = canDrop,
						rare = false,
						limit = -1,
						position = "secondinventory",
					}
					table.insert(items, accountData)
				end
			end
		end
	
		for key, value in pairs(weapons) do
			local weaponHash = GetHashKey(weapons[key].name)
			local playerPed = PlayerPedId()
			if weapons[key].name ~= "WEAPON_UNARMED" then
				local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)

				table.insert(items, {
					label = weapons[key].label,
					count = ammo,
					limit = -1,
					type = "item_weapon",
					name = weapons[key].name,
					notUse = false,
					notRemove = SettingItem.DisableRemove[weapons[key].name],
					notGive = SettingItem.DisableGive[weapons[key].name],
					rare = false,
					position = "secondinventory",
					skin = dataskin or nil,
				})
			end
		end
	
		if inventory ~= nil then
			local playerData = ESX.GetPlayerData()
			local datainven = playerData.inventory
			for k, v in pairs(datainven) do
				if inventory[v.name] and inventory[v.name] >= 1 then
					v.type = "item_standard"
					v.count = inventory[v.name]
					v.notUse = SettingItem.DisableUse[v.name]
					v.notGive = SettingItem.DisableGive[v.name]
					v.notRemove = SettingItem.DisableRemove[v.name]
					v.rare = false
					v.position = "secondinventory"
					table.insert(items, v)
				end
			end
		end


		for k, v in pairs(items) do
			local founditem = false
			for category, value in pairs(Config.Category) do
				for index, data in pairs(value) do
					if Config.Category[category][index] == items[k].name then
						items[k].category = category
						founditem = true
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
	
			-- items[k].fashion = fashion[items[k].name] or nil
			items[k].info = self.infoitem[items[k].name] or nil
			items[k].template = Template.items[items[k].name] or 0
	
			if items[k].name == "garden_water_can" then
				local waterCanCurrrent, waterCanMax = exports["jsp_garden"]:GetWaterCan()
				items[k].info = {
					detail = ('ใช้สำหรับรดน้ำต้นไม้ในสวน (น้ำคงเหลือ: %s/%s)'):format(waterCanCurrrent, waterCanMax),
					where = {'ร้านค้าทั่วไป'},
					rare = 1,
				}
			end
		end

		-- model.SearchData.id = target
		-- local firstInventory, fastslot = Client:GetmyInventory()
		Eventnui("RefreshSecondInventory", {
			InfoText = infotext,
			SecondInventory = items,
			type = SecondType,
			disableSecond = SettingItem.DisableSecond[SecondType] and SettingItem.DisableSecond[SecondType][model.SecondDataType] or false,
		})
	end
	
	
	RegisEvent(GetName('cl','SearchRefresh'), function(SecondType, Typename, inventory)
		log('SearchRefresh')
		Client:RefreshSearch(SecondType, Typename, inventory, {label = 'BUILD SEARCH PLAYER'})
	end)
end
