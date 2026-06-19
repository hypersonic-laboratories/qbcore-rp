local Lang = require('locales/en')
local TARGET_DISTANCE = Config.TargetDistance or 1000
local garbageMarkers = {}
local registeredTargets = {}
local registeredModels = {}

local function addMapMarker(coords, marker)
    local markerId = exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'waste-basket',
        color = marker.blipColor,
        markerType = marker.markerType or 'Store',
    })

    if markerId then
        garbageMarkers[#garbageMarkers + 1] = markerId
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

local function addTargetModel(modelName, options, distance)
    exports['qb-target']:AddTargetModel(modelName, {
        options = options,
        distance = distance or TARGET_DISTANCE,
    })
    registeredModels[#registeredModels + 1] = modelName
end

local function clearRegisteredTargets()
    for _, entity in ipairs(registeredTargets) do
        exports['qb-target']:RemoveTargetEntity(entity)
    end
    registeredTargets = {}

    for _, modelName in ipairs(registeredModels) do
        exports['qb-target']:RemoveTargetModel(modelName)
    end
    registeredModels = {}
end

local function registerModelTargets()
    addTargetModel('SM_Dumpster', {
        {
            icon = 'box',
            label = Lang.t('target.collect_garbage'),
            type = 'server',
            event = 'qb-garbagejob:server:grabBag',
            job = Config.Job,
        },
    })

    addTargetModel('GarbageTruck', {
        {
            label = Lang.t('target.deposit_garbage'),
            icon = 'truck-ramp-box',
            type = 'server',
            event = 'qb-garbagejob:server:loadBag',
            job = Config.Job,
        },
    })
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
                    event = 'qb-garbagejob:server:startJob',
                    label = Lang.t('target.start_job'),
                    icon = 'truck-field',
                    job = Config.Job,
                    depot = jobPeds[i].depot,
                },
                {
                    type = 'server',
                    event = 'qb-garbagejob:server:completeJob',
                    label = Lang.t('target.complete_route'),
                    icon = 'circle-check',
                    job = Config.Job,
                },
            }
            addTargetEntity(ped, options)
        end
    end)
end

local function createGarbageMarkers()
    for _, depot in ipairs(Config.Locations.Depots) do
        if depot.showBlip then
            addMapMarker(depot.pedSpawn, depot)
        end
    end
end

local function clearGarbageMarkers()
    for _, id in ipairs(garbageMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    garbageMarkers = {}
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    registerModelTargets()
    setupPeds()
    createGarbageMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearRegisteredTargets()
    clearGarbageMarkers()
end)

function onShutdown()
    clearRegisteredTargets()
    clearGarbageMarkers()
end

RegisterClientEvent('qb-garbagejob:client:removeTargets', function(vehicle)
    if vehicle then
        exports['qb-target']:RemoveTargetEntity(vehicle)
    end
end)
