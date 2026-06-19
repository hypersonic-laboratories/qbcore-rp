local Lang = require('locales/en')
local depotMarkers = {}
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

local function createDepotMarkers()
    for _, depot in ipairs(Config.Locations.Depots) do
        if depot.showBlip then
            local markerId = exports['qb-hud']:AddMarker(depot.pedSpawn.coords, {
                title = depot.label,
                description = depot.description or '',
                icon = depot.blipIcon or 'bus',
                color = depot.blipColor,
                markerType = 'Store',
            })
            if markerId then
                depotMarkers[#depotMarkers + 1] = markerId
            end
        end
    end
end

local function clearDepotMarkers()
    for _, id in ipairs(depotMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    depotMarkers = {}
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
            exports['qb-target']:AddTargetEntity(ped, { options = options, distance = 1000 })
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
    clearDepotMarkers()
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    setupPeds()
    createDepotMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearRouteZone()
    clearDepotMarkers()
end)

RegisterClientEvent('qb-busjob:client:pickupSpot', function(coords, stopIndex)
    createRouteZone(coords, stopIndex, 'pickup')
end)

RegisterClientEvent('qb-busjob:client:dropoffSpot', function(coords, stopIndex)
    createRouteZone(coords, stopIndex, 'dropoff')
end)

RegisterClientEvent('qb-busjob:client:jobComplete', function(payout)
    clearRouteZone()
    exports['qb-core']:Notify(Lang.t('success.dropped_off', { amount = payout }), 'success')
end)

RegisterClientEvent('qb-busjob:client:routeEnded', function()
    clearRouteZone()
end)

Input.BindKey('E', function()
    if inPickupZone and currentPickupStopIndex then
        TriggerServerEvent('qb-busjob:server:pickupNPC', currentPickupStopIndex)
    elseif inDropoffZone and currentDropoffStopIndex then
        TriggerServerEvent('qb-busjob:server:dropoffNPC', currentDropoffStopIndex)
    end
end)
