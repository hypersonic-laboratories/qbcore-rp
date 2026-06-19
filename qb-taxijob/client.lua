local Lang = require('locales/en')
local my_webui = WebUI('qb-taxijob', 'qb-taxijob/html/index.html')
local TARGET_DISTANCE = Config.TargetDistance or 1000
local meterOpen = false
local depotMarkers = {}
local registeredTargets = {}
local pickupMarker = nil
local dropoffMarker = nil
local meterActive = false
local inPickupZone = false
local inDropoffZone = false
local currentPickupBenchIndex = nil
local currentDropoffBenchIndex = nil
local pickupZone = nil
local dropoffZone = nil
local distanceUU = 0.0
local lastVehiclePos = nil
local CM_PER_MILE = 160934
local distance_timer = nil
local meterData = {
    fareAmount = Config.Rate,
    currentFare = 0,
    distanceTraveled = 0,
}

local function addMapMarker(coords, marker)
    local markerId = exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'taxi',
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

-- UI Events

my_webui:RegisterEventHandler('enableMeter', function(bool)
    meterActive = bool
    if bool then
        distanceUU = 0.0
        lastVehiclePos = nil
        meterData.distanceTraveled = 0
        meterData.currentFare = 0
        if distance_timer then
            Timer.ClearInterval(distance_timer)
            distance_timer = nil
        end
        distance_timer = Timer.SetInterval(function()
            UpdateTaxiDistance()
        end, 100)
    else
        if distance_timer then
            Timer.ClearInterval(distance_timer)
            distance_timer = nil
        end
    end
end)

-- Functions

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

local function createFareMarker(coords, marker)
    return exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'taxi',
        color = marker.blipColor,
        markerType = marker.markerType or 'Store',
    })
end

local function clearFareMarkers()
    removeMarker(pickupMarker)
    removeMarker(dropoffMarker)
    pickupMarker = nil
    dropoffMarker = nil
end

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
    if distance_timer then
        Timer.ClearInterval(distance_timer)
        distance_timer = nil
    end
    clearRegisteredTargets()
    clearFareMarkers()
    clearDepotMarkers()
end

-- Events

function UpdateTaxiDistance()
    if not meterActive then
        return
    end

    local vehicle = GetVehiclePedIsIn(GetPlayerPawn())
    if not vehicle then
        lastVehiclePos = nil
        return
    end
    local pos = GetEntityCoords(vehicle)
    if lastVehiclePos then
        local delta = GetDistanceBetweenCoords(pos, lastVehiclePos)
        distanceUU = distanceUU + delta
        local miles = distanceUU / CM_PER_MILE
        meterData.distanceTraveled = miles
        meterData.currentFare = math.floor(meterData.distanceTraveled * meterData.fareAmount)
        my_webui:SendEvent('updateMeter', {
            meterData = meterData,
        })
    end
    lastVehiclePos = pos
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
                    event = 'qb-taxijob:server:takeVehicle',
                    label = Lang.t('target.take_vehicle'),
                    icon = 'truck-field',
                    job = Config.Job,
                    depot = jobPeds[i].depot,
                },
                {
                    event = 'qb-taxijob:client:finishWork',
                    label = Lang.t('target.finish_work'),
                    icon = 'circle-check',
                    job = Config.Job,
                },
            }
            addTargetEntity(ped, options)
        end
    end)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    setupPeds()
    createDepotMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearRegisteredTargets()
    clearFareMarkers()
    clearDepotMarkers()
end)

RegisterClientEvent('qb-taxijob:client:finishWork', function()
    clearFareMarkers()
    if meterOpen then
        my_webui:SendEvent('openMeter', { toggle = false })
        meterOpen = false
    end
    if meterActive then
        meterActive = false
        if distance_timer then
            Timer.ClearInterval(distance_timer)
            distance_timer = nil
        end
    end
    TriggerServerEvent('qb-taxijob:server:finishWork')
end)

RegisterClientEvent('qb-taxijob:client:toggleMeter', function()
    local vehicle = GetVehiclePedIsIn(GetPlayerPawn())
    if not vehicle then
        return
    end
    if not meterOpen then
        my_webui:SendEvent('openMeter', { toggle = true, meterData = meterData })
        meterOpen = true
    else
        my_webui:SendEvent('openMeter', { toggle = false })
        meterOpen = false
    end
end)

RegisterClientEvent('qb-taxijob:client:enableMeter', function()
    local vehicle = GetVehiclePedIsIn(GetPlayerPawn())
    if not vehicle then
        return
    end
    if meterOpen then
        my_webui:SendEvent('toggleMeter')
    end
end)

RegisterClientEvent('qb-taxijob:client:pickupSpot', function(coords, benchIndex)
    clearFareMarkers()
    pickupMarker = createFareMarker(Vector(coords.X, coords.Y, coords.Z), {
        label = Lang.t('marker.pickup'),
        description = Lang.t('marker.pickup_description'),
        blipIcon = 'user-round',
        blipColor = Config.PickupMarkerColor,
    })

    coords.X = coords.X + 300
    if pickupZone then
        DeleteEntity(pickupZone)
    end

    pickupZone = Trigger(Vector(coords.X, coords.Y, coords.Z), Rotator(), Vector(100), TriggerType.Sphere, true, function()
        inPickupZone = true
        currentPickupBenchIndex = benchIndex
        exports['qb-core']:DrawText('[E] - Pickup NPC', 'left')
    end)

    local Shape = pickupZone:GetComponentByClass(UE.UShapeComponent)
    Shape.OnComponentEndOverlap:Add(HWorld, function(_)
        inPickupZone = false
        currentPickupBenchIndex = nil
        exports['qb-core']:HideText()
    end)
end)

RegisterClientEvent('qb-taxijob:client:dropoffSpot', function(coords, benchIndex)
    removeMarker(pickupMarker)
    removeMarker(dropoffMarker)
    pickupMarker = nil
    dropoffMarker = createFareMarker(Vector(coords.X, coords.Y, coords.Z), {
        label = Lang.t('marker.dropoff'),
        description = Lang.t('marker.dropoff_description'),
        blipIcon = 'map-pin-check',
        blipColor = Config.DropoffMarkerColor,
    })

    if pickupZone then
        DeleteEntity(pickupZone)
        pickupZone = nil
    end
    inPickupZone = false
    currentPickupBenchIndex = nil
    exports['qb-core']:HideText()
    dropoffZone = Trigger(Vector(coords.X, coords.Y, coords.Z), Rotator(), Vector(100), TriggerType.Sphere, true, function()
        inDropoffZone = true
        currentDropoffBenchIndex = benchIndex
        exports['qb-core']:DrawText('[E] - Drop Off NPC', 'left')
    end)

    local Shape = dropoffZone:GetComponentByClass(UE.UShapeComponent)
    Shape.OnComponentEndOverlap:Add(HWorld, function(_)
        inDropoffZone = false
        currentDropoffBenchIndex = nil
        exports['qb-core']:HideText()
    end)
end)

RegisterClientEvent('qb-taxijob:client:jobComplete', function(payout)
    clearFareMarkers()

    if dropoffZone then
        DeleteEntity(dropoffZone)
        dropoffZone = nil
    end
    inDropoffZone = false
    currentDropoffBenchIndex = nil
    exports['qb-core']:HideText()

    exports['qb-core']:Notify('Job complete! You earned $' .. payout, 'success')
end)

-- Input

Input.BindKey('E', function()
    if inPickupZone and currentPickupBenchIndex then
        if not meterOpen then
            my_webui:SendEvent('openMeter', { toggle = true, meterData = meterData })
            meterOpen = true
        end
        my_webui:SendEvent('toggleMeter')
        TriggerServerEvent('qb-taxijob:server:pickupNPC', currentPickupBenchIndex)
    elseif inDropoffZone and currentDropoffBenchIndex then
        if meterActive then
            meterActive = false
            if distance_timer then
                Timer.ClearInterval(distance_timer)
                distance_timer = nil
            end
            my_webui:SendEvent('toggleMeter')
            my_webui:SendEvent('resetMeter')
        end
        TriggerServerEvent('qb-taxijob:server:dropoffNPC', currentDropoffBenchIndex, meterData.currentFare)
    end
end)
