local Lang = require('locales/en')
local playerVehicles = {}
local benches = {}
local jobPeds = {}
local pickupNPCs = {}
local activeJobs = {}
local Initialised = false
local CM_PER_MILE = 160934

local function deleteActor(actor)
    if actor and actor:IsValid() then
        DeleteEntity(actor)
    end
end

local function spawnJobPed(depot, depotIndex)
    local pedName = depot.pedName or depot.label or 'Taxi Depot'
    HPawn(depot.pedSpawn, Rotator(0, depot.pedHeading or 0, 0), function(npc)
        if not npc then
            return
        end

        jobPeds[#jobPeds + 1] = { npc = npc, depot = depotIndex }
        npc:SetCharacterName(pedName)
        SetEntityInvincible(npc, true)
    end, { CharacterName = pedName, bShowNameplate = true })
end

local function spawnJobVehicle(depot)
    local vehicle = HVehicle(depot.vehicleSpawn, Rotator(0, depot.vehicleHeading or 0, 0), Config.Vehicle)
    if vehicle and vehicle.SetFuel then
        vehicle:SetFuel(100.0)
    end
    return vehicle
end

function onShutdown()
    for _, v in pairs(benches) do
        deleteActor(v)
    end
    benches = {}

    for i = 1, #jobPeds do
        deleteActor(jobPeds[i].npc)
    end
    jobPeds = {}

    for _, npc in pairs(pickupNPCs) do
        deleteActor(npc)
    end
    pickupNPCs = {}
end

for i = 1, #Config.Locations['Benches'] do
    local bench = StaticMesh(Config.Locations['Benches'][i].coords, Rotator(0, Config.Locations['Benches'][i].heading, 0), '/QBCoreAssets/Meshes/SM_BusStop.SM_BusStop')
    benches[bench.Object] = bench.Object
end

RegisterServerEvent('HEvent:PlayerPossessed', function()
    if Initialised then
        return
    end
    for i = 1, #Config.Locations['Depots'] do
        spawnJobPed(Config.Locations.Depots[i], i)
    end
    Initialised = true
end)

local function getRandomBench(excludeIndex)
    local availableBenches = {}
    for i = 1, #Config.Locations['Benches'] do
        if i ~= excludeIndex then
            table.insert(availableBenches, i)
        end
    end
    if #availableBenches == 0 then
        return nil
    end
    return availableBenches[math.random(#availableBenches)]
end

-- Callbacks

RegisterCallback('getPeds', function()
    return jobPeds
end)

-- Events

RegisterServerEvent('qb-taxijob:server:takeVehicle', function(source, args)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job then
        print('qb-taxijob:server:takeVehicle - Player job is not taxi')
        return
    end
    local depot = Config.Locations.Depots[args.depot]
    if not depot then
        return
    end
    local vehicle = spawnJobVehicle(depot)
    playerVehicles[GetPlayerId(source)] = vehicle
end)

RegisterServerEvent('qb-taxijob:server:finishWork', function(source)
    local playerId = GetPlayerId(source)
    local vehicle = playerVehicles[playerId]
    if vehicle and vehicle:IsValid() then
        DeleteVehicle(vehicle)
        playerVehicles[playerId] = nil
    end
    if activeJobs[playerId] then
        local npc = activeJobs[playerId].npc
        if npc and npc:IsValid() then
            DeleteEntity(npc)
        end
        activeJobs[playerId] = nil
    end
end)

RegisterServerEvent('qb-taxijob:server:startWork', function(source)
    local playerId = GetPlayerId(source)
    local vehicle = GetVehiclePedIsIn(GetPlayerPawn(source))
    local model = vehicle.Object
    local modelName = model:GetName()
    print(modelName)
    local pickupBenchIndex = math.random(#Config.Locations['Benches'])
    local pickupBench = Config.Locations['Benches'][pickupBenchIndex]
    local coords = {
        X = pickupBench.coords.X + 100,
        Y = pickupBench.coords.Y,
        Z = pickupBench.coords.Z,
    }
    HPawn(coords, Rotator(0, 0, 0), function(npc)
        table.insert(pickupNPCs, npc)
        Config.Locations['Benches'][pickupBenchIndex].npc = npc
        local dropoffBenchIndex = getRandomBench(pickupBenchIndex)
        activeJobs[playerId] = {
            npc = npc,
            pickupBenchIndex = pickupBenchIndex,
            dropoffBenchIndex = dropoffBenchIndex,
            hasPickedUp = false,
            maxFare = 0,
        }
        TriggerClientEvent(source, 'qb-taxijob:client:pickupSpot', coords, pickupBenchIndex)
    end, { CharacterName = 'Taxi Passenger', bShowNameplate = true })
end)

RegisterServerEvent('qb-taxijob:server:pickupNPC', function(source, benchIndex)
    local playerId = GetPlayerId(source)
    local pawn = GetPlayerPawn(source)
    local vehicle = pawn:GetCurrentVehicle()

    if not activeJobs[playerId] then
        print('No active job for player')
        return
    end

    local job = activeJobs[playerId]

    if benchIndex ~= job.pickupBenchIndex then
        print('Wrong bench index')
        return
    end

    if Config.Locations['Benches'][benchIndex] and Config.Locations['Benches'][benchIndex].npc then
        local npc = Config.Locations['Benches'][benchIndex].npc

        if npc and npc:IsValid() then
            local params = UE.FHEnterVehicleParams()
            params.bSkipAnimations = true
            local success = UE.UHGameplaySystemGlobals.SendEnterVehicleEventToActor(npc, vehicle, 2, params)
            if success then
                job.hasPickedUp = true
                Config.Locations['Benches'][benchIndex].npc = nil
                local pickupCoords = Config.Locations['Benches'][job.pickupBenchIndex].coords
                local dropoffCoords = Config.Locations['Benches'][job.dropoffBenchIndex].coords
                local distanceUU = GetDistanceBetweenCoords(pickupCoords, dropoffCoords)
                local miles = distanceUU / CM_PER_MILE
                local baseFare = miles * Config.Rate
                local padding = Config.MaxFarePadding or 1.5
                job.maxFare = math.floor(baseFare * padding)
                local baseDropoffCoords = Config.Locations['Benches'][job.dropoffBenchIndex].coords
                local dropoffCoordsForZone = {
                    X = baseDropoffCoords.X + 300,
                    Y = baseDropoffCoords.Y,
                    Z = baseDropoffCoords.Z,
                }
                TriggerClientEvent(source, 'qb-taxijob:client:dropoffSpot', dropoffCoordsForZone, job.dropoffBenchIndex)
            end
        end
    end
end)

RegisterServerEvent('qb-taxijob:server:dropoffNPC', function(source, benchIndex, meterFare)
    local playerId = GetPlayerId(source)
    local pawn = GetPlayerPawn(source)
    local vehicle = pawn:GetCurrentVehicle()

    if not activeJobs[playerId] then
        print('No active job for player')
        return
    end

    local job = activeJobs[playerId]

    if not job.hasPickedUp then
        print('NPC not picked up yet')
        return
    end

    if benchIndex ~= job.dropoffBenchIndex then
        print('Wrong drop-off bench')
        return
    end

    local npc = job.npc

    if npc and npc:IsValid() then
        local seatClass = LoadClass('/Game/SimpleVehicle/Blueprints/Components/SimpleVehicleSeat.SimpleVehicleSeat_C')
        local Seats = GetComponentsByClass(vehicle, seatClass)
        for _, v in pairs(Seats) do
            local Occupier = v:GetSeatOccupancy()
            if Occupier and Occupier == npc then
                UE.UHGameplaySystemGlobals.SendExitVehicleEventToActor(Occupier, UE.FHExitVehicleParams())
                break
            end
        end

        Timer.SetTimeout(function()
            if npc and npc:IsValid() then
                DeleteEntity(npc)
            end
        end, 7500)

        local rawFare = tonumber(meterFare) or 0
        if rawFare < 0 then
            rawFare = 0
        end

        local maxFare = job.maxFare or rawFare
        local payout = math.min(rawFare, maxFare)

        local Player = exports['qb-core']:GetPlayer(source)
        if Player and payout > 0 then
            Player.AddMoney('bank', payout, 'taxi-job')
        end

        activeJobs[playerId] = nil
        TriggerClientEvent(source, 'qb-taxijob:client:jobComplete', payout)
    end
end)
