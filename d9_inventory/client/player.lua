function Client:InitPlayer()
	local targetPlayer
	local targetPlayerName
	local typeopen = nil

	RegisEvent("esx_inventoryhud:openPlayerInventory", function(target, type)
		targetPlayer = target
		typeopen = type
		setPlayerInventoryData()
		Wait(150)
		openPlayerInventory()

		Citizen.CreateThread(function()
			while true do
				local closestPlayer, distance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and distance ~= -1 then
					target_id = GetPlayerServerId(closestPlayer)
					local closestPlayerPed = GetPlayerPed(closestPlayer)
					coords_b = GetEntityCoords(closestPlayerPed)
				end

				local coords_a = GetEntityCoords(PlayerPedId())

				if GetDistanceBetweenCoords(coords_a, coords_b, true) > 5.0 and model.openui then
					if target_id == targetPlayer then
						TriggerEvent("esx_inventoryhud:closeInventory")
						targetPlayer = nil
						break
					end
				end

				if not model.openui then
					targetPlayer = nil
					break
				end

				if IsEntityDead(PlayerPedId()) then
					TriggerEvent("esx_inventoryhud:closeInventory")
					targetPlayer = nil
					break
				end
				Citizen.Wait(500)
			end
		end)
	end)

	function openPlayerInventory()

		local items, fastslot = Client:GetmyInventory()
		Eventnui("setting", {
			items = items,
			fastslot = fastslot,
			selectfastslot = self.selectfastslot,
		})
		TriggerScreenblurFadeIn(100)
		SetNuiFocus(true, true)
		model.openui = true
	end

	function refreshPlayerInventory()
		setPlayerInventoryData()
		Wait(150)
		openPlayerInventory()
	end

	function setPlayerInventoryData()
		ESX.TriggerServerCallback("esx_inventoryhud:getPlayerInventory", function(data)
			if data ~= nil then
				items = {}
				inventory = data.inventory
				accounts = data.accounts
				money = data.money
				weapons = data.weapons

				if typeopen == "thief" then
					if inventory["newgang_card"] ~= nil and inventory["newgang_card"] <= 0 then
						if inventory["newplayer_card"] ~= nil and inventory["newplayer_card"] >= 1 then
							goto pass
						end
					end
				end



				-- if Config.IncludeAccounts and accounts ~= nil then
					for key, value in pairs(accounts) do
						if not model:shouldSkipAccount(accounts[key].name) then
							local canDrop = accounts[key].name ~= "bank"
							if accounts[key].money > 0 then
								accountData = {
									label = accounts[key].label,
									count = accounts[key].money,
									type = "item_account",
									name = accounts[key].name,
									usable = false,
									rare = false,
									limit = -1,
									canRemove = canDrop,
									canGive = SettingItem.DisableGive[accounts[key].name],
								}
								table.insert(items, accountData)
							end
						end
					end
				-- end

				if inventory ~= nil then
					local playerData = ESX.GetPlayerData()
					local datainven = playerData.inventory
					for k, v in pairs(datainven) do
						if inventory[v.name] and inventory[v.name] >= 1 then
							v.type = "item_standard"
							v.count = inventory[v.name]
							table.insert(items, v)
						end
					end
				end

				-- if Config.IncludeWeapons and weapons ~= nil then
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
								usable = false,
								rare = false,
								canRemove = true,
								canGive = SettingItem.DisableGive[weapons[key].name],
							})
						end
					end
				-- end

				Eventnui("secondinventory", {
					items = items,
                    type = 'player'
				})

				::pass::
			end
		end, targetPlayer)
	end

	RegisterNUICallback("TakeFromPlayer", function(data, cb)

		if not data then
			return
		end

		data.number = tonumber(data.number)

		local playerPed = PlayerPedId()
		ped = NetworkGetEntityFromNetworkId(targetPlayer)

		if IsPedSittingInAnyVehicle(playerPed) then
			return
		end

		if type(data.number) == "number" and math.floor(data.number) == data.number then
			local count = tonumber(data.number)
			if data.item.type == "item_weapon" then
				count = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.item.name))
			end
			
			TriggerServerEvent(
				"esx_inventoryhud:tradePlayerItem",
				targetPlayer,
				GetPlayerServerId(PlayerId()),
				data.item.type,
				data.item.name,
				count,
				typeopen
			)
			Wait(250)
			refreshPlayerInventory()
		end

		cb("ok")
	end)

	RegisterNUICallback("PutIntoPlayer", function(data, cb)

        if not data then
            return
        end

        data.number = tonumber(data.number)

		local playerPed = PlayerPedId()

		if IsPedSittingInAnyVehicle(playerPed) then
			return
		end
		if type(data.number) == "number" and math.floor(data.number) == data.number then
			local count = tonumber(data.number)
			if data.item.type == "item_weapon" then
				count = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.item.name))
			end
			TriggerServerEvent(
				"esx_inventoryhud:tradePlayerItem",
				GetPlayerServerId(PlayerId()),
				targetPlayer,
				data.item.type,
				data.item.name,
				count
			)
		end
		Wait(250)
		refreshPlayerInventory()
		cb("ok")
	end)

end
