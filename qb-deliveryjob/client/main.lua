local Lang = require('locales/en')
local TARGET_DISTANCE = Config.TargetDistance or 1500
local VEHICLE_TARGET_DISTANCE = Config.VehicleTargetDistance or 4000

local HoldingPackage = false
local CurrentLocation = {
    TimerId = nil,
    Cone = nil,
    Coords = nil,
    jobId = nil,
}
local depotMarkers = {}
local registeredTargets = {}
local currentVehicleTarget = nil
local deliveryMarker = nil

local function getDepots()
    return (Config.Locations and Config.Locations.Depots) or Config.Depots or {}
end

local function addMapMarker(coords, marker)
    local markerId = exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'boxes-stacked',
        color = marker.blipColor,
        markerType = marker.markerType or 'Store',
    })

    if markerId then
        depotMarkers[#depotMarkers + 1] = markerId
    end
end

local function addTargetEntity(entity, options, distance)
    if not entity then
        return
    end

    exports['qb-target']:AddTargetEntity(entity, {
        options = options,
        distance = distance or TARGET_DISTANCE,
    })
    registeredTargets[#registeredTargets + 1] = entity
end

local function clearRegisteredTargets()
    for _, entity in ipairs(registeredTargets) do
        exports['qb-target']:RemoveTargetEntity(entity)
    end
    registeredTargets = {}
    currentVehicleTarget = nil
end

local function createDepotMarkers()
    for _, depot in ipairs(getDepots()) do
        if depot.showBlip then
            addMapMarker(depot.pedSpawn, depot)
        end
    end
end

local function clearDepotMarkers()
    for _, id in ipairs(depotMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    depotMarkers = {}
end

local function removeMarker(markerId)
    if markerId then
        exports['qb-hud']:RemoveMarker(markerId)
    end
end

local function createDeliveryMarker(coords, currentStop, maxStops)
    return exports['qb-hud']:AddMarker(coords, {
        title = Lang.t('marker.delivery_stop', { Current = currentStop, Max = maxStops }),
        description = Lang.t('marker.delivery_stop_description'),
        icon = Config.DeliveryMarkerIcon or 'map-pin-check',
        color = Config.DeliveryMarkerColor,
        markerType = 'Store',
    })
end

local function clearRouteIndicator()
    if CurrentLocation.TimerId then
        Timer.ClearInterval(CurrentLocation.TimerId)
    end

    if CurrentLocation.Cone and CurrentLocation.Cone:IsValid() then
        DeleteEntity(CurrentLocation.Cone)
    end

    CurrentLocation.TimerId = nil
    CurrentLocation.Cone = nil
    CurrentLocation.Coords = nil
    removeMarker(deliveryMarker)
    deliveryMarker = nil
    exports['qb-core']:HideText()
end

local function clearVehicleTarget()
    if currentVehicleTarget then
        exports['qb-target']:RemoveTargetEntity(currentVehicleTarget)
        currentVehicleTarget = nil
    end
end

function onShutdown()
    clearRouteIndicator()
    clearVehicleTarget()
    clearRegisteredTargets()
    clearDepotMarkers()
end

local function setupPeds()
    TriggerCallback('getPeds', function(jobPeds)
        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc or jobPeds[i].Ped
            local depot = jobPeds[i].depot or jobPeds[i].Index

            addTargetEntity(ped, {
                {
                    label = Lang.t('info.start_delivering'),
                    icon = 'boxes-stacked',
                    job = Config.Job,
                    type = 'server',
                    event = 'qb-deliveryjob:server:takeVehicle',
                    depot = depot,
                },
                {
                    label = Lang.t('info.finish_delivering'),
                    icon = 'circle-check',
                    job = Config.Job,
                    type = 'client',
                    event = 'qb-deliveryjob:client:finishDelivering',
                },
            })
        end
    end)
end

local function deliverPackage()
    if not CurrentLocation.Coords then
        return
    end

    local Pawn = GetPlayerPawn(HPlayer)
    local PawnCoords = GetEntityCoords(Pawn)
    if PawnCoords and PawnCoords:Dist(CurrentLocation.Coords) > 1000 then
        exports['qb-core']:Notify(Lang.t('error.too_far'), 'error')
        return
    end
    TriggerCallback('deliverPackage', function(success)
        if not success then
            return
        end
        HoldingPackage = false
    end, CurrentLocation.jobId)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    setupPeds()
    createDepotMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    HoldingPackage = false
    CurrentLocation.jobId = nil
    clearRouteIndicator()
    clearRegisteredTargets()
    clearDepotMarkers()
end)

RegisterClientEvent('qb-deliveryjob:client:pickupBox', function(targetData)
    CurrentLocation.jobId = targetData.jobId
    TriggerCallback('server.pickupBox', function(success)
        if not success then
            return
        end
        exports['qb-core']:DrawText(Lang.t('info.deliver_package'))
        HoldingPackage = true
    end, targetData.jobId)
end)

RegisterClientEvent('qb-deliveryjob:client:setupVehicleTarget', function(Vehicle, Job)
    local entity = Vehicle and (Vehicle.Object or Vehicle)
    clearVehicleTarget()
    currentVehicleTarget = entity

    addTargetEntity(entity, {
        {
            label = Lang.t('info.pickup_box'),
            icon = 'boxes-stacked',
            job = Config.Job,
            type = 'client',
            event = 'qb-deliveryjob:client:pickupBox',
            jobId = Job,
        },
    }, VEHICLE_TARGET_DISTANCE)
end)

RegisterClientEvent('qb-deliveryjob:client:setCurrentLocation', function(Location, Vehicle, CurrentStop, MaxStops)
    clearRouteIndicator()

    if not Location then
        clearVehicleTarget()
        return
    end

    local FindRotation = UE.UKismetMathLibrary.FindLookAtRotation
    local Pawn = GetPlayerPawn(HPlayer)
    local Cone = StaticMesh(GetEntityCoords(Pawn), Rotator(), '/QuietRuntimeEditor/UserContent/StaticMeshes/Primitives/SM_Cone.SM_Cone')
    CurrentLocation.Cone = Cone
    AttachActorToActor(Cone.Object, Pawn, Vector(0, 0, 0), nil, '', {
        Location = AttachmentRule.KeepWorld,
        Rotation = AttachmentRule.KeepRelative,
    }, true)
    Cone:SetActorScale3D(Vector(0.2, 0.2, 0.2))
    CurrentLocation.TimerId = Timer.SetInterval(function()
        local targetRotation = FindRotation(GetEntityCoords(Pawn), Location)
        targetRotation.Roll = 0
        targetRotation.Pitch = 90
        targetRotation.Yaw = targetRotation.Yaw + 180
        SetEntityRotation(Cone, targetRotation)
    end, 50)
    CurrentLocation.Coords = Location
    deliveryMarker = createDeliveryMarker(Location, CurrentStop, MaxStops)

    exports['qb-core']:DrawText(Lang.t('status.location_info', { Current = CurrentStop, Max = MaxStops }))
end)

RegisterClientEvent('qb-deliveryjob:client:finishDelivering', function()
    TriggerCallback('finishDelivering', function(success)
        if not success then
            return
        end
        HoldingPackage = false
        CurrentLocation.jobId = nil
        clearRouteIndicator()
        clearVehicleTarget()
    end, CurrentLocation.jobId)
end)

Input.BindKey('E', function()
    if HoldingPackage then
        deliverPackage()
    end
end)
