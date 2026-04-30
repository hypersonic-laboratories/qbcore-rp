---@diagnostic disable: undefined-global

-- ─────────────────────────────────────────────────────────────────────────────
-- Call state  (session-only, cleared on server restart)
-- ─────────────────────────────────────────────────────────────────────────────

local pendingCalls = {}
local activeCalls  = {}

local function genChannel()
    return math.random(50000, 99999)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Data tables  (in-memory, keyed by phone number where applicable)
-- ─────────────────────────────────────────────────────────────────────────────

-- contacts[ownerPhone]        = { {name, number, image}, ... }
local contacts       = {}

-- messages[pairKey]           = { {id, senderNumber, senderName, text, time}, ... }
-- pairKey = two phone numbers sorted and joined with '|'
local messages       = {}

-- callHistory[phone]          = { {name, number, callType, time, missed}, ... }
local callHistory    = {}

-- posts                       = { {id, authorName, authorNumber, handle, content, image, time}, ... }
-- likes[postId]               = { [phone] = true, ... }
-- reposts[postId]             = { [phone] = true, ... }
-- comments[postId]            = { {id, authorName, authorNumber, handle, text, time}, ... }
local posts          = {}
local likes          = {}
local reposts        = {}
local comments       = {}

-- follows[followerPhone]      = { [targetHandle] = true, ... }
local follows        = {}

-- playerProfiles[phone]       = {name, handle, bio}
-- populated whenever a player creates a post; used to build USERS for the feed
local playerProfiles = {}

-- emails[recipientPhone]      = { {id, from, fromNumber, subject, body, snippet, time, read, starred}, ... }
local emails         = {}

-- calendarEvents[ownerPhone]  = { [month] = { [day] = { {id, title, time, detail}, ... } } }
local calendarEvents = {}

-- photos[ownerPhone]          = { {id, url, takenAt}, ... }
local photos         = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function getPlayer(source)
    return exports['qb-core']:GetPlayer(source)
end

local function getPhone(source)
    local p = getPlayer(source)
    return p and p.PlayerData.charinfo.phone or nil
end

local function getFullName(player)
    return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
end

local function makeHandle(fullName)
    return '@' .. string.lower(string.gsub(fullName, '%s+', ''))
end

-- Canonical key for a message thread; always the same regardless of who is sender/receiver
local function pairKey(a, b)
    if a < b then return a .. '|' .. b else return b .. '|' .. a end
end

-- Count entries in a boolean-set table  { [key] = true, ... }
local function countSet(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- Initialise a sub-table if it does not exist yet
local function ensureTable(t, key)
    if not t[key] then t[key] = {} end
    return t[key]
end

-- Monotonic ID counter so every record has a unique numeric id
local _nextId = 1
local function genId()
    local id = _nextId
    _nextId = _nextId + 1
    return id
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Payload builders  (assemble client-facing JSON from the tables above)
-- ─────────────────────────────────────────────────────────────────────────────

-- Build the CONVERSATIONS array the client expects from the flat messages table
local function buildConversations(phone)
    local convMap = {}
    for key, msgs in pairs(messages) do
        local a, b = string.match(key, '^([^|]+)|([^|]+)$')
        if a == phone or b == phone then
            local other = (a == phone) and b or a
            if not convMap[other] then
                -- Prefer saved contact name, fall back to phone number
                local displayName = other
                if contacts[phone] then
                    for _, c in ipairs(contacts[phone]) do
                        if c.number == other then
                            displayName = c.name
                            break
                        end
                    end
                end
                -- Remap sender field to 'me' / 'them' for this player
                local clientMsgs = {}
                for _, m in ipairs(msgs) do
                    table.insert(clientMsgs, {
                        id     = m.id,
                        sender = (m.senderNumber == phone) and 'me' or 'them',
                        text   = m.text,
                        time   = m.time,
                    })
                end
                convMap[other] = {
                    id       = other,
                    name     = displayName,
                    number   = other,
                    image    = '',
                    messages = clientMsgs,
                }
            end
        end
    end
    local convList = {}
    for _, conv in pairs(convMap) do table.insert(convList, conv) end
    return convList
end

-- Build the feed with per-player liked/reposted flags
local function buildFeedForPhone(phone)
    local feed = {}
    for _, post in ipairs(posts) do
        local postLikes      = likes[post.id] or {}
        local postReposts    = reposts[post.id] or {}
        local postComments   = comments[post.id] or {}
        local clientComments = {}
        for _, c in ipairs(postComments) do
            table.insert(clientComments, {
                id     = c.id,
                author = c.authorName,
                handle = c.handle,
                text   = c.text,
                time   = c.time,
            })
        end
        table.insert(feed, {
            id       = post.id,
            author   = post.authorName,
            handle   = post.handle,
            content  = post.content,
            image    = post.image,
            time     = post.time,
            likes    = countSet(postLikes),
            liked    = postLikes[phone] == true,
            reposts  = countSet(postReposts),
            reposted = postReposts[phone] == true,
            comments = clientComments,
        })
    end
    return feed
end

-- Build the USERS map (author profiles) as seen by a specific viewer
local function buildUsersForPhone(viewerPhone)
    local users = {}
    for phone, profile in pairs(playerProfiles) do
        local followerCount = 0
        for _, followSet in pairs(follows) do
            if followSet[profile.handle] then followerCount = followerCount + 1 end
        end
        local followingCount = countSet(follows[phone] or {})
        local isFollowing    = follows[viewerPhone] and follows[viewerPhone][profile.handle] == true or false
        users[profile.name]  = {
            handle          = profile.handle,
            bio             = profile.bio,
            phone           = phone,
            followers       = followerCount,
            following_count = followingCount,
            following       = isFollowing,
        }
    end
    return users
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Call events
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:dial', function(source, targetNumber)
    local caller = getPlayer(source)
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

    local callerName           = getFullName(caller)
    local callerNumber         = caller.PlayerData.charinfo.phone
    local targetName           = getFullName(target)

    pendingCalls[targetIntSrc] = {
        callerSrc    = source,
        callerIntSrc = callerIntSrc,
        channel      = genChannel(),
        callerName   = callerName,
        callerNumber = callerNumber,
        targetNumber = targetNumber,
    }

    TriggerClientEvent(targetIntSrc, 'qb-phone:client:incomingCall', callerName, callerNumber)
    TriggerClientEvent(callerIntSrc, 'qb-phone:client:callRinging', targetName, targetNumber)
end)

RegisterServerEvent('qb-phone:server:accept', function(source)
    local player = getPlayer(source)
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

RegisterServerEvent('qb-phone:server:hangup', function(source)
    local player = getPlayer(source)
    if not player then return end

    local intSrc = player.PlayerData.source
    local time   = os.date('%H:%M')

    -- Hung up on an active call
    for channel, call in pairs(activeCalls) do
        if call.callerIntSrc == intSrc or call.targetIntSrc == intSrc then
            activeCalls[channel] = nil
            call.callerSrc:LeaveVoiceChannel(channel)
            call.targetSrc:LeaveVoiceChannel(channel)
            TriggerClientEvent(call.callerIntSrc, 'qb-phone:client:callEnded')
            TriggerClientEvent(call.targetIntSrc, 'qb-phone:client:callEnded')

            local callerPlayer = getPlayer(call.callerSrc)
            local targetPlayer = getPlayer(call.targetSrc)
            if callerPlayer and targetPlayer then
                local callerPhone = callerPlayer.PlayerData.charinfo.phone
                local targetPhone = targetPlayer.PlayerData.charinfo.phone
                local callerName  = getFullName(callerPlayer)
                local targetName  = getFullName(targetPlayer)
                ensureTable(callHistory, callerPhone)
                table.insert(callHistory[callerPhone], 1, { name = targetName, number = targetPhone, callType = 'outgoing', time = time, missed = false })
                ensureTable(callHistory, targetPhone)
                table.insert(callHistory[targetPhone], 1, { name = callerName, number = callerPhone, callType = 'incoming', time = time, missed = false })
                TriggerClientEvent(call.callerIntSrc, 'qb-phone:client:callLogged', targetName, targetPhone, 'outgoing', time, false)
                TriggerClientEvent(call.targetIntSrc, 'qb-phone:client:callLogged', callerName, callerPhone, 'incoming', time, false)
            end
            return
        end
    end

    -- Cancelled a pending/ringing call
    for targetSrc, pending in pairs(pendingCalls) do
        if pending.callerIntSrc == intSrc or targetSrc == intSrc then
            pendingCalls[targetSrc] = nil
            TriggerClientEvent(pending.callerIntSrc, 'qb-phone:client:callEnded')
            TriggerClientEvent(targetSrc, 'qb-phone:client:callEnded')

            local callerPlayer = getPlayer(pending.callerSrc)
            local targetPlayer = getPlayer(targetSrc)
            if callerPlayer and targetPlayer then
                local callerPhone = callerPlayer.PlayerData.charinfo.phone
                local targetPhone = targetPlayer.PlayerData.charinfo.phone
                local callerName  = getFullName(callerPlayer)
                local targetName  = getFullName(targetPlayer)
                ensureTable(callHistory, callerPhone)
                table.insert(callHistory[callerPhone], 1, { name = targetName, number = targetPhone, callType = 'outgoing', time = time, missed = true })
                ensureTable(callHistory, targetPhone)
                table.insert(callHistory[targetPhone], 1, { name = callerName, number = callerPhone, callType = 'missed', time = time, missed = true })
                TriggerClientEvent(pending.callerIntSrc, 'qb-phone:client:callLogged', targetName, targetPhone, 'outgoing', time, true)
                TriggerClientEvent(targetSrc, 'qb-phone:client:callLogged', callerName, callerPhone, 'missed', time, true)
            end
            return
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Data loading  (sends full player state on phone open)
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:givePhone', function(source)
    local ped = GetPlayerPawn(source)
    HInventory.GiveAndEquipItemByName(ped, 'ID_Misc_Phone')
end)

RegisterServerEvent('qb-phone:server:takePhone', function(source)
    local ped = GetPlayerPawn(source)
    HInventory.RemoveItemByName(ped, 'ID_Misc_Phone')
end)

-- Core data loaded on every phone open (contacts, conversations, call history)
RegisterCallback('qb-phone:loadCoreData', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    return {
        contacts      = json.encode(contacts[phone] or {}),
        conversations = json.encode(buildConversations(phone)),
        callHistory   = json.encode(callHistory[phone] or {}),
    }
end)

-- Lazy-loaded when the player opens the H (social feed) app
RegisterCallback('qb-phone:loadFeed', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    return {
        feed  = json.encode(buildFeedForPhone(phone)),
        users = json.encode(buildUsersForPhone(phone)),
    }
end)

-- Lazy-loaded when the player opens the Hmail app
RegisterCallback('qb-phone:loadEmails', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    return {
        emails = json.encode(emails[phone] or {}),
    }
end)

-- Lazy-loaded when the player opens the Calendar app
RegisterCallback('qb-phone:loadCalendar', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    return {
        events = json.encode(calendarEvents[phone] or {}),
    }
end)

-- Lazy-loaded when the player opens the Gallery app
RegisterCallback('qb-phone:loadPhotos', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    return {
        photos = json.encode(photos[phone] or {}),
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Messages
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:deleteConversation', function(source, targetNumber)
    local phone = getPhone(source)
    if not phone then return end
    messages[pairKey(phone, targetNumber)] = nil
end)

RegisterServerEvent('qb-phone:server:sendMessage', function(source, targetNumber, text)
    local sender = getPlayer(source)
    if not sender then return end

    local senderName   = getFullName(sender)
    local senderNumber = sender.PlayerData.charinfo.phone
    local time         = os.date('%H:%M')
    local key          = pairKey(senderNumber, targetNumber)

    ensureTable(messages, key)
    local msg = {
        id           = genId(),
        senderNumber = senderNumber,
        senderName   = senderName,
        text         = text,
        time         = time,
    }
    table.insert(messages[key], msg)

    local target = exports['qb-core']:GetPlayerByPhone(targetNumber)
    if target then
        TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:messageReceived', senderName, senderNumber, text, time)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Contacts
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:saveContact', function(source, name, number, image)
    local phone = getPhone(source)
    if not phone then return end
    ensureTable(contacts, phone)
    for i, c in ipairs(contacts[phone]) do
        if c.number == number then
            contacts[phone][i] = { name = name, number = number, image = image }
            return
        end
    end
    table.insert(contacts[phone], { name = name, number = number, image = image })
end)

RegisterServerEvent('qb-phone:server:deleteContact', function(source, number)
    local phone = getPhone(source)
    if not phone or not contacts[phone] then return end
    for i, c in ipairs(contacts[phone]) do
        if c.number == number then
            table.remove(contacts[phone], i)
            return
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- H (Social Feed)
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:createPost', function(source, content, image)
    local player = getPlayer(source)
    if not player then return end

    local authorName   = getFullName(player)
    local authorNumber = player.PlayerData.charinfo.phone
    local handle       = makeHandle(authorName)
    local time         = os.date('%H:%M')
    local postId       = genId()

    -- Upsert author profile so they appear in USERS on other players' phones
    if not playerProfiles[authorNumber] then
        playerProfiles[authorNumber] = { name = authorName, handle = handle, bio = '' }
    end

    local post = {
        id           = postId,
        authorName   = authorName,
        authorNumber = authorNumber,
        handle       = handle,
        content      = content,
        image        = image or '',
        time         = time,
    }
    table.insert(posts, 1, post)
    likes[postId]    = {}
    reposts[postId]  = {}
    comments[postId] = {}

    -- Broadcast to all; liked/reposted are false for a brand-new post
    local payload    = {
        id       = postId,
        author   = authorName,
        handle   = handle,
        content  = content,
        image    = image or '',
        time     = time,
        likes    = 0,
        liked    = false,
        reposts  = 0,
        reposted = false,
        comments = {},
    }
    TriggerClientEvent(-1, 'qb-phone:client:postReceived', json.encode(payload))
end)

RegisterServerEvent('qb-phone:server:deletePost', function(source, postId)
    local phone = getPhone(source)
    if not phone then return end
    for i, post in ipairs(posts) do
        if post.id == postId and post.authorNumber == phone then
            table.remove(posts, i)
            likes[postId]    = nil
            reposts[postId]  = nil
            comments[postId] = nil
            TriggerClientEvent(-1, 'qb-phone:client:postDeleted', postId)
            return
        end
    end
end)

RegisterServerEvent('qb-phone:server:likePost', function(source, postId, liked)
    local phone = getPhone(source)
    if not phone then return end
    ensureTable(likes, postId)
    if liked then
        likes[postId][phone] = true
    else
        likes[postId][phone] = nil
    end
    TriggerClientEvent(-1, 'qb-phone:client:postLikeUpdated', postId, countSet(likes[postId]))
end)

RegisterServerEvent('qb-phone:server:repostPost', function(source, postId, reposted)
    local phone = getPhone(source)
    if not phone then return end
    ensureTable(reposts, postId)
    if reposted then
        reposts[postId][phone] = true
    else
        reposts[postId][phone] = nil
    end
    TriggerClientEvent(-1, 'qb-phone:client:postRepostUpdated', postId, countSet(reposts[postId]))
end)

RegisterServerEvent('qb-phone:server:followUser', function(source, handle, following, targetPhone)
    local follower = getPlayer(source)
    if not follower then return end

    local followerName   = getFullName(follower)
    local followerNumber = follower.PlayerData.charinfo.phone

    ensureTable(follows, followerNumber)
    if following then
        follows[followerNumber][handle] = true
    else
        follows[followerNumber][handle] = nil
    end

    if following and targetPhone and targetPhone ~= '' then
        local target = exports['qb-core']:GetPlayerByPhone(targetPhone)
        if target then
            TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:newFollower', followerName, followerNumber)
        end
    end
end)

RegisterServerEvent('qb-phone:server:addComment', function(source, postId, text)
    local player = getPlayer(source)
    if not player then return end
    if not comments[postId] then return end

    local authorName   = getFullName(player)
    local authorNumber = player.PlayerData.charinfo.phone
    local handle       = makeHandle(authorName)
    local time         = os.date('%H:%M')
    local comment      = {
        id           = genId(),
        authorName   = authorName,
        authorNumber = authorNumber,
        handle       = handle,
        text         = text,
        time         = time,
    }
    table.insert(comments[postId], comment)

    local payload = { id = comment.id, author = authorName, handle = handle, text = text, time = time }
    TriggerClientEvent(-1, 'qb-phone:client:commentAdded', postId, json.encode(payload))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Email
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:sendEmail', function(source, toNumber, subject, body)
    local sender = getPlayer(source)
    if not sender then return end

    local senderName   = getFullName(sender)
    local senderNumber = sender.PlayerData.charinfo.phone
    local time         = os.date('%H:%M')

    ensureTable(emails, toNumber)
    local email = {
        id         = genId(),
        from       = senderName,
        fromNumber = senderNumber,
        subject    = subject,
        snippet    = string.sub(body, 1, 80),
        body       = body,
        time       = time,
        read       = false,
        starred    = false,
    }
    table.insert(emails[toNumber], 1, email)

    local target = exports['qb-core']:GetPlayerByPhone(toNumber)
    if target then
        TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:emailReceived', json.encode(email))
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Calendar
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:saveCalendarEvent', function(source, month, day, title, time, detail)
    local phone = getPhone(source)
    if not phone then return end
    ensureTable(calendarEvents, phone)
    ensureTable(calendarEvents[phone], month)
    ensureTable(calendarEvents[phone][month], day)
    local event = { id = genId(), title = title, time = time, detail = detail }
    table.insert(calendarEvents[phone][month][day], event)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Photos
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:deletePhoto', function(source, photoId)
    local phone = getPhone(source)
    if not phone or not photos[phone] then return end
    for i, p in ipairs(photos[phone]) do
        if p.id == photoId then
            table.remove(photos[phone], i)
            return
        end
    end
end)
