local Lang = require('locales/en')
local TARGET_DISTANCE = Config.TargetDistance or 1000
local depotMarkers = {}
local registeredTargets = {}
local pickupMarker = nil
local dropoffMarker = nil
local routeZone = nil
local currentPickupStopIndex = nil
local currentDropoffStopIndex = nil
local inPickupZone = false
local inDropoffZone = false

local function clearRouteZone()
    if routeZone then
        DeleteEntity(routeZone)
        routeZone = nil
    end
    currentPickupStopIndex = nil
    currentDropoffStopIndex = nil
    inPickupZone = false
    inDropoffZone = false
    exports['qb-core']:HideText()
end

local function addMapMarker(coords, marker)
    local markerId = exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'bus',
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
end

local function createDepotMarkers()
    for _, depot in ipairs(Config.Locations.Depots) do
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

local function createRouteMarker(coords, marker)
    return exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'bus',
        color = marker.blipColor,
        markerType = marker.markerType or 'Store',
    })
end

local function clearRouteMarkers()
    removeMarker(pickupMarker)
    removeMarker(dropoffMarker)
    pickupMarker = nil
    dropoffMarker = nil
end

local function setupPeds()
    TriggerCallback('getPeds', function(jobPeds)
        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc
            local options = {
                {
                    type = 'server',
                    event = 'QBCore:ToggleDuty',
                    label = Lang.t('target.toggle_duty'),
                    icon = 'clipboard',
                    job = Config.Job,
                },
                {
                    type = 'server',
                    event = 'qb-busjob:server:takeVehicle',
                    label = Lang.t('target.take_vehicle'),
                    icon = 'bus',
                    job = Config.Job,
                    depot = jobPeds[i].depot,
                },
                {
                    type = 'server',
                    event = 'qb-busjob:server:finishWork',
                    label = Lang.t('target.finish_work'),
                    icon = 'circle-check',
                    job = Config.Job,
                },
            }
            addTargetEntity(ped, options)
        end
    end)
end

local function createRouteZone(coords, stopIndex, action)
    clearRouteZone()

    routeZone = Trigger(Vector(coords.X, coords.Y, coords.Z), Rotator(), Vector(Config.StopRadius), TriggerType.Sphere, true, function()
        if action == 'pickup' then
            inPickupZone = true
            currentPickupStopIndex = stopIndex
            exports['qb-core']:DrawText(Lang.t('info.board_passenger'), 'left')
        else
            inDropoffZone = true
            currentDropoffStopIndex = stopIndex
            exports['qb-core']:DrawText(Lang.t('info.drop_off_passenger'), 'left')
        end
    end)

    local shape = routeZone:GetComponentByClass(UE.UShapeComponent)
    shape.OnComponentEndOverlap:Add(HWorld, function(_)
        if action == 'pickup' then
            inPickupZone = false
            currentPickupStopIndex = nil
        else
            inDropoffZone = false
            currentDropoffStopIndex = nil
        end
        exports['qb-core']:HideText()
    end)
end

function onShutdown()
    clearRouteZone()
    clearRegisteredTargets()
    clearRouteMarkers()
    clearDepotMarkers()
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    setupPeds()
    createDepotMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearRouteZone()
    clearRegisteredTargets()
    clearRouteMarkers()
    clearDepotMarkers()
end)

RegisterClientEvent('qb-busjob:client:pickupSpot', function(coords, stopIndex)
    clearRouteMarkers()
    pickupMarker = createRouteMarker(Vector(coords.X, coords.Y, coords.Z), {
        label = Lang.t('marker.pickup'),
        description = Lang.t('marker.pickup_description'),
        blipIcon = 'user-round',
        blipColor = Config.PickupMarkerColor,
    })

    createRouteZone(coords, stopIndex, 'pickup')
end)

RegisterClientEvent('qb-busjob:client:dropoffSpot', function(coords, stopIndex)
    removeMarker(pickupMarker)
    removeMarker(dropoffMarker)
    pickupMarker = nil
    dropoffMarker = createRouteMarker(Vector(coords.X, coords.Y, coords.Z), {
        label = Lang.t('marker.dropoff'),
        description = Lang.t('marker.dropoff_description'),
        blipIcon = 'map-pin-check',
        blipColor = Config.DropoffMarkerColor,
    })

    createRouteZone(coords, stopIndex, 'dropoff')
end)

RegisterClientEvent('qb-busjob:client:jobComplete', function(payout)
    clearRouteZone()
    clearRouteMarkers()
    exports['qb-core']:Notify(Lang.t('success.dropped_off', { amount = payout }), 'success')
end)

RegisterClientEvent('qb-busjob:client:routeEnded', function()
    clearRouteZone()
    clearRouteMarkers()
end)

Input.BindKey('E', function()
    if inPickupZone and currentPickupStopIndex then
        TriggerServerEvent('qb-busjob:server:pickupNPC', currentPickupStopIndex)
    elseif inDropoffZone and currentDropoffStopIndex then
        TriggerServerEvent('qb-busjob:server:dropoffNPC', currentDropoffStopIndex)
    end
end)
