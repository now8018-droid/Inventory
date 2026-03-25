xWeapon = {
	allweapon = {},
	myskin = {}
}

function xWeapon:InitSkinWeapon()
	log('InitSkinWeapon')
	self.myskin = json.decode(GetResourceKvpString("myskin") or "{}")
	
	if not self.myskin then
		self.myskin = {}
	end

	log('self.myskin', self.myskin)
	xWeapon:ThreadRefreshSkin()
end

function xWeapon:GetSkinByWeapon(weapon, itemCounts)
	if not Skinweapon.General[weapon] then
		return nil
	end

	local Setting = Skinweapon.General[weapon]

	if not itemCounts then
		itemCounts = model:BuildInventoryCount()
	end

	for k, v in pairs(Setting) do
		local req = v.require
		local cnt = itemCounts[req] or 0
		v.have = cnt > 0
	end

	return self.myskin[weapon] or nil
end

function xWeapon:SetSkinByWeapon(weapon, skin)
	if not Skinweapon.General[weapon] then 
		log('not found weapon')
		return 
	end

	local Setting = Skinweapon.General[weapon]
	if not Setting[skin] then
		log('not found skin')
		return 
	end

	if model:checkItemCount(Setting[skin].require) <= 0 then 
		log('not found item')
		return 
	end

	if self.myskin[weapon] then
		local weaponName = GetHashKey(weapon)
		log(weaponName)
		RemoveWeaponComponentFromPed(PlayerPedId(), weaponName, GetHashKey(skin))
		self.myskin[weapon] = nil
	end

	self.myskin[weapon] = skin
	SetResourceKvp("myskin", json.encode(self.myskin))
	return self.myskin[weapon]
end

function xWeapon:ClearSkinByWeapon(weapon)
	local weaponName = GetHashKey(weapon)
	RemoveWeaponComponentFromPed(PlayerPedId(), weaponName, GetHashKey(self.myskin[weapon]))
	self.myskin[weapon] = nil
	SetResourceKvp("myskin", json.encode(self.myskin))
	return true
end

function xWeapon:GetAllSkin()
	return self.myskin
end

function xWeapon:RefreshSkin()
	log('RefreshSkin')
	for k,v in pairs(self.myskin) do
		local Setting = Skinweapon.General[k]
		if Setting then
			log('Have Setting')
			for a,b in pairs(Setting) do
				if a == v then
					if model:checkItemCount(b.require) <= 0 then
						local weaponName = GetHashKey(k)
						RemoveWeaponComponentFromPed(PlayerPedId(), weaponName, GetHashKey(self.myskin[k]))
						self.myskin[k] = nil
					end
				end
			end
		end
	end
end

function xWeapon:ThreadRefreshSkin()
	Citizen.CreateThread(function()
		while true do
			local nothing, weapon = GetCurrentPedWeapon(PlayerPedId(), true)
			if weapon then
				for k,v in pairs(self.myskin) do
					if GetHashKey(k) == weapon then
						--log('GiveWeaponComponentToPed', k, v)
						local componentHash = GetHashKey(v)
						GiveWeaponComponentToPed(PlayerPedId(), weapon, componentHash)
					end
				end
			end

			Wait(500)
		end
	end)
end