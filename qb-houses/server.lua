local Lang = require('locales/en')

-- Runtime state
local Entrances = {}         -- [entranceId] = { entranceId, label, entranceType, coords={x,y,z}, interiorRef, price }
local PropertyUnits = {}     -- [propertyKey] = { entranceId, ownerCitizenId, interiorType, interiorRef }
local OwnedByEntrance = {}   -- [entranceId] = { [citizenId] = propertyKey }
local EntranceUnits = {}     -- [entranceId] = { [propertyKey] = true }
local PropertyInstances = {} -- [propertyKey] = { interiorRef, offset, object, poiOffsets, location, garage, players, requests }
local PropertyOffsets = {}   -- [propertyKey] = offset

-- Startup

local function ensureEntranceMaps(entranceId)
    OwnedByEntrance[entranceId] = OwnedByEntrance[entranceId] or {}
    EntranceUnits[entranceId] = EntranceUnits[entranceId] or {}
end

local function registerUnit(propertyKey, entranceId, ownerCitizenId, interiorType, interiorRef)
    PropertyUnits[propertyKey] = {
        entranceId = entranceId,
        ownerCitizenId = ownerCitizenId,
        interiorType = interiorType,
        interiorRef = interiorRef
    }
    ensureEntranceMaps(entranceId)
    OwnedByEntrance[entranceId][ownerCitizenId] = propertyKey
    EntranceUnits[entranceId][propertyKey] = true
end

local dbproperties = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM properties WHERE owned = 1', {})
if not dbproperties then return end
for _, row in ipairs(dbproperties) do
    if row.property_key and row.entrance_id and row.owner_citizenid and row.interior_type then
        registerUnit(
            row.property_key,
            row.entrance_id,
            row.owner_citizenid,
            row.interior_type,
            row.interior_ref
        )
    end
end

for entranceId, apt in pairs(Config.Apartments) do
    Entrances[entranceId] = {
        entranceId = entranceId,
        label = apt.label or entranceId,
        entranceType = 'instanced',
        coords = { x = apt.coords[1], y = apt.coords[2], z = apt.coords[3] },
        garageCoords = apt.storeVehicle,
        interiorRef = entranceId,
        price = apt.price or 0,
        isHardcoded = true
    }
    ensureEntranceMaps(entranceId)
end

-- Functions

local function getOwnedUnitKey(entranceId, citizenId)
    return OwnedByEntrance[entranceId] and OwnedByEntrance[entranceId][citizenId] or nil
end

local function AddPlayerToProperty(source, propertyKey)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('AddPlayerToProperty - No player found for source')
        return
    end
    local inst = PropertyInstances[propertyKey]
    if not inst then
        print('AddPlayerToProperty - No instance found for propertyKey', propertyKey)
        return
    end
    inst.players = inst.players or {}
    inst.playersSet = inst.playersSet or {}
    inst.players[Player.PlayerData.citizenid] = source
    inst.playersSet[source] = true
    local insideMeta = Player.PlayerData.metadata['inside']
    insideMeta.property = propertyKey
    insideMeta.apartment = nil
    insideMeta.house = nil
    exports['qb-core']:Player(source, 'SetMetaData', 'inside', insideMeta)
    local enteringPlayerId = GetPlayerId(source)
    TriggerClientEvent(source, 'qb-houses:client:HideAllPlayers')
    local enteringTalker = source:GetVoiceTalker()
    for _, otherCtrl in pairs(GetAllPlayers()) do
        if otherCtrl ~= source then
            local otherPS = otherCtrl.PlayerState
            if otherPS and enteringTalker then
                local otherIsInside = inst.playersSet[otherCtrl] == true
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
        if otherCtrl ~= source and not inst.playersSet[otherCtrl] then
            TriggerClientEvent(otherCtrl, 'qb-houses:client:HidePlayer', enteringPlayerId)
        end
    end
    for _, otherCtrl in pairs(inst.players) do
        if otherCtrl ~= source then
            TriggerClientEvent(source, 'qb-houses:client:ShowPlayer', GetPlayerId(otherCtrl))
            TriggerClientEvent(otherCtrl, 'qb-houses:client:ShowPlayer', enteringPlayerId)
        end
    end
end

local function RemovePlayerFromProperty(Player, propertyKey)
    local inst = PropertyInstances[propertyKey]
    if not inst or not inst.players then
        print('RemovePlayerFromProperty - No instance found for propertyKey', propertyKey)
        return
    end
    inst.playersSet = inst.playersSet or {}
    local source = inst.players[Player.PlayerData.citizenid]
    if not source then
        print('RemovePlayerFromProperty - No source found for player', Player.PlayerData.citizenid)
        return
    end
    local leavingPlayerId = GetPlayerId(source)
    inst.players[Player.PlayerData.citizenid] = nil
    inst.playersSet[source] = nil
    local insideMeta = Player.PlayerData.metadata['inside']
    insideMeta.property = nil
    insideMeta.apartment = nil
    insideMeta.house = nil
    exports['qb-core']:Player(source, 'SetMetaData', 'inside', insideMeta)
    local leavingTalker = source:GetVoiceTalker()
    for _, otherCtrl in pairs(GetAllPlayers()) do
        if otherCtrl ~= source then
            local otherPS = otherCtrl.PlayerState
            if otherPS and leavingTalker then
                local otherIsStillInside = inst.playersSet[otherCtrl] == true
                local shouldMute = otherIsStillInside
                leavingTalker:SetMutedForPlayerState(shouldMute, otherPS)
                local otherTalker = otherCtrl:GetVoiceTalker()
                if otherTalker then
                    otherTalker:SetMutedForPlayerState(shouldMute, source.PlayerState)
                end
            end
        end
    end

    TriggerClientEvent(source, 'qb-houses:client:ShowAllPlayers')
    for _, insideCtrl in pairs(inst.players) do
        TriggerClientEvent(source, 'qb-houses:client:HidePlayer', GetPlayerId(insideCtrl))
    end
    for _, insideCtrl in pairs(inst.players) do
        TriggerClientEvent(insideCtrl, 'qb-houses:client:HidePlayer', leavingPlayerId)
    end
    for _, otherCtrl in pairs(GetAllPlayers()) do
        if otherCtrl ~= source and not inst.playersSet[otherCtrl] then
            TriggerClientEvent(otherCtrl, 'qb-houses:client:ShowPlayer', leavingPlayerId)
        end
    end
end

local function GetOrCreateOffset(entranceId, propertyKey)
    if PropertyOffsets[propertyKey] then
        return tonumber(PropertyOffsets[propertyKey])
    end
    local highest = 0
    for pKey, offset in pairs(PropertyOffsets) do
        local unit = PropertyUnits[pKey]
        if unit and unit.entranceId == entranceId and tonumber(offset) > highest then
            highest = tonumber(offset)
        end
    end
    if highest == 0 then
        PropertyOffsets[propertyKey] = Config.InitialOffset
    else
        PropertyOffsets[propertyKey] = highest + Config.SpawnOffset
    end
    return PropertyOffsets[propertyKey]
end

local function PopulateGarage(playerData, entranceId, shellConfig, garageCoords)
    local results = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid, vehicle, plate, fuel, drivingdistance FROM player_vehicles WHERE citizenid = ? and garage = ? and state = 1', {
        playerData.citizenid,
        entranceId,
    })
    if type(results) ~= 'table' or #results <= 0 then return end

    local vehicles = {}
    for index, vehicleData in pairs(results) do
        local spawnPos = shellConfig.garageVehicleOffsets[index]
        if spawnPos then
            local coords = Vector(garageCoords.X - spawnPos.offset.x, garageCoords.Y - spawnPos.offset.y, garageCoords.Z + spawnPos.offset.z)
            local vehicle, plate = exports['qb-core']:SpawnVehicle(playerData.source, vehicleData.vehicle, coords, spawnPos.heading, vehicleData.plate, playerData.citizenid, tonumber(vehicleData.drivingdistance))
            print(string.format('[hl-properties] PopulateGarage - Spawning vehicle with plate: %s, vehicleName: %s', vehicleData.plate, vehicleData.vehicle))
            if vehicle then
                vehicle = HVehicle.wrap(vehicle.Object)
                vehicles[#vehicles + 1] = { entity = vehicle, plate = plate, id = vehicle:GetVehicleId() }
            end
        end
    end

    return vehicles
end

local function EnterInstancedUnit(source, propertyKey)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('EnterInstancedUnit - No Player Found')
        return
    end

    local unit = PropertyUnits[propertyKey]
    if not unit then
        print('EnterInstancedUnit - No Property Unit Found for key', propertyKey)
        return
    end

    local interiorRef = unit.interiorRef
    if not interiorRef then
        print('EnterInstancedUnit - No interiorRef found for propertyKey', propertyKey)
        return
    end

    local shellConfig = interiorRef and Config.Shells and Config.Shells[interiorRef] or nil
    if not shellConfig then
        print('EnterInstancedUnit - No shellConfig found for interiorRef', interiorRef)
        return
    end

    local inst = PropertyInstances[propertyKey]

    if inst and inst.creating then
        print('EnterInstancedUnit - Instance for propertyKey', propertyKey, 'is currently locked')
        return
    end

    if inst then
        if inst.playersSet and inst.playersSet[source] then
            print('EnterInstancedUnit - Player is already inside instance for propertyKey', propertyKey)
            return
        end

        inst.creating = true

        local poiOffsets = inst.poiOffsets
        local coords = Vector(
            inst.location.X - poiOffsets.exit.x,
            inst.location.Y - poiOffsets.exit.y,
            inst.location.Z + poiOffsets.exit.z
        )

        AddPlayerToProperty(source, propertyKey)

        local garageLoc = inst.garage and inst.garage.location or nil

        TriggerClientEvent(
            source,
            'qb-houses:client:EnterProperty',
            propertyKey,
            interiorRef,
            inst.location,
            garageLoc,
            coords
        )

        inst.creating = false
        return
    end

    print('EnterInstancedUnit - No existing instance found for propertyKey', propertyKey, ' - Creating new instance')

    local offset = GetOrCreateOffset(unit.entranceId, propertyKey)
    print('EnterInstancedUnit - Creating new instance for propertyKey', propertyKey, 'with offset', offset)

    PropertyInstances[propertyKey] = {
        creating = true,
        players = {},
        playersSet = {},
        requests = {}
    }
    inst = PropertyInstances[propertyKey]

    local entrance = Entrances[unit.entranceId]
    if not entrance then
        print('EnterInstancedUnit - No entrance found for entranceId', unit.entranceId)
        PropertyInstances[propertyKey] = nil
        return
    end

    if not entrance.coords then
        print('EnterInstancedUnit - No entrance coords found for entranceId', unit.entranceId)
        PropertyInstances[propertyKey] = nil
        return
    end

    local shellSpawn = Vector(
        entrance.coords.x,
        entrance.coords.y,
        entrance.coords.z + offset
    )
    local spawnTransform = Transform()
    spawnTransform.Translation = shellSpawn
    local propertyInstance = SpawnActor(shellConfig.shell, spawnTransform)
    if not propertyInstance then
        print('EnterInstancedUnit - Failed to create LevelInstance for propertyKey', propertyKey)
        PropertyInstances[propertyKey] = nil
        return
    end

    local exteriorData = nil
    if shellConfig.exterior then
        exteriorData = {}
        for _, path in pairs(shellConfig.exterior) do
            local Transform = Transform()
            Transform.Translation = shellSpawn
            exteriorData[#exteriorData + 1] = SpawnActor(path, Transform)
        end
    end

    local poiOffsets = { exit = shellConfig.exitOffset }

    local garageData = nil
    local garageCoords = nil
    if shellConfig.garage and shellConfig.garage ~= '' then
        local garageOffset = shellConfig.garageOffset or 0
        garageCoords = Vector(shellSpawn.X, shellSpawn.Y, shellSpawn.Z + garageOffset)
        local garageTransform = Transform()
        garageTransform.Translation = garageCoords
        local garageInstance = SpawnActor(shellConfig.garage, garageTransform)
        garageData = {
            location = garageCoords,
            offset = garageOffset,
            object = garageInstance,
            shell = shellConfig.garage,
            poiOffsets = { exit = shellConfig.garageExitOffset }
        }

        if shellConfig.garageVehicleOffsets then
            garageData.vehicles = PopulateGarage(Player.PlayerData, unit.entranceId, shellConfig, garageCoords)
        end
    end

    inst.entranceId = unit.entranceId
    inst.interiorRef = interiorRef
    inst.offset = offset
    inst.object = propertyInstance
    inst.exterior = exteriorData
    inst.poiOffsets = poiOffsets
    inst.location = shellSpawn
    inst.garage = garageData

    AddPlayerToProperty(source, propertyKey)

    local exitCoords = Vector(
        shellSpawn.X - poiOffsets.exit.x,
        shellSpawn.Y - poiOffsets.exit.y,
        shellSpawn.Z + poiOffsets.exit.z
    )

    TriggerClientEvent(
        source,
        'qb-houses:client:EnterProperty',
        propertyKey,
        interiorRef,
        shellSpawn,
        garageCoords,
        exitCoords
    )

    inst.creating = false
end
exports('hl-properties', 'EnterInstancedUnit', EnterInstancedUnit)

local function LeaveInstancedUnit(source, propertyKey, isInVehicle)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('LeaveInstancedUnit - Player not found')
        return
    end
    local unit = PropertyUnits[propertyKey]
    if not unit then
        print('LeaveInstancedUnit - Property unit not found')
        return
    end
    RemovePlayerFromProperty(Player, propertyKey)
    local inst = PropertyInstances[propertyKey]
    if not inst then
        print('LeaveInstancedUnit - Property instance not found')
        return
    end
    local entrance = Entrances[unit.entranceId]
    if not entrance then
        print('LeaveInstancedUnit - Entrance not found')
        return
    end
    if entrance and entrance.coords and not isInVehicle then
        SetEntityCoords(GetPlayerPawn(source), Vector(entrance.coords.x + math.random(-50, 50), entrance.coords.y + math.random(-50, 50), entrance.coords.z))
    end
    if inst and (not inst.players or not next(inst.players)) then
        local eid = inst.entranceId or unit.entranceId
        if inst.object then inst.object:K2_DestroyActor() end
        if inst.exterior then
            for _, exteriorObject in pairs(inst.exterior) do
                if exteriorObject then
                    exteriorObject:K2_DestroyActor()
                end
            end
        end
        if inst.garage and inst.garage.object then inst.garage.object:K2_DestroyActor() end
        if inst.garage and type(inst.garage.vehicles) == 'table' and #inst.garage.vehicles > 0 then
            local VehicleManager = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(HWorld, UE.UHVehicleManager)
            if VehicleManager then
                for id, vehicleData in pairs(inst.garage.vehicles) do
                    print(string.format('[hl-properties] LeaveInstancedUnit - Deleting Vehicle with id: %s', tostring(id)))
                    if vehicleData.id then
                        VehicleManager:DestroyVehicle(vehicleData.id)
                    else
                        DeleteVehicle(vehicleData.entity.Object)
                    end
                end
            end
        end
        inst.requests = nil
        PropertyInstances[propertyKey] = nil
    end
    TriggerClientEvent(source, 'qb-houses:client:LeaveProperty')
end
exports('hl-properties', 'LeaveInstancedUnit', LeaveInstancedUnit)

local function IsPropertyOwner(source, propertyKey)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('IsPropertyOwner - Player not found')
        return false
    end
    local unit = PropertyUnits[propertyKey]
    if not unit then return false end
    return unit.ownerCitizenId == Player.PlayerData.citizenid
end
exports('hl-properties', 'IsPropertyOwner', IsPropertyOwner)

-- Logout Handler

RegisterServerEvent('HEvent:PlayerLoggedOut', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('HEvent:PlayerLoggedOut - Player not found')
        return
    end
    local citizenId = Player.PlayerData.citizenid

    for propertyKey, inst in pairs(PropertyInstances) do
        if inst.players and inst.players[citizenId] then
            LeaveInstancedUnit(source, propertyKey)
        end
    end
end)

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('HEvent:PlayerUnloaded - Player not found')
        return
    end
    local citizenId = Player.PlayerData.citizenid

    for propertyKey, inst in pairs(PropertyInstances) do
        if inst.players and inst.players[citizenId] then
            LeaveInstancedUnit(source, propertyKey)
        end
    end
end)

RegisterServerEvent('QBCore:Server:OnPlayerUnload', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('QBCore:Server:OnPlayerUnload - Player not found')
        return
    end
    local citizenId = Player.PlayerData.citizenid

    for propertyKey, inst in pairs(PropertyInstances) do
        if inst.players and inst.players[citizenId] then
            LeaveInstancedUnit(source, propertyKey)
        end
    end
end)

-- Events

RegisterServerEvent('qb-houses:server:teleportPlayer', function(source, coords)
    if not coords then
        print('teleportPlayer - No coords provided')
        return
    end
    local playerPawn = GetPlayerPawn(source)
    SetEntityCoords(playerPawn, Vector(coords.X, coords.Y, coords.Z))
end)

RegisterServerEvent('qb-houses:server:EnterEntrance', function(source, data)
    local entranceId = data and data.entranceId or nil
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('EnterEntrance - Player isnt ready')
        return
    end
    if not entranceId then
        print('EnterEntrance - No entranceId provided')
        return
    end
    local entrance = Entrances[entranceId]
    if not entrance then
        print('EnterEntrance - Entrance not found')
        return
    end
    local propertyKey = getOwnedUnitKey(entranceId, Player.PlayerData.citizenid)
    if not propertyKey then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_owner'), 'danger')
        return
    end
    EnterInstancedUnit(source, propertyKey)
end)

RegisterServerEvent('qb-houses:server:PurchaseProperty', function(source, data)
    local entranceId = data and data.entranceId or nil
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('EnterEntrance - Player isnt ready')
        return
    end
    if not entranceId then
        print('EnterEntrance - No entranceId provided')
        return
    end
    local entrance = Entrances[entranceId]
    if not entrance then
        print('EnterEntrance - Entrance not found')
        return
    end
    if entrance.entranceType ~= 'instanced' then
        print('PurchaseProperty - Entrance is not instanced')
        return
    end
    local cid = Player.PlayerData.citizenid
    if getOwnedUnitKey(entranceId, cid) then
        print('PurchaseProperty - Player already owns a unit for entranceId', entranceId)
        return
    end
    local price = tonumber(entrance.price) or 0
    local money = Player.PlayerData.money or {}
    local cash = tonumber(money.cash) or 0
    if cash < price then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_enough_money'), 'danger')
        return
    end
    local propertyKey = exports['qb-core']:CreateApartmentId()
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO properties (property_key, entrance_id, owner_citizenid, owned, interior_type, interior_ref) VALUES (?, ?, ?, ?, ?, ?)', { propertyKey, entranceId, cid, 1, 'instanced', entrance.interiorRef })
    exports['qb-core']:Player(source, 'RemoveMoney', 'cash', price)
    exports['qb-inventory']:CreateStash(propertyKey .. '_furniture', {
        maxweight = 50000000000,
        slots = 500,
        label = ('%s Furniture Stash'):format(propertyKey)
    })
    registerUnit(propertyKey, entranceId, cid, 'instanced', entrance.interiorRef)
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.purchased_apart') .. (entrance.label or entranceId))
    EnterInstancedUnit(source, propertyKey)
    TriggerClientEvent(source, 'qb-houses:client:PurchaseProperty')
end)

RegisterServerEvent('qb-houses:server:LeaveProperty', function(source, data)
    local propertyKey = data and data.CurrentProperty or nil
    if not propertyKey then
        print('LeaveProperty - No propertyKey provided')
        return
    end
    LeaveInstancedUnit(source, propertyKey)
end)

-- RegisterServerEvent('qb-houses:server:LogoutProperty', function(source, data) -- not used for now
-- 	local propertyKey = data and data.CurrentProperty or nil
-- 	if not propertyKey then return end
-- 	LeaveInstancedUnit(source, propertyKey)
-- 	exports['qb-core']:Logout(source)
-- 	TriggerClientEvent(source, 'qb-multicharacter:client:chooseChar')
-- end)

RegisterServerEvent('qb-houses:server:GoToGarage', function(source, data)
    local propertyKey = data and data.CurrentProperty or nil
    if not propertyKey then
        print('GoToGarage - No propertyKey provided')
        return
    end
    local inst = PropertyInstances[propertyKey]
    if not (inst and inst.garage) then
        print('GoToGarage - No garage found for propertyKey', propertyKey)
        return
    end
    local garageOffset = inst.garage.offset
    local garagePOI = inst.garage.poiOffsets
    local garageCoords = Vector(
        inst.location.X - garagePOI.exit.x,
        inst.location.Y - garagePOI.exit.y,
        inst.location.Z + garageOffset + garagePOI.exit.z
    )
    local playerPawn = GetPlayerPawn(source)
    SetEntityCoords(playerPawn, garageCoords)
    TriggerClientEvent(source, 'qb-houses:client:GarageInteractions', garageCoords)
end)

RegisterServerEvent('qb-houses:server:StoreVehicle', function(source, data)
    local pawn = GetPlayerPawn(source)
    local vehicle = GetVehiclePedIsIn(pawn)
    if not vehicle then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_in_vehicle'), 'danger')
        return
    end
    local entranceId = data.entranceId
    -- check player and distance data
    local Player = exports['qb-core']:GetPlayer(source)
    if not (Player and entranceId) then return end

    local entrance = Entrances[entranceId]
    if not entrance or not entrance.garageCoords then return end
    if GetDistanceBetweenCoords(GetEntityCoords(pawn), entrance.garageCoords.coords) > 500 then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.too_far_from_garage'), 'danger')
        return
    end

    -- check for vehicle slots
    local shellData = Config.Shells[entranceId]
    if not shellData.garageVehicleOffsets then return end

    -- check ownership
    local propertyKey = getOwnedUnitKey(entranceId, Player.PlayerData.citizenid)
    if not propertyKey then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_owner'), 'danger')
        return
    end

    -- check garage slots
    local vehiclePlate = vehicle:GetPlate()
    local results = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM player_vehicles WHERE plate = ? and citizenid = ?', {
        vehiclePlate,
        Player.PlayerData.citizenid,
    })
    if type(results) ~= 'table' or #results <= 0 then
        print(string.format('[hl-properties] StoreVehicle - Vehicle not found for plate: %s, citizenid: %s', vehiclePlate, Player.PlayerData.citizenid))
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_vehicle_owner'), 'danger')
        return
    end
    if #results > #shellData.garageVehicleOffsets then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.full_garage'), 'danger')
        return
    end

    exports['hl-garages']:DepositVehicle(source, pawn, entranceId, vehicle)
end)

RegisterServerEvent('qb-houses:server:ReturnToProperty', function(source, data)
    local propertyKey = data and data.CurrentProperty or nil
    if not propertyKey then
        print('ReturnToProperty - No propertyKey provided')
        return
    end
    local inst = PropertyInstances[propertyKey]
    if not inst then
        print('ReturnToProperty - No instance found for propertyKey', propertyKey)
        return
    end
    local poiOffsets = inst.poiOffsets
    local coords = Vector(
        inst.location.X - poiOffsets.exit.x,
        inst.location.Y - poiOffsets.exit.y,
        inst.location.Z + poiOffsets.exit.z
    )
    SetEntityCoords(GetPlayerPawn(source), coords)
end)

RegisterServerEvent('qb-houses:server:OpenStash', function(source, data)
    local propertyKey = data and data.CurrentProperty or nil
    if not propertyKey then
        print('OpenStash - No propertyKey provided')
        return
    end
    exports['qb-inventory']:OpenInventory(source, propertyKey)
end)

RegisterServerEvent('qb-houses:server:OpenFurnitureStash', function(source, data)
    local propertyKey = data and data.CurrentProperty or nil
    if not propertyKey then
        print('OpenStash - No propertyKey provided')
        return
    end
    local inventoryName = propertyKey .. '_furniture'
    exports['qb-inventory']:OpenInventory(source, inventoryName)
end)

-- RegisterServerEvent('qb-houses:server:createProperty', function(source, data) -- not used for now
-- 	local Player = exports['qb-core']:GetPlayer(source)
-- 	if not Player then return end
-- 	local entranceId   = data and data.entranceId
-- 	local label        = data and data.label
-- 	local entranceType = data and data.entranceType or 'instanced'
-- 	local interiorRef  = data and data.interiorRef or entranceId
-- 	local price        = tonumber(data and data.price) or 0
-- 	local coords       = data and data.coords
-- 	if not entranceId or entranceId == '' then return end
-- 	if not coords or coords.x == nil or coords.y == nil or coords.z == nil then return end
-- 	if entranceType ~= 'instanced' and entranceType ~= 'world' then entranceType = 'instanced' end
-- 	if entranceType == 'instanced' then
-- 		local shells = Config.Shells or {}
-- 		if not interiorRef or not shells[interiorRef] then return end
-- 	else
-- 		interiorRef = nil
-- 	end
-- 	local existing = exports['qb-core']:DatabaseAction('Select', 'SELECT entrance_id FROM property_entrances WHERE entrance_id = ? LIMIT 1', { entranceId })
-- 	if existing and existing[1] then
-- 		TriggerClientEvent(source, 'QBCore:Notify', 'Entrance ID already exists', 'error')
-- 		return
-- 	end
-- 	exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO property_entrances (entrance_id, label, entrance_type, coords, interior_ref, price, active) VALUES (?, ?, ?, ?, ?, ?, 1)',
-- 		{
-- 			entranceId,
-- 			label or entranceId,
-- 			entranceType,
-- 			JSON.stringify({ x = coords.x, y = coords.y, z = coords.z }),
-- 			interiorRef,
-- 			price
-- 		}
-- 	)
-- 	Entrances[entranceId] = {
-- 		entranceId = entranceId,
-- 		label = label or entranceId,
-- 		entranceType = entranceType,
-- 		coords = { x = coords.x, y = coords.y, z = coords.z },
-- 		interiorRef = interiorRef,
-- 		price = price,
-- 		isHardcoded = false
-- 	}
-- 	ensureEntranceMaps(entranceId)
-- 	TriggerClientEvent(source, 'QBCore:Notify', ('Property created: %s'):format(entranceId), 'success')
-- end)

local function HandleInventory(source, propertyKey, oldSceneData, sceneData)
    local diff = UE.TMap('', 0)
    local success = UE.UQuietEditorDataModelLibrary.ComputeSceneInventoryDiff(diff, oldSceneData, sceneData)

    if not success then
        print('Failed to compute inventory diff')
        return false
    end

    for itemName, amount in pairs(diff) do
        if amount > 0 then
            local removed = exports['qb-inventory']:RemoveItem(source, itemName, amount)
            if not removed then
                print('Failed to remove item from inventory:', itemName, amount)
                return false
            end
        elseif amount < 0 then
            local added = exports['qb-inventory']:AddItem(propertyKey .. '_furniture', itemName, math.abs(amount))
            if not added then
                print('Failed to add item to inventory:', itemName, math.abs(amount))
                return false
            end
        end
    end

    return true
end

RegisterServerEvent('qb-houses:server:SaveSceneData', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('SaveSceneData - Player not found for source', source)
        return
    end
    local citizenId = Player.PlayerData.citizenid
    local propertyKey = data and data.CurrentProperty or nil
    local oldSceneData = data and data.oldSceneData or nil
    local sceneData = data and data.sceneData or nil
    if not propertyKey or type(sceneData) ~= 'string' then
        print('SaveSceneData - Invalid data provided')
        return
    end

    if oldSceneData ~= nil and type(oldSceneData) ~= 'string' then
        print('SaveSceneData - Invalid oldSceneData type')
        return
    end

    if not IsPropertyOwner(source, propertyKey) then
        print('SaveSceneData - Player is not the owner of the property', propertyKey)
        return
    end

    local inventorySuccess = HandleInventory(source, propertyKey, oldSceneData or '{"actors":{}}', sceneData)
    if not inventorySuccess then
        print('SaveSceneData - Inventory handling failed, aborting save')
        TriggerClientEvent(source, 'QBCore:Notify', 'Failed to save furniture - inventory error', 'danger')
        return
    end

    exports['qb-core']:DatabaseAction('Execute', "UPDATE properties SET scene_data = ?, updated_at = strftime('%s','now') WHERE property_key = ? AND owner_citizenid = ?", { sceneData, propertyKey, citizenId })
    TriggerClientEvent(source, 'QBCore:Notify', 'Furniture saved!', 'check')
    pcall(function()
        exports['hl-onboarding']:CompleteStep(source, 'place_furniture')
    end)
    local inst = PropertyInstances[propertyKey]
    if inst and inst.players then
        for _, playerSrc in pairs(inst.players) do
            TriggerClientEvent(playerSrc, 'qb-houses:client:ReloadFurniture', propertyKey)
        end
    end
end)

RegisterServerEvent('qb-houses:server:getProperties', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        print('getProperties - Player not found for source', source)
        return
    end
    local allProperties = {}
    for propertyKey, unit in pairs(PropertyUnits) do
        local entranceId = unit.entranceId
        local entrance = Entrances[entranceId]
        if entrance then
            local property = {
                id = propertyKey,
                label = entrance.label or propertyKey,
                coords = entrance.coords,
                interiorRef = unit.interiorRef,
                price = entrance.price,
                owner = unit.ownerCitizenId or nil,
                property_tag = entranceId,
            }
            if not property.owner or property.owner == '' then property.owner = nil end
            if unit.ownerCitizenId then
                local ownerPlayer = exports['qb-core']:GetPlayerByCitizenId(unit.ownerCitizenId)
                if ownerPlayer then
                    property.ownerData = {
                        citizenid = ownerPlayer.PlayerData.citizenid,
                        name = ownerPlayer.PlayerData.charinfo and (ownerPlayer.PlayerData.charinfo.firstname .. ' ' .. ownerPlayer.PlayerData.charinfo.lastname) or 'Unknown',
                        charinfo = ownerPlayer.PlayerData.charinfo,
                        money = ownerPlayer.PlayerData.money,
                        online = ownerPlayer.PlayerData.source ~= nil
                    }
                end
            end
            table.insert(allProperties, property)
        end
    end
    TriggerClientEvent(source, 'qb-houses:client:updateProperties', allProperties)
end)

-- Callbacks

RegisterCallback('GetEntrances', function(_)
    local out = {}
    for id, e in pairs(Entrances) do
        out[id] = {
            entranceId = e.entranceId,
            label = e.label,
            entranceType = e.entranceType,
            coords = e.coords,
            garageCoords = e.garageCoords,
            price = e.price
        }
    end
    return out
end)

RegisterCallback('IsPropertyOwner', function(source, propertyKey)
    return IsPropertyOwner(source, propertyKey)
end)

RegisterCallback('IsOwnerAtEntrance', function(source, entranceId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return false end
    return getOwnedUnitKey(entranceId, Player.PlayerData.citizenid) ~= nil
end)

RegisterCallback('GetOccupiedUnitsAtEntrance', function(_, entranceId)
    local out = {}
    local units = EntranceUnits[entranceId]
    if not units then return out end
    for propertyKey in pairs(units) do
        local inst = PropertyInstances[propertyKey]
        if inst and inst.players and next(inst.players) ~= nil then
            out[propertyKey] = true
        end
    end
    return out
end)

RegisterCallback('GetDoorRequests', function(_, propertyKey)
    local inst = PropertyInstances[propertyKey]
    if not inst then return nil end
    return inst.requests
end)

RegisterCallback('getSceneData', function(source, propertyKey)
    if not propertyKey then return nil end
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT scene_data FROM properties WHERE property_key = ? LIMIT 1', { propertyKey })
    if rows and rows[1] then return rows[1].scene_data end
    return nil
end)

RegisterCallback('getProperties', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return {} end
    local citizenId = Player.PlayerData.citizenid
    local ownedProperties = {}
    for propertyKey, unit in pairs(PropertyUnits) do
        if unit.ownerCitizenId == citizenId then
            local entranceId = unit.entranceId
            local entrance = Entrances[entranceId]
            if entrance then
                ownedProperties[propertyKey] = {
                    id = entranceId,
                    label = entrance.label,
                    interiorRef = unit.interiorRef,
                    price = entrance.price,
                }
            end
        end
    end
    return ownedProperties
end)

RegisterCallback('getInventory', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.items
end)

RegisterCallback('WithdrawVehicle', function(source, propertyKey)
    local unit = PropertyUnits[propertyKey]
    if not unit then return false end

    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return false end

    local withdrawLocation = Config.Apartments[unit.entranceId].storeVehicle
    if not withdrawLocation then return false end

    local playerPawn = GetPlayerPawn(source)
    local vehicle = GetVehiclePedIsIn(playerPawn)
    if not vehicle then return false end

    -- update vehicle garage state
    local vehiclePlate = vehicle:GetPlate()
    local success = exports['hl-garages']:WithdrawVehicle(source, vehiclePlate, unit.entranceId, nil, vehicle)
    if not success then return false end
    print(string.format('[hl-properties] WithdrawVehicle - Withdrawing Vehicle with plate: %s, citizenid: %s, propertyKey: %s', vehiclePlate, Player.PlayerData.citizenid, propertyKey))

    -- remove from cached vehicle entries to prevent being cleaned
    local garageData = PropertyInstances[propertyKey].garage
    local vehicles = garageData and garageData.vehicles
    if type(vehicles) ~= 'table' then return false end
    for index, vehicleData in pairs(vehicles) do
        print(string.format('[hl-properties] WithdrawVehicle - Checking cached vehicle with plate: %s against withdrawn plate: %s', vehicleData.plate, vehiclePlate), vehicleData.plate == vehiclePlate)
        if vehicleData.plate == vehiclePlate then
            vehicles[index] = nil
            print(string.format('[hl-properties] WithdrawVehicle - Removing Vehicle from garage cache with plate: %s, index: %s', vehicleData.plate, index))
            break
        end
    end

    -- leave property and set vehicle location
    vehicle.VehicleMovementComponent:StopActiveMovement()
    LeaveInstancedUnit(source, propertyKey, true)
    SetEntityCoords(vehicle, withdrawLocation.coords)
    SetEntityHeading(vehicle, withdrawLocation.heading)
    return true
end)

-- Optional: starter apartment

-- RegisterServerEvent('qb-houses:server:StarterApartment', function(source, entrance_id)
--     local Player = exports['qb-core']:GetPlayer(source)
--     if not Player then
--         print('StarterApartment - Player not found for source', source)
--         return
--     end
--     local entranceId = entrance_id or 'starter_apt'
--     local entrance = Entrances[entranceId]
--     if not entrance or entrance.entranceType ~= 'instanced' then
--         print('StarterApartment - Invalid entrance or entrance type for entranceId', entranceId)
--         return
--     end
--     local existingKey = getOwnedUnitKey(entranceId, Player.PlayerData.citizenid)
--     if existingKey then
--         EnterInstancedUnit(source, existingKey)
--         return
--     end
--     local propertyKey = exports['qb-core']:CreateApartmentId()
--     exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO properties (property_key, entrance_id, owner_citizenid, owned, interior_type, interior_ref) VALUES (?, ?, ?, ?, ?, ?)',
--         {
--             propertyKey,
--             entranceId,
--             Player.PlayerData.citizenid,
--             1,
--             'instanced',
--             entrance.interiorRef
--         }
--     )
--     exports['qb-inventory']:CreateStash(propertyKey .. '_furniture', {
--         maxweight = 50000000000,
--         slots = 500,
--         label = ('%s Furniture Stash'):format(propertyKey)
--     })
--     registerUnit(propertyKey, entranceId, Player.PlayerData.citizenid, 'instanced', entrance.interiorRef)
--     TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.receive_apart') .. ' (' .. entrance.label .. ')')
--     EnterInstancedUnit(source, propertyKey)
-- end)
