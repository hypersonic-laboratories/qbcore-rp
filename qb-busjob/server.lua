local Lang = require('locales/en')
local jobPeds = {}
local busStops = {}
local activeRoutes = {}
local Initialised = false

local function deleteActor(actor)
    if actor and actor:IsValid() then
        DeleteEntity(actor)
    end
end

local function notify(source, message, notifyType)
    TriggerClientEvent(source, 'QBCore:Notify', message, notifyType or 'primary')
end

local function spawnJobPed(depot, depotIndex)
    local pedName = depot.pedName or depot.label or 'Bus Depot'
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
    if not vehicle then
        return nil
    end

    if vehicle.SetFuel then
        vehicle:SetFuel(100.0)
    end
    if vehicle.SetPlate then
        vehicle:SetPlate('BUS' .. tostring(math.random(1000, 9999)))
    end

    return vehicle
end

local function getPlayerRoute(source)
    return activeRoutes[GetPlayerId(source)]
end

local function deletePassenger(route)
    deleteActor(route and route.passenger)
    if route then
        route.passenger = nil
        route.hasPassenger = false
    end
end

local function cleanupRoute(source)
    local playerId = GetPlayerId(source)
    local route = activeRoutes[playerId]
    if not route then
        return
    end

    deletePassenger(route)
    if route.vehicle and route.vehicle:IsValid() then
        DeleteVehicle(route.vehicle)
    end
    activeRoutes[playerId] = nil
    TriggerClientEvent(source, 'qb-busjob:client:routeEnded')
end

local function getNextStopIndex(stopIndex)
    if stopIndex and stopIndex < #Config.Locations.Stops then
        return stopIndex + 1
    end
    return 1
end

local function getPassengerCoords(stop)
    return {
        X = stop.coords.X + Config.PassengerOffset.X,
        Y = stop.coords.Y + Config.PassengerOffset.Y,
        Z = stop.coords.Z + Config.PassengerOffset.Z,
    }
end

local function isNearStop(source, stopIndex)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return false
    end

    local stop = Config.Locations.Stops[stopIndex]
    if not stop then
        return false
    end

    local coords = GetEntityCoords(pawn)
    return coords:Dist(stop.coords) <= Config.StopInteractionDistance
end

local function getPayout()
    local payout = math.random(Config.Payment.Min, Config.Payment.Max)
    if math.random(1, 100) <= Config.Payment.TipChance then
        payout = payout + math.random(Config.Payment.TipMin, Config.Payment.TipMax)
    end
    return payout
end

local function enterPassengerVehicle(passenger, vehicle)
    local params = UE.FHEnterVehicleParams()
    params.bSkipAnimations = true

    if vehicle.K2_GetComponentsByClass and UE.USeatComponent then
        local seats = vehicle:K2_GetComponentsByClass(UE.USeatComponent):ToTable()
        for i = 2, #seats do
            local seat = seats[i]
            if seat and not seat:IsSeatOccupied() then
                return UE.UHGameplaySystemGlobals.SendEnterVehicleEventToActorBySeat(passenger, vehicle, seat, params)
            end
        end
    end

    return UE.UHGameplaySystemGlobals.SendEnterVehicleEventToActor(passenger, vehicle, 2, params)
end

local function exitPassengerVehicle(passenger, vehicle)
    if not passenger or not passenger:IsValid() or not vehicle then
        return
    end

    local seatClass = LoadClass('/Game/SimpleVehicle/Blueprints/Components/SimpleVehicleSeat.SimpleVehicleSeat_C')
    local seats = GetComponentsByClass(vehicle, seatClass)
    for _, seat in pairs(seats) do
        local occupier = seat:GetSeatOccupancy()
        if occupier and occupier == passenger then
            local params = UE.FHExitVehicleParams()
            params.bSkipAnimations = true
            UE.UHGameplaySystemGlobals.SendExitVehicleEventToActor(occupier, params)
            return
        end
    end
end

local function assignPassenger(source, pickupStopIndex)
    local route = getPlayerRoute(source)
    if not route then
        return
    end

    deletePassenger(route)

    local pickupStop = Config.Locations.Stops[pickupStopIndex]
    if not pickupStop then
        return
    end

    local passengerCoords = getPassengerCoords(pickupStop)
    HPawn(passengerCoords, Rotator(0, pickupStop.heading, 0), function(npc)
        route = getPlayerRoute(source)
        if not route then
            if npc and npc:IsValid() then
                DeleteEntity(npc)
            end
            return
        end

        route.passenger = npc
        route.pickupStopIndex = pickupStopIndex
        route.dropoffStopIndex = getNextStopIndex(pickupStopIndex)
        route.hasPassenger = false
        route.currentStopIndex = pickupStopIndex

        npc:SetCharacterName('Bus Passenger')
        SetEntityInvincible(npc, true)

        TriggerClientEvent(source, 'qb-busjob:client:pickupSpot', passengerCoords, pickupStopIndex)
        notify(source, Lang.t('info.goto_busstop'), 'primary')
    end, { CharacterName = 'Bus Passenger', bShowNameplate = true })
end

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    cleanupRoute(source)
end)

function onShutdown()
    for _, route in pairs(activeRoutes) do
        deletePassenger(route)
        if route.vehicle and route.vehicle:IsValid() then
            DeleteVehicle(route.vehicle)
        end
    end
    activeRoutes = {}

    for _, stop in pairs(busStops) do
        deleteActor(stop)
    end
    busStops = {}

    for i = 1, #jobPeds do
        deleteActor(jobPeds[i].npc)
    end
    jobPeds = {}
end

for i = 1, #Config.Locations.Stops do
    local stop = Config.Locations.Stops[i]
    local busStop = StaticMesh(stop.coords, Rotator(0, stop.heading, 0), '/QBCoreAssets/Meshes/SM_BusStop.SM_BusStop')
    busStops[busStop.Object] = busStop.Object
end

RegisterServerEvent('HEvent:PlayerPossessed', function()
    if Initialised then
        return
    end

    for i = 1, #Config.Locations.Depots do
        spawnJobPed(Config.Locations.Depots[i], i)
    end

    Initialised = true
end)

RegisterCallback('getPeds', function()
    return jobPeds
end)

RegisterServerEvent('qb-busjob:server:takeVehicle', function(source, args)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job then
        print('qb-busjob:server:takeVehicle - Player job is not bus')
        return
    end

    if getPlayerRoute(source) then
        notify(source, Lang.t('error.one_bus_active'), 'error')
        return
    end

    local depot = Config.Locations.Depots[args.depot]
    if not depot then
        return
    end

    local vehicle = spawnJobVehicle(depot)
    if not vehicle then
        return
    end

    activeRoutes[GetPlayerId(source)] = {
        vehicle = vehicle,
        currentStopIndex = math.random(#Config.Locations.Stops),
        stopsCompleted = 0,
    }

    notify(source, Lang.t('success.route_started'), 'success')
    assignPassenger(source, getPlayerRoute(source).currentStopIndex)
end)

RegisterServerEvent('qb-busjob:server:finishWork', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job then
        print('qb-busjob:server:finishWork - Player job is not bus')
        return
    end

    local route = getPlayerRoute(source)
    if not route then
        notify(source, Lang.t('error.no_route'), 'error')
        return
    end

    if route.hasPassenger and route.passenger and route.passenger:IsValid() then
        notify(source, Lang.t('error.drop_off_passengers'), 'error')
        return
    end

    cleanupRoute(source)
    notify(source, Lang.t('success.route_finished'), 'success')
end)

RegisterServerEvent('qb-busjob:server:pickupNPC', function(source, stopIndex)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job then
        return
    end

    local route = getPlayerRoute(source)
    if not route then
        notify(source, Lang.t('error.no_route'), 'error')
        return
    end

    if stopIndex ~= route.pickupStopIndex or not isNearStop(source, stopIndex) then
        notify(source, Lang.t('error.too_far'), 'error')
        return
    end

    local pawn = GetPlayerPawn(source)
    local vehicle = pawn and pawn:GetCurrentVehicle()
    if not vehicle then
        notify(source, Lang.t('error.not_in_bus'), 'error')
        return
    end

    if not route.passenger or not route.passenger:IsValid() then
        return
    end

    local entered = enterPassengerVehicle(route.passenger, vehicle)
    if not entered then
        notify(source, Lang.t('error.no_seat'), 'error')
        return
    end

    route.hasPassenger = true

    local dropoffStop = Config.Locations.Stops[route.dropoffStopIndex]
    TriggerClientEvent(source, 'qb-busjob:client:dropoffSpot', dropoffStop.coords, route.dropoffStopIndex)
    notify(source, Lang.t('info.goto_busstop'), 'primary')
end)

RegisterServerEvent('qb-busjob:server:dropoffNPC', function(source, stopIndex)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job then
        return
    end

    local route = getPlayerRoute(source)
    if not route then
        notify(source, Lang.t('error.no_route'), 'error')
        return
    end

    if stopIndex ~= route.dropoffStopIndex or not isNearStop(source, stopIndex) then
        notify(source, Lang.t('error.too_far'), 'error')
        return
    end

    if not route.hasPassenger then
        return
    end

    local pawn = GetPlayerPawn(source)
    local vehicle = pawn and pawn:GetCurrentVehicle()
    local passenger = route.passenger

    exitPassengerVehicle(passenger, vehicle)
    Timer.SetTimeout(function()
        if passenger and passenger:IsValid() then
            DeleteEntity(passenger)
        end
    end, 7500)

    local payout = getPayout()
    Player.AddMoney('cash', payout, 'bus-job')

    route.passenger = nil
    route.hasPassenger = false
    route.stopsCompleted = route.stopsCompleted + 1
    route.currentStopIndex = stopIndex

    TriggerClientEvent(source, 'qb-busjob:client:jobComplete', payout)
    Timer.SetTimeout(function()
        assignPassenger(source, getNextStopIndex(stopIndex))
    end, 1000)
end)
