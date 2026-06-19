local Lang = require('locales/en')

local ObjectList = {}
local SpawnedSpikes = {}

local function removeObjectTarget(objectId)
    local objectData = ObjectList[objectId]
    if objectData and objectData.actor then
        exports['qb-target']:RemoveTargetEntity(objectData.actor)
    end
    ObjectList[objectId] = nil
end

local function registerObjectTarget(objectId, objectType, actor)
    if not actor then
        return
    end

    removeObjectTarget(objectId)
    ObjectList[objectId] = {
        id = objectId,
        type = objectType,
        actor = actor,
    }

    exports['qb-target']:AddTargetEntity(actor, {
        distance = 200,
        options = {
            {
                label = Lang.t('progressbar.remove_object'),
                icon = 'trash',
                event = 'qb-policejob:server:deleteObject',
                type = 'server',
                objectId = objectId,
                jobType = 'leo',
            },
        },
    })
end

local function spawnPoliceObject(objectType)
    TriggerServerEvent('qb-policejob:server:spawnObject', objectType)
end

RegisterClientEvent('qb-policejob:client:spawnCone', function()
    spawnPoliceObject('cone')
end)

RegisterClientEvent('qb-policejob:client:spawnBarrier', function()
    spawnPoliceObject('barrier')
end)

RegisterClientEvent('qb-policejob:client:spawnRoadSign', function()
    spawnPoliceObject('roadsign')
end)

RegisterClientEvent('qb-policejob:client:spawnTent', function()
    spawnPoliceObject('tent')
end)

RegisterClientEvent('qb-policejob:client:spawnLight', function()
    spawnPoliceObject('light')
end)

RegisterClientEvent('qb-policejob:client:deleteObject', function()
    exports['qb-core']:Notify('Target a placed police object to remove it.', 'primary')
end)

RegisterClientEvent('qb-policejob:client:removeObject', function(objectId)
    removeObjectTarget(objectId)
end)

RegisterClientEvent('qb-policejob:client:spawnObject', function(objectId, objectType, actor)
    local objectConfig = Config.Objects[objectType]
    if not objectConfig then
        return
    end

    if objectConfig.model == '' then
        -- TODO(helix): Fill Config.Objects[objectType].model with a Helix mesh path.
        ObjectList[objectId] = {
            id = objectId,
            type = objectType,
        }
        return
    end

    registerObjectTarget(objectId, objectType, actor)
end)

RegisterClientEvent('qb-policejob:client:SpawnSpikeStrip', function()
    -- TODO(helix): Spike strips need Helix vehicle tire/overlap support.
    exports['qb-core']:Notify('TODO: Spike strips are not implemented in Helix yet.', 'primary')
end)

RegisterClientEvent('qb-policejob:client:SyncSpikes', function(spikes)
    SpawnedSpikes = spikes or {}
end)

local previousOnShutdown = onShutdown

function onShutdown()
    if previousOnShutdown then
        previousOnShutdown()
    end

    for _, objectData in pairs(ObjectList) do
        if objectData.actor then
            exports['qb-target']:RemoveTargetEntity(objectData.actor)
        end
    end
    ObjectList = {}
end
