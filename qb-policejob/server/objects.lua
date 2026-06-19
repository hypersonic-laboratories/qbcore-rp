local Objects = {}

local function notify(source, text, notifyType)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType)
end

local function isLeoOnDuty(Player)
    return Player and Player.PlayerData.job and Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty
end

local function CreateObjectId()
    local objectId = 'police-object-' .. GenerateId(8, 'mixed')
    while Objects[objectId] do
        objectId = 'police-object-' .. GenerateId(8, 'mixed')
    end
    return objectId
end

RegisterServerEvent('qb-policejob:server:spawnObject', function(source, objectType)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeoOnDuty(Player) then
        return
    end

    local objectConfig = Config.Objects[objectType]
    if not objectConfig then
        return
    end

    if objectConfig.model == '' then
        -- TODO(helix): Fill Config.Objects[objectType].model with a Helix mesh path.
        notify(source, ('TODO: Police object "%s" has no Helix mesh configured yet.'):format(objectType), 'primary')
        return
    end

    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end

    local coords = GetEntityCoords(pawn)
    local rotation = GetEntityRotation(pawn)
    local forward = pawn:GetActorForwardVector()
    local spawnX = coords.X + forward.X * 150
    local spawnY = coords.Y + forward.Y * 150
    local hit = Trace:LineSingle(Vector(spawnX, spawnY, coords.Z + 200), Vector(spawnX, spawnY, coords.Z - 500))
    local spawnZ = (hit and hit.ImpactPoint) and hit.ImpactPoint.Z or (coords.Z - 88)
    local spawnCoords = Vector(spawnX, spawnY, spawnZ)
    local spawnRotation = Rotator(0, rotation.Yaw, 0)

    local object = StaticMesh(spawnCoords, spawnRotation, objectConfig.model, CollisionType.Normal, objectConfig.freeze ~= false)
    local actor = object and object.Object or object
    if not actor then
        return
    end

    local objectId = CreateObjectId()
    Objects[objectId] = {
        type = objectType,
        object = actor,
    }
    Objects[objectId].coords = spawnCoords

    BroadcastEvent('qb-policejob:client:spawnObject', objectId, objectType, actor)
end)

RegisterServerEvent('qb-policejob:server:deleteObject', function(source, objectId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeoOnDuty(Player) then
        return
    end

    if type(objectId) == 'table' then
        objectId = objectId.objectId
    end
    if not objectId then
        notify(source, 'Target a placed police object to remove it.', 'primary')
        return
    end

    local objectData = Objects[objectId]
    if objectData and objectData.object then
        DestroyActor(objectData.object)
    end
    Objects[objectId] = nil
    BroadcastEvent('qb-policejob:client:removeObject', objectId)
end)

RegisterServerEvent('qb-policejob:server:SyncSpikes', function(_, spikes)
    BroadcastEvent('qb-policejob:client:SyncSpikes', spikes)
end)
