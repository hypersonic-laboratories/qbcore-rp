local Lang = require('locales/en')
local isLoggedIn = false

-- Skin helpers

local function SerializeSkin(System)
	local Loadout = System:GetCosmeticLoadout()
	local data = {
		gender   = (Loadout.Gender == UE.EHCharacterCosmeticsGender.Female) and 'Female' or 'Male',
		bodyType = (Loadout.BodyType == UE.EHCosmeticBodyType.Underweight) and 'Underweight' or 'Average',
		items    = {}
	}
	local Slots = Loadout.Slots
	for i = 1, Slots:Length() do
		local Entry = Slots:Get(i)
		if Entry.ItemID ~= '' then
			data.items[#data.items + 1] = {
				slot   = tostring(Entry.SlotTag.TagName),
				itemId = Entry.ItemID
			}
		end
	end
	return JSON.stringify(data)
end

local function ApplySkin(System, skinJson)
	local data = JSON.parse(skinJson)
	local gender = data.gender == 'Female'
		and UE.EHCharacterCosmeticsGender.Female
		or  UE.EHCharacterCosmeticsGender.Male
	local body = data.bodyType == 'Underweight'
		and UE.EHCosmeticBodyType.Underweight
		or  UE.EHCosmeticBodyType.Average
	System:SetCosmeticGender(gender)
	System:SetCosmeticBodyType(body)
	System:ClearAllCosmeticSlots()
	local Items = UE.TArray(UE.FString)
	for _, entry in ipairs(data.items) do
		Items:Add(entry.itemId)
	end
	System:EquipCosmeticItems(Items)
end

local function WaitForCosmeticsAndRun(fn)
	local pawn = GetPlayerPawn()
	if not pawn then return end
	local checkId
	checkId = Timer.SetInterval(function()
		if not pawn:IsInitialCosmeticsLoadDone() then return end
		Timer.ClearInterval(checkId)
		local System = pawn:GetCosmeticsSystem()
		if not System then return end
		fn(System)
	end, 500)
end
local InApartment = false
local ClosestApartment = nil
local CurrentApartment = nil
local IsOwned = false
local CurrentOffset = 0
local ApartmentObj = 0
local POIOffsets = nil
local InApartmentTargets = {}
local intervalTimer

-- Functions

local function RegisterApartmentEntranceTarget(apartmentName, apartmentData)
	local coords = Vector(apartmentData.coords[1], apartmentData.coords[2], apartmentData.coords[3])
	local boxName = 'apartmentEntrance_' .. apartmentName
	local boxData = apartmentData.polyzoneBoxData
	if boxData.created then return end
	local options = {}

	if apartmentName == ClosestApartment and IsOwned then
		options = {
			{
				icon = 'door-open',
				label = Lang.t('text.enter'),
				type = 'server',
				event = 'qb-apartments:server:EnterApartment',
				ClosestApartment = ClosestApartment,
			},
		}
	else
		options = {
			{
				icon = 'hotel',
				label = Lang.t('text.move_here'),
				type = 'server',
				event = 'qb-apartments:server:UpdateApartment',
				ClosestApartment = ClosestApartment,
			},
		}
	end

	options[#options + 1] = {
		type = 'client',
		event = 'qb-apartments:client:DoorbellMenu',
		icon = 'concierge-bell',
		label = Lang.t('text.ring_doorbell'),
	}

	exports['qb-target']:AddBoxZone(boxName, coords, boxData.length, boxData.width, {
		name = boxName,
		heading = boxData.heading,
		debug = boxData.debug,
		distance = boxData.distance,
	}, options)

	boxData.created = true
end

local function RegisterInApartmentTarget(targetKey, coords, heading, options)
	if not InApartment then return end
	if InApartmentTargets[targetKey] and InApartmentTargets[targetKey].created then return end

	local boxName = 'inApartmentTarget_' .. targetKey
	exports['qb-target']:AddBoxZone(boxName, coords, 100, 100, {
		name = boxName,
		heading = heading,
		distance = 500,
		debug = true
	}, options)

	InApartmentTargets[targetKey] = InApartmentTargets[targetKey] or {}
	InApartmentTargets[targetKey].created = true
end

local function SetApartmentsEntranceTargets()
	if Apartments.Locations and next(Apartments.Locations) then
		for id, apartment in pairs(Apartments.Locations) do
			if apartment and apartment.coords then
				RegisterApartmentEntranceTarget(id, apartment)
			end
		end
	end
end

local function SetInApartmentTargets(apartmentName)
	if not POIOffsets then return end
	local entrancePos = Vector(
		Apartments.Locations[apartmentName].coords[1] - POIOffsets.exit.x,
		Apartments.Locations[apartmentName].coords[2] - POIOffsets.exit.y,
		Apartments.Locations[apartmentName].coords[3] + CurrentOffset + POIOffsets.exit.z
	)
	local stashPos = Vector(
		Apartments.Locations[apartmentName].coords[1] - POIOffsets.stash.x,
		Apartments.Locations[apartmentName].coords[2] - POIOffsets.stash.y,
		Apartments.Locations[apartmentName].coords[3] + CurrentOffset + POIOffsets.stash.z
	)
	local outfitsPos = Vector(
		Apartments.Locations[apartmentName].coords[1] - POIOffsets.clothes.x,
		Apartments.Locations[apartmentName].coords[2] - POIOffsets.clothes.y,
		Apartments.Locations[apartmentName].coords[3] + CurrentOffset + POIOffsets.clothes.z
	)
	local logoutPos = Vector(
		Apartments.Locations[apartmentName].coords[1] - POIOffsets.logout.x,
		Apartments.Locations[apartmentName].coords[2] - POIOffsets.logout.y,
		Apartments.Locations[apartmentName].coords[3] + CurrentOffset + POIOffsets.logout.z
	)
	RegisterInApartmentTarget('entrancePos', entrancePos, 0, {
		{
			icon = 'clipboard-list',
			label = Lang.t('text.open_door'),
			event = 'qb-apartments:client:DoorRequestMenu',
			CurrentApartment = CurrentApartment,
		},
		{
			icon = 'door-open',
			label = Lang.t('text.leave'),
			type = 'server',
			event = 'qb-apartments:server:LeaveApartment',
			CurrentApartment = CurrentApartment,
		},
	})
	RegisterInApartmentTarget('stashPos', stashPos, 0, {
		{
			icon = 'box',
			label = Lang.t('text.open_stash'),
			type = 'server',
			event = 'qb-apartments:server:OpenStash',
			CurrentApartment = CurrentApartment,
		},
	})
	RegisterInApartmentTarget('outfitsPos', outfitsPos, 0, {
		{
			type = 'client',
			event = 'qb-apartments:client:ChangeOutfit',
			icon = 'shirt',
			label = Lang.t('text.change_outfit'),
		},
	})
	RegisterInApartmentTarget('logoutPos', logoutPos, 0, {
		{
			icon = 'log-out',
			label = Lang.t('text.logout'),
			type = 'server',
			event = 'qb-apartments:server:LogoutApartment',
			CurrentApartment = CurrentApartment,
		},
	})
end

local function DeleteApartmentsEntranceTargets()
	if Apartments.Locations and next(Apartments.Locations) then
		for id, info in pairs(Apartments.Locations) do
			exports['qb-target']:RemoveZone('apartmentEntrance_' .. id)
			local boxData = info.polyzoneBoxData
			boxData.created = false
		end
	end
end

local function DeleteInApartmentTargets()
	if InApartmentTargets and next(InApartmentTargets) then
		for id in pairs(InApartmentTargets) do
			exports['qb-target']:RemoveZone('inApartmentTarget_' .. id)
		end
	end
	InApartmentTargets = {}
end

local function SetClosestApartment()
	if not isLoggedIn then return end
	local ped = GetPlayerPawn()
	if not ped then return end
	local pos = GetEntityCoords(ped)
	local current = nil
	local dist = 1000
	for id in pairs(Apartments.Locations) do
		local apartmentPos = Vector(
			Apartments.Locations[id].coords[1],
			Apartments.Locations[id].coords[2],
			Apartments.Locations[id].coords[3]
		)
		if GetDistanceBetweenCoords(pos, apartmentPos) < dist then
			current = id
		end
	end
	if current ~= ClosestApartment and isLoggedIn and not InApartment then
		ClosestApartment = current
		TriggerCallback('IsOwner', function(result)
			IsOwned = result
			DeleteApartmentsEntranceTargets()
			DeleteInApartmentTargets()
		end, ClosestApartment)
	end
end

function onShutdown()
	if intervalTimer then
		Timer.ClearInterval(intervalTimer)
		intervalTimer = nil
	end
	if ApartmentObj and ApartmentObj ~= 0 then
		exports['qb-interior']:DespawnInterior_C(ApartmentObj)
		ApartmentObj = 0
	end
	DeleteApartmentsEntranceTargets()
	DeleteInApartmentTargets()
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
	isLoggedIn = true
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
	isLoggedIn = false
	CurrentApartment = nil
	InApartment = false
	CurrentOffset = 0
	DeleteApartmentsEntranceTargets()
	DeleteInApartmentTargets()
end)

RegisterClientEvent('qb-apartments:client:setupSpawnUI', function(cData)
	TriggerCallback('GetOwnedApartment', function(result)
		if result then
			TriggerLocalClientEvent('qb-spawn:client:openUI', true, cData, false, nil)
		else
			if Apartments.Starting then
				TriggerLocalClientEvent('qb-spawn:client:openUI', true, cData, true, Apartments.Locations)
			else
				TriggerLocalClientEvent('qb-spawn:client:openUI', true, cData, false, nil)
			end
		end
	end, cData.citizenid)
end)

RegisterClientEvent('qb-apartments:client:EnterApartment', function(coords, offset, apartmentId, apartmentName)
	local data = exports['qb-interior']:StarterAptFurn_C(coords)
	ApartmentObj = data[1]
	POIOffsets = data[2]
	InApartment = true
	CurrentOffset = offset
	CurrentApartment = apartmentId
	ClosestApartment = apartmentName
	IsOwned = true
	SetInApartmentTargets(apartmentName)

	TriggerCallback('GetPlayerSkin', function(skinJson)
		WaitForCosmeticsAndRun(function(System)
			if skinJson then
				ApplySkin(System, skinJson)
			else
				System:ShowCharacterCustomizationUI()
			end
		end)
	end)
end)

RegisterClientEvent('qb-apartments:client:LeaveApartment', function()
	local pawn = GetPlayerPawn()
	if pawn then
		local System = pawn:GetCosmeticsSystem()
		if System then
			TriggerServerEvent('qb-apartments:server:SaveSkin', SerializeSkin(System))
		end
	end

	exports['qb-interior']:DespawnInterior_C(ApartmentObj)
	CurrentApartment = nil
	ClosestApartment = nil
	InApartment = false
	CurrentOffset = 0
	POIOffsets = nil
	ApartmentObj = 0
	DeleteInApartmentTargets()
	DeleteApartmentsEntranceTargets()
end)

RegisterClientEvent('qb-apartments:client:UpdateApartment', function()
	IsOwned = true
	DeleteApartmentsEntranceTargets()
	DeleteInApartmentTargets()
end)

RegisterClientEvent('qb-apartments:client:DoorbellMenu', function()
	TriggerCallback('GetAvailableApartments', function(apartments)
		if next(apartments) == nil then
			exports['qb-core']:Notify(Lang.t('error.nobody_home'), 'error')
			exports['qb-menu']:closeMenu()
		else
			local apartmentMenu = {
				{
					header = Lang.t('text.tennants'),
					isMenuHeader = true
				}
			}

			for k, v in pairs(apartments) do
				apartmentMenu[#apartmentMenu + 1] = {
					header = k,
					txt = '',
					params = {
						isServer = true,
						event = 'qb-apartments:server:RingDoor',
						args = {
							apartmentId = k,
							apartmentName = v
						}
					}

				}
			end

			apartmentMenu[#apartmentMenu + 1] = {
				header = Lang.t('text.close_menu'),
				txt = '',
				params = {
					event = 'qb-menu:client:closeMenu'
				}

			}
			exports['qb-menu']:openMenu(apartmentMenu)
		end
	end, ClosestApartment)
end)

RegisterClientEvent('qb-apartments:client:DoorRequestMenu', function(data)
	TriggerCallback('GetDoorRequests', function(requests)
		if not requests or next(requests) == nil then
			exports['qb-core']:Notify(Lang.t('error.nobody_at_door'))
			exports['qb-menu']:closeMenu()
			return
		end

		local menu = {
			{
				header = 'Visitors',
				isMenuHeader = true
			}
		}

		for cid, req in pairs(requests) do
			local label = (req.name and req.name ~= '') and req.name or cid
			menu[#menu + 1] = {
				header = label,
				txt = '',
				params = {
					isServer = true,
					event = 'qb-apartments:server:OpenDoor',
					args = {
						targetCitizenId = cid,
						apartmentId = data.CurrentApartment
					}
				}
			}
		end

		menu[#menu + 1] = {
			header = Lang.t('text.close_menu'),
			txt = '',
			params = {
				event = 'qb-menu:client:closeMenu'
			}
		}

		exports['qb-menu']:openMenu(menu)
	end, data.CurrentApartment)
end)

RegisterClientEvent('qb-apartments:client:LastLocationHouse', function(apartmentType, apartmentId)
	TriggerServerEvent('qb-apartments:server:EnterApartment', { ClosestApartment = apartmentType })
end)

RegisterClientEvent('qb-apartments:client:ChangeOutfit', function()
	local pawn = GetPlayerPawn()
	if not pawn then return end
	local System = pawn:GetCosmeticsSystem()
	if not System then return end
	System:ShowCharacterCustomizationUI()
end)

-- Visibility & Voice

-- Hide Everyone
RegisterClientEvent('qb-apartments:client:HideAllPlayers', function()
	local pawns = GetAllPawns()
	for _, pawn in pairs(pawns) do
		if not pawn:IsLocallyControlled() then
			pawn:SetActorHiddenInGame(true)
		end
	end
end)

-- Show Everyone
RegisterClientEvent('qb-apartments:client:ShowAllPlayers', function()
	local pawns = GetAllPawns()
	for _, pawn in pairs(pawns) do
		if not pawn:IsLocallyControlled() then
			pawn:SetActorHiddenInGame(false)
		end
	end
end)

local function FindPawnByPlayerId(targetPlayerId)
	for _, pawn in pairs(GetAllPawns()) do
		local ps = pawn.PlayerState
		if ps and ps:GetPlayerId() == targetPlayerId then
			return pawn
		end
	end
	return nil
end

RegisterClientEvent('qb-apartments:client:ShowPlayer', function(targetPlayerId)
	local pawn = FindPawnByPlayerId(targetPlayerId)
	if pawn and not pawn:IsLocallyControlled() then
		pawn:SetActorHiddenInGame(false)
	end
end)

RegisterClientEvent('qb-apartments:client:HidePlayer', function(targetPlayerId)
	local pawn = FindPawnByPlayerId(targetPlayerId)
	if pawn and not pawn:IsLocallyControlled() then
		pawn:SetActorHiddenInGame(true)
	end
end)

-- Loop

intervalTimer = Timer.SetInterval(function()
	if isLoggedIn then
		if not InApartment then
			SetClosestApartment()
			SetApartmentsEntranceTargets()
		end
	end
end, 1000)

-- Commands

local HConsole = GetActorByTag('HConsole')
if HConsole then
	HConsole:RegisterCommand('getoffset', 'Apartment Offset', nil, { HWorld, function()
		if not InApartment then return end
		if not CurrentApartment then return end
		if not ClosestApartment then return end
		if not POIOffsets then return end

		local spawnPos = Vector(
			Apartments.Locations[ClosestApartment].coords[1],
			Apartments.Locations[ClosestApartment].coords[2],
			Apartments.Locations[ClosestApartment].coords[3] + CurrentOffset
		)

		local playerPawn = GetPlayerPawn()
		if not playerPawn then return end
		local pos = GetEntityCoords(playerPawn)
		local offset = ('{ x = %.2f, y = %.2f, z = %.2f }'):format(
			spawnPos.X - pos.X,
			spawnPos.Y - pos.Y,
			pos.Z - spawnPos.Z
		)
		CopyToClipboard(offset)
		exports['qb-core']:Notify('Offset copied to clipboard')
	end })
end
