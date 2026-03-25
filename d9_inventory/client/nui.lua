function model:InitNUI()
	RegisterNUICallback("closeinventory", function()
		model:CloseInventiry()
	end)

	local function respond(cb, value)
		if cb then
			cb(value)
		end
	end

	local function requireData(data, cb, emptyValue)
		if data then
			return true
		end
		respond(cb, emptyValue)
		return false
	end

	RegisterNUICallback("UseItem", function(data, cb)
		if not requireData(data, cb, false) then return end
		model:Useitem(data.item)
		respond(cb, true)
	end)

	local function Draw3dText(coords, text, outline, color, scale)
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

	local function SelectNearbyPlayer()
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
			local nextRefresh = GetGameTimer() + 250
			while isOpenPlayerNearby do
				Wait(0)
				local now = GetGameTimer()
				if now >= nextRefresh then
					updateNearbyPlayers()
					nextRefresh = now + 250
				end

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
					nextRefresh = GetGameTimer() + 250
					Wait(100)
				end

				local myCoords = GetEntityCoords(PlayerPedId())
				for index, playerInfo in ipairs(nearbyPlayers) do
					local targetPed = GetPlayerPed(playerInfo.id)
					local targetCoords = GetEntityCoords(targetPed)
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
		if not requireData(data, cb, false) then return end
		model:CloseInventiry()
		data.id = SelectNearbyPlayer()
		if not data.id then
			respond(cb, true)
			return
		end
		data.number = tonumber(data.number)
		model:Giveitem(data)
		respond(cb, true)
	end)

	RegisterNUICallback("DropItem", function(data, cb)
		if not requireData(data, cb, false) then return end

		data.number = tonumber(data.number)
		if not data.number then
			respond(cb, false)
			return
		end

		model:DropItem(data)
		respond(cb, true)
	end)

	RegisterNUICallback("PutIntoFast", function(data, callback)
		if not requireData(data, callback, false) then return end

		local fastslot = Client.fastWeapons
		local maxFastslot = tonumber(Config.MaxFastslot) or 7
		local targetSlot = tonumber(data.slot)
		if not targetSlot or targetSlot < 1 or targetSlot > maxFastslot then
			respond(callback, false)
			return
		end

		local main = data.item
		if not main then
			respond(callback, false)
			return
		end

		if main.name == "money" or main.name == "black_money" or main.name == "id_card" or data.category == "key" then
			respond(callback, false)
			return
		end

		if SettingItem.Blockfastslot and SettingItem.Blockfastslot[main.name] == true then
			respond(callback, false)
			return
		end

		for k, v in pairs(fastslot) do
			if v.name == main.name then
				fastslot[k] = nil
			end
		end

		if fastslot[targetSlot] ~= nil then
			if data.item.position ~= "fastslot" then
				fastslot[targetSlot] = nil
				fastslot[targetSlot] = data.item
				fastslot[targetSlot].position = "fastslot"
			else
				local item1 = data.item
				local item2 = fastslot[targetSlot] -- Target

				fastslot[item1.slot] = nil
				fastslot[item2.slot] = nil

				fastslot[item1.slot] = item2
				fastslot[item1.slot].slot = item2.slot
				fastslot[item2.slot] = item1
				fastslot[item2.slot].slot = item1.slot
			end
		else
			fastslot[targetSlot] = main
			fastslot[targetSlot].position = "fastslot"
		end
		Client.fastWeapons = fastslot
		Client:UpdateFastslot()
		respond(callback, true)
	end)
	RegisterNUICallback("ChangeFastslot", function(data, cb)
		if not requireData(data, cb, false) then return end

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

		if Client.allfastslot[Client.selectfastslot] then
			Client.fastWeapons = Client.allfastslot[Client.selectfastslot]
			Client:UpdateFastslot()
		end
		respond(cb, true)
	end)

	RegisterNUICallback("TakeFromFast", function(data, cb)
		if not requireData(data, cb, false) then return end
		local fastslot = Client.fastWeapons
		local maxFastslot = tonumber(Config.MaxFastslot) or 7
		local targetSlot = tonumber(data.slot)
		if not targetSlot or targetSlot < 1 or targetSlot > maxFastslot then
			respond(cb, false)
			return
		end
		if fastslot[targetSlot] ~= nil then
			fastslot[targetSlot] = nil
			Client:UpdateFastslot()
			respond(cb, "ok")
			return
		end
		respond(cb, false)
	end)

	RegisterNUICallback("SecondaryInventoryAction", function(data, cb)
		if not requireData(data, cb, false) then return end
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
		respond(cb, true)
	end)

	-- transferitem

	RegisterNUICallback("ChangeSkinWeapon", function(data, cb)
		if not requireData(data, cb, false) then return end
		respond(cb, xWeapon:SetSkinByWeapon(data.item.name, data.skin))
		-- cb(true)
	end)
	RegisterNUICallback("ClearSkinWeapon", function(data, cb)
		if not requireData(data, cb, false) then return end
		respond(cb, xWeapon:ClearSkinByWeapon(data.item.name))
		-- cb(true)
	end)

	RegisterNUICallback("GetMailbox", function(data, cb)
		if not requireData(data, cb, {}) then return end
		if GetResourceState('d9_mailbox') == 'missing' then
			respond(cb, {})
			return
		end
		exports['AP29_PlaySound2']:playsound('click.mp3', 0.7)
		respond(cb, exports["d9_mailbox"]:GetMailbox())
	end)

	RegisterNUICallback("PickupMail", function(data, cb)
		if not requireData(data, cb, false) then return end
		if GetResourceState("d9_mailbox") == "missing" then
			respond(cb, false)
			return
		end
		exports['AP29_PlaySound2']:playsound('click.mp3', 0.7)
		respond(cb, exports["d9_mailbox"]:PickUpMail(data))
	end)

end
