local activePairs = {} -- netId -> partner netId
local pendingRequests = {} -- target netId -> { requester = netId, emote = emoteId }

local function notify(target, text, notifyType)
    TriggerClientEvent(target, 'QBCore:Notify', text, notifyType)
end

local function getNetId(source)
    local Player = exports['qb-core']:GetPlayer(source)
    return Player and Player.PlayerData.netId or nil
end

local function getCharacterName(Player)
    local info = Player.PlayerData.charinfo
    if info and info.firstname then
        return info.firstname .. ' ' .. info.lastname
    end
    return Player.PlayerData.name or 'Someone'
end

local function isNear(a, b, maxDistance)
    local pawnA = GetPlayerPawn(a)
    local pawnB = GetPlayerPawn(b)
    if not pawnA or not pawnB then
        return false
    end
    return GetDistanceBetweenCoords(GetEntityCoords(pawnA), GetEntityCoords(pawnB)) <= (maxDistance or Config.PairedRequestDistance)
end

local function findEmote(categoryName, emoteId)
    for i = 1, #Config.Categories do
        local category = Config.Categories[i]
        if category.name == categoryName then
            for j = 1, #category.emotes do
                if category.emotes[j].id == emoteId then
                    return category.emotes[j], category
                end
            end
            return nil
        end
    end
    return nil
end

local function findPairedEmote(emoteId)
    for i = 1, #Config.PairedEmotes do
        if Config.PairedEmotes[i].id == emoteId then
            return Config.PairedEmotes[i]
        end
    end
    return nil
end

local function buildParams(loop, upperBody)
    local params = UE.FHPlayAnimParams()
    params.LoopCount = loop and -1 or 1
    if upperBody then
        params.AnimSlotName = 'UpperBody'
        params.bIgnoreMovementInput = false
    end
    return params
end

-- Stops both sides of a paired emote. Returns true if the player was in one.
local function stopPairFor(netId)
    local partner = activePairs[netId]
    if not partner then
        return false
    end
    activePairs[netId] = nil
    activePairs[partner] = nil

    for _, id in ipairs({ netId, partner }) do
        local pawn = GetPlayerPawn(id)
        if pawn then
            Animation.Stop(pawn)
        end
        TriggerClientEvent(id, 'qb-emotes:client:emoteCleared')
    end
    return true
end

-- Plays one side of a paired emote: intro one-shot chained into the loop, a
-- bare loop, or a plain one-shot when no loop is defined.
local function playPairedSide(netId, pawn, side)
    if side.loop then
        if side.start then
            local partner = activePairs[netId]
            Animation.Play(pawn, side.start, buildParams(false), function()
                if activePairs[netId] ~= partner then
                    return
                end
                local currentPawn = GetPlayerPawn(netId)
                if currentPawn then
                    Animation.Play(currentPawn, side.loop, buildParams(true))
                end
            end)
        else
            Animation.Play(pawn, side.loop, buildParams(true))
        end
    else
        Animation.Play(pawn, side.start, buildParams(false))
    end
end

local function startPairedEmote(attNetId, vicNetId, emote)
    local attPawn = GetPlayerPawn(attNetId)
    local vicPawn = GetPlayerPawn(vicNetId)
    if not attPawn or not vicPawn then
        return
    end

    -- Break any pair either player is already in, and stop any solo emote
    -- still playing (a new custom animation won't start over a running one)
    stopPairFor(attNetId)
    stopPairFor(vicNetId)
    Animation.Stop(attPawn)
    Animation.Stop(vicPawn)

    -- Place the target relative to the requester
    local attCoords = GetEntityCoords(attPawn)
    local attRot = GetEntityRotation(attPawn)
    local offset = attRot:GetForwardVector() * (emote.distance or 80)
    if emote.right and emote.right ~= 0 then
        offset = offset + Rotator(0, attRot.Yaw + 90, 0):GetForwardVector() * emote.right
    end
    SetEntityCoords(vicPawn, attCoords + offset)
    SetEntityHeading(vicPawn, attRot.Yaw + (emote.vicYaw or 180))

    activePairs[attNetId] = vicNetId
    activePairs[vicNetId] = attNetId

    playPairedSide(attNetId, attPawn, emote.att)
    playPairedSide(vicNetId, vicPawn, emote.vic)

    TriggerClientEvent(attNetId, 'qb-emotes:client:pairedStarted', emote.id)
    TriggerClientEvent(vicNetId, 'qb-emotes:client:pairedStarted', emote.id)

    -- One-shot paired emotes clean themselves up
    if not emote.att.loop then
        Timer.SetTimeout(function()
            if activePairs[attNetId] == vicNetId then
                stopPairFor(attNetId)
            end
        end, emote.duration or 6000)
    end
end

-- Events

RegisterServerEvent('qb-emotes:server:play', function(source, categoryName, emoteId)
    local emote, category = findEmote(categoryName, emoteId)
    if not emote or not category then
        return
    end

    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end

    local netId = getNetId(source)
    if netId then
        stopPairFor(netId)
    end

    -- A new custom animation won't start while one is still playing
    Animation.Stop(pawn)
    Animation.Play(pawn, emote.anim, buildParams(not category.oneShot, emote.upperBody))
end)

RegisterServerEvent('qb-emotes:server:stop', function(source)
    local netId = getNetId(source)
    if netId and stopPairFor(netId) then
        return
    end

    local pawn = GetPlayerPawn(source)
    if pawn then
        Animation.Stop(pawn)
    end
end)

RegisterServerEvent('qb-emotes:server:pairedRequest', function(source, targetId, emoteId)
    local emote = findPairedEmote(emoteId)
    if not emote then
        return
    end

    local Requester = exports['qb-core']:GetPlayer(source)
    local Target = exports['qb-core']:GetPlayer(tonumber(targetId))
    if not Requester or not Target then
        return
    end

    local requesterNetId = Requester.PlayerData.netId
    local targetNetId = Target.PlayerData.netId
    if requesterNetId == targetNetId then
        return
    end

    if not isNear(requesterNetId, targetNetId, Config.PairedRequestDistance) then
        notify(source, 'Nobody close enough for a paired emote', 'error')
        return
    end

    pendingRequests[targetNetId] = { requester = requesterNetId, emote = emoteId }
    Timer.SetTimeout(function()
        local pending = pendingRequests[targetNetId]
        if pending and pending.requester == requesterNetId and pending.emote == emoteId then
            pendingRequests[targetNetId] = nil
        end
    end, Config.PairedRequestTimeout)

    TriggerClientEvent(targetNetId, 'qb-emotes:client:pairedRequest', requesterNetId, getCharacterName(Requester), emote.id, emote.label)
    notify(source, 'Emote request sent to the nearest player', 'primary')
end)

RegisterServerEvent('qb-emotes:server:pairedResponse', function(source, requesterId, emoteId, accepted)
    local Target = exports['qb-core']:GetPlayer(source)
    if not Target then
        return
    end

    local targetNetId = Target.PlayerData.netId
    local pending = pendingRequests[targetNetId]
    if not pending or pending.requester ~= tonumber(requesterId) or pending.emote ~= emoteId then
        return
    end
    pendingRequests[targetNetId] = nil

    if not accepted then
        notify(pending.requester, 'Your emote request was declined', 'error')
        return
    end

    if not isNear(pending.requester, targetNetId, Config.PairedRequestDistance) then
        notify(pending.requester, 'You are too far apart now', 'error')
        notify(source, 'You are too far apart now', 'error')
        return
    end

    local emote = findPairedEmote(emoteId)
    if not emote then
        return
    end

    startPairedEmote(pending.requester, targetNetId, emote)
end)
