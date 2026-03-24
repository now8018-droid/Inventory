function model:InitNUI()
	RegisterNUICallback("closeinventory", function()
		model:CloseInventiry()
	end)

	RegisterNUICallback("UseItem", function(data, cb)
		if not data then
			return
		end
		model:Useitem(data.item)
		cb(true)
	end)

	function Draw3dText(coords, text, outline, color, scale)
		RegisterFontFile("font4thai");
		local fontId = RegisterFontId("font4thai");
		local camCoords = GetGameplayCamCoord()
		local dist = #(coords - camCoords)
		local xscale = 200 / (GetGameplayCamFov() * dist)
		
		SetTextFont(fontId)
		if scale then
			SetTextScale(0, xscale * scale)
		else
			SetTextScale(0, xscale * 0.8)
		end
		if outline then
			SetTextOutline()
		end
		if color then
			SetTextColour(color.r, color.g, color.b, 255)
		end
		SetTextCentre(true)
		BeginTextCommandDisplayText("STRING")
		AddTextComponentSubstringPlayerName(text)
		SetDrawOrigin(coords.x, coords.y, coords.z + 1.0, 0)
		EndTextCommandDisplayText(0, 0)
		ClearDrawOrigin()
	end

	function SelectNearbyPlayer()
		local p = promise.new()
		local nearbyPlayers = {}
		local key = {
			[1] = 157,
			[2] = 158,
			[3] = 160,
			[4] = 164,
			[5] = 165,
			[6] = 159,
			[7] = 161,
		}
		local updateNearbyPlayers = function()
			local myCoords = GetEntityCoords(PlayerPedId())
			local totalPlayers = 0
			for _, player in ipairs(GetActivePlayers()) do
				if NetworkIsPlayerActive(player) and player ~= PlayerId() then
					local targetPed = GetPlayerPed(player)
					local targetCoords = GetEntityCoords(targetPed, false)
					local distance = #(myCoords - targetCoords)
					if distance <= 10 then
						totalPlayers = totalPlayers + 1
						nearbyPlayers[totalPlayers] = {
							id = player,
							distance = distance
						}
					end
				end
			end
			for i = 1, math.min(7, totalPlayers) do
				for j = i + 1, totalPlayers do
					if nearbyPlayers[j].distance < nearbyPlayers[i].distance then
						nearbyPlayers[i], nearbyPlayers[j] = nearbyPlayers[j], nearbyPlayers[i]
					end
				end
			end
		end

		local isPressed = function(input, key)
			return IsControlPressed(input, key) or IsDisabledControlPressed(input, key)
		end

		CreateThread(function()
			isOpenPlayerNearby = true
			blockFastLost = true
			updateNearbyPlayers()
			while isOpenPlayerNearby do
				Wait(0)
				-- ปุ่ม ESC/BACKSPACE เพื่อปิดเมนู
				if isPressed(0, 202) then
					isOpenPlayerNearby = false
					SetTimeout(500, function()
						blockFastLost = false
					end)
					Eventnui("closePlayerNearby", {})
					p:resolve(nil)
				end

				-- ปุ่ม SPACEBAR เพื่อรีเฟรชผู้เล่นที่อยู่ใกล้
				if isPressed(0, 22) then
					updateNearbyPlayers()
					Wait(100)
				end
				
				for index, playerInfo in ipairs(nearbyPlayers) do
					local targetPed = GetPlayerPed(playerInfo.id)
					local targetCoords = GetEntityCoords(targetPed)
					local myCoords = GetEntityCoords(PlayerPedId())
					local distance = #(myCoords - targetCoords)
					local targetId = GetPlayerServerId(playerInfo.id)
					if distance <= 1.5 then
						local targetCoords = GetEntityCoords(GetPlayerPed(playerInfo.id))
						if (Player(targetId).state.HaveMusroomParty ~= true) then
							Draw3dText(vector3(targetCoords.x, targetCoords.y, targetCoords.z + 0.1), "~w~กด ~b~"..index.." ~w~เพื่อเลือก", true, nil, 0.6)
							if isPressed(0, key[index]) then
								isOpenPlayerNearby = false
								SetTimeout(500, function()
									blockFastLost = false
								end)
								Eventnui("closePlayerNearby", {})
								p:resolve(targetId)
							end
						else
							Draw3dText(vector3(targetCoords.x, targetCoords.y, targetCoords.z + 0.1), "~c~กด "..index.." เพื่อเลือก", true, nil, 0.6)
						end
					elseif distance <= 10 then
						Draw3dText(vector3(targetCoords.x, targetCoords.y, targetCoords.z + 0.1), "~c~กด "..index.." เพื่อเลือก", true, nil, 0.6)
					end
				end
			end
		end)

		Eventnui("openPlayerNearby", {})
		return Citizen.Await(p)
	end

	RegisterNUICallback("GiveItem", function(data, cb)
		if not data then
			return
		end
		model:CloseInventiry()
		data.id = SelectNearbyPlayer()
		if not data.id then
			cb(true)
			return
		end
		data.number = tonumber(data.number)
		model:Giveitem(data)
		cb(true)
	end)

	RegisterNUICallback("DropItem", function(data, cb)
		if not data then
			return
		end

		data.number = tonumber(data.number)

		model:DropItem(data)
		cb(true)
	end)

	RegisterNUICallback("PutIntoFast", function(data, callback)
		if not data then
			return
		end

		local fastslot = Client.fastWeapons

		local main = data.item

		if main.name == "money" or main.name == "black_money" or main.name == "id_card" or data.category == "key" then
			return
		end
			
		if SettingItem.Blockfastslot and SettingItem.Blockfastslot[main.name] == true then
			return
		end

		for k, v in pairs(fastslot) do
			if v.name == main.name then
				fastslot[k] = nil
			end
		end

		if fastslot[data.slot] ~= nil then
			if data.item.position ~= "fastslot" then
				fastslot[data.slot] = nil
				fastslot[data.slot] = data.item
				fastslot[data.slot].position = "fastslot"
			else
				item1 = data.item
				item2 = fastslot[data.slot] -- Target

				fastslot[item1.slot] = nil
				fastslot[item2.slot] = nil

				fastslot[item1.slot] = item2
				fastslot[item1.slot].slot = item2.slot
				fastslot[item2.slot] = item1
				fastslot[item2.slot].slot = item1.slot
			end
		else
			fastslot[data.slot] = main
			fastslot[data.slot].position = "fastslot"
		end
		Client.fastWeapons = fastslot
		Client:UpdateFastslot()
	end)
	RegisterNUICallback("ChangeFastslot", function(data, cb)

		if not data then
			return
		end

		-- if data.type == 'up' then
		-- 	Client.selectfastslot = Client.selectfastslot + 1
		-- else
		-- 	Client.selectfastslot = Client.selectfastslot - 1
		-- end

		-- if Client.selectfastslot > 3 then
		-- 	Client.selectfastslot = 1
		-- elseif Client.selectfastslot < 1 then
		-- 	Client.selectfastslot = 3
		-- end

		Client.selectfastslot = data.template

		local main = Client.fastWeapons
		if Client.allfastslot[Client.selectfastslot] then
			Client.fastWeapons = Client.allfastslot[Client.selectfastslot]
			Client:UpdateFastslot()
		end
	end)

	RegisterNUICallback("TakeFromFast", function(data, cb)
		local fastslot = Client.fastWeapons
		if fastslot[data.slot] ~= nil then
			fastslot[data.slot] = nil
			Client:UpdateFastslot()
			cb("ok")
		end
	end)

	RegisterNUICallback("SecondaryInventoryAction", function(data, cb)
		if not data then
			return
		end
		Citizen.CreateThread(function()
			Config.ClientSecondaryInventoryAction(
				self.SecondType,
				self.SecondDataType,
				data.action,
				data.item,
				data.number,
				ESX.GetPlayerData().job,
				self.SearchData
			)
		end)
		cb(true)
	end)

	-- transferitem

	RegisterNUICallback("ChangeSkinWeapon", function(data, cb)
		if not data then
			return
		end
		cb(xWeapon:SetSkinByWeapon(data.item.name, data.skin))
		-- cb(true)
	end)
	RegisterNUICallback("ClearSkinWeapon", function(data, cb)
		if not data then
			return
		end
		cb(xWeapon:ClearSkinByWeapon(data.item.name))
		-- cb(true)
	end)

	RegisterNUICallback("GetMailbox", function(data, cb)
		if not data then
			return
		end
		if GetResourceState('d9_mailbox') == 'missing' then 
			return
		end
		exports['AP29_PlaySound2']:playsound('click.mp3', 0.7)
		cb(exports["d9_mailbox"]:GetMailbox())
	end)

	RegisterNUICallback("PickupMail", function(data, cb)
		if not data then
			return
		end
		if GetResourceState("d9_mailbox") == "missing" then
			return
		end
		exports['AP29_PlaySound2']:playsound('click.mp3', 0.7)
		cb(exports["d9_mailbox"]:PickUpMail(data))
	end)

end
