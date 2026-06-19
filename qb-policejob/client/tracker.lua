local Lang = require('locales/en')

local function getPlayerIdFromEntity(entity)
    if not entity or not entity.PlayerState then
        return nil
    end
    return entity.PlayerState:GetPlayerId()
end

local function getClosestPlayerId(maxDistance)
    local pawn = GetPlayerPawn()
    if not pawn then
        return nil, -1
    end

    local pos = GetEntityCoords(pawn)
    local closestPlayerId, closestDistance = nil, maxDistance or 250.0
    for _, otherPawn in pairs(GetAllPawns()) do
        if otherPawn ~= pawn and otherPawn.PlayerState and otherPawn:IsPlayerControlled() then
            local distance = GetDistanceBetweenCoords(pos, GetEntityCoords(otherPawn))
            if distance < closestDistance then
                closestPlayerId = otherPawn.PlayerState:GetPlayerId()
                closestDistance = distance
            end
        end
    end

    return closestPlayerId, closestPlayerId and closestDistance or -1
end

local function getTargetPlayerId(data)
    local entityPlayerId = getPlayerIdFromEntity(data and data.entity)
    if entityPlayerId then
        return entityPlayerId, 0.0
    end
    return getClosestPlayerId(250.0)
end

RegisterClientEvent('qb-policejob:client:CheckDistance', function(data)
    local playerId, distance = getTargetPlayerId(data)
    if playerId and distance < 250.0 then
        TriggerServerEvent('qb-policejob:server:SetTracker', playerId)
    else
        exports['qb-core']:Notify(Lang.t('error.none_nearby'), 'error')
    end
end)

RegisterClientEvent('qb-policejob:client:SetTracker', function(_)
    -- TODO(helix): Clothing/accessory changes for tracker anklets are not available yet.
end)

RegisterClientEvent('qb-policejob:client:SendTrackerLocation', function(requestId)
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end
    TriggerServerEvent('qb-policejob:server:SendTrackerLocation', GetEntityCoords(pawn), requestId)
end)

RegisterClientEvent('qb-policejob:client:TrackerMessage', function(msg, coords)
    exports['qb-core']:Notify(msg, 'police')

    if not coords or not exports['qb-hud'] then
        return
    end
    local markerId = exports['qb-hud']:AddMarker(Vector(coords.X or coords.x, coords.Y or coords.y, coords.Z or coords.z), {
        title = Lang.t('info.ankle_location'),
        description = msg,
        icon = 'map-pin',
        markerType = 'Alert',
    })

    if markerId then
        Timer.SetTimeout(function()
            exports['qb-hud']:RemoveMarker(markerId)
        end, 180000)
    end
end)
