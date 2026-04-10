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

        local playerSource = tonumber(data.source) or tonumber(sourceId) or 0
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
        selectedPlayerId = src,

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

-- Events

RegisterServerEvent('qb-admin:server:fileReport', function(source, data)
    if type(data) ~= 'table' then
        return
    end

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
    if type(data) ~= 'table' then
        return
    end

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
    if type(data) ~= 'table' then
        return
    end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if not x or not y or not z then
        return
    end

    TeleportToInterior(source, x, y, z)
end

local function handleChatSend(source, data)
    if type(data) ~= 'table' then
        return
    end

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

RegisterServerEvent('qb-admin:server:developer:spawnObject', function(source, data)
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    local ForwardVec = playerPed:GetActorForwardVector()
    local SpawnPosition = playerCoords + (ForwardVec * 800)
    SpawnPosition = Vector(SpawnPosition.X, SpawnPosition.Y, SpawnPosition.Z - 100)
end)

RegisterServerEvent('qb-admin:server:players:context-action', function(source, data)
    -- data = { action = 'spectate'|'quick-kick'|'bring'|'freeze'|'heal', playerId = number }
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    if action == 'spectate' then
        -- TODO: Implement spectate action.
    elseif action == 'quick-kick' then
        -- TODO: Implement quick-kick action.
    elseif action == 'bring' then
        -- TODO: Implement bring action.
    elseif action == 'freeze' then
        -- TODO: Implement freeze action.
    elseif action == 'heal' then
        -- TODO: Implement heal action.
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:vehicleAction', function(source, data)
    -- data = { action = 'repair'|'refuel'|'ownership'|'glovebox'|'trunk'|'delete', playerId = number }
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    if action == 'repair' then
        -- TODO: Implement vehicle repair action.
    elseif action == 'refuel' then
        -- TODO: Implement vehicle refuel action.
    elseif action == 'ownership' then
        -- TODO: Implement vehicle ownership action.
    elseif action == 'glovebox' then
        -- TODO: Implement vehicle glovebox action.
    elseif action == 'trunk' then
        -- TODO: Implement vehicle trunk action.
    elseif action == 'delete' then
        -- TODO: Implement vehicle delete action.
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:gangAction', function(source, data)
    -- data = { action = 'change'|'remove', playerId = number, gang = string?, grade = number? }
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    if action == 'remove' then
        -- TODO: Implement gang remove action.
    elseif action == 'change' then
        local gangName = tostring(data.gang or '')
        local gradeLevel = tonumber(data.grade) or 0
        if gangName == '' then
            return
        end

        -- TODO: Implement gang change action using gangName and gradeLevel.
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:jobAction', function(source, data)
    -- data = { action = 'change'|'fire', playerId = number, job = string?, grade = number? }
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    if action == 'fire' then
        -- TODO: Implement job fire action.
    elseif action == 'change' then
        local jobName = tostring(data.job or '')
        local gradeLevel = tonumber(data.grade) or 0
        if jobName == '' then
            return
        end

        -- TODO: Implement job change action using jobName and gradeLevel.
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:quickControl', function(source, data)
    -- data = {
    --   action = 'teleport-to'|'bring-to-you'|'spectate'|'kick'|'ban'|'freeze'|'clothing'|'inventory'|'revive'|'kill',
    --   playerId = number
    -- }
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    local targetPlayerId = tonumber(data.playerId)
    if action == '' or not targetPlayerId then
        return
    end

    if action == 'teleport-to' then
        -- TODO: Implement teleport-to action.
    elseif action == 'bring-to-you' then
        -- TODO: Implement bring-to-you action.
    elseif action == 'spectate' then
        -- TODO: Implement spectate action.
    elseif action == 'kick' then
        -- TODO: Implement kick action.
    elseif action == 'ban' then
        -- TODO: Implement ban action.
    elseif action == 'freeze' then
        -- TODO: Implement freeze action.
    elseif action == 'clothing' then
        -- TODO: Implement clothing action.
    elseif action == 'inventory' then
        -- TODO: Implement inventory action.
    elseif action == 'revive' then
        -- TODO: Implement revive action.
    elseif action == 'kill' then
        -- TODO: Implement kill action.
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:replenishVital', function(source, data)
    -- data = { playerId = number, vital = 'health'|'armor'|'hunger'|'thirst' }
    if type(data) ~= 'table' then
        return
    end

    local targetPlayerId = tonumber(data.playerId)
    local vitalKey = tostring(data.vital or '')
    if not targetPlayerId or vitalKey == '' then
        return
    end

    if vitalKey == 'health' then
        -- TODO: Implement health replenish action.
    elseif vitalKey == 'armor' then
        -- TODO: Implement armor replenish action.
    elseif vitalKey == 'hunger' then
        -- TODO: Implement hunger replenish action.
    elseif vitalKey == 'thirst' then
        -- TODO: Implement thirst replenish action.
    else
        -- Unknown vital; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:players:currencyAdjust', function(source, data)
    -- data = { playerId = number, currency = 'cash'|'bank'|'crypto', delta = number, value = number }
    if type(data) ~= 'table' then
        return
    end

    local targetPlayerId = tonumber(data.playerId)
    local currencyKey = tostring(data.currency or '')
    local delta = tonumber(data.delta)
    local nextValue = tonumber(data.value)
    if not targetPlayerId or currencyKey == '' or not delta or not nextValue then
        return
    end

    if currencyKey == 'cash' then
        -- TODO: Implement cash currency adjust action.
    elseif currencyKey == 'bank' then
        -- TODO: Implement bank currency adjust action.
    elseif currencyKey == 'crypto' then
        -- TODO: Implement crypto currency adjust action.
    else
        -- Unknown currency key; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:dashboard:announce', function(source, data)
    -- data = { message = string }
    if type(data) ~= 'table' then
        return
    end

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
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    local targetPlayerId = data.targetPlayerId ~= nil and tonumber(data.targetPlayerId) or nil
    if action == '' then
        return
    end

    if action == 'noclip' then
        -- TODO: Implement noclip quick action.
    elseif action == 'god-mode' then
        -- TODO: Implement god-mode quick action.
    elseif action == 'invisibility' then
        -- TODO: Implement invisibility quick action.
    elseif action == 'admin-duty' then
        -- TODO: Implement admin-duty quick action.
    elseif action == 'overhead-names' then
        -- TODO: Implement overhead-names quick action.
    elseif action == 'self-heal' then
        -- TODO: Implement self-heal quick action.
    elseif action == 'self-revive' then
        -- TODO: Implement self-revive quick action.
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:environment:cleanup', function(source, data)
    -- data = { action = 'vehicles-50m'|'peds-50m'|'objects-50m'|'everything-100m' }
    if type(data) ~= 'table' then
        return
    end

    local action = tostring(data.action or '')
    if action == '' then
        return
    end

    if action == 'vehicles-50m' then
        -- TODO: Implement cleanup for vehicles within 50m.
    elseif action == 'peds-50m' then
        -- TODO: Implement cleanup for peds within 50m.
    elseif action == 'objects-50m' then
        -- TODO: Implement cleanup for objects within 50m.
    elseif action == 'everything-100m' then
        -- TODO: Implement cleanup for vehicles, peds, and objects within 100m.
    else
        -- Unknown action; ignore for now.
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
    if type(data) ~= 'table' then
        return
    end

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

    if action == 'goto' then
        -- TODO: Implement goto action (teleport admin to targetPlayerId location).
    elseif action == 'bring' then
        -- TODO: Implement bring action (bring targetPlayerId to admin).
    elseif action == 'heal' then
        -- TODO: Implement heal action (set targetPlayerId health to 100).
    elseif action == 'freeze' then
        -- TODO: Implement freeze action (freeze targetPlayerId).
    else
        -- Unknown action; ignore for now.
        return
    end
end)

RegisterServerEvent('qb-admin:server:reports:updateState', function(source, data)
    -- data = { id = string|number, column = 'incoming'|'in-progress'|'resolved', owner = string?, resolution = string? }
    if type(data) ~= 'table' then
        return
    end

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

RegisterServerEvent('qb-admin:server:reports:resolved', function(source, data)
    -- data = { id = string|number, resolution = string }
    if type(data) ~= 'table' then
        return
    end

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

RegisterServerEvent('qb-admin:server:reports:clearResolved', function(source, data)
    -- data = { ids = array<string|number> }
    if type(data) ~= 'table' then
        return
    end

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

RegisterCallback('syncRequest', function(source)
    return { time = CurrentTime, weather = CurrentWeather }
end)

RegisterCallback('getOpenContext', function(source, data)
    return {
        success = true,
        context = buildOpenAdminContext(source),
    }
end)
