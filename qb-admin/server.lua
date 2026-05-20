local resourceStartTime = os.time()
local CurrentTime = Config.Weather.StartingTime
local CurrentWeather = Config.Weather.StartingWeather
local jobsShared = exports['qb-core']:GetShared('Jobs')
local gangsShared = exports['qb-core']:GetShared('Gangs')
local itemsShared = exports['qb-core']:GetShared('Items')
local vehiclesShared = exports['qb-core']:GetShared('Vehicles')

local reportsState = {}
local ticketsState = {}
local disciplinaryFeedState = {}
local chatMessagesState = {}
local logsHistoryState = {}

local nextReportId = 1
local nextTicketId = 1
local nextLogId = 1
local nextChatMessageId = 1

local function formatClockTime(ts)
    return os.date('%H:%M', ts or os.time())
end

local function pushFeedEntry(message)
    if type(message) ~= 'string' or message == '' then
        return
    end

    table.insert(disciplinaryFeedState, 1, message)
    if #disciplinaryFeedState > 30 then
        table.remove(disciplinaryFeedState)
    end
end

local function pushLogEntry(action, target, details)
    table.insert(logsHistoryState, 1, {
        id = nextLogId,
        time = formatClockTime(),
        actor = 'System',
        action = action,
        target = target,
        details = details,
    })

    nextLogId = nextLogId + 1

    if #logsHistoryState > 200 then
        table.remove(logsHistoryState)
    end
end

local function pushChatMessage(entry)
    table.insert(chatMessagesState, entry)
    if #chatMessagesState > 300 then
        table.remove(chatMessagesState, 1)
    end
end

local function TeleportToInterior(player, x, y, z)
    local ped = GetPlayerPawn(player)
    if not ped then
        return
    end

    SetEntityCoords(ped, Vector(x, y, z))
end

local function resolveTeleportLocationByKey(locationKey)
    local key = tostring(locationKey or '')
    if key == '' then
        return nil
    end

    local locations = (Config and type(Config.Locations) == 'table') and Config.Locations or {}
    local directMatch = locations[key]
    if type(directMatch) == 'table' then
        return directMatch
    end

    for configKey, entry in pairs(locations) do
        if type(entry) == 'table' then
            local entryKey = tostring(entry.key or configKey)
            if entryKey == key then
                return entry
            end
        end
    end

    return nil
end

local function getLocationCoordinates(entry)
    if type(entry) ~= 'table' then
        return nil, nil, nil
    end

    local coords = entry.coords
    local x = tonumber((coords and (coords.X or coords.x)) or entry.x)
    local y = tonumber((coords and (coords.Y or coords.y)) or entry.y)
    local z = tonumber((coords and (coords.Z or coords.z)) or entry.z)

    return x, y, z
end

local function buildTeleportLocationOptions()
    local options = {}
    local locations = (Config and type(Config.Locations) == 'table') and Config.Locations or {}

    for configKey, entry in pairs(locations) do
        if type(entry) == 'table' then
            local key = tostring(entry.key or configKey)
            local x, y, z = getLocationCoordinates(entry)
            options[#options + 1] = {
                key = key,
                name = entry.name or key,
                x = x or 0.0,
                y = y or 0.0,
                z = z or 0.0,
            }
        end
    end

    table.sort(options, function(a, b)
        return a.name < b.name
    end)

    return options
end

local function getQBPlayers()
    local ok, players = pcall(function()
        return exports['qb-core']:GetPlayers()
    end)

    if ok and type(players) == 'table' then
        return players
    end

    return {}
end

local function formatUptime(seconds)
    local total = math.max(0, math.floor(seconds or 0))
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    return ('%dh %02dm'):format(hours, minutes)
end

local function normalizeGrades(grades)
    local normalized = {}

    for gradeLevel, gradeData in pairs(grades or {}) do
        local level = tonumber(gradeLevel) or 0
        normalized[#normalized + 1] = {
            level = level,
            name = gradeData.name or tostring(level),
            payment = tonumber(gradeData.payment) or 0,
            isboss = gradeData.isboss == true,
        }
    end

    table.sort(normalized, function(a, b)
        return a.level < b.level
    end)

    return normalized
end

local function buildJobsCatalog(jobsShared)
    local jobsCatalog = {}

    for key, entry in pairs(jobsShared or {}) do
        jobsCatalog[#jobsCatalog + 1] = {
            key = key,
            label = entry.label or key,
            type = entry.type,
            defaultDuty = entry.defaultDuty == true,
            offDutyPay = entry.offDutyPay == true,
            grades = normalizeGrades(entry.grades),
        }
    end

    table.sort(jobsCatalog, function(a, b)
        return a.label < b.label
    end)

    return jobsCatalog
end

local function buildGangsCatalog(gangsShared)
    local gangsCatalog = {}

    for key, entry in pairs(gangsShared or {}) do
        gangsCatalog[#gangsCatalog + 1] = {
            key = key,
            label = entry.label or key,
            grades = normalizeGrades(entry.grades),
        }
    end

    table.sort(gangsCatalog, function(a, b)
        return a.label < b.label
    end)

    return gangsCatalog
end

local function buildItemsCatalog(itemsShared)
    local itemsCatalog = {}

    for key, entry in pairs(itemsShared or {}) do
        itemsCatalog[#itemsCatalog + 1] = {
            name = key,
            label = entry.label or key,
            weight = tonumber(entry.weight) or 0,
            type = entry.type or 'item',
            image = entry.image or '',
            unique = entry.unique == true,
            useable = entry.useable == true,
            shouldClose = entry.shouldClose == true,
            description = entry.description or '',
        }
    end

    table.sort(itemsCatalog, function(a, b)
        return a.label < b.label
    end)

    return itemsCatalog
end

local function buildVehiclesCatalog(vehiclesShared)
    local vehiclesCatalog = {}

    for key, entry in pairs(vehiclesShared or {}) do
        vehiclesCatalog[#vehiclesCatalog + 1] = {
            key = key,
            brand = entry.brand or '',
            label = entry.name or entry.label or key,
            price = tonumber(entry.price) or 0,
        }
    end

    table.sort(vehiclesCatalog, function(a, b)
        return a.label < b.label
    end)

    return vehiclesCatalog
end

local function buildPlayerList(qbPlayers, jobsShared, gangsShared)
    local players = {}

    for i = 1, #qbPlayers do
        local playerId = qbPlayers[i]
        local player = exports['qb-core']:GetPlayer(playerId)
        local data = player.PlayerData or {}
        local charinfo = data.charinfo or {}
        local metadata = data.metadata or {}
        local money = data.money or {}
        local job = data.job or {}
        local gang = data.gang or {}

        local playerSource = tonumber(data.netId) or 0
        local firstName = charinfo.firstname or ''
        local lastName = charinfo.lastname or ''
        local characterName = (firstName .. ' ' .. lastName):gsub('^%s+', ''):gsub('%s+$', '')
        if characterName == '' then
            characterName = GetPlayerName(playerSource) or ('Player ' .. tostring(playerSource))
        end

        local jobKey = job.name
        local gangKey = gang.name
        local sharedJob = jobKey and jobsShared[jobKey] or nil
        local sharedGang = gangKey and gangsShared[gangKey] or nil

        players[#players + 1] = {
            id = playerSource,
            character = characterName,
            identifier = data.license or data.steam or data.discord or tostring(playerSource),
            citizenId = data.citizenid or '',
            phone = charinfo.phone or '',
            bankAccount = charinfo.account or '',
            isOnline = true,
            currentJob = {
                name = sharedJob and sharedJob.label or (jobKey or 'Unknown'),
                grade = tonumber(job.grade and (job.grade.level or job.grade)) or 0,
            },
            currentGang = {
                name = sharedGang and sharedGang.label or (gangKey or 'None'),
                grade = tonumber(gang.grade and (gang.grade.level or gang.grade)) or 0,
            },
            currentVehicle = nil,
            financials = {
                cash = tonumber(money.cash) or 0,
                bank = tonumber(money.bank) or 0,
                crypto = tonumber(money.crypto) or 0,
            },
            vitals = {
                health = tonumber(metadata.health) or 100,
                armor = tonumber(metadata.armor) or 0,
                hunger = tonumber(metadata.hunger) or 100,
                thirst = tonumber(metadata.thirst) or 100,
            },
        }
    end

    table.sort(players, function(a, b)
        return a.id < b.id
    end)

    return players
end

local function buildOpenAdminContext(src)
    local qbPlayers = getQBPlayers()

    local players = buildPlayerList(qbPlayers, jobsShared, gangsShared)
    local playersOnline = #players
    local serverUptime = formatUptime(os.time() - resourceStartTime)
    local ping = GetPlayerPing(src) or 0
    local adminName = GetPlayerName(src)
    local adminPlayer = exports['qb-core']:GetPlayer(src)
    local adminNetId = (adminPlayer and tonumber(adminPlayer.PlayerData.netId)) or 0

    local jobsCatalog = buildJobsCatalog(jobsShared)
    local gangsCatalog = buildGangsCatalog(gangsShared)
    local itemsCatalog = buildItemsCatalog(itemsShared)
    local vehiclesCatalog = buildVehiclesCatalog(vehiclesShared)

    local jobOptions = {}
    for _, job in ipairs(jobsCatalog) do
        jobOptions[#jobOptions + 1] = { name = job.label }
    end

    local gangOptions = {}
    for _, gang in ipairs(gangsCatalog) do
        gangOptions[#gangOptions + 1] = { name = gang.label }
    end

    local itemOptions = {}
    for i = 1, math.min(#itemsCatalog, 200) do
        itemOptions[#itemOptions + 1] = { name = itemsCatalog[i].label }
    end

    local spawnVehicleOptions = {}
    for i = 1, math.min(#vehiclesCatalog, 200) do
        spawnVehicleOptions[#spawnVehicleOptions + 1] = {
            name = vehiclesCatalog[i].label,
            model = vehiclesCatalog[i].key,
        }
    end

    local leaderboardPlayers = {}
    for _, player in ipairs(players) do
        leaderboardPlayers[#leaderboardPlayers + 1] = {
            name = player.character,
            cash = player.financials.cash,
            bank = player.financials.bank,
            crypto = player.financials.crypto,
        }
    end

    return {
        page = 'dashboard',
        currentAdminName = adminName,

        stats = {
            { label = 'Players Online', value = tostring(playersOnline) },
            { label = 'Server Uptime',  value = serverUptime },
            { label = 'Server Ping',    value = tostring(ping) .. 'ms' },
        },
        disciplinaryFeed = disciplinaryFeedState,
        reports = reportsState,
        tickets = ticketsState,
        players = players,
        selectedPlayerId = adminNetId,

        chatMessages = chatMessagesState,
        logsHistory = logsHistoryState,
        leaderboardPlayers = leaderboardPlayers,
        leaderboardMetric = 'wealth',
        nextChatMessageId = nextChatMessageId,

        currentWeather = 'ClearSkies',
        timeValue = 12,
        environmentToggles = {
            freezeWeather = false,
            freezeTime = false,
            blackout = false,
            disableTraffic = false,
            disableAmbientPeds = false,
        },

        itemsCatalog = itemsCatalog,
        vehiclesCatalog = vehiclesCatalog,
        jobsCatalog = jobsCatalog,
        gangsCatalog = gangsCatalog,
        jobOptions = jobOptions,
        gangOptions = gangOptions,
        itemOptions = itemOptions,

        teleportLocationOptions = buildTeleportLocationOptions(),
        spawnVehicleOptions = spawnVehicleOptions,
        spawnObjectOptions = {},
        currentCoordinates = 0,
        currentRotation = 0,
        currentHeading = 0,
    }
end

local function getSourceByPlayerId(targetId)
    local targetNum = tonumber(targetId)
    if not targetNum then return nil end
    local qbPlayers = getQBPlayers()
    for _, src in ipairs(qbPlayers) do
        local player = exports['qb-core']:GetPlayer(src)
        if player and tonumber(player.PlayerData.netId) == targetNum then
            return src
        end
    end
    return nil
end

local function findJobKey(nameOrKey)
    local lower = tostring(nameOrKey or ''):lower()
    if lower == '' then return nil end
    for key, job in pairs(jobsShared) do
        if key:lower() == lower or (job.label and job.label:lower() == lower) then
            return key
        end
    end
    return nil
end

local function findGangKey(nameOrKey)
    local lower = tostring(nameOrKey or ''):lower()
    if lower == '' then return nil end
    for key, gang in pairs(gangsShared) do
        if key:lower() == lower or (gang.label and gang.label:lower() == lower) then
            return key
        end
    end
    return nil
end

-- Events

RegisterServerEvent('qb-admin:server:fileReport', function(source, data)
    local reportDescription = tostring(data.description or data.message or '')
    if reportDescription == '' then
        return
    end

    local playerId = GetPlayerId(source)
    local playerName = GetPlayerName(source)
    local category = tostring(data.category or 'General')
    local fullText = tostring(data.fullText or reportDescription)

    local reportNumericId = nextReportId
    nextReportId = nextReportId + 1

    local ticketNumericId = nextTicketId
    nextTicketId = nextTicketId + 1

    local reportId = tostring(reportNumericId)
    local ticketId = tostring(ticketNumericId)

    local reportEntry = {
        id = reportId,
        playerId = playerId,
        playerName = playerName,
        description = reportDescription,
        timeAgo = 'just now',
        claimed = false,
        resolved = false,
    }

    local ticketEntry = {
        id = ticketId,
        reportId = reportId,
        playerId = playerId,
        category = category,
        preview = reportDescription,
        fullText = fullText,
        ageMinutes = 0,
        ageLabel = 'just now',
        column = 'incoming',
        owner = '',
        resolution = '',
    }

    table.insert(reportsState, 1, reportEntry)
    ticketsState[ticketId] = ticketEntry

    pushFeedEntry(('Report #%s filed by %s'):format(reportId, playerName))
    pushLogEntry('Report Filed', '#' .. reportId, reportDescription)

    BroadcastEvent('qb-admin:client:reportFiled', {
        report = reportEntry,
        ticket = ticketEntry,
    })
end)

local function handleTeleportToLocation(source, data)
    local location = resolveTeleportLocationByKey(data.key)
    if type(location) ~= 'table' then
        return
    end

    local x, y, z = getLocationCoordinates(location)
    if not x or not y or not z then
        return
    end

    TeleportToInterior(source, x, y, z)
end

local function handleTeleportToCoordinates(source, data)
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if not x or not y or not z then
        return
    end

    TeleportToInterior(source, x, y, z)
end

local function handleChatSend(source, data)
    local message = tostring(data.message or '')
    if message == '' then
        return
    end

    local entry = {
        id = nextChatMessageId,
        author = GetPlayerName(source),
        message = message,
        time = formatClockTime(),
    }

    nextChatMessageId = nextChatMessageId + 1
    pushChatMessage(entry)
    pushFeedEntry(('Admin chat: %s'):format(message))
    pushLogEntry('Admin Chat', tostring(source), message)

    BroadcastEvent('qb-admin:client:chatMessage', entry)
end

RegisterServerEvent('qb-admin:server:developer:teleportToLocation', function(source, data)
    handleTeleportToLocation(source, data)
end)

RegisterServerEvent('qb-admin:server:developer:teleportToCoordinates', function(source, data)
    handleTeleportToCoordinates(source, data)
end)

RegisterServerEvent('qb-admin:server:chat:send', function(source, data)
    handleChatSend(source, data)
end)

RegisterServerEvent('qb-admin:server:developer:spawnVehicle', function(source, data)
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    local ForwardVec = playerPed:GetActorForwardVector()
    local SpawnPosition = playerCoords + (ForwardVec * 800)
    SpawnPosition = Vector(SpawnPosition.X, SpawnPosition.Y, SpawnPosition.Z - 100)
    local vehicleInfo = vehiclesShared[data.model]
    HVehicle(SpawnPosition, Rotator(0, 0, 0), vehicleInfo.asset_name)
end)

RegisterServerEvent('qb-admin:server:developer:spawnObject', function(source, _)
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    local ForwardVec = playerPed:GetActorForwardVector()
    local SpawnPosition = playerCoords + (ForwardVec * 800)
    SpawnPosition = Vector(SpawnPosition.X, SpawnPosition.Y, SpawnPosition.Z - 100)
end)

RegisterServerEvent('qb-admin:server:players:context-action', function(source, data)
    -- data = { action = 'spectate'|'quick-kick'|'bring'|'freeze'|'heal', playerId = number }
    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    local adminName = GetPlayerName(source)

    if action == 'spectate' then
        TriggerClientEvent(source, 'qb-admin:client:spectatePlayer', targetPlayerId)
        pushLogEntry('Spectate', 'Player #' .. targetPlayerId, adminName .. ' started spectating')
        pushFeedEntry(adminName .. ' spectated player #' .. targetPlayerId)
    elseif action == 'quick-kick' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetName = GetPlayerName(targetSrc)
        targetSrc:Kick('Kicked by admin')
        pushLogEntry('Quick Kick', targetName, 'Kicked by ' .. adminName)
        pushFeedEntry(adminName .. ' kicked ' .. targetName)
    elseif action == 'bring' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local adminPawn = GetPlayerPawn(source)
        if not adminPawn then return end
        local adminCoords = GetEntityCoords(adminPawn)
        local targetPawn = GetPlayerPawn(targetSrc)
        if not targetPawn then return end
        SetEntityCoords(targetPawn, Vector(adminCoords.X + 200, adminCoords.Y, adminCoords.Z))
        pushLogEntry('Bring', GetPlayerName(targetSrc), 'Brought by ' .. adminName)
        pushFeedEntry(adminName .. ' brought player #' .. targetPlayerId)
    elseif action == 'freeze' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        TriggerClientEvent(targetSrc, 'qb-admin:client:setFrozen', true)
        pushLogEntry('Freeze', GetPlayerName(targetSrc), 'Frozen by ' .. adminName)
        pushFeedEntry(adminName .. ' froze player #' .. targetPlayerId)
    elseif action == 'heal' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
        if not targetPlayer then return end
        targetPlayer.SetMetaData('hunger', 100)
        targetPlayer.SetMetaData('thirst', 100)
        targetPlayer.SetMetaData('stress', 0)
        targetPlayer.SetMetaData('isdead', false)
        TriggerClientEvent(targetSrc, 'qb-admin:client:setHealth', 100)
        pushLogEntry('Heal', GetPlayerName(targetSrc), 'Healed by ' .. adminName)
        pushFeedEntry(adminName .. ' healed player #' .. targetPlayerId)
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:vehicleAction', function(source, data)
    -- data = { action = 'repair'|'refuel'|'ownership'|'glovebox'|'trunk'|'delete', playerId = number }
    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    local adminName = GetPlayerName(source)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then return end
    local targetName = GetPlayerName(targetSrc)

    if action == 'repair' then
        TriggerClientEvent(targetSrc, 'qb-admin:client:vehicleRepair')
        pushLogEntry('Vehicle Repair', targetName, 'Repaired by ' .. adminName)
    elseif action == 'refuel' then
        TriggerClientEvent(targetSrc, 'qb-admin:client:vehicleRefuel')
        pushLogEntry('Vehicle Refuel', targetName, 'Refueled by ' .. adminName)
    elseif action == 'ownership' then
        TriggerClientEvent(source, 'qb-admin:client:openVehicleOwnership', targetPlayerId)
        pushLogEntry('Vehicle Ownership', targetName, 'Ownership viewed by ' .. adminName)
    elseif action == 'glovebox' then
        TriggerClientEvent(targetSrc, 'qb-admin:client:openVehicleGlovebox')
        pushLogEntry('Vehicle Glovebox', targetName, 'Opened by ' .. adminName)
    elseif action == 'trunk' then
        TriggerClientEvent(targetSrc, 'qb-admin:client:openVehicleTrunk')
        pushLogEntry('Vehicle Trunk', targetName, 'Opened by ' .. adminName)
    elseif action == 'delete' then
        TriggerClientEvent(targetSrc, 'qb-admin:client:vehicleDelete')
        pushLogEntry('Vehicle Delete', targetName, 'Vehicle deleted by ' .. adminName)
        pushFeedEntry(adminName .. ' deleted vehicle of ' .. targetName)
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:gangAction', function(source, data)
    -- data = { action = 'change'|'remove', playerId = number, gang = string?, grade = number? }
    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    local adminName = GetPlayerName(source)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then return end
    local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
    if not targetPlayer then return end
    local targetName = GetPlayerName(targetSrc)

    if action == 'remove' then
        targetPlayer.SetGang('none', 0)
        pushLogEntry('Gang Remove', targetName, 'Removed from gang by ' .. adminName)
        pushFeedEntry(adminName .. ' removed ' .. targetName .. ' from their gang')
    elseif action == 'change' then
        local gangName = tostring(data.gang or '')
        local gradeLevel = tonumber(data.grade) or 0
        if gangName == '' then return end
        local gangKey = findGangKey(gangName)
        if not gangKey then return end
        targetPlayer.SetGang(gangKey, gradeLevel)
        pushLogEntry('Gang Change', targetName, 'Set to ' .. gangKey .. ' grade ' .. gradeLevel .. ' by ' .. adminName)
        pushFeedEntry(adminName .. ' set ' .. targetName .. ' gang to ' .. gangName)
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:jobAction', function(source, data)
    -- data = { action = 'change'|'fire', playerId = number, job = string?, grade = number? }
    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    local adminName = GetPlayerName(source)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then return end
    local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
    if not targetPlayer then return end
    local targetName = GetPlayerName(targetSrc)

    if action == 'fire' then
        targetPlayer.SetJob('unemployed', 0)
        pushLogEntry('Job Fire', targetName, 'Fired by ' .. adminName)
        pushFeedEntry(adminName .. ' fired ' .. targetName)
    elseif action == 'change' then
        local jobName = tostring(data.job or '')
        local gradeLevel = tonumber(data.grade) or 0
        if jobName == '' then return end
        local jobKey = findJobKey(jobName)
        if not jobKey then return end
        targetPlayer.SetJob(jobKey, gradeLevel)
        pushLogEntry('Job Change', targetName, 'Set to ' .. jobKey .. ' grade ' .. gradeLevel .. ' by ' .. adminName)
        pushFeedEntry(adminName .. ' set ' .. targetName .. ' job to ' .. jobName)
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:quickControl', function(source, data)
    -- data = {
    --   action = 'teleport-to'|'bring-to-you'|'spectate'|'kick'|'ban'|'freeze'|'clothing'|'inventory'|'revive'|'kill',
    --   playerId = number
    -- }
    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    local adminName = GetPlayerName(source)

    if action == 'teleport-to' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetPawn = GetPlayerPawn(targetSrc)
        if not targetPawn then return end
        local targetCoords = GetEntityCoords(targetPawn)
        TeleportToInterior(source, targetCoords.X + 200, targetCoords.Y, targetCoords.Z)
        pushLogEntry('Teleport To', GetPlayerName(targetSrc), adminName .. ' teleported to target')
        pushFeedEntry(adminName .. ' teleported to player #' .. targetPlayerId)
    elseif action == 'bring-to-you' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local adminPawn = GetPlayerPawn(source)
        if not adminPawn then return end
        local adminCoords = GetEntityCoords(adminPawn)
        local targetPawn = GetPlayerPawn(targetSrc)
        if not targetPawn then return end
        SetEntityCoords(targetPawn, Vector(adminCoords.X + 200, adminCoords.Y, adminCoords.Z))
        pushLogEntry('Bring To You', GetPlayerName(targetSrc), 'Brought by ' .. adminName)
        pushFeedEntry(adminName .. ' brought player #' .. targetPlayerId)
    elseif action == 'spectate' then
        TriggerClientEvent(source, 'qb-admin:client:spectatePlayer', targetPlayerId)
        pushLogEntry('Spectate', 'Player #' .. targetPlayerId, adminName .. ' started spectating')
        pushFeedEntry(adminName .. ' started spectating player #' .. targetPlayerId)
    elseif action == 'kick' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetName = GetPlayerName(targetSrc)
        targetSrc:Kick('Kicked by admin')
        pushLogEntry('Kick', targetName, 'Kicked by ' .. adminName)
        pushFeedEntry(adminName .. ' kicked ' .. targetName)
    elseif action == 'ban' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetName = GetPlayerName(targetSrc)
        local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
        local citizenId = targetPlayer and targetPlayer.PlayerData.citizenid or 'unknown'
        TriggerLocalServerEvent('qb-log:server:CreateLog', 'admin', 'Player Banned', 'red',
            adminName .. ' banned ' .. targetName .. ' (citizenid: ' .. citizenId .. ')')
        targetSrc:Kick('Banned by admin')
        pushLogEntry('Ban', targetName, 'Banned by ' .. adminName)
        pushFeedEntry(adminName .. ' banned ' .. targetName)
    elseif action == 'freeze' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        TriggerClientEvent(targetSrc, 'qb-admin:client:setFrozen', true)
        pushLogEntry('Freeze', GetPlayerName(targetSrc), 'Frozen by ' .. adminName)
        pushFeedEntry(adminName .. ' froze player #' .. targetPlayerId)
    elseif action == 'clothing' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        TriggerClientEvent(targetSrc, 'qb-admin:client:openClothing')
        pushLogEntry('Clothing', GetPlayerName(targetSrc), 'Opened by ' .. adminName)
    elseif action == 'inventory' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        TriggerClientEvent(source, 'qb-admin:client:openInventory', targetPlayerId)
        pushLogEntry('Inventory', GetPlayerName(targetSrc), 'Viewed by ' .. adminName)
    elseif action == 'revive' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
        if targetPlayer then
            targetPlayer.SetMetaData('isdead', false)
        end
        TriggerClientEvent(targetSrc, 'qb-admin:client:revivePlayer')
        pushLogEntry('Revive', GetPlayerName(targetSrc), 'Revived by ' .. adminName)
        pushFeedEntry(adminName .. ' revived player #' .. targetPlayerId)
    elseif action == 'kill' then
        local targetSrc = getSourceByPlayerId(targetPlayerId)
        if not targetSrc then return end
        local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
        if targetPlayer then
            targetPlayer.SetMetaData('isdead', true)
        end
        TriggerClientEvent(targetSrc, 'qb-admin:client:killPlayer')
        pushLogEntry('Kill', GetPlayerName(targetSrc), 'Killed by ' .. adminName)
        pushFeedEntry(adminName .. ' killed player #' .. targetPlayerId)
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:replenishVital', function(source, data)
    -- data = { playerId = number, vital = 'health'|'armor'|'hunger'|'thirst' }
    local targetPlayerId = tonumber(data.playerId)
    local vitalKey = tostring(data.vital or '')
    if not targetPlayerId or vitalKey == '' then
        return
    end

    local adminName = GetPlayerName(source)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then return end
    local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
    if not targetPlayer then return end
    local targetName = GetPlayerName(targetSrc)

    if vitalKey == 'health' then
        targetPlayer.SetMetaData('isdead', false)
        TriggerClientEvent(targetSrc, 'qb-admin:client:setHealth', 100)
        pushLogEntry('Replenish Health', targetName, 'By ' .. adminName)
        pushFeedEntry(adminName .. ' replenished health of ' .. targetName)
    elseif vitalKey == 'armor' then
        targetPlayer.SetMetaData('armor', 100)
        TriggerClientEvent(targetSrc, 'qb-admin:client:setArmor', 100)
        pushLogEntry('Replenish Armor', targetName, 'By ' .. adminName)
    elseif vitalKey == 'hunger' then
        targetPlayer.SetMetaData('hunger', 100)
        pushLogEntry('Replenish Hunger', targetName, 'By ' .. adminName)
    elseif vitalKey == 'thirst' then
        targetPlayer.SetMetaData('thirst', 100)
        pushLogEntry('Replenish Thirst', targetName, 'By ' .. adminName)
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:currencyAdjust', function(source, data)
    -- data = { playerId = number, currency = 'cash'|'bank'|'crypto', delta = number, value = number }
    local targetPlayerId = tonumber(data.playerId)
    local currencyKey = tostring(data.currency or '')
    local delta = tonumber(data.delta)
    local nextValue = tonumber(data.value)
    if not targetPlayerId or currencyKey == '' or not delta or not nextValue then
        return
    end

    local adminName = GetPlayerName(source)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then return end
    local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
    if not targetPlayer then return end
    local targetName = GetPlayerName(targetSrc)

    local function applyAdjust(moneyType)
        if delta > 0 then
            targetPlayer.AddMoney(moneyType, delta, 'admin-adjustment by ' .. adminName)
        elseif delta < 0 then
            targetPlayer.RemoveMoney(moneyType, math.abs(delta), 'admin-adjustment by ' .. adminName)
        else
            targetPlayer.SetMoney(moneyType, nextValue, 'admin-set by ' .. adminName)
        end
        pushLogEntry('Currency Adjust ' .. moneyType, targetName, adminName .. ' delta=' .. delta)
        pushFeedEntry(adminName .. ' adjusted ' .. moneyType .. ' of ' .. targetName .. ' by ' .. delta)
    end

    if currencyKey == 'cash' then
        applyAdjust('cash')
    elseif currencyKey == 'bank' then
        applyAdjust('bank')
    elseif currencyKey == 'crypto' then
        applyAdjust('crypto')
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:dashboard:announce', function(_, data)
    -- data = { message = string }
    local message = tostring(data.message or '')
    if message == '' then
        return
    end

    BroadcastEvent('qb-admin:client:dashboardAnnounce', message)
end)

RegisterServerEvent('qb-admin:server:dashboard:quickAction', function(source, data)
    -- data = {
    --   action = 'noclip'|'god-mode'|'invisibility'|'admin-duty'|'overhead-names'|'self-heal'|'self-revive',
    --   targetPlayerId = number|nil
    -- }
    local action = tostring(data.action or '')
    if action == '' then
        return
    end

    local adminName = GetPlayerName(source)

    if action == 'noclip' then
        TriggerClientEvent(source, 'qb-admin:client:toggleNoclip')
        pushLogEntry('Noclip', adminName, 'Toggled noclip')
    elseif action == 'god-mode' then
        TriggerClientEvent(source, 'qb-admin:client:toggleGodMode')
        pushLogEntry('God Mode', adminName, 'Toggled god mode')
    elseif action == 'invisibility' then
        TriggerClientEvent(source, 'qb-admin:client:toggleInvisibility')
        pushLogEntry('Invisibility', adminName, 'Toggled invisibility')
    elseif action == 'admin-duty' then
        TriggerClientEvent(source, 'qb-admin:client:toggleAdminDuty')
        pushLogEntry('Admin Duty', adminName, 'Toggled admin duty')
        pushFeedEntry(adminName .. ' toggled admin duty')
    elseif action == 'overhead-names' then
        TriggerClientEvent(source, 'qb-admin:client:toggleOverheadNames')
        pushLogEntry('Overhead Names', adminName, 'Toggled overhead names')
    elseif action == 'self-heal' then
        local player = exports['qb-core']:GetPlayer(source)
        if player then
            player.SetMetaData('hunger', 100)
            player.SetMetaData('thirst', 100)
            player.SetMetaData('stress', 0)
            player.SetMetaData('isdead', false)
        end
        TriggerClientEvent(source, 'qb-admin:client:setHealth', 100)
        pushLogEntry('Self Heal', adminName, 'Healed self')
    elseif action == 'self-revive' then
        local player = exports['qb-core']:GetPlayer(source)
        if player then
            player.SetMetaData('isdead', false)
        end
        TriggerClientEvent(source, 'qb-admin:client:revivePlayer')
        pushLogEntry('Self Revive', adminName, 'Revived self')
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:environment:cleanup', function(source, data)
    -- data = { action = 'vehicles-50m'|'peds-50m'|'objects-50m'|'everything-100m' }
    local action = tostring(data.action or '')
    if action == '' then
        return
    end

    local adminName = GetPlayerName(source)

    if action == 'vehicles-50m' then
        TriggerClientEvent(source, 'qb-admin:client:cleanupNearby', { type = 'vehicles', radius = 50 })
        pushLogEntry('Cleanup', adminName, 'Cleared vehicles within 50m')
        pushFeedEntry(adminName .. ' cleared vehicles within 50m')
    elseif action == 'peds-50m' then
        TriggerClientEvent(source, 'qb-admin:client:cleanupNearby', { type = 'peds', radius = 50 })
        pushLogEntry('Cleanup', adminName, 'Cleared peds within 50m')
        pushFeedEntry(adminName .. ' cleared peds within 50m')
    elseif action == 'objects-50m' then
        TriggerClientEvent(source, 'qb-admin:client:cleanupNearby', { type = 'objects', radius = 50 })
        pushLogEntry('Cleanup', adminName, 'Cleared objects within 50m')
        pushFeedEntry(adminName .. ' cleared objects within 50m')
    elseif action == 'everything-100m' then
        TriggerClientEvent(source, 'qb-admin:client:cleanupNearby', { type = 'all', radius = 100 })
        pushLogEntry('Cleanup', adminName, 'Cleared all entities within 100m')
        pushFeedEntry(adminName .. ' cleared all entities within 100m')
    else
        return
    end
end)

RegisterServerEvent('qb-admin:server:changeTime', function(_, hour)
    CurrentTime = hour
    BroadcastEvent('qb-admin:client:changeTime', hour)
end)

RegisterServerEvent('qb-admin:server:changeWeather', function(_, weatherType)
    CurrentWeather = weatherType
    BroadcastEvent('qb-admin:client:changeWeather', weatherType)
end)

RegisterServerEvent('qb-admin:server:reports:investigationAction', function(source, data)
    -- data = { action = 'goto'|'bring'|'heal'|'freeze', ticketId = string|number?, playerId = number? }
    local action = tostring(data.action or '')
    local ticketId = tostring(data.ticketId or '')
    local targetPlayerId = tonumber(data.playerId)

    if not targetPlayerId and ticketId ~= '' then
        local ticket = ticketsState[ticketId]
        if type(ticket) == 'table' then
            targetPlayerId = tonumber(ticket.playerId)
        end
    end

    if action == '' or not targetPlayerId then
        return
    end

    local adminName = GetPlayerName(source)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then return end
    local targetName = GetPlayerName(targetSrc)

    if action == 'goto' then
        local targetPawn = GetPlayerPawn(targetSrc)
        if not targetPawn then return end
        local targetCoords = GetEntityCoords(targetPawn)
        TeleportToInterior(source, targetCoords.X + 200, targetCoords.Y, targetCoords.Z)
        pushLogEntry('Goto Reporter', targetName, adminName .. ' teleported to reporter')
        pushFeedEntry(adminName .. ' went to report player ' .. targetName)
    elseif action == 'bring' then
        local adminPawn = GetPlayerPawn(source)
        if not adminPawn then return end
        local adminCoords = GetEntityCoords(adminPawn)
        local targetPawn = GetPlayerPawn(targetSrc)
        if not targetPawn then return end
        SetEntityCoords(targetPawn, Vector(adminCoords.X + 200, adminCoords.Y, adminCoords.Z))
        pushLogEntry('Bring Reporter', targetName, 'Brought by ' .. adminName)
        pushFeedEntry(adminName .. ' brought report player ' .. targetName)
    elseif action == 'heal' then
        local targetPlayer = exports['qb-core']:GetPlayer(targetSrc)
        if targetPlayer then
            targetPlayer.SetMetaData('hunger', 100)
            targetPlayer.SetMetaData('thirst', 100)
            targetPlayer.SetMetaData('isdead', false)
        end
        TriggerClientEvent(targetSrc, 'qb-admin:client:setHealth', 100)
        pushLogEntry('Heal Reporter', targetName, 'Healed by ' .. adminName)
        pushFeedEntry(adminName .. ' healed report player ' .. targetName)
    elseif action == 'freeze' then
        TriggerClientEvent(targetSrc, 'qb-admin:client:setFrozen', true)
        pushLogEntry('Freeze Reporter', targetName, 'Frozen by ' .. adminName)
        pushFeedEntry(adminName .. ' froze report player ' .. targetName)
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:reports:updateState', function(_, data)
    -- data = { id = string|number, column = 'incoming'|'in-progress'|'resolved', owner = string?, resolution = string? }
    local ticketId = tostring(data.id or '')
    local ticket = ticketsState[ticketId]
    if ticketId == '' or type(ticket) ~= 'table' then
        return
    end

    local column = tostring(data.column or '')
    if column ~= 'incoming' and column ~= 'in-progress' and column ~= 'resolved' then
        return
    end

    ticket.column = column
    ticket.owner = tostring(data.owner or ticket.owner or '')
    if column == 'resolved' then
        ticket.resolution = tostring(data.resolution or ticket.resolution or 'Resolved by admin.')
    else
        ticket.resolution = tostring(data.resolution or ticket.resolution or '')
    end

    local reportId = tostring(ticket.reportId or '')
    for i = 1, #reportsState do
        local report = reportsState[i]
        local reportMatches = (reportId ~= '' and tostring(report.id) == reportId) or (tostring(report.playerId) == tostring(ticket.playerId))
        if reportMatches then
            report.claimed = column == 'in-progress'
            report.resolved = column == 'resolved'
            break
        end
    end

    BroadcastEvent('qb-admin:client:reportsUpdateState', {
        id = ticketId,
        reportId = ticket.reportId,
        playerId = ticket.playerId,
        column = ticket.column,
        owner = ticket.owner,
        resolution = ticket.resolution,
    })
end)

RegisterServerEvent('qb-admin:server:reports:resolved', function(_, data)
    -- data = { id = string|number, resolution = string }
    local ticketId = tostring(data.id or '')
    local ticket = ticketsState[ticketId]
    if ticketId == '' or type(ticket) ~= 'table' then
        return
    end

    local resolution = tostring(data.resolution or '')
    if resolution == '' then
        resolution = 'Resolved by admin.'
    end

    ticket.column = 'resolved'
    ticket.resolution = resolution

    local reportId = tostring(ticket.reportId or '')
    for i = 1, #reportsState do
        local report = reportsState[i]
        local reportMatches = (reportId ~= '' and tostring(report.id) == reportId) or (tostring(report.playerId) == tostring(ticket.playerId))
        if reportMatches then
            report.claimed = false
            report.resolved = true
            break
        end
    end

    BroadcastEvent('qb-admin:client:reportResolved', {
        id = ticketId,
        reportId = ticket.reportId,
        playerId = ticket.playerId,
        column = ticket.column,
        resolution = ticket.resolution,
    })
end)

RegisterServerEvent('qb-admin:server:reports:clearResolved', function(_, data)
    -- data = { ids = array<string|number> }
    local ids = {}

    if type(data.ids) == 'table' then
        for i = 1, #data.ids do
            local ticketId = tostring(data.ids[i] or '')
            if ticketId ~= '' and type(ticketsState[ticketId]) == 'table' and ticketsState[ticketId].column == 'resolved' then
                ids[#ids + 1] = ticketId
            end
        end
    end

    if #ids == 0 then
        for ticketId, ticket in pairs(ticketsState) do
            if type(ticket) == 'table' and ticket.column == 'resolved' then
                ids[#ids + 1] = tostring(ticketId)
            end
        end
    end

    if #ids == 0 then
        return
    end

    for i = 1, #ids do
        ticketsState[ids[i]] = nil
    end

    BroadcastEvent('qb-admin:client:reportsClearedResolved', {
        ids = ids,
    })
end)

-- Callbacks

RegisterCallback('syncRequest', function(_)
    return { time = CurrentTime, weather = CurrentWeather }
end)

RegisterCallback('getOpenContext', function(source, _)
    return {
        success = true,
        context = buildOpenAdminContext(source),
    }
end)
