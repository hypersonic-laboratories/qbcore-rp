local pendingCalls = {}
local activeCalls  = {}

local function genChannel()
    return math.random(50000, 99999)
end

RegisterServerEvent('qb-phone:server:dial', function(source, targetNumber)
    local caller = exports['qb-core']:GetPlayer(source)
    if not caller then return end

    local target = exports['qb-core']:GetPlayerByPhone(targetNumber)
    if not target then
        TriggerClientEvent(caller.PlayerData.source, 'qb-phone:client:callFailed', 'unavailable')
        return
    end

    local callerIntSrc = caller.PlayerData.source
    local targetIntSrc = target.PlayerData.source

    if targetIntSrc == callerIntSrc then return end

    if pendingCalls[targetIntSrc] then
        TriggerClientEvent(callerIntSrc, 'qb-phone:client:callFailed', 'busy')
        return
    end

    local callerName           = caller.PlayerData.charinfo.firstname .. ' ' .. caller.PlayerData.charinfo.lastname
    local callerNumber         = caller.PlayerData.charinfo.phone
    local targetName           = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname

    pendingCalls[targetIntSrc] = {
        callerSrc    = source,
        callerIntSrc = callerIntSrc,
        channel      = genChannel(),
        callerName   = callerName,
        callerNumber = callerNumber,
    }

    TriggerClientEvent(targetIntSrc, 'qb-phone:client:incomingCall', callerName, callerNumber)
    TriggerClientEvent(callerIntSrc, 'qb-phone:client:callRinging', targetName, targetNumber)
end)

RegisterServerEvent('qb-phone:server:accept', function(source)
    local player = exports['qb-core']:GetPlayer(source)
    if not player then return end

    local targetIntSrc = player.PlayerData.source
    local pending = pendingCalls[targetIntSrc]
    if not pending then return end

    pendingCalls[targetIntSrc] = nil

    activeCalls[pending.channel] = {
        callerSrc    = pending.callerSrc,
        targetSrc    = source,
        callerIntSrc = pending.callerIntSrc,
        targetIntSrc = targetIntSrc,
    }

    pending.callerSrc:JoinVoiceChannel(pending.channel)
    source:JoinVoiceChannel(pending.channel)

    TriggerClientEvent(pending.callerIntSrc, 'qb-phone:client:callStarted', pending.channel)
    TriggerClientEvent(targetIntSrc, 'qb-phone:client:callStarted', pending.channel)
end)

---@diagnostic disable: undefined-global

RegisterServerEvent('qb-phone:server:hangup', function(source)
    local player = exports['qb-core']:GetPlayer(source)
    if not player then return end

    local intSrc = player.PlayerData.source

    for channel, call in pairs(activeCalls) do
        if call.callerIntSrc == intSrc or call.targetIntSrc == intSrc then
            activeCalls[channel] = nil
            call.callerSrc:LeaveVoiceChannel(channel)
            call.targetSrc:LeaveVoiceChannel(channel)
            TriggerClientEvent(call.callerIntSrc, 'qb-phone:client:callEnded')
            TriggerClientEvent(call.targetIntSrc, 'qb-phone:client:callEnded')
            return
        end
    end

    for targetSrc, pending in pairs(pendingCalls) do
        if pending.callerIntSrc == intSrc or targetSrc == intSrc then
            pendingCalls[targetSrc] = nil
            TriggerClientEvent(pending.callerIntSrc, 'qb-phone:client:callEnded')
            TriggerClientEvent(targetSrc, 'qb-phone:client:callEnded')
            return
        end
    end
end)

-- Data Loading

RegisterServerEvent('qb-phone:server:givePhone', function(source)
    local ped = GetPlayerPawn(source)
    HInventory.GiveAndEquipItemByName(ped, 'ID_Misc_Phone')
end)

RegisterServerEvent('qb-phone:server:takePhone', function(source)
    local ped = GetPlayerPawn(source)
    HInventory.RemoveItemByName(ped, 'ID_Misc_Phone')
end)

RegisterServerEvent('qb-phone:server:loadPlayerData', function(source)
    local player = exports['qb-core']:GetPlayer(source)
    if not player then return end
    -- TODO: query DB for this player's data and send each payload
    -- TriggerClientEvent(source, 'qb-phone:client:contactsLoaded', json.encode(contacts))
    -- TriggerClientEvent(source, 'qb-phone:client:photosLoaded',   json.encode(photos))
    -- TriggerClientEvent(source, 'qb-phone:client:calendarEventsLoaded', json.encode(events))
    -- TriggerClientEvent(source, 'qb-phone:client:feedLoaded',     json.encode(posts))
end)

-- Messages

RegisterServerEvent('qb-phone:server:sendMessage', function(source, targetNumber, text)
    local sender = exports['qb-core']:GetPlayer(source)
    if not sender then return end

    local target       = exports['qb-core']:GetPlayerByPhone(targetNumber)

    local senderName   = sender.PlayerData.charinfo.firstname .. ' ' .. sender.PlayerData.charinfo.lastname
    local senderNumber = sender.PlayerData.charinfo.phone
    local time         = os.date('%H:%M')

    -- TODO: persist message to DB

    if target then
        TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:messageReceived', senderName, senderNumber, text, time)
    end
end)

-- Contacts

RegisterServerEvent('qb-phone:server:saveContact', function(_, _, _, _)
    -- TODO: upsert contact row for source player; args: source, name, number, image
end)

RegisterServerEvent('qb-phone:server:deleteContact', function(_, _)
    -- TODO: delete contact row for source player; args: source, number
end)

-- H (Social Feed)

RegisterServerEvent('qb-phone:server:createPost', function(source, content, image)
    local player = exports['qb-core']:GetPlayer(source)
    if not player then return end

    local authorName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local time       = os.date('%H:%M')

    -- TODO: persist post to DB and replace id with DB-assigned value
    local post       = {
        id       = os.time(),
        author   = authorName,
        handle   = '@' .. string.lower(string.gsub(authorName, '%s+', '')),
        content  = content,
        image    = image or '',
        time     = time,
        likes    = 0,
        liked    = false,
        reposts  = 0,
        reposted = false,
        comments = {},
    }

    TriggerClientEvent(-1, 'qb-phone:client:postReceived', json.encode(post))
end)

RegisterServerEvent('qb-phone:server:deletePost', function(_, postId)
    -- TODO: verify source player owns the post
    -- TODO: delete post and its comments from DB
    TriggerClientEvent(-1, 'qb-phone:client:postDeleted', postId)
end)

RegisterServerEvent('qb-phone:server:likePost', function(_, postId, _)
    -- TODO: upsert/delete like row for source player; args: source, postId, liked
    local likeCount = 0 -- TODO: fetch updated count from DB
    TriggerClientEvent(-1, 'qb-phone:client:postLikeUpdated', postId, likeCount)
end)

RegisterServerEvent('qb-phone:server:repostPost', function(_, postId, _)
    -- TODO: upsert/delete repost row for source player; args: source, postId, reposted
    local repostCount = 0 -- TODO: fetch updated count from DB
    TriggerClientEvent(-1, 'qb-phone:client:postRepostUpdated', postId, repostCount)
end)

RegisterServerEvent('qb-phone:server:followUser', function(source, _, following)
    local follower = exports['qb-core']:GetPlayer(source)
    if not follower then return end

    -- TODO: upsert/delete follow row; args: source, handle, following
    -- TODO: if following, look up target player by handle and send qb-phone:client:newFollower
    _ = following
end)

RegisterServerEvent('qb-phone:server:addComment', function(source, postId, text)
    local commenter = exports['qb-core']:GetPlayer(source)
    if not commenter then return end

    local authorName = commenter.PlayerData.charinfo.firstname .. ' ' .. commenter.PlayerData.charinfo.lastname
    local time       = os.date('%H:%M')

    -- TODO: persist comment to DB and replace id with DB-assigned value
    local comment    = {
        id     = os.time(),
        author = authorName,
        handle = '@' .. string.lower(string.gsub(authorName, '%s+', '')),
        text   = text,
        time   = time,
    }

    TriggerClientEvent(-1, 'qb-phone:client:commentAdded', postId, json.encode(comment))
end)

-- Calendar

RegisterServerEvent('qb-phone:server:saveCalendarEvent', function(_, _, _, _, _, _)
    -- TODO: upsert calendar event row for source player; args: source, month, day, title, time, detail
end)

-- Photos

RegisterServerEvent('qb-phone:server:deletePhoto', function(_, _)
    -- TODO: delete photo record from DB and storage; args: source, photoId
end)
