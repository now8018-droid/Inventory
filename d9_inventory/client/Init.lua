ESX = exports["es_extended"]:getSharedObject()
local ResourceName = GetCurrentResourceName()

-- Utility functions
GetName = function(a, b)
	return string.format("%s:%s:%s", ResourceName, a, b)
end

RegisEvent = function(n, h)
	return RegisterNetEvent(n), AddEventHandler(n, h)
end

ispressed = function(input, key)
	return IsDisabledControlJustReleased(input, key)
end

Eventnui = function(event, data)
	SendNUIMessage({
		event = event,
		data = data,
	})
end

local nuiReady = promise.new()
RegisterNUICallback("Ready", function(data, cb)
	Wait(1000)
	nuiReady:resolve()
	log("NUI is ready")
end)

-- Client initialization
Citizen.CreateThread(function()
	while NetworkIsPlayerActive(PlayerId()) ~= 1 do
		Citizen.Wait(0)
	end

	while not ESX.IsPlayerLoaded() do
		Citizen.Wait(100)
	end

	Citizen.Await(nuiReady)

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	ESX.PlayerData = ESX.GetPlayerData()
	Wait(1000)
	Client:Init()
	model:InitNUI()
end)

function Client:SetInfo(data)
	self.infoweapon = data
	self._weaponLabelLookup = {}
	for i = 1, #data do
		local weapon = data[i]
		self._weaponLabelLookup[weapon.name] = weapon.label or weapon.name
	end
end

function Client:SetInfoItem(data)
	self.infoitem = data
end

function Client:Init()
	Client:InitRegis()
	Client:SetInfo(ESX.GetWeaponList()) 
	Client:SetInfoItem(Infoitem)
	Client:Fastslot()
	Client:Setup()
	Client:LoopInit()
	Client:InitWeapon()
	Client:InitPlayer()
	Client:Inittrunk()
	Client:InitVault()
	xWeapon:InitSkinWeapon()
	Client:InitSecondInventory()
end

function Client:Setup()
	TriggerServerEvent(GetName("sv", "first"))
	local Accessories = Client:GetAccessories()
	local keyVehicle = Client:GetVehicle()
	local items, fastslot = Client:GetmyInventory()
	Eventnui("setting", {
		items = items,
		Type = fastslot,
		selectfastslot = self.selectfastslot,
		playerid = GetPlayerServerId(PlayerId()),
		blockcategory = Config.blocktypeonallcategory,
		Template = Template.color,
		Category = Config.CategoryLabel,
		DisableSecond = SettingItem.DisableSecond,
	})
	Client:UpdateFastslot()

	CreateThread(function()
		Wait(2000)
		
		if GetResourceState("d9_mailbox") ~= "started" then
			print("^1[ERROR] d9_mailbox resource not started^0")
			return
		end
		
		local mailbox = exports["d9_mailbox"]:GetMailbox()
		
		if not mailbox or type(mailbox) ~= "table" then
			print("^1[ERROR] Mailbox is not a table!^0")
			mailbox = {}
		end
		
		local countMb = 0
		for k, v in pairs(mailbox) do 
			countMb = countMb + 1 
		end
		
		print("^2[Mailbox] Count: " .. countMb)
		
		local dataToSend = {
			mailboxCount = countMb
		}
		
		Eventnui("MailBoxCount", dataToSend)
	end)
end

RegisterNetEvent("inventory:updateMailboxCount")
AddEventHandler("inventory:updateMailboxCount", function()
	local mailbox = exports["d9_mailbox"]:GetMailbox()
		
	if not mailbox or type(mailbox) ~= "table" then
		print("^1[ERROR] Mailbox is not a table!^0")
		mailbox = {}
	end
	
	local countMb = 0
	for k, v in pairs(mailbox) do 
		countMb = countMb + 1 
	end
	
	print("^2[Mailbox] Count: " .. countMb)
	
	local dataToSend = {
		mailboxCount = countMb
	}
	
	Eventnui("MailBoxCount", dataToSend)
end)

function Client:GetmyInventory()
	local playerPed = PlayerPedId()
	local playerData = ESX.GetPlayerData()
	local inventory = playerData.inventory
	local accounts = playerData.accounts
	local Accessories = Client.Accessories
	local fashion = self.fashion
	local KeyVehicle = self.KeyVehicle

	local items = {}
	local fastItems = {}
	
	-- Pre-build fastWeapons lookup table for O(1) access
	local fastWeaponsLookup = {}
	for slot, item in pairs(self.fastWeapons) do
		fastWeaponsLookup[item.name] = slot
	end

	-- Process accounts
	for _, account in ipairs(accounts) do
		if not model:shouldSkipAccount(account.name) and account.money > 0 then
			local canDrop = account.name ~= "bank"
			local accountData = {
				label = account.label,
				count = account.money,
				type = "item_account",
				name = account.name,
				notGive = false,
				notRemove = canDrop,
				rare = false,
				limit = -1,
				position = "inventory",
			}
			
			table.insert(items, accountData)
			
			-- Check if in fast slots
			local slot = fastWeaponsLookup[account.name]
			if slot then
				local fastData = {}
				for k, v in pairs(accountData) do
					fastData[k] = v
				end
				fastData.slot = slot
				fastData.position = "fastslot"
				table.insert(fastItems, fastData)
			end
		end
	end

	-- Add ID card
	table.insert(items, {
		label = "บัตรประชาชน",
		name = "id_card",
		type = "item_account",
		count = 1,
		limit = 1,
		notGive = true,
		notRemove = false,
		rare = false,
		position = "inventory",
	})

	-- Process weapons (ใช้ loadout เป็นแหล่งหลัก + fallback ด้วย ped weapon)
	local weaponLabels = self._weaponLabelLookup or {}

	local addedWeapons = {}
	local loadout = playerData.loadout or {}

	local function addWeaponToInventory(weaponName, weaponLabel, ammo)
		if not weaponName or weaponName == "WEAPON_UNARMED" or addedWeapons[weaponName] then
			return
		end

		local weaponData = {
			label = weaponLabel or weaponName,
			count = ammo or 0,
			limit = -1,
			type = "item_weapon",
			name = weaponName,
			notUse = false,
			notRemove = SettingItem.DisableRemove[weaponName],
			notGive = SettingItem.DisableGive[weaponName],
			rare = false,
			position = "inventory",
			skin = dataskin,
			myskin = dataskin and currentskin and dataskin[currentskin]
		}

		addedWeapons[weaponName] = true
		table.insert(items, weaponData)

		local slot = fastWeaponsLookup[weaponName]
		if slot then
			local fastData = {}
			for k, v in pairs(weaponData) do
				fastData[k] = v
			end
			fastData.slot = slot
			fastData.position = "fastslot"
			table.insert(fastItems, fastData)
		end
	end

	for i = 1, #loadout do
		local loadoutWeapon = loadout[i]
		local weaponName = loadoutWeapon.name
		local ammo = loadoutWeapon.ammo
		if ammo == nil then
			ammo = GetAmmoInPedWeapon(playerPed, GetHashKey(weaponName))
		end
		addWeaponToInventory(weaponName, loadoutWeapon.label or weaponLabels[weaponName], ammo)
	end

	-- fallback: เผื่อ loadout ยัง sync ไม่ทัน แต่ ped มีอาวุธอยู่แล้ว
	for i = 1, #self.infoweapon do
		local weapon = self.infoweapon[i]
		local weaponHash = GetHashKey(weapon.name)
		if HasPedGotWeapon(playerPed, weaponHash, false) then
			local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
			addWeaponToInventory(weapon.name, weapon.label, ammo)
		end
	end

	-- Process Accessories
	for k, v in pairs(Accessories) do
		local decoded = nil
		if type(v) == "string" then
			local ok, parsed = pcall(json.decode, v)
			if ok and type(parsed) == "table" then
				decoded = parsed
			end
		elseif type(v) == "table" then
			decoded = v
		end

		if not decoded then
			goto continue_accessory
		end

		table.insert(items, {
			label = k,
			count = 1,
			limit = -1,
			type = "item_accessories",
			name = k,
			notUse = false,
			notRemove = true,
			notGive = true,
			itemnum = decoded.mask_1,
			itemskin = decoded.mask_2,
			position = "inventory",
		})
		::continue_accessory::
	end

	-- Process inventory items
	if inventory then
		for _, item in pairs(inventory) do
			if item and item.count > 0 then
				local itemData = {
					label = item.label,
					count = item.count,
					limit = item.limit,
					type = "item_standard",
					name = item.name,
					notUse = SettingItem.DisableUse[item.name],
					notGive = SettingItem.DisableGive[item.name],
					notRemove = SettingItem.DisableRemove[item.name],
					rare = item.rare,
					position = "inventory",
				}
				
				table.insert(items, itemData)
				
				-- Check if in fast slots
				local slot = fastWeaponsLookup[item.name]
				if slot then
					local fastData = {}
					for k, v in pairs(itemData) do
						fastData[k] = v
					end
					fastData.slot = slot
					fastData.position = "fastslot"
					table.insert(fastItems, fastData)
				end
			end
		end
	end

	-- Process vehicle keys
	for _, v in pairs(KeyVehicle) do
		table.insert(items, {
			label = v.plate,
			count = 1,
			limit = -1,
			type = "item_key",
			name = 'key',
			notUse = false,
			notRemove = true,
			notGive = false,
			position = "inventory",
		})
	end

	-- Pre-build category lookup for O(1) access (cache across opens)
	local categoryLookup = self._categoryLookup
	if not categoryLookup then
		categoryLookup = {}
		for category, itemList in pairs(Config.Category) do
			for _, itemName in pairs(itemList) do
				categoryLookup[itemName] = category
			end
		end
		self._categoryLookup = categoryLookup
	end

	-- Assign categories and additional data
	for _, item in ipairs(items) do
		-- Assign category
		item.category = categoryLookup[item.name]
		
		if not item.category then
			if item.type == "item_key" or item.type == "item_keyhouse" then
				item.category = "key"
			elseif item.type == "item_weapon" then
				item.category = "weapon"
			elseif item.type == "item_accessories" then
				item.category = "clothes"
			else
				item.category = "all"
			end
		end

		-- Assign additional data
		item.fashion = fashion[item.name]
		item.info = self.infoitem[item.name]
		item.template = Template.items[item.name] or 0
		item.Skinweapon = Skinweapon.General[item.name]
		item.myskin = xWeapon:GetSkinByWeapon(item.name)
	end

	-- Assign templates to fast items
	for _, v in ipairs(fastItems) do
		v.template = Template.items[v.name] or 0
	end

	return items, fastItems
end

-- function Client:GetmyInventory()
-- 	local playerPed = PlayerPedId()
-- 	local playerData = ESX.GetPlayerData()
-- 	local inventory = playerData.inventory
-- 	local accounts = playerData.accounts
-- 	local Accessories = Client.Accessories
-- 	local fashion = self.fashion
-- 	local KeyVehicle = self.KeyVehicle

-- 	local items = {}
-- 	local fastItems = {}

-- 	for key, value in pairs(accounts) do
-- 		if not model:shouldSkipAccount(accounts[key].name) then
-- 			local canDrop = accounts[key].name ~= "bank"
-- 			if accounts[key].money > 0 then
-- 				local accountData = {
-- 					label = accounts[key].label,
-- 					count = accounts[key].money,
-- 					type = "item_account",
-- 					name = accounts[key].name,
-- 					notGive = false,
-- 					notRemove = canDrop,
-- 					rare = false,
-- 					limit = -1,
-- 					position = "inventory",
-- 				}
-- 				table.insert(items, accountData)
-- 			end

-- 			for slot, item in pairs(self.fastWeapons) do
-- 				if item.name == accounts[key].name then
-- 					table.insert(fastItems, {
-- 						label = accounts[key].label,
-- 						count = accounts[key].money,
-- 						type = "item_account",
-- 						name = accounts[key].name,
-- 						notGive = false,
-- 						notRemove = canDrop,
-- 						rare = false,
-- 						limit = -1,
-- 						slot = slot,
-- 						position = "fastslot",
-- 					})
-- 				end
-- 			end
-- 		end
-- 	end

-- 	-- Add ID card
-- 	local itemData = {
-- 		label = "บัตรประชาชน",
-- 		name = "id_card",
-- 		type = "item_account",
-- 		count = 1,
-- 		limit = 1,
-- 		notGive = true,
-- 		notRemove = false,
-- 		rare = false,
-- 		position = "inventory",
-- 	}
-- 	table.insert(items, itemData)

-- 	for i = 1, #self.infoweapon, 1 do
-- 		local weaponHash = GetHashKey(self.infoweapon[i].name)
-- 		local playerPed = PlayerPedId()

-- 		if HasPedGotWeapon(playerPed, weaponHash, false) and self.infoweapon[i].name ~= "WEAPON_UNARMED" then
-- 			local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
-- 			local founditem = false


-- 			for slot, item in pairs(self.fastWeapons) do
-- 				if item.name == self.infoweapon[i].name then
-- 					table.insert(fastItems, {
-- 						label = self.infoweapon[i].label,
-- 						count = ammo,
-- 						limit = -1,
-- 						type = "item_weapon",
-- 						name = self.infoweapon[i].name,
-- 						notUse = false,
-- 						notRemove = SettingItem.DisableRemove[self.infoweapon[i].name],
-- 						notGive = SettingItem.DisableGive[self.infoweapon[i].name],
-- 						rare = false,
-- 						slot = slot,
-- 						position = "fastslot",
-- 						skin = dataskin or nil,
-- 						myskin = dataskin and currentskin and dataskin[currentskin] or nil
-- 					})
-- 				end
-- 			end

-- 			table.insert(items, {
-- 				label = self.infoweapon[i].label,
-- 				count = ammo,
-- 				limit = -1,
-- 				type = "item_weapon",
-- 				name = self.infoweapon[i].name,
-- 				notUse = false,
-- 				notRemove = SettingItem.DisableRemove[self.infoweapon[i].name],
-- 				notGive = SettingItem.DisableGive[self.infoweapon[i].name],
-- 				rare = false,
-- 				position = "inventory",
-- 				skin = dataskin or nil,
-- 				myskin = dataskin and currentskin and dataskin[currentskin] or nil
-- 			})
-- 		end
-- 	end

-- 	for k,v in pairs(Accessories) do
-- 		table.insert(items, {
-- 			label = k or "mask",
-- 			count = 1,
-- 			limit = -1,
-- 			type = "item_accessories",
-- 			name = k or "mask",
-- 			notUse = false,
-- 			notRemove = true,
-- 			notGive = true,
-- 			itemnum = json.decode(v).mask_1,
-- 			itemskin = json.decode(v).mask_2,
-- 			position = "inventory",
-- 		})
-- 	end

-- 	if inventory ~= nil then
-- 		for key, value in pairs(inventory) do

-- 			if type(inventory[key]) == "number" or inventory[key] and inventory[key].count <= 0 then
-- 				inventory[key] = nil
-- 			else
-- 				for slot, item in pairs(self.fastWeapons) do
-- 					if item.name == inventory[key].name then
-- 						table.insert(fastItems, {
-- 							label = inventory[key].label,
-- 							count = inventory[key].count,
-- 							limit = inventory[key].limit,
-- 							type = "item_standard",
-- 							name = inventory[key].name,
-- 							notUse = SettingItem.DisableUse[inventory[key].name],
-- 							notGive = SettingItem.DisableGive[inventory[key].name],
-- 							notRemove = SettingItem.DisableRemove[inventory[key].name],
-- 							rare = inventory[key].rare,
-- 							slot = slot,
-- 							position = "fastslot",
-- 						})
-- 					end
-- 				end

-- 				table.insert(items, {
-- 					label = inventory[key].label,
-- 					count = inventory[key].count,
-- 					limit = inventory[key].limit,
-- 					type = "item_standard",
-- 					name = inventory[key].name,
-- 					notUse = SettingItem.DisableUse[inventory[key].name],
-- 					notGive = SettingItem.DisableGive[inventory[key].name],
-- 					notRemove = SettingItem.DisableRemove[inventory[key].name],
-- 					rare = inventory[key].rare,
-- 					slot = slot,
-- 					position = "inventory",
-- 				})
-- 			end

-- 			::continue::

-- 		end
-- 	end

-- 	for k,v in pairs(KeyVehicle) do
-- 		table.insert(items, {
-- 			label = v.plate,
-- 			count = 1,
-- 			limit = -1,
-- 			type = "item_key",
-- 			name = 'key',
-- 			notUse = false,
-- 			notRemove = true,
-- 			notGive = false,
-- 			position = "inventory",
-- 		})
-- 	end

-- 	for k, v in pairs(items) do
-- 		local founditem = false
-- 		for category, value in pairs(Config.Category) do
-- 			for index, data in pairs(value) do
-- 				if Config.Category[category][index] == items[k].name then
-- 					items[k].category = category
-- 					founditem = true
-- 					-- break
-- 				end
-- 			end
-- 		end

-- 		if founditem == false then
-- 			if items[k].type == "item_key" or items[k].type == "item_keyhouse" then
-- 				items[k].category = "key"
-- 			elseif items[k].type == "item_weapon" then
-- 				items[k].category = "weapon"
-- 			elseif items[k].type == "item_accessories" then
-- 				items[k].category = "clothes"
-- 			else
-- 				items[k].category = "all"
-- 			end
-- 		end

-- 		items[k].fashion = fashion[items[k].name] or nil
-- 		items[k].info = self.infoitem[items[k].name] or nil
-- 		items[k].template = Template.items[items[k].name] or 0
-- 		items[k].Skinweapon = Skinweapon.General[items[k].name] or nil
-- 		items[k].myskin = xWeapon:GetSkinByWeapon(items[k].name) or nil
-- 	end

-- 	for k, v in pairs(fastItems) do
-- 		v.template = Template.items[v.name] or 0
-- 	end


-- 	return items, fastItems
-- end

function Client:Fastslot()

	-- DeleteResourceKvp("fastslot")
	-- DeleteResourceKvp("selectfastslot")

	local fastslot = GetResourceKvpString("fastslot")
	local selectslot = GetResourceKvpString("selectfastslot")
	if not fastslot or not selectslot then
		local data = {
			[1] = {},
			[2] = {},
			[3] = {},
		}

		SetResourceKvp("fastslot", json.encode(data))
		SetResourceKvp("selectfastslot", 1)
		self.fastWeapons = {}
		self.allfastslot = data
		self.selectfastslot = tonumber(1)
	else
		local result = json.decode(fastslot)
		self.fastWeapons = result[tonumber(selectslot)] or {}
		self.allfastslot = result
		self.selectfastslot = tonumber(selectslot)
	end
end

function Client:UpdateFastslot()
	local tablefast = {}
	local playerPed = PlayerPedId()
	for k, v in pairs(self.fastWeapons) do
		v.slot = k
		if string.find(v.name, "WEAPON_", 1) == nil and string.find(v.name, "weapon_", 1) == nil then
			if model:checkItemCount(v.name) > 0 then
				v.count = model:checkItemCount(v.name)
				table.insert(tablefast, v)
			end
		else
			if HasPedGotWeapon(playerPed, GetHashKey(v.name), false) and v.name ~= "WEAPON_UNARMED" then
				v.count = model:checkItemCount(v.name)
				table.insert(tablefast, v)
			end
		end
	end
	
	self.allfastslot[tonumber(self.selectfastslot)] = self.fastWeapons
	SetResourceKvp("fastslot", json.encode(self.allfastslot))
	Eventnui("update-fastslot", {
		fastslot = tablefast,
		selectfastslot = self.selectfastslot,
	})
end

------------------------------------

function Client:LoopInit()
	-- Citizen.CreateThread(function()
	-- 	while true do
	-- 		sleep = 0
	-- 		if not IsPlayerDead(PlayerPedId()) and not IsDead then
	-- 			if IsDisabledControlJustReleased(0, Config.OpenControl) and IsInputDisabled(0) then
	-- 				model:OpenInventiry()
	-- 			end
	-- 		else
	-- 			if isInInventory then
	-- 				model:CloseInventiry()
	-- 			end
	-- 		end
	-- 		Wait(sleep)
	-- 	end
	-- end)

	RegisterKeyMapping("inventoryopen", "Open Inventory", "keyboard", "T")
	RegisterCommand("inventoryopen", function()
		if not IsPlayerDead(PlayerPedId()) and not IsDead then
			if not self.openui then
				model:OpenInventiry()
			else
				model:CloseInventiry()
			end
		end
	end, false)


	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)
			HudForceWeaponWheel(false)
			HudWeaponWheelIgnoreSelection()
			DisableControlAction(1, 37, true)
			DisableControlAction(1, 157, true)
			DisableControlAction(1, 158, true)
			DisableControlAction(1, 160, true)
			DisableControlAction(1, 164, true)
			DisableControlAction(1, 165, true)
			DisableControlAction(2, 157, true) -- disable changing weapon
			DisableControlAction(2, 158, true) -- disable changing weapon
			DisableControlAction(2, 159, true) -- disable changing weapon
			DisableControlAction(2, 160, true) -- disable changing weapon
			DisableControlAction(2, 161, true) -- disable changing weapon
			DisableControlAction(2, 162, true) -- disable changing weapon
			DisableControlAction(2, 163, true) -- disable changing weapon
			DisableControlAction(2, 164, true) -- disable changing weapon
			DisableControlAction(2, 165, true) -- disable changing weapon
		end
	end)

	Citizen.CreateThread(function()
		local fastSlotControls = {
			{control = 157, slot = 1},
			{control = 158, slot = 2},
			{control = 160, slot = 3},
			{control = 164, slot = 4},
			{control = 165, slot = 5},
			{control = 159, slot = 6},
			{control = 161, slot = 7},
			{control = 162, slot = 8}
		}

		local function useFastSlot(slotIndex)
			model:showfast()
			local slotItem = self.fastWeapons and self.fastWeapons[slotIndex]
			if not slotItem then
				return
			end

			if slotItem.name == "key" then
				TriggerServerEvent("meeta_remote:ServerLock", slotItem.label)
			elseif slotItem.type == "item_weapon" then
				SetWeapon(slotItem)
			else
				model:Useitem(slotItem)
			end
		end

		while true do
			local sleep = 250
			local ped = PlayerPedId()
			local isAlive = not IsPlayerDead(ped) and not IsDead
			if isAlive then
				sleep = 0
				DisableControlAction(0, 37, true)

				if IsControlPressed(0, 19) or UpdateOnscreenKeyboard() == 0 then
					goto back
				end

				if self.fastWeapons == nil then
					goto back
				end

				if model.Isgive then
					goto back
				end
				
				if blockFastLost then
					goto back
				end

				if IsDisabledControlJustReleased(0, 37) then
					Eventnui("change-showtrade", {})
				else
					for i = 1, #fastSlotControls do
						local control = fastSlotControls[i]
						if IsDisabledControlJustReleased(0, control.control) then
							useFastSlot(control.slot)
							break
						end
					end
				end

				if IsControlJustReleased(0, 24) or IsControlJustReleased(0, 45) then
					if not self.cooldown then
						Citizen.CreateThread(function()
							if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey("WEAPON_UNARMED") then
								self.cooldown = true
								Wait(2000)
								self.cooldown = false
							end
						end)
					end
				end

				::back::
			end
			Citizen.Wait(sleep)
		end
	end)
end

function model:showfast()
	Eventnui("showtrade", {})
end

function Client:InitWeapon()

	local IsSetWeapon = false
	local varweapon = nil
	local blockat = false
	local blockatThreadRunning = false

	function loadAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			RequestAnimDict(dict)
			Citizen.Wait(50)
		end
	end

	blockatk = function()
		blockat = true
		if blockatThreadRunning then
			return
		end
		blockatThreadRunning = true
		Citizen.CreateThread(function()
			while true do
				Citizen.Wait(0)
				if blockat then
					if IsControlJustReleased(0, 24) or IsControlJustReleased(0, 45) then
						if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey("WEAPON_UNARMED") then
							Citizen.CreateThread(function()
								self.cooldown = true
								self.meleeatk = true
								Wait(2000)
								self.cooldown = false
								self.meleeatk = false
							end)
						end
					end

					DisableControlAction(0, 24, true) -- Attack
					DisableControlAction(0, 45, true) -- Attack
					DisableControlAction(0, 257, true) -- Attack 2
				else
					blockatThreadRunning = false
					break
				end
			end
		end)
	end

	SetWeapon = function(data)
		if self.cooldown then
			return
		end
		blockatk()
		if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey("WEAPON_UNARMED") then
			shoqweapon(data)
		else
			if varweapon == GetHashKey(data.name) and varweapon then
				keepweapon()
			else
				weapon2action(data)
			end
		end
	end

	shoqweapon = function(data, twoac)
		self.cooldown = true
		-- Citizen.CreateThread(function()
		local ped = PlayerPedId()
		loadAnimDict("reaction@intimidation@1h")
		TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", -8.0, 2.0, -1, 48, 2, 0, 0, 0)
		Wait(1500)
		if not self.meleeatk then
			StopAnimTask(PlayerPedId(), "reaction@intimidation@1h", "intro", 5.0)
			SetCurrentPedWeapon(ped, data.name, true)
			varweapon = GetHashKey(data.name)
			IsSetWeapon = true
		else
			StopAnimTask(PlayerPedId(), "reaction@intimidation@1h", "intro", 5.0)
		end
		self.cooldown = false
		blockat = false
	end

	keepweapon = function()
		self.cooldown = true
		-- Citizen.CreateThread(function()
		local ped = PlayerPedId()

		loadAnimDict("reaction@intimidation@1h")
		TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", -8.0, 2.0, -1, 48, 2, 0, 0, 0)
		Wait(1500)
		StopAnimTask(PlayerPedId(), "reaction@intimidation@1h", "outro", 5.0)
		-- ClearPedTasks(ped)
		SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
		IsSetWeapon = false
		blockat = false
		self.cooldown = false
		-- end)
	end

	weapon2action = function(data)
		keepweapon()
		blockatk()
		shoqweapon(data, true)
	end
end
