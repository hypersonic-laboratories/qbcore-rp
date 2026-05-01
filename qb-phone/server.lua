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

-- Monotonic-ish ID counter so every record has a unique numeric id across restarts.
local _nextId = math.random(1000, 9999)
local function genId()
    local id = tonumber(os.time() .. string.format('%04d', _nextId % 10000))
    _nextId = _nextId + 1
    return id
end

local function dbAction(action, ...)
    local ok, result = pcall(function(...)
        if Database and Database[action] then
            return Database[action](...)
        end
        return exports['qb-core']:DatabaseAction(action, ...)
    end, ...)

    if not ok then
        print(('[qb-phone] Database %s failed: %s'):format(tostring(action), tostring(result)))
        if action == 'Execute' or action == 'ExecuteAsync' then return false end
        return {}
    end

    if type(result) == 'userdata' and result.__name == 'TArray' then
        local rows = {}
        local okRows, rawRows = pcall(function() return result:ToTable() end)
        if not okRows then return rows end
        for k, row in pairs(rawRows) do
            if row.Columns and row.Columns.ToTable then
                rows[k] = row.Columns:ToTable()
            else
                rows[k] = row
            end
        end
        return rows
    end

    if type(result) ~= 'table' then return result end

    local rows = {}
    for k, row in pairs(result) do
        if type(row) == 'table' and row.Columns and type(row.Columns) == 'table' then
            rows[k] = row.Columns
        elseif type(row) == 'table' and row.Columns and row.Columns.ToTable then
            rows[k] = row.Columns:ToTable()
        else
            rows[k] = row
        end
    end
    return rows
end

local function dbExecute(query, params)
    return dbAction('Execute', query, params or {})
end

local function dbSelect(query, params)
    local rows = dbAction('Select', query, params or {})
    return type(rows) == 'table' and rows or {}
end

local function getCitizenIdFromPlayer(player)
    if not player or not player.PlayerData then return nil end
    return player.PlayerData.citizenid
        or (player.PlayerData.charinfo and player.PlayerData.charinfo.citizenid)
        or (player.PlayerData.charinfo and player.PlayerData.charinfo.phone)
end

local function getCitizenId(source)
    return getCitizenIdFromPlayer(getPlayer(source))
end

local function getFirstName(player)
    return player.PlayerData.charinfo.firstname or ''
end

local function getLastName(player)
    return player.PlayerData.charinfo.lastname or ''
end

local function syncPlayerAccount(player)
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then return nil end

    local phone = player.PlayerData.charinfo.phone or citizenid
    local firstName = getFirstName(player)
    local lastName = getLastName(player)
    local name = getFullName(player)
    local handle = makeHandle(name)

    dbExecute([[
        INSERT INTO phone_accounts (citizenid, phone, name, first_name, last_name, handle, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(citizenid) DO UPDATE SET
            phone = excluded.phone,
            name = excluded.name,
            first_name = excluded.first_name,
            last_name = excluded.last_name,
            handle = excluded.handle,
            updated_at = CURRENT_TIMESTAMP
    ]], { citizenid, phone, name, firstName, lastName, handle })

    if phone ~= citizenid then
        dbExecute('UPDATE OR IGNORE phone_messages SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        dbExecute('UPDATE OR IGNORE player_contacts SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        dbExecute('UPDATE OR IGNORE player_mails SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        dbExecute('UPDATE OR IGNORE phone_gallery SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        dbExecute('UPDATE OR IGNORE phone_call_history SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        dbExecute('UPDATE OR IGNORE phone_calendar_events SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
    end

    return citizenid
end

local function getKnownAccountByPhone(number)
    local rows = dbSelect('SELECT citizenid, phone, name, handle FROM phone_accounts WHERE phone = ? LIMIT 1', { number })
    return rows[1]
end

local function getOwnerKeyForPhone(number)
    local target = exports['qb-core']:GetPlayerByPhone(number)
    if target then
        return syncPlayerAccount(target), getFullName(target)
    end

    local account = getKnownAccountByPhone(number)
    if account then
        return account.citizenid, account.name
    end

    return number, number
end

local function decodeJsonArray(value)
    if not value or value == '' then return {} end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then return decoded end
    return {}
end

local function dbBool(value)
    return value == true or value == 1 or value == '1' or value == 'true'
end

local function displayTime(value)
    if not value or value == '' then return os.date('%H:%M') end
    local h, m = string.match(tostring(value), '(%d%d):(%d%d):%d%d')
    if h and m then return h .. ':' .. m end
    h, m = string.match(tostring(value), '(%d%d):(%d%d)')
    if h and m then return h .. ':' .. m end
    return tostring(value)
end

local function contactNameMap(contactList)
    local map = {}
    for _, contact in ipairs(contactList or {}) do
        map[contact.number] = contact
    end
    return map
end

local function loadContacts(citizenid, phone)
    local rows = dbSelect('SELECT name, number, image FROM player_contacts WHERE citizenid = ? OR citizenid = ? ORDER BY rowid DESC', { citizenid, phone or citizenid })
    local result = {}
    local seen = {}
    for _, row in ipairs(rows) do
        local number = row.number or row.Number or ''
        if number ~= '' and not seen[number] then
            seen[number] = true
            table.insert(result, {
                name = row.name or row.Name or '',
                number = number,
                image = row.image or row.Image or '',
            })
        end
    end
    return result
end

local function loadConversations(citizenid, phone, contactList)
    local rows = dbSelect([[
        SELECT number, display_name, image, messages
        FROM phone_messages
        WHERE citizenid = ? OR citizenid = ?
        ORDER BY updated_at DESC, rowid DESC
    ]], { citizenid, phone })

    local contactsByNumber = contactNameMap(contactList)
    local result = {}
    local seen = {}

    for _, row in ipairs(rows) do
        local number = row.number or row.Number or ''
        if number ~= '' and not seen[number] then
            seen[number] = true
            local savedContact = contactsByNumber[number]
            local displayName = row.display_name or row.DisplayName or row.displayName or number
            local image = row.image or row.Image or ''
            if savedContact then
                displayName = savedContact.name
                image = savedContact.image or image
            end

            local messageList = decodeJsonArray(row.messages or row.Messages)
            for _, message in ipairs(messageList) do
                if not message.sender and message.senderNumber then
                    message.sender = message.senderNumber == phone and 'me' or 'them'
                end
            end

            table.insert(result, {
                id = number,
                name = displayName,
                number = number,
                image = image or '',
                messages = messageList,
            })
        end
    end

    return result
end

local function saveConversationMessages(ownerKey, otherNumber, displayName, image, messageList)
    if not ownerKey or ownerKey == '' or not otherNumber or otherNumber == '' then return end
    dbExecute('DELETE FROM phone_messages WHERE citizenid = ? AND number = ?', { ownerKey, otherNumber })
    dbExecute([[
        INSERT INTO phone_messages (citizenid, number, display_name, image, messages, updated_at)
        VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    ]], { ownerKey, otherNumber, displayName or otherNumber, image or '', json.encode(messageList or {}) })
end

local function appendConversationMessage(ownerKey, otherNumber, displayName, image, message)
    if not ownerKey or ownerKey == '' then return end
    local rows = dbSelect('SELECT messages FROM phone_messages WHERE citizenid = ? AND number = ? LIMIT 1', { ownerKey, otherNumber })
    local messageList = rows[1] and decodeJsonArray(rows[1].messages or rows[1].Messages) or {}
    table.insert(messageList, message)
    saveConversationMessages(ownerKey, otherNumber, displayName, image, messageList)
end

local function loadCallHistory(citizenid, phone)
    local rows = dbSelect([[
        SELECT name, number, type, missed, time, created_at
        FROM phone_call_history
        WHERE citizenid = ? OR citizenid = ?
        ORDER BY rowid DESC
        LIMIT 100
    ]], { citizenid, phone })

    local result = {}
    for _, row in ipairs(rows) do
        table.insert(result, {
            name = row.name or '',
            number = row.number or '',
            type = row.type or '',
            time = (row.time and row.time ~= '') and row.time or displayTime(row.created_at),
            missed = dbBool(row.missed),
        })
    end
    return result
end

local function saveCallHistory(ownerKey, name, number, callType, time, missed)
    if not ownerKey or ownerKey == '' then return end
    dbExecute([[
        INSERT INTO phone_call_history (citizenid, name, number, type, missed, time)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { ownerKey, name or number or '', number or '', callType or '', missed and 1 or 0, time or os.date('%H:%M') })
end

local function loadEmails(citizenid, phone)
    local rows = dbSelect([[
        SELECT rowid AS row_id, id, mailid, sender, sender_number, subject, message, read, starred, date
        FROM player_mails
        WHERE citizenid = ? OR citizenid = ?
        ORDER BY rowid DESC
        LIMIT 100
    ]], { citizenid, phone })

    local result = {}
    for _, row in ipairs(rows) do
        local body = row.message or ''
        table.insert(result, {
            id = tonumber(row.mailid) or tonumber(row.row_id) or tonumber(row.id) or row.mailid or row.row_id or row.id,
            from = row.sender or '',
            fromNumber = row.sender_number or row.senderNumber or '',
            subject = row.subject or '',
            snippet = string.sub(body, 1, 80),
            body = body,
            time = displayTime(row.date),
            read = dbBool(row.read),
            starred = dbBool(row.starred),
        })
    end
    return result
end

local function loadCalendarEvents(citizenid, phone)
    local rows = dbSelect([[
        SELECT id, month, day, title, event_time, detail, accent
        FROM phone_calendar_events
        WHERE citizenid = ? OR citizenid = ?
        ORDER BY created_at ASC
    ]], { citizenid, phone })

    local result = {}
    for _, row in ipairs(rows) do
        local month = tonumber(row.month) or 0
        local day = tonumber(row.day) or 1
        ensureTable(result, month)
        ensureTable(result[month], day)
        table.insert(result[month][day], {
            id = row.id,
            title = row.title or '',
            time = row.event_time or '',
            detail = row.detail or '',
            accent = row.accent or 'bg-rose-500',
        })
    end
    return result
end

local function loadPhotos(citizenid, phone)
    local rows = dbSelect([[
        SELECT rowid AS id, image, date
        FROM phone_gallery
        WHERE citizenid = ? OR citizenid = ?
        ORDER BY rowid DESC
        LIMIT 200
    ]], { citizenid, phone })

    local result = {}
    for _, row in ipairs(rows) do
        local image = row.image or ''
        table.insert(result, {
            id = tonumber(row.id) or row.id or image,
            url = image,
            gradient = image ~= '' and ('url(' .. image .. ') center/cover no-repeat') or '',
            takenAt = displayTime(row.date),
        })
    end
    return result
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Payload builders  (assemble client-facing JSON from the tables above)
-- ─────────────────────────────────────────────────────────────────────────────

-- Build the feed with per-player liked/reposted flags
local function buildFeedForPhone(phone, viewerCitizenId)
    local reactionRows = dbSelect('SELECT tweet_id, citizenid, type FROM phone_tweet_reactions', {})
    local reactions = {}
    for _, row in ipairs(reactionRows) do
        local tweetId = tostring(row.tweet_id or row.tweetId or '')
        local reactionType = row.type or ''
        local citizenid = row.citizenid
        if tweetId ~= '' and reactionType ~= '' and citizenid then
            ensureTable(reactions, tweetId)
            ensureTable(reactions[tweetId], reactionType)
            reactions[tweetId][reactionType][citizenid] = true
        end
    end

    local commentRows = dbSelect([[
        SELECT id, tweet_id, firstName, lastName, handle, message, date
        FROM phone_tweet_comments
        ORDER BY date ASC
    ]], {})
    local commentsByTweet = {}
    for _, row in ipairs(commentRows) do
        local tweetId = tostring(row.tweet_id or row.tweetId or '')
        ensureTable(commentsByTweet, tweetId)
        local firstName = row.firstName or row.firstname or ''
        local lastName = row.lastName or row.lastname or ''
        local authorName = (firstName .. ' ' .. lastName):gsub('^%s+', ''):gsub('%s+$', '')
        table.insert(commentsByTweet[tweetId], {
            id = tonumber(row.id) or row.id,
            author = authorName ~= '' and authorName or (row.handle or 'Unknown'),
            handle = row.handle or makeHandle(authorName),
            text = row.message or '',
            time = displayTime(row.date),
        })
    end

    local tweetRows = dbSelect([[
        SELECT rowid AS row_id, tweetId, citizenid, firstName, lastName, handle, message, url, date
        FROM phone_tweets
        ORDER BY date DESC, rowid DESC
    ]], {})

    local feed = {}
    for _, row in ipairs(tweetRows) do
        local tweetId = tostring(row.tweetId or row.tweetid or row.row_id or row.id)
        local firstName = row.firstName or row.firstname or ''
        local lastName = row.lastName or row.lastname or ''
        local authorName = (firstName .. ' ' .. lastName):gsub('^%s+', ''):gsub('%s+$', '')
        local postLikes = reactions[tweetId] and reactions[tweetId].like or {}
        local postReposts = reactions[tweetId] and reactions[tweetId].repost or {}

        table.insert(feed, {
            id = tonumber(tweetId) or tweetId,
            author = authorName ~= '' and authorName or 'Unknown',
            handle = row.handle or makeHandle(authorName),
            content = row.message or '',
            image = row.url or '',
            time = displayTime(row.date),
            likes = countSet(postLikes),
            liked = viewerCitizenId and postLikes[viewerCitizenId] == true or postLikes[phone] == true,
            reposts = countSet(postReposts),
            reposted = viewerCitizenId and postReposts[viewerCitizenId] == true or postReposts[phone] == true,
            comments = commentsByTweet[tweetId] or {},
        })
    end

    return feed
end

-- Build the USERS map (author profiles) as seen by a specific viewer
local function buildUsersForPhone(viewerPhone, viewerCitizenId)
    local users = {}
    local accounts = dbSelect('SELECT citizenid, phone, name, handle, bio FROM phone_accounts', {})
    local followsRows = dbSelect('SELECT follower_citizenid, target_citizenid, target_name, target_handle FROM phone_tweet_follows', {})

    local followersByTarget = {}
    local followingByFollower = {}
    local viewerFollowing = {}

    for _, row in ipairs(followsRows) do
        local targetName = row.target_name or row.targetName or ''
        if targetName ~= '' then
            followersByTarget[targetName] = (followersByTarget[targetName] or 0) + 1
        end
        local follower = row.follower_citizenid or row.followerCitizenid or ''
        if follower ~= '' then
            followingByFollower[follower] = (followingByFollower[follower] or 0) + 1
        end
        if viewerCitizenId and follower == viewerCitizenId and targetName ~= '' then
            viewerFollowing[targetName] = true
        end
    end

    for _, row in ipairs(accounts) do
        local name = row.name or ''
        if name ~= '' then
            users[name] = {
                handle = row.handle or makeHandle(name),
                bio = row.bio or '',
                phone = row.phone or '',
                followers = followersByTarget[name] or 0,
                following_count = followingByFollower[row.citizenid or ''] or 0,
                following = viewerFollowing[name] == true or viewerFollowing[row.handle or ''] == true,
            }
        end
    end

    -- If an old tweet exists before the author has opened this phone, still expose a profile.
    local tweetAuthors = dbSelect('SELECT DISTINCT citizenid, firstName, lastName, handle FROM phone_tweets', {})
    for _, row in ipairs(tweetAuthors) do
        local firstName = row.firstName or row.firstname or ''
        local lastName = row.lastName or row.lastname or ''
        local name = (firstName .. ' ' .. lastName):gsub('^%s+', ''):gsub('%s+$', '')
        if name ~= '' and not users[name] then
            users[name] = {
                handle = row.handle or makeHandle(name),
                bio = '',
                phone = '',
                followers = followersByTarget[name] or 0,
                following_count = followingByFollower[row.citizenid or ''] or 0,
                following = viewerFollowing[name] == true,
            }
        end
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
                local callerPhone     = callerPlayer.PlayerData.charinfo.phone
                local targetPhone     = targetPlayer.PlayerData.charinfo.phone
                local callerName      = getFullName(callerPlayer)
                local targetName      = getFullName(targetPlayer)
                local callerCitizenId = syncPlayerAccount(callerPlayer)
                local targetCitizenId = syncPlayerAccount(targetPlayer)
                ensureTable(callHistory, callerPhone)
                table.insert(callHistory[callerPhone], 1, { name = targetName, number = targetPhone, callType = 'outgoing', time = time, missed = false })
                ensureTable(callHistory, targetPhone)
                table.insert(callHistory[targetPhone], 1, { name = callerName, number = callerPhone, callType = 'incoming', time = time, missed = false })
                saveCallHistory(callerCitizenId, targetName, targetPhone, 'outgoing', time, false)
                saveCallHistory(targetCitizenId, callerName, callerPhone, 'incoming', time, false)
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
                local callerPhone     = callerPlayer.PlayerData.charinfo.phone
                local targetPhone     = targetPlayer.PlayerData.charinfo.phone
                local callerName      = getFullName(callerPlayer)
                local targetName      = getFullName(targetPlayer)
                local callerCitizenId = syncPlayerAccount(callerPlayer)
                local targetCitizenId = syncPlayerAccount(targetPlayer)
                ensureTable(callHistory, callerPhone)
                table.insert(callHistory[callerPhone], 1, { name = targetName, number = targetPhone, callType = 'outgoing', time = time, missed = true })
                ensureTable(callHistory, targetPhone)
                table.insert(callHistory[targetPhone], 1, { name = callerName, number = callerPhone, callType = 'missed', time = time, missed = true })
                saveCallHistory(callerCitizenId, targetName, targetPhone, 'outgoing', time, true)
                saveCallHistory(targetCitizenId, callerName, callerPhone, 'missed', time, true)
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
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return nil end
    local contactList = loadContacts(citizenid, phone)
    local firstName = player.PlayerData.charinfo.firstname or ''
    local lastName  = player.PlayerData.charinfo.lastname  or ''
    return {
        contacts      = json.encode(contactList),
        conversations = json.encode(loadConversations(citizenid, phone, contactList)),
        callHistory   = json.encode(loadCallHistory(citizenid, phone)),
        playerName    = (firstName .. ' ' .. lastName):match('^%s*(.-)%s*$'),
    }
end)

-- Lazy-loaded when the player opens the H (social feed) app
RegisterCallback('qb-phone:loadFeed', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return nil end
    return {
        feed  = json.encode(buildFeedForPhone(phone, citizenid)),
        users = json.encode(buildUsersForPhone(phone, citizenid)),
    }
end)

-- Lazy-loaded when the player opens the Hmail app
RegisterCallback('qb-phone:loadEmails', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return nil end
    return {
        emails = json.encode(loadEmails(citizenid, phone)),
    }
end)

-- Lazy-loaded when the player opens the Calendar app
RegisterCallback('qb-phone:loadCalendar', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return nil end
    return {
        events = json.encode(loadCalendarEvents(citizenid, phone)),
    }
end)

-- Lazy-loaded when the player opens the Gallery app
RegisterCallback('qb-phone:loadPhotos', function(source)
    local player = getPlayer(source)
    if not player then return nil end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return nil end
    return {
        photos = json.encode(loadPhotos(citizenid, phone)),
    }
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Messages
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:deleteConversation', function(source, targetNumber)
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    messages[pairKey(phone, targetNumber)] = nil
    dbExecute('DELETE FROM phone_messages WHERE citizenid = ? AND number = ?', { citizenid, targetNumber })
    if phone ~= citizenid then
        dbExecute('DELETE FROM phone_messages WHERE citizenid = ? AND number = ?', { phone, targetNumber })
    end
end)

RegisterServerEvent('qb-phone:server:sendMessage', function(source, targetNumber, text)
    local sender = getPlayer(source)
    if not sender then return end

    local senderName      = getFullName(sender)
    local senderNumber    = sender.PlayerData.charinfo.phone
    local senderCitizenId = syncPlayerAccount(sender)
    local time            = os.date('%H:%M')
    local key             = pairKey(senderNumber, targetNumber)

    ensureTable(messages, key)
    local msg = {
        id           = genId(),
        senderNumber = senderNumber,
        senderName   = senderName,
        text         = text,
        time         = time,
    }
    table.insert(messages[key], msg)

    appendConversationMessage(senderCitizenId, targetNumber, targetNumber, '', {
        id = msg.id,
        sender = 'me',
        text = text,
        time = time,
    })

    local target = exports['qb-core']:GetPlayerByPhone(targetNumber)
    local targetCitizenId = nil
    local targetDisplayName = senderName
    if target then
        targetCitizenId = syncPlayerAccount(target)
        targetDisplayName = senderName
        TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:messageReceived', senderName, senderNumber, text, time)
    else
        targetCitizenId = getOwnerKeyForPhone(targetNumber)
    end

    appendConversationMessage(targetCitizenId, senderNumber, targetDisplayName, '', {
        id = msg.id,
        sender = 'them',
        text = text,
        time = time,
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Contacts
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:saveContact', function(source, name, number, image)
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    ensureTable(contacts, phone)
    for i, c in ipairs(contacts[phone]) do
        if c.number == number then
            contacts[phone][i] = { name = name, number = number, image = image }
            dbExecute('DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { citizenid, number })
            if phone ~= citizenid then
                dbExecute('DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { phone, number })
            end
            dbExecute([[
                INSERT INTO player_contacts (citizenid, name, number, image, iban)
                VALUES (?, ?, ?, ?, '0')
            ]], { citizenid, name, number, image or '' })
            return
        end
    end
    table.insert(contacts[phone], { name = name, number = number, image = image })
    dbExecute('DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { citizenid, number })
    if phone ~= citizenid then
        dbExecute('DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { phone, number })
    end
    dbExecute([[
        INSERT INTO player_contacts (citizenid, name, number, image, iban)
        VALUES (?, ?, ?, ?, '0')
    ]], { citizenid, name, number, image or '' })
end)

RegisterServerEvent('qb-phone:server:deleteContact', function(source, number)
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    if contacts[phone] then
        for i, c in ipairs(contacts[phone]) do
            if c.number == number then
                table.remove(contacts[phone], i)
                break
            end
        end
    end
    dbExecute('DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { citizenid, number })
    if phone ~= citizenid then
        dbExecute('DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { phone, number })
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- H (Social Feed)
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:createPost', function(source, content, image)
    local player = getPlayer(source)
    if not player then return end

    local authorName      = getFullName(player)
    local authorNumber    = player.PlayerData.charinfo.phone
    local authorCitizenId = syncPlayerAccount(player)
    if not authorCitizenId then return end
    local firstName = getFirstName(player)
    local lastName  = getLastName(player)
    local handle    = makeHandle(authorName)
    local time      = os.date('%H:%M')
    local postId    = genId()

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

    dbExecute([[
        INSERT INTO phone_tweets (citizenid, firstName, lastName, handle, message, url, picture, tweetId)
        VALUES (?, ?, ?, ?, ?, ?, './img/default.png', ?)
    ]], { authorCitizenId, firstName, lastName, handle, content, image or '', tostring(postId) })

    -- Broadcast to all; liked/reposted are false for a brand-new post
    local payload = {
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
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    for i, post in ipairs(posts) do
        if post.id == postId and post.authorNumber == phone then
            table.remove(posts, i)
            likes[postId]    = nil
            reposts[postId]  = nil
            comments[postId] = nil
            dbExecute('DELETE FROM phone_tweet_reactions WHERE tweet_id = ?', { tostring(postId) })
            dbExecute('DELETE FROM phone_tweet_comments WHERE tweet_id = ?', { tostring(postId) })
            dbExecute('DELETE FROM phone_tweets WHERE tweetId = ? AND citizenid = ?', { tostring(postId), citizenid })
            TriggerClientEvent(-1, 'qb-phone:client:postDeleted', postId)
            return
        end
    end

    local rows = dbSelect('SELECT citizenid FROM phone_tweets WHERE tweetId = ? LIMIT 1', { tostring(postId) })
    if rows[1] and rows[1].citizenid == citizenid then
        dbExecute('DELETE FROM phone_tweet_reactions WHERE tweet_id = ?', { tostring(postId) })
        dbExecute('DELETE FROM phone_tweet_comments WHERE tweet_id = ?', { tostring(postId) })
        dbExecute('DELETE FROM phone_tweets WHERE tweetId = ?', { tostring(postId) })
        TriggerClientEvent(-1, 'qb-phone:client:postDeleted', postId)
    end
end)

RegisterServerEvent('qb-phone:server:likePost', function(source, postId, liked)
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    ensureTable(likes, postId)
    if liked then
        likes[postId][phone] = true
    else
        likes[postId][phone] = nil
    end
    dbExecute('DELETE FROM phone_tweet_reactions WHERE tweet_id = ? AND citizenid = ? AND type = ?', { tostring(postId), citizenid, 'like' })
    if liked then
        dbExecute('INSERT INTO phone_tweet_reactions (tweet_id, citizenid, type) VALUES (?, ?, ?)', { tostring(postId), citizenid, 'like' })
    end
    local rows = dbSelect('SELECT citizenid FROM phone_tweet_reactions WHERE tweet_id = ? AND type = ?', { tostring(postId), 'like' })
    TriggerClientEvent(-1, 'qb-phone:client:postLikeUpdated', postId, #rows)
end)

RegisterServerEvent('qb-phone:server:repostPost', function(source, postId, reposted)
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    ensureTable(reposts, postId)
    if reposted then
        reposts[postId][phone] = true
    else
        reposts[postId][phone] = nil
    end
    dbExecute('DELETE FROM phone_tweet_reactions WHERE tweet_id = ? AND citizenid = ? AND type = ?', { tostring(postId), citizenid, 'repost' })
    if reposted then
        dbExecute('INSERT INTO phone_tweet_reactions (tweet_id, citizenid, type) VALUES (?, ?, ?)', { tostring(postId), citizenid, 'repost' })
    end
    local rows = dbSelect('SELECT citizenid FROM phone_tweet_reactions WHERE tweet_id = ? AND type = ?', { tostring(postId), 'repost' })
    TriggerClientEvent(-1, 'qb-phone:client:postRepostUpdated', postId, #rows)
end)

RegisterServerEvent('qb-phone:server:followUser', function(source, handle, following, targetPhone)
    local follower = getPlayer(source)
    if not follower then return end

    local followerName      = getFullName(follower)
    local followerNumber    = follower.PlayerData.charinfo.phone
    local followerCitizenId = syncPlayerAccount(follower)
    if not followerCitizenId then return end
    local targetCitizenId = ''
    local targetHandle = ''
    local targetName = handle or ''

    if targetPhone and targetPhone ~= '' then
        local target = exports['qb-core']:GetPlayerByPhone(targetPhone)
        if target then
            targetCitizenId = syncPlayerAccount(target) or ''
            targetName = getFullName(target)
            targetHandle = makeHandle(targetName)
        else
            local account = getKnownAccountByPhone(targetPhone)
            if account then
                targetCitizenId = account.citizenid or ''
                targetName = account.name or targetName
                targetHandle = account.handle or makeHandle(targetName)
            end
        end
    end

    ensureTable(follows, followerNumber)
    if following then
        follows[followerNumber][targetName] = true
        dbExecute([[
            INSERT OR REPLACE INTO phone_tweet_follows (follower_citizenid, target_citizenid, target_name, target_handle, target_phone)
            VALUES (?, ?, ?, ?, ?)
        ]], { followerCitizenId, targetCitizenId, targetName, targetHandle, targetPhone or '' })
    else
        follows[followerNumber][targetName] = nil
        dbExecute('DELETE FROM phone_tweet_follows WHERE follower_citizenid = ? AND target_name = ?', { followerCitizenId, targetName })
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

    local authorName      = getFullName(player)
    local authorNumber    = player.PlayerData.charinfo.phone
    local authorCitizenId = syncPlayerAccount(player)
    if not authorCitizenId then return end
    local firstName = getFirstName(player)
    local lastName  = getLastName(player)
    local handle    = makeHandle(authorName)
    local time      = os.date('%H:%M')
    local comment   = {
        id           = genId(),
        authorName   = authorName,
        authorNumber = authorNumber,
        handle       = handle,
        text         = text,
        time         = time,
    }
    ensureTable(comments, postId)
    table.insert(comments[postId], comment)

    dbExecute([[
        INSERT INTO phone_tweet_comments (id, tweet_id, citizenid, firstName, lastName, handle, message)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { tostring(comment.id), tostring(postId), authorCitizenId, firstName, lastName, handle, text })

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
    syncPlayerAccount(sender)
    local time               = os.date('%H:%M')
    local recipientCitizenId = getOwnerKeyForPhone(toNumber)
    local emailId            = genId()

    ensureTable(emails, toNumber)
    local email = {
        id         = emailId,
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

    dbExecute([[
        INSERT INTO player_mails (citizenid, sender, sender_number, subject, message, read, starred, mailid)
        VALUES (?, ?, ?, ?, ?, 0, 0, ?)
    ]], { recipientCitizenId, senderName, senderNumber, subject, body, tostring(emailId) })

    local target = exports['qb-core']:GetPlayerByPhone(toNumber)
    if target then
        TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:emailReceived', json.encode(email))
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Calendar
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:saveCalendarEvent', function(source, month, day, title, time, detail)
    local player = getPlayer(source)
    if not player then return end
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end
    dbExecute([[
        INSERT INTO phone_calendar_events (id, citizenid, month, day, title, event_time, detail)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { tostring(genId()), citizenid, tonumber(month) or 0, tonumber(day) or 1, title, time, detail })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Photos
-- ─────────────────────────────────────────────────────────────────────────────

RegisterServerEvent('qb-phone:server:savePhoto', function(source, url)
    if not url or url == '' then return end
    local player = getPlayer(source)
    if not player then return end
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end

    dbExecute('INSERT INTO phone_gallery (citizenid, image) VALUES (?, ?)', { citizenid, url })
end)

RegisterServerEvent('qb-phone:server:deletePhoto', function(source, photoId)
    local player = getPlayer(source)
    if not player then return end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = syncPlayerAccount(player)
    if not citizenid then return end

    if photos[phone] then
        for i, p in ipairs(photos[phone]) do
            if p.id == photoId then
                table.remove(photos[phone], i)
                break
            end
        end
    end

    dbExecute('DELETE FROM phone_gallery WHERE citizenid = ? AND rowid = ?', { citizenid, photoId })
end)
