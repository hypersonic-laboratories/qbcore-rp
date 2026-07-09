---@diagnostic disable: undefined-global

local function nonEmpty(s)
    return type(s) == 'string' and s ~= '' and s or nil
end

local function textValue(value)
    if value == nil then
        return nil
    end
    local text = tostring(value)
    return text ~= '' and text or nil
end

local pendingCalls = {}
local activeCalls = {}

local function genChannel()
    return math.random(50000, 99999)
end

local contacts = {}
local messages = {}
local callHistory = {}
local posts = {}
local likes = {}
local reposts = {}
local comments = {}
local follows = {}
local emails = {}
local photos = {}

local function getPlayer(source)
    return exports['qb-core']:GetPlayer(source)
end

local function getCharInfo(player)
    if not player or not player.PlayerData then
        return {}
    end
    return player.PlayerData.charinfo or {}
end

local function getCharField(player, key)
    return textValue(getCharInfo(player)[key])
end

local function getFullName(player)
    local firstName = getCharField(player, 'firstname') or ''
    local lastName = getCharField(player, 'lastname') or ''
    local charName = (firstName .. ' ' .. lastName):match('^%s*(.-)%s*$')
    return nonEmpty(charName) or textValue(player and player.PlayerData and player.PlayerData.name) or 'HELIX Player'
end

local function makeHandle(fullName)
    return '@' .. string.lower(string.gsub(fullName, '%s+', ''))
end

local function pairKey(a, b)
    if a < b then
        return a .. '|' .. b
    else
        return b .. '|' .. a
    end
end

local function countSet(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function ensureTable(t, key)
    if not t[key] then
        t[key] = {}
    end
    return t[key]
end

local _nextId = math.random(100000, 999999)
local function genId()
    _nextId = _nextId + 1
    return _nextId
end

local function getCitizenIdFromPlayer(player)
    if not player or not player.PlayerData then
        return nil
    end
    return textValue(player.PlayerData.citizenid) or getCharField(player, 'citizenid') or getCharField(player, 'phone')
end

local function getFirstName(player)
    return getCharField(player, 'firstname') or ''
end

local function getLastName(player)
    return getCharField(player, 'lastname') or ''
end

local function getPhoneNumber(player, fallback)
    return getCharField(player, 'phone') or fallback
end

local function getAccountNumber(player)
    return getCharField(player, 'account') or ''
end

local function syncPlayerAccount(player)
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return nil
    end

    local phone = getPhoneNumber(player, citizenid)
    local firstName = getFirstName(player)
    local lastName = getLastName(player)
    local name = getFullName(player)
    local handle = makeHandle(name)

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_accounts (citizenid, phone, name, first_name, last_name, handle, updated_at) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP) ON CONFLICT(citizenid) DO UPDATE SET phone = excluded.phone, name = excluded.name, first_name = excluded.first_name, last_name = excluded.last_name, handle = excluded.handle, updated_at = CURRENT_TIMESTAMP', { citizenid, phone, name, firstName, lastName, handle })

    if phone ~= citizenid then
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE OR IGNORE phone_messages SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE OR IGNORE player_contacts SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE OR IGNORE player_mails SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE OR IGNORE phone_gallery SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE OR IGNORE phone_call_history SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE OR IGNORE phone_calendar_events SET citizenid = ? WHERE citizenid = ?', { citizenid, phone })
    end

    return citizenid
end

local function getKnownAccountByPhone(number)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid, phone, name, handle FROM phone_accounts WHERE phone = ? LIMIT 1', { number }) or {}
    return rows[1]
end

local function getOwnerKeyForPhone(number)
    local target = exports['qb-core']:GetPlayerByPhone(number)
    if target then
        return getCitizenIdFromPlayer(target), getFullName(target)
    end

    local account = getKnownAccountByPhone(number)
    if account then
        return account.citizenid, account.name
    end

    return number, number
end

local function decodeJsonArray(value)
    if not value or value == '' then
        return {}
    end
    local ok, decoded = pcall(JSON.parse, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end
    return {}
end

local function dbBool(value)
    return value == true or value == 1 or value == '1' or value == 'true'
end

local function displayTime(value)
    if not value or value == '' then
        return os.date('%H:%M')
    end
    local h, m = string.match(tostring(value), '(%d%d):(%d%d):%d%d')
    if h and m then
        return h .. ':' .. m
    end
    h, m = string.match(tostring(value), '(%d%d):(%d%d)')
    if h and m then
        return h .. ':' .. m
    end
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
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT name, number, image FROM player_contacts WHERE citizenid = ? OR citizenid = ? ORDER BY rowid DESC', { citizenid, phone or citizenid }) or {}
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
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT number, display_name, image, messages FROM phone_messages WHERE citizenid = ? OR citizenid = ? ORDER BY updated_at DESC, rowid DESC', { citizenid, phone }) or {}

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
    if not ownerKey or ownerKey == '' or not otherNumber or otherNumber == '' then
        return
    end
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_messages WHERE citizenid = ? AND number = ?', { ownerKey, otherNumber })
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_messages (citizenid, number, display_name, image, messages, updated_at) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)', { ownerKey, otherNumber, displayName or otherNumber, image or '', JSON.stringify(messageList or {}) })
end

local function appendConversationMessage(ownerKey, otherNumber, displayName, image, message)
    if not ownerKey or ownerKey == '' then
        return
    end
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT messages FROM phone_messages WHERE citizenid = ? AND number = ? LIMIT 1', { ownerKey, otherNumber }) or {}
    local messageList = rows[1] and decodeJsonArray(rows[1].messages or rows[1].Messages) or {}
    table.insert(messageList, message)
    saveConversationMessages(ownerKey, otherNumber, displayName, image, messageList)
end

local function loadCallHistory(citizenid, phone)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT name, number, type, missed, time, created_at FROM phone_call_history WHERE citizenid = ? OR citizenid = ? ORDER BY rowid DESC LIMIT 100', { citizenid, phone }) or {}

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
    if not ownerKey or ownerKey == '' then
        return
    end
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_call_history (citizenid, name, number, type, missed, time) VALUES (?, ?, ?, ?, ?, ?)', { ownerKey, name or number or '', number or '', callType or '', missed and 1 or 0, time or os.date('%H:%M') })
end

local function loadEmails(citizenid, phone)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT rowid AS row_id, id, mailid, sender, sender_number, subject, message, read, starred, date FROM player_mails WHERE citizenid = ? OR citizenid = ? ORDER BY rowid DESC LIMIT 100', { citizenid, phone }) or {}

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
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT id, year, month, day, title, event_time, detail FROM phone_calendar_events WHERE citizenid = ? OR citizenid = ? ORDER BY created_at ASC', { citizenid, phone }) or {}

    local result = {}
    for _, row in ipairs(rows) do
        local year = tonumber(row.year or row.Year) or 0
        local month = tonumber(row.month or row.Month) or 0
        local day = tonumber(row.day or row.Day) or 1
        local yearKey = tostring(year)
        local monthKey = tostring(month)
        local dayKey = tostring(day)
        ensureTable(result, yearKey)
        ensureTable(result[yearKey], monthKey)
        ensureTable(result[yearKey][monthKey], dayKey)
        table.insert(result[yearKey][monthKey][dayKey], {
            id = row.id or row.Id,
            title = row.title or row.Title or '',
            time = row.event_time or row.Event_time or row.EventTime or '',
            detail = row.detail or row.Detail or '',
        })
    end
    return result
end

local function sendCalendarEvents(player, citizenid, phone)
    TriggerClientEvent(player.PlayerData.source, 'qb-phone:client:calendarEventsLoaded', JSON.stringify(loadCalendarEvents(citizenid, phone)))
end

local function loadPhotos(citizenid, phone)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT rowid AS id, image, date FROM phone_gallery WHERE citizenid = ? OR citizenid = ? ORDER BY rowid DESC LIMIT 200', { citizenid, phone }) or {}

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

local function buildPhotoPayloadForPlayer(player)
    if not player then
        return '[]'
    end

    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return '[]'
    end
    local phone = getPhoneNumber(player, citizenid)
    return JSON.stringify(loadPhotos(citizenid, phone))
end

local function buildFeedForPhone(phone, viewerCitizenId)
    local reactionRows = exports['qb-core']:DatabaseAction('Select', 'SELECT tweet_id, citizenid, type FROM phone_tweet_reactions', {}) or {}
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

    local commentRows = exports['qb-core']:DatabaseAction('Select', 'SELECT id, tweet_id, firstName, lastName, handle, message, date FROM phone_tweet_comments ORDER BY date ASC', {}) or {}
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

    local tweetRows = exports['qb-core']:DatabaseAction('Select', 'SELECT rowid AS row_id, tweetId, citizenid, firstName, lastName, handle, message, url, date FROM phone_tweets ORDER BY date DESC, rowid DESC', {}) or {}

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

local function buildUsersForPhone(viewerPhone, viewerCitizenId)
    local users = {}
    local accounts = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid, phone, name, handle, bio FROM phone_accounts', {}) or {}
    local followsRows = exports['qb-core']:DatabaseAction('Select', 'SELECT follower_citizenid, target_citizenid, target_name, target_handle FROM phone_tweet_follows', {}) or {}

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

    -- Expose profiles for authors who posted before ever opening this phone.
    local tweetAuthors = exports['qb-core']:DatabaseAction('Select', 'SELECT DISTINCT citizenid, firstName, lastName, handle FROM phone_tweets', {}) or {}
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

do
    local cols = exports['qb-core']:DatabaseAction('Select', 'PRAGMA table_info(phone_calendar_events)', {}) or {}
    local hasYear = false
    for _, col in ipairs(cols) do
        if (col.name or '') == 'year' then
            hasYear = true
            break
        end
    end
    if not hasYear then
        exports['qb-core']:DatabaseAction('Execute', 'ALTER TABLE phone_calendar_events ADD COLUMN year INTEGER DEFAULT 0', {})
    end
end

RegisterServerEvent('qb-phone:server:dial', function(source, targetNumber)
    local caller = getPlayer(source)
    if not caller then
        return
    end

    local target = exports['qb-core']:GetPlayerByPhone(targetNumber)
    if not target then
        TriggerClientEvent(caller.PlayerData.source, 'qb-phone:client:callFailed', 'unavailable')
        return
    end

    local callerIntSrc = caller.PlayerData.source
    local targetIntSrc = target.PlayerData.source

    if targetIntSrc == callerIntSrc then
        return
    end

    if pendingCalls[targetIntSrc] then
        TriggerClientEvent(callerIntSrc, 'qb-phone:client:callFailed', 'busy')
        return
    end

    local callerName = getFullName(caller)
    local callerNumber = caller.PlayerData.charinfo.phone
    local targetName = getFullName(target)

    pendingCalls[targetIntSrc] = {
        callerSrc = source,
        callerIntSrc = callerIntSrc,
        channel = genChannel(),
        callerName = callerName,
        callerNumber = callerNumber,
        targetNumber = targetNumber,
    }

    TriggerClientEvent(targetIntSrc, 'qb-phone:client:incomingCall', callerName, callerNumber)
    TriggerClientEvent(callerIntSrc, 'qb-phone:client:callRinging', targetName, targetNumber)
end)

RegisterServerEvent('qb-phone:server:accept', function(source)
    local player = getPlayer(source)
    if not player then
        return
    end

    local targetIntSrc = player.PlayerData.source
    local pending = pendingCalls[targetIntSrc]
    if not pending then
        return
    end

    pendingCalls[targetIntSrc] = nil

    activeCalls[pending.channel] = {
        callerSrc = pending.callerSrc,
        targetSrc = source,
        callerIntSrc = pending.callerIntSrc,
        targetIntSrc = targetIntSrc,
    }

    local callerTalker = GetVoipTalker(pending.callerSrc)
    local targetTalker = GetVoipTalker(source)
    if callerTalker then
        callerTalker:SetVoiceChannel(pending.channel, true)
    end
    if targetTalker then
        targetTalker:SetVoiceChannel(pending.channel, true)
    end

    TriggerClientEvent(pending.callerIntSrc, 'qb-phone:client:callStarted', pending.channel)
    TriggerClientEvent(targetIntSrc, 'qb-phone:client:callStarted', pending.channel)
end)

RegisterServerEvent('qb-phone:server:hangup', function(source)
    local player = getPlayer(source)
    if not player then
        return
    end

    local intSrc = player.PlayerData.source
    local time = os.date('%H:%M')

    for channel, call in pairs(activeCalls) do
        if call.callerIntSrc == intSrc or call.targetIntSrc == intSrc then
            activeCalls[channel] = nil
            local callerTalker = GetVoipTalker(call.callerSrc)
            local targetTalker = GetVoipTalker(call.targetSrc)
            if callerTalker then
                callerTalker:SetVoiceChannel(channel, false)
            end
            if targetTalker then
                targetTalker:SetVoiceChannel(channel, false)
            end
            TriggerClientEvent(call.callerIntSrc, 'qb-phone:client:callEnded')
            TriggerClientEvent(call.targetIntSrc, 'qb-phone:client:callEnded')

            local callerPlayer = getPlayer(call.callerSrc)
            local targetPlayer = getPlayer(call.targetSrc)
            if callerPlayer and targetPlayer then
                local callerPhone = callerPlayer.PlayerData.charinfo.phone
                local targetPhone = targetPlayer.PlayerData.charinfo.phone
                local callerName = getFullName(callerPlayer)
                local targetName = getFullName(targetPlayer)
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
                local callerName = getFullName(callerPlayer)
                local targetName = getFullName(targetPlayer)
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

RegisterServerEvent('qb-phone:server:givePhone', function(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end
    HInventory.GiveAndEquipItemByName(pawn, 'ID_Misc_Phone')
end)

RegisterServerEvent('qb-phone:server:takePhone', function(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end
    HInventory.RemoveItemByName(pawn, 'ID_Misc_Phone', 1)
end)

RegisterCallback('qb-phone:loadCoreData', function(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end
    local citizenid = syncPlayerAccount(player)
    if not citizenid then
        return nil
    end
    local phone = getPhoneNumber(player, citizenid)
    local contactList = loadContacts(citizenid, phone)
    return {
        contacts = JSON.stringify(contactList),
        conversations = JSON.stringify(loadConversations(citizenid, phone, contactList)),
        callHistory = JSON.stringify(loadCallHistory(citizenid, phone)),
        playerName = getFullName(player),
        phoneNumber = tostring(phone),
        citizenid = tostring(citizenid),
        accountNumber = tostring(getAccountNumber(player)),
    }
end)

RegisterCallback('qb-phone:loadFeed', function(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return nil
    end
    return {
        feed = JSON.stringify(buildFeedForPhone(phone, citizenid)),
        users = JSON.stringify(buildUsersForPhone(phone, citizenid)),
    }
end)

RegisterCallback('qb-phone:loadEmails', function(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return nil
    end
    return {
        emails = JSON.stringify(loadEmails(citizenid, phone)),
    }
end)

RegisterCallback('qb-phone:loadPhotos', function(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end
    return {
        photos = buildPhotoPayloadForPlayer(player),
    }
end)

RegisterServerEvent('qb-phone:server:requestPhotos', function(source)
    local player = getPlayer(source)
    if not player then
        return
    end
    TriggerClientEvent(source, 'qb-phone:client:photosLoaded', buildPhotoPayloadForPlayer(player))
end)

RegisterCallback('qb-phone:loadProfile', function(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end
    local citizenid = syncPlayerAccount(player)
    if not citizenid then
        return nil
    end
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT name, phone FROM phone_accounts WHERE citizenid = ? LIMIT 1', { citizenid }) or {}
    local account = rows[1]
    local name = nonEmpty(account and (account.name or account.Name)) or getFullName(player)
    local phone = nonEmpty(account and (account.phone or account.Phone)) or getPhoneNumber(player, citizenid)
    return {
        name = tostring(name),
        phone = tostring(phone),
        citizenid = tostring(citizenid),
        account = tostring(getAccountNumber(player)),
    }
end)

RegisterServerEvent('qb-phone:server:deleteConversation', function(source, targetNumber)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    messages[pairKey(phone, targetNumber)] = nil
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_messages WHERE citizenid = ? AND number = ?', { citizenid, targetNumber })
    if phone ~= citizenid then
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_messages WHERE citizenid = ? AND number = ?', { phone, targetNumber })
    end
end)

RegisterServerEvent('qb-phone:server:sendMessage', function(source, targetNumber, text)
    local sender = getPlayer(source)
    if not sender then
        return
    end

    local senderName = getFullName(sender)
    local senderNumber = sender.PlayerData.charinfo.phone
    local senderCitizenId = getCitizenIdFromPlayer(sender)
    local time = os.date('%H:%M')
    local key = pairKey(senderNumber, targetNumber)

    ensureTable(messages, key)
    local msg = {
        id = genId(),
        senderNumber = senderNumber,
        senderName = senderName,
        text = text,
        time = time,
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

RegisterServerEvent('qb-phone:server:saveContact', function(source, name, number, image)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    ensureTable(contacts, phone)
    for i, c in ipairs(contacts[phone]) do
        if c.number == number then
            contacts[phone][i] = { name = name, number = number, image = image }
            exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { citizenid, number })
            if phone ~= citizenid then
                exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { phone, number })
            end
            exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_contacts (citizenid, name, number, image, iban) VALUES (?, ?, ?, ?, \'0\')', { citizenid, name, number, image or '' })
            return
        end
    end
    table.insert(contacts[phone], { name = name, number = number, image = image })
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { citizenid, number })
    if phone ~= citizenid then
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { phone, number })
    end
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_contacts (citizenid, name, number, image, iban) VALUES (?, ?, ?, ?, \'0\')', { citizenid, name, number, image or '' })
end)

RegisterServerEvent('qb-phone:server:deleteContact', function(source, number)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    if contacts[phone] then
        for i, c in ipairs(contacts[phone]) do
            if c.number == number then
                table.remove(contacts[phone], i)
                break
            end
        end
    end
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { citizenid, number })
    if phone ~= citizenid then
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_contacts WHERE citizenid = ? AND number = ?', { phone, number })
    end
end)

local _recentPostCreates = {}

RegisterServerEvent('qb-phone:server:createPost', function(source, content, image)
    local player = getPlayer(source)
    if not player then
        return
    end

    local authorName = getFullName(player)
    local authorNumber = player.PlayerData.charinfo.phone
    local authorCitizenId = getCitizenIdFromPlayer(player)
    if not authorCitizenId then
        return
    end
    local dedupeKey = authorCitizenId .. '|' .. (content or '') .. '|' .. (image or '')
    local now = os.time()
    if _recentPostCreates[dedupeKey] and now - _recentPostCreates[dedupeKey] < 5 then
        return
    end
    _recentPostCreates[dedupeKey] = now
    local firstName = getFirstName(player)
    local lastName = getLastName(player)
    local handle = makeHandle(authorName)
    local time = os.date('%H:%M')
    local postId = genId()

    local post = {
        id = postId,
        authorName = authorName,
        authorNumber = authorNumber,
        handle = handle,
        content = content,
        image = image or '',
        time = time,
    }
    table.insert(posts, 1, post)
    likes[postId] = {}
    reposts[postId] = {}
    comments[postId] = {}

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_tweets (citizenid, firstName, lastName, handle, message, url, picture, tweetId) VALUES (?, ?, ?, ?, ?, ?, \'./img/default.png\', ?)', { authorCitizenId, firstName, lastName, handle, content, image or '', tostring(postId) })

    local payload = {
        id = postId,
        author = authorName,
        handle = handle,
        content = content,
        image = image or '',
        time = time,
        likes = 0,
        liked = false,
        reposts = 0,
        reposted = false,
        comments = {},
    }
    BroadcastEvent('qb-phone:client:postReceived', JSON.stringify(payload))
end)

RegisterServerEvent('qb-phone:server:deletePost', function(source, postId)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    for i, post in ipairs(posts) do
        if post.id == postId and post.authorNumber == phone then
            table.remove(posts, i)
            likes[postId] = nil
            reposts[postId] = nil
            comments[postId] = nil
            exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_reactions WHERE tweet_id = ?', { tostring(postId) })
            exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_comments WHERE tweet_id = ?', { tostring(postId) })
            exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweets WHERE tweetId = ? AND citizenid = ?', { tostring(postId), citizenid })
            BroadcastEvent('qb-phone:client:postDeleted', postId)
            return
        end
    end

    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid FROM phone_tweets WHERE tweetId = ? LIMIT 1', { tostring(postId) }) or {}
    if rows[1] and rows[1].citizenid == citizenid then
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_reactions WHERE tweet_id = ?', { tostring(postId) })
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_comments WHERE tweet_id = ?', { tostring(postId) })
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweets WHERE tweetId = ?', { tostring(postId) })
        BroadcastEvent('qb-phone:client:postDeleted', postId)
    end
end)

RegisterServerEvent('qb-phone:server:likePost', function(source, postId, liked)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    ensureTable(likes, postId)
    if liked then
        likes[postId][phone] = true
    else
        likes[postId][phone] = nil
    end
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_reactions WHERE tweet_id = ? AND citizenid = ? AND type = ?', { tostring(postId), citizenid, 'like' })
    if liked then
        exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_tweet_reactions (tweet_id, citizenid, type) VALUES (?, ?, ?)', { tostring(postId), citizenid, 'like' })
    end
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid FROM phone_tweet_reactions WHERE tweet_id = ? AND type = ?', { tostring(postId), 'like' }) or {}
    BroadcastEvent('qb-phone:client:postLikeUpdated', postId, #rows)
end)

RegisterServerEvent('qb-phone:server:repostPost', function(source, postId, reposted)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    ensureTable(reposts, postId)
    if reposted then
        reposts[postId][phone] = true
    else
        reposts[postId][phone] = nil
    end
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_reactions WHERE tweet_id = ? AND citizenid = ? AND type = ?', { tostring(postId), citizenid, 'repost' })
    if reposted then
        exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_tweet_reactions (tweet_id, citizenid, type) VALUES (?, ?, ?)', { tostring(postId), citizenid, 'repost' })
    end
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid FROM phone_tweet_reactions WHERE tweet_id = ? AND type = ?', { tostring(postId), 'repost' }) or {}
    BroadcastEvent('qb-phone:client:postRepostUpdated', postId, #rows)
end)

RegisterServerEvent('qb-phone:server:followUser', function(source, handle, following, targetPhone)
    local follower = getPlayer(source)
    if not follower then
        return
    end

    local followerName = getFullName(follower)
    local followerNumber = follower.PlayerData.charinfo.phone
    local followerCitizenId = getCitizenIdFromPlayer(follower)
    if not followerCitizenId then
        return
    end
    local targetCitizenId = ''
    local targetHandle = ''
    local targetName = handle or ''

    if targetPhone and targetPhone ~= '' then
        local target = exports['qb-core']:GetPlayerByPhone(targetPhone)
        if target then
            targetCitizenId = getCitizenIdFromPlayer(target) or ''
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
        exports['qb-core']:DatabaseAction('Execute', 'INSERT OR REPLACE INTO phone_tweet_follows (follower_citizenid, target_citizenid, target_name, target_handle, target_phone) VALUES (?, ?, ?, ?, ?)', { followerCitizenId, targetCitizenId, targetName, targetHandle, targetPhone or '' })
    else
        follows[followerNumber][targetName] = nil
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_tweet_follows WHERE follower_citizenid = ? AND target_name = ?', { followerCitizenId, targetName })
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
    if not player then
        return
    end

    local authorName = getFullName(player)
    local authorNumber = player.PlayerData.charinfo.phone
    local authorCitizenId = getCitizenIdFromPlayer(player)
    if not authorCitizenId then
        return
    end
    local firstName = getFirstName(player)
    local lastName = getLastName(player)
    local handle = makeHandle(authorName)
    local time = os.date('%H:%M')
    local comment = {
        id = genId(),
        authorName = authorName,
        authorNumber = authorNumber,
        handle = handle,
        text = text,
        time = time,
    }
    ensureTable(comments, postId)
    table.insert(comments[postId], comment)

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_tweet_comments (id, tweet_id, citizenid, firstName, lastName, handle, message) VALUES (?, ?, ?, ?, ?, ?, ?)', { tostring(comment.id), tostring(postId), authorCitizenId, firstName, lastName, handle, text })

    local payload = { id = comment.id, author = authorName, handle = handle, text = text, time = time }
    BroadcastEvent('qb-phone:client:commentAdded', postId, JSON.stringify(payload))
end)

RegisterServerEvent('qb-phone:server:sendEmail', function(source, toNumber, subject, body)
    local sender = getPlayer(source)
    if not sender then
        return
    end

    local senderName = getFullName(sender)
    local senderNumber = sender.PlayerData.charinfo.phone
    getCitizenIdFromPlayer(sender)
    local time = os.date('%H:%M')
    local recipientCitizenId = getOwnerKeyForPhone(toNumber)
    local emailId = genId()

    ensureTable(emails, toNumber)
    local email = {
        id = emailId,
        from = senderName,
        fromNumber = senderNumber,
        subject = subject,
        snippet = string.sub(body, 1, 80),
        body = body,
        time = time,
        read = false,
        starred = false,
    }
    table.insert(emails[toNumber], 1, email)

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_mails (citizenid, sender, sender_number, subject, message, read, starred, mailid) VALUES (?, ?, ?, ?, ?, 0, 0, ?)', { recipientCitizenId, senderName, senderNumber, subject, body, tostring(emailId) })

    local target = exports['qb-core']:GetPlayerByPhone(toNumber)
    if target then
        TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:emailReceived', JSON.stringify(email))
    end
end)

RegisterServerEvent('qb-phone:server:deleteEmail', function(source, emailId)
    local player = getPlayer(source)
    if not player then
        return
    end
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_mails WHERE mailid = ? AND citizenid = ?', { tostring(emailId), citizenid })
end)

RegisterServerEvent('qb-phone:server:loadCalendar', function(source)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    sendCalendarEvents(player, citizenid, phone)
end)

RegisterServerEvent('qb-phone:server:saveCalendarEvent', function(source, year, month, day, title, time, detail)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_calendar_events (citizenid, year, month, day, title, event_time, detail) VALUES (?, ?, ?, ?, ?, ?, ?)', { citizenid, tonumber(year) or 0, tonumber(month) or 0, tonumber(day) or 1, title, time, detail })
    sendCalendarEvents(player, citizenid, phone)
end)

RegisterServerEvent('qb-phone:server:deleteCalendarEvent', function(source, eventId)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_calendar_events WHERE id = ? AND citizenid = ?', { tonumber(eventId), citizenid })
    sendCalendarEvents(player, citizenid, phone)
end)

local _recentPhotoSaves = {}

RegisterServerEvent('qb-phone:server:savePhoto', function(source, url)
    if not url or url == '' then
        return
    end
    local player = getPlayer(source)
    if not player then
        return
    end
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end
    local dedupeKey = citizenid .. '|' .. url
    local now = os.time()
    if _recentPhotoSaves[dedupeKey] and now - _recentPhotoSaves[dedupeKey] < 5 then
        return
    end
    _recentPhotoSaves[dedupeKey] = now
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO phone_gallery (citizenid, image) VALUES (?, ?)', { citizenid, url })
end)

RegisterServerEvent('qb-phone:server:uploadPhoto', function(source, filePath)
    if not filePath or filePath == '' or PHOTO_WEBHOOK == '' then
        TriggerClientEvent(source, 'qb-phone:client:photoUploaded', nil)
        return
    end

    -- TODO: replace with HELIX server HTTP call
    -- local file = io.open(filePath, 'rb')
    -- if not file then TriggerClientEvent(source, 'qb-phone:client:photoUploaded', nil); return end
    -- local data = file:read('*all'); file:close()
    -- local boundary = 'HELIXphoto' .. tostring(os.time())
    -- local filename = filePath:match('[^\\/]+$') or 'photo.png'
    -- local body = '--' .. boundary .. '\r\n'
    --     .. 'Content-Disposition: form-data; name="file"; filename="' .. filename .. '"\r\n'
    --     .. 'Content-Type: image/png\r\n\r\n'
    --     .. data .. '\r\n--' .. boundary .. '--\r\n'
    -- HTTP.Post(PHOTO_WEBHOOK, body, 'multipart/form-data; boundary=' .. boundary, function(status, responseBody)
    --     local ok, parsed = pcall(JSON.parse, responseBody)
    --     local url = ok and parsed and parsed.attachments and parsed.attachments[1] and parsed.attachments[1].url
    --     TriggerClientEvent(source, 'qb-phone:client:photoUploaded', url)
    -- end)
    TriggerClientEvent(source, 'qb-phone:client:photoUploaded', nil)
end)

RegisterServerEvent('qb-phone:server:sendMoney', function(source, targetNumber, amount)
    local sender = getPlayer(source)
    if not sender then
        return
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        TriggerClientEvent(source, 'qb-phone:client:moneyTransferResult', false, 'Invalid amount')
        return
    end

    if sender.PlayerData.money.bank < amount then
        TriggerClientEvent(source, 'qb-phone:client:moneyTransferResult', false, 'Insufficient funds')
        return
    end

    local target = exports['qb-core']:GetPlayerByPhone(tostring(targetNumber))
    if not target then
        TriggerClientEvent(source, 'qb-phone:client:moneyTransferResult', false, 'Recipient is unavailable')
        return
    end

    sender.RemoveMoney('bank', amount, 'Phone transfer')
    target.AddMoney('bank', amount, 'Phone transfer')

    local senderPhone = sender.PlayerData.charinfo.phone
    exports['qb-banking']:CreateBankStatement(source, 'checking', amount, 'Phone transfer to ' .. tostring(targetNumber), 'withdraw', 'player')
    exports['qb-banking']:CreateBankStatement(target.PlayerData.source, 'checking', amount, 'Phone transfer from ' .. senderPhone, 'deposit', 'player')

    local senderName = getFullName(sender)
    local senderCitizenId = getCitizenIdFromPlayer(sender)
    local targetCitizenId = syncPlayerAccount(target)
    local time = os.date('%H:%M')
    local key = pairKey(senderPhone, tostring(targetNumber))
    local text = '[PAYMENT:' .. amount .. ']'

    ensureTable(messages, key)
    local msg = { id = genId(), senderNumber = senderPhone, senderName = senderName, text = text, time = time }
    table.insert(messages[key], msg)

    appendConversationMessage(senderCitizenId, targetNumber, tostring(targetNumber), '', { id = msg.id, sender = 'me', text = text, time = time })
    appendConversationMessage(targetCitizenId, senderPhone, senderName, '', { id = msg.id, sender = 'them', text = text, time = time })

    TriggerClientEvent(target.PlayerData.source, 'qb-phone:client:messageReceived', senderName, senderPhone, text, time)
    TriggerClientEvent(source, 'qb-phone:client:moneyTransferResult', true, amount)
end)

RegisterServerEvent('qb-phone:server:deletePhoto', function(source, photoId)
    local player = getPlayer(source)
    if not player then
        return
    end
    local phone = player.PlayerData.charinfo.phone
    local citizenid = getCitizenIdFromPlayer(player)
    if not citizenid then
        return
    end

    if photos[phone] then
        for i, p in ipairs(photos[phone]) do
            if p.id == photoId then
                table.remove(photos[phone], i)
                break
            end
        end
    end

    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM phone_gallery WHERE citizenid = ? AND rowid = ?', { citizenid, photoId })
end)
