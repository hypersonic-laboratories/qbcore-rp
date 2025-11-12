local Lang = require('locales/en')
local ApartmentObjects = {}

-- Functions

local function AddPlayerToApartment(source, apartmentId)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end
	if ApartmentObjects[apartmentId] ~= nil then
		ApartmentObjects[apartmentId].players[Player.PlayerData.citizenid] = source
	end
end

local function RemovePlayerFromApartment(Player, apartmentId)
	if ApartmentObjects[apartmentId] and ApartmentObjects[apartmentId].players ~= nil then
		ApartmentObjects[apartmentId].players[Player.PlayerData.citizenid] = nil
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
			if apartmentData.offset and tonumber(apartmentData.offset) > highestOffset then
				highestOffset = tonumber(apartmentData.offset)
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

	local data = exports['qb-interior']:CreateApartmentFurnished(source, coords, false, false)
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

	local insideMeta = Player.PlayerData.metadata['inside']
	insideMeta.apartment.apartmentType = aptName
	insideMeta.apartment.apartmentId = apartmentId
	insideMeta.house = nil
	exports['qb-core']:Player(source, 'SetMetaData', 'inside', insideMeta)

	TriggerClientEvent(source, 'qb-apartments:client:EnterApartment', coords, offset, apartmentId, aptName)
end

local function LeaveApartment(source, apartmentId, aptName)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end

	local exitCoords = Apartments.Locations[aptName].coords

	RemovePlayerFromApartment(Player, apartmentId)

	local insideMeta = Player.PlayerData.metadata['inside']
	insideMeta.apartment.apartmentType = nil
	insideMeta.apartment.apartmentId = nil
	insideMeta.house = nil
	exports['qb-core']:Player(source, 'SetMetaData', 'inside', insideMeta)

	local ped = GetPlayerPawn(source)
	if not ped then return end
	SetEntityCoords(ped, Vector(exitCoords[1], exitCoords[2], exitCoords[3]))
	TriggerClientEvent(source, 'qb-apartments:client:LeaveApartment')
end

-- Entry Point (qb-spawn)

RegisterServerEvent('qb-apartments:server:CreateApartment', function(source, aptName)
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then return end
	local apartmentId = exports['qb-core']:CreateApartmentId()
	local label = Apartments.Locations[aptName].label
	exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO apartments (name, type, label, citizenid) VALUES (?, ?, ?, ?)', {
		apartmentId,
		aptName,
		label,
		Player.PlayerData.citizenid,
	})
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
		if result[1] ~= nil then
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
