local Lang = require('locales/en')
local ApartmentObjects = {}
local pendingApartmentCreation = {}

-- Functions

local function AddPlayerToApartment(source, apartmentId)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	if ApartmentObjects[apartmentId] ~= nil then
		ApartmentObjects[apartmentId].players[Player.PlayerData.citizenid] = source

		local insideMeta = Player.PlayerData.metadata['inside']
		insideMeta.apartment.apartmentType = ApartmentObjects[apartmentId].label
		insideMeta.apartment.apartmentId = apartmentId
		insideMeta.house = nil
		Player.SetMetaData('inside', insideMeta)

		local enteringPlayerId = GetPlayerId(source)
		TriggerClientEvent(source, 'qb-apartments:client:HideAllPlayers')

		local inst = ApartmentObjects[apartmentId]
		local insideSources = {}
		for _, playerSrc in pairs(inst.players) do
			insideSources[playerSrc] = true
		end
		local enteringTalker = source:GetVoiceTalker()

		for _, otherCtrl in pairs(GetAllPlayers()) do
			if otherCtrl ~= source then
				local otherPS = otherCtrl.PlayerState
				if otherPS and enteringTalker then
					local otherIsInside = insideSources[otherCtrl] == true
					local shouldMute = not otherIsInside
					enteringTalker:SetMutedForPlayerState(shouldMute, otherPS)
					local otherTalker = otherCtrl:GetVoiceTalker()
					if otherTalker then
						otherTalker:SetMutedForPlayerState(shouldMute, source.PlayerState)
					end
				end
			end
		end

		for _, otherCtrl in pairs(GetAllPlayers()) do
			if otherCtrl ~= source and not insideSources[otherCtrl] then
				TriggerClientEvent(otherCtrl, 'qb-apartments:client:HidePlayer', enteringPlayerId)
			end
		end

		for _, otherCtrl in pairs(inst.players) do
			if otherCtrl ~= source then
				TriggerClientEvent(source, 'qb-apartments:client:ShowPlayer', GetPlayerId(otherCtrl))
				TriggerClientEvent(otherCtrl, 'qb-apartments:client:ShowPlayer', enteringPlayerId)
			end
		end
	end
end

local function RemovePlayerFromApartment(Player, apartmentId)
	if ApartmentObjects[apartmentId] and ApartmentObjects[apartmentId].players ~= nil then
		ApartmentObjects[apartmentId].players[Player.PlayerData.citizenid] = nil

		local source = Player.PlayerData.source

		local insideMeta = Player.PlayerData.metadata['inside']
		insideMeta.apartment.apartmentType = nil
		insideMeta.apartment.apartmentId = nil
		insideMeta.house = nil
		Player.SetMetaData('inside', insideMeta)

		local inst = ApartmentObjects[apartmentId]
		local insideSources = {}
		for _, playerSrc in pairs(inst.players) do
			insideSources[playerSrc] = true
		end
		local leavingTalker = source:GetVoiceTalker()
		local leavingPlayerId = GetPlayerId(source)

		for _, otherCtrl in pairs(GetAllPlayers()) do
			if otherCtrl ~= source then
				local otherPS = otherCtrl.PlayerState
				if otherPS and leavingTalker then
					local otherIsStillInside = insideSources[otherCtrl] == true
					local shouldMute = otherIsStillInside
					leavingTalker:SetMutedForPlayerState(shouldMute, otherPS)
					local otherTalker = otherCtrl:GetVoiceTalker()
					if otherTalker then
						otherTalker:SetMutedForPlayerState(shouldMute, source.PlayerState)
					end
				end
			end
		end

		TriggerClientEvent(source, 'qb-apartments:client:ShowAllPlayers')

		for _, insideCtrl in pairs(inst.players) do
			TriggerClientEvent(source, 'qb-apartments:client:HidePlayer', GetPlayerId(insideCtrl))
		end

		for _, insideCtrl in pairs(inst.players) do
			TriggerClientEvent(insideCtrl, 'qb-apartments:client:HidePlayer', leavingPlayerId)
		end

		for _, otherCtrl in pairs(GetAllPlayers()) do
			if otherCtrl ~= source and not insideSources[otherCtrl] then
				TriggerClientEvent(otherCtrl, 'qb-apartments:client:ShowPlayer', leavingPlayerId)
			end
		end
	end
end

local function GetOrCreateOffset(apartmentId)
	if ApartmentObjects ~= nil then
		if ApartmentObjects[apartmentId] ~= nil then
			return tonumber(ApartmentObjects[apartmentId].offset)
		end
	end

	local highestOffset = 0
	if ApartmentObjects ~= nil then
		for _, apartmentData in pairs(ApartmentObjects) do
			local offsetNum = tonumber(apartmentData.offset)
			if offsetNum and offsetNum > highestOffset then
				highestOffset = offsetNum
			end
		end
	end

	local newOffset
	if highestOffset == 0 then
		newOffset = Apartments.InitialOffset
	else
		newOffset = highestOffset + Apartments.SpawnOffset
	end

	return newOffset
end

local function EnterApartment(source, apartmentId, aptName)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	local offset = GetOrCreateOffset(apartmentId)

	local coords = Vector(
		Apartments.Locations[aptName].coords[1],
		Apartments.Locations[aptName].coords[2],
		Apartments.Locations[aptName].coords[3] + offset
	)

	local data = exports['qb-interior']:StarterAptFurn_S(source, coords, false, false)
	local apartmentData = { object = data[1], poiOffsets = data[2] }

	if not ApartmentObjects[apartmentId] then
		ApartmentObjects[apartmentId] = {
			label = aptName,
			offset = offset,
			object = apartmentData.object,
			poiOffsets = apartmentData.poiOffsets,
			players = {}
		}
	else
		ApartmentObjects[apartmentId].offset = offset
	end

	AddPlayerToApartment(source, apartmentId)

	TriggerClientEvent(source, 'qb-apartments:client:EnterApartment', coords, offset, apartmentId, aptName)
end

local function LeaveApartment(source, apartmentId, aptName)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	local exitCoords = Apartments.Locations[aptName].coords

	RemovePlayerFromApartment(Player, apartmentId)

	local ped = GetPlayerPawn(source)
	if not ped then return end
	SetEntityCoords(ped, Vector(exitCoords[1], exitCoords[2], exitCoords[3]))

	exports['qb-interior']:DespawnInterior_S(apartmentId)
	TriggerClientEvent(source, 'qb-apartments:client:LeaveApartment')
end

-- Entry Point (qb-spawn)

RegisterServerEvent('qb-apartments:server:CreateApartment', function(source, aptName)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end
	if pendingApartmentCreation[source] then return end
	pendingApartmentCreation[source] = true

	local apartmentId = exports['qb-core']:CreateApartmentId()
	local label = Apartments.Locations[aptName].label
	exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO apartments (name, type, label, citizenid) VALUES (?, ?, ?, ?)', {
		apartmentId,
		aptName,
		label,
		Player.PlayerData.citizenid,
	})
	pendingApartmentCreation[source] = nil
	TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.receive_apart') .. ' (' .. label .. ')')
	EnterApartment(source, apartmentId, aptName)
end)

RegisterServerEvent('qb-apartments:server:UpdateApartment', function(source, data)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end
	local aptName = data.ClosestApartment
	local label = Apartments.Locations[aptName].label
	exports['qb-core']:DatabaseAction('Execute', 'UPDATE apartments SET type = ?, label = ? WHERE citizenid = ?', {
		aptName,
		label,
		Player.PlayerData.citizenid
	})
	TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.changed_apart'))
end)

-- Target Events

RegisterServerEvent('qb-apartments:server:EnterApartment', function(source, data)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE citizenid = ? AND type = ?', {
		Player.PlayerData.citizenid,
		data.ClosestApartment
	})

	if result and result[1] then
		local apartmentId = result[1].name
		local aptName = result[1].type
		EnterApartment(source, apartmentId, aptName)
	else
		TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_owner'), 'error')
	end
end)

RegisterServerEvent('qb-apartments:server:LeaveApartment', function(source, data)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE name = ?', {
		data.CurrentApartment
	})

	if result and result[1] then
		local apartmentId = result[1].name
		local aptName = result[1].type
		LeaveApartment(source, apartmentId, aptName)
	end
end)

RegisterServerEvent('qb-apartments:server:LogoutApartment', function(source, data)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE name = ?', {
		data.CurrentApartment
	})

	if result and result[1] then
		local apartmentId = result[1].name
		local aptName = result[1].type
		LeaveApartment(source, apartmentId, aptName)
	end

	exports['qb-core']:Logout(source)
	TriggerClientEvent(source, 'qb-multicharacter:client:chooseChar')
end)

RegisterServerEvent('qb-apartments:server:OpenStash', function(source, data)
	exports['qb-inventory']:OpenInventory(source, data.CurrentApartment)
end)

RegisterServerEvent('qb-apartments:server:RingDoor', function(source, data)
	local apartmentId = data.apartmentId
	local Player = exports['qb-core']:GetPlayer(source)
	if not (apartmentId and Player) then return end

	local entry = ApartmentObjects[apartmentId]
	if not entry then return end
	entry.requests = entry.requests or {}

	entry.requests[Player.PlayerData.citizenid] = {
		src = source,
		name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
		citizenid = Player.PlayerData.citizenid,
	}

	if not next(entry.players) then
		TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.nobody_home'))
		return
	end

	for _, playerSrc in pairs(entry.players) do
		TriggerClientEvent(playerSrc, 'QBCore:Notify', Lang:t('info.at_the_door'))
	end
end)

RegisterServerEvent('qb-apartments:server:OpenDoor', function(_, data)
	local apartmentId = data.apartmentId
	local targetCid = data.targetCitizenId
	local entry = ApartmentObjects[apartmentId]
	local aptName = entry and entry.label or nil

	if not entry then
		return print(string.format('^3[qb-apartments] Apartment not found: %s', apartmentId))
	end

	if not targetCid then
		return print('^1[qb-apartments] Missing target citizen ID')
	end

	if not (entry.requests and entry.requests[targetCid]) then
		return print(string.format('^3[qb-apartments] No pending request for CID: %s', targetCid))
	end

	local targetSrc = entry.requests[targetCid].src
	entry.requests[targetCid] = nil
	EnterApartment(targetSrc, apartmentId, aptName)
end)

-- Callbacks

RegisterCallback('GetOwnedApartment', function(source, cid)
	if cid then
		local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE citizenid = ?', { cid })
		if result[1] ~= nil then
			return result[1]
		end
		return nil
	else
		local Player = exports['qb-core']:GetPlayer(source)
		if not Player then return nil end
		local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE citizenid = ?', { Player.PlayerData.citizenid })
		if result and result[1] ~= nil then
			return result[1]
		end
		return nil
	end
end)

RegisterCallback('GetDoorRequests', function(_, apartmentId)
	if not ApartmentObjects[apartmentId] then return nil end
	return ApartmentObjects[apartmentId].requests
end)

RegisterCallback('GetAvailableApartments', function(_, apartmentName)
	local apartments = {}
	if ApartmentObjects then
		for id, entry in pairs(ApartmentObjects) do
			if entry.label == apartmentName and entry.players and next(entry.players) ~= nil then
				apartments[id] = entry.label
			end
		end
	end
	return apartments
end)

RegisterCallback('IsOwner', function(source, apartment)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return nil end
	local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE citizenid = ?', { Player.PlayerData.citizenid })
	if result[1] then
		if result[1].type == apartment then
			return true
		else
			return false
		end
	else
		return false
	end
end)
