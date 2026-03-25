-- @param Typename string
-- @param Action string
-- @param items table
-- @param count number
-- @param job table
Config.ClientSecondaryInventoryAction = function(SecondName, Typename, Action, items, count, job, SearchData)
	log(SecondName, Typename, Action, items, count, job)

	if IsPedSittingInAnyVehicle(PlayerPedId()) then
		return
	end

	if SecondName == "vault" then
		if Action == "TakeFromSecond" then
			-- if not model:CheckDisableSecond(SecondName, Typename, items)
			-- 	or SettingItem.BypassVault
			-- 		and SettingItem.BypassVault[SecondName]
			-- 		and SettingItem.BypassVault[SecondName][items.name]
			-- then
			-- 	if type(count) == "number" and math.floor(count) == count then
			-- 		exports.d9_vault:takein({
			-- 			item = items,
			-- 			number = count,
			-- 		})
			-- 	end
			-- end
			if type(count) == "number" and math.floor(count) == count then
				exports.d9_vault:takein({
					item = items,
					number = count,
				})
			end
		elseif Action == "PutIntoSecond" then
			log('PutIntoSecond')
			if not model:CheckDisableSecond(SecondName, Typename, items)
				or SettingItem.BypassVault
					and SettingItem.BypassVault[SecondName]
					and SettingItem.BypassVault[SecondName][items.name]
			then
				log('PutIntoSecond 2')
				if type(count) == "number" and math.floor(count) == count then
					exports.d9_vault:putin({
						item = items,
						number = count,
					})
				end
			end
		end
	elseif SecondName == "trunk" then
		if Action == "TakeFromSecond" then
			-- if not model:CheckDisableSecond(SecondName, Typename, items)
			-- 	or SettingItem.BypassVault
			-- 		and SettingItem.BypassVault[SecondName]
			-- 		and SettingItem.BypassVault[SecondName][items.name]
			-- then
			-- 	if type(count) == "number" and math.floor(count) == count then

			-- end
			if type(count) == "number" and math.floor(count) == count then
				exports.d9_trunk:OnTake({
					item = items,
					number = count,
				})
			end
		elseif Action == "PutIntoSecond" then
			if not model:CheckDisableSecond(SecondName, Typename, items)
				or SettingItem.BypassVault
					and SettingItem.BypassVault[SecondName]
					and SettingItem.BypassVault[SecondName][items.name]
			then
				if type(count) == "number" and math.floor(count) == count then
					exports.d9_trunk:OnPut({
						item = items,
						number = count,
					})
				end
			end
		end
	elseif SecondName == "search" then
		if Action == "TakeFromSecond" then
			-- if not model:CheckDisableSecond(SecondName, Typename, items)
			-- 	or SettingItem.BypassVault
			-- 		and SettingItem.BypassVault[SecondName]
			-- 		and SettingItem.BypassVault[SecondName][items.name]
			-- then
			-- 	if type(count) == "number" and math.floor(count) == count then

			-- end
			if type(count) == "number" and math.floor(count) == count then
				TriggerServerEvent(GetName('sv','SearchPlayer'), SecondName, Typename, Action, items, count, job, SearchData)
			end
		elseif Action == "PutIntoSecond" then
			if not model:CheckDisableSecond(SecondName, Typename, items)
				or SettingItem.BypassVault
					and SettingItem.BypassVault[SecondName]
					and SettingItem.BypassVault[SecondName][items.name] then
				if type(count) == "number" and math.floor(count) == count then
					TriggerServerEvent(GetName('sv','SearchPlayer'), SecondName, Typename, Action, items, count, job, SearchData)
				end
			end
		end
	end

	return true
end
