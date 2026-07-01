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
local adminQuickActionStates = {}
local nextReportId = 1
local nextTicketId = 1
local nextLogId = 1
local nextChatMessageId = 1

local function formatClockTime(ts)
    return os.date('%H:%M', ts or os.time())
end

local serverSky

local function getServerSky()
    if not Sky then
        return nil
    end

    if serverSky then
        return serverSky
    end

    local ok, skyInstance = pcall(function()
        return Sky()
    end)

    if ok then
        serverSky = skyInstance
        return serverSky
    end

    return nil
end

local function getWeatherTypeKey(weatherValue)
    if weatherValue == nil then
        return CurrentWeather
    end

    local weatherTypes = (Config and Config.Weather and Config.Weather.WeatherTypes) or {}
    for weatherKey, enumWeather in pairs(weatherTypes) do
        if weatherValue == enumWeather or tostring(weatherValue) == tostring(enumWeather) then
            return weatherKey
        end
    end

    local weatherText = tostring(weatherValue):lower()
    for weatherKey in pairs(weatherTypes) do
        if weatherText == weatherKey:lower() or weatherText:find(weatherKey:lower(), 1, true) then
            return weatherKey
        end
    end

    return CurrentWeather
end

local function getUiTimeFromSkyTime(skyTime)
    local timeValue = tonumber(skyTime) or 0
    if timeValue <= 24 then
        return timeValue
    end

    local hour = math.floor(timeValue / 100)
    local minute = timeValue - (hour * 100)
    return hour + (minute / 60)
end

local function getSkyTimeFromUiTime(uiTime)
    local timeValue = tonumber(uiTime)
    if not timeValue then
        return nil
    end

    if timeValue > 24 then
        return timeValue
    end

    local hour = math.floor(timeValue)
    local minute = math.floor(((timeValue - hour) * 60) + 0.5)
    if minute >= 60 then
        hour = hour + 1
        minute = 0
    end

    return (hour * 100) + minute
end

local function getCurrentSkyInfo()
    local timeValue = CurrentTime
    local weatherType = CurrentWeather
    local skyInstance = getServerSky()

    if skyInstance then
        local timeOk, actualTime = pcall(function()
            return skyInstance:GetTimeOfDay()
        end)

        if not timeOk then
            serverSky = nil
        elseif tonumber(actualTime) then
            timeValue = tonumber(actualTime)
        end

        local weatherOk, actualWeather = pcall(function()
            return skyInstance:GetWeather()
        end)

        if not weatherOk then
            serverSky = nil
        else
            weatherType = getWeatherTypeKey(actualWeather)
        end
    end

    CurrentTime = timeValue
    CurrentWeather = weatherType

    return {
        time = timeValue,
        uiTime = getUiTimeFromSkyTime(timeValue),
        weather = weatherType,
    }
end

local function setCurrentSkyTime(hour)
    local nextTime = getSkyTimeFromUiTime(hour)
    if not nextTime then
        return nil
    end

    CurrentTime = nextTime

    local skyInstance = getServerSky()
    if skyInstance then
        local ok = pcall(function()
            skyInstance:SetTimeOfDay(nextTime)
        end)
        if not ok then
            serverSky = nil
        end
    end

    return CurrentTime
end

local function setCurrentSkyWeather(weatherType)
    local weatherKey = tostring(weatherType or '')
    local weatherTypes = (Config and Config.Weather and Config.Weather.WeatherTypes) or {}
    local enumWeather = weatherTypes[weatherKey]

    if not enumWeather then
        weatherKey = Config.Weather.StartingWeather
        enumWeather = weatherTypes[weatherKey]
    end

    CurrentWeather = weatherKey

    local skyInstance = getServerSky()
    if skyInstance and enumWeather then
        local ok = pcall(function()
            skyInstance:ChangeWeather(enumWeather, Config.Weather.TransitionDelay)
        end)
        if not ok then
            serverSky = nil
        end
    end

    return CurrentWeather
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

local function buildCatalog(shared, mapper)
    local catalog = {}
    for key, entry in pairs(shared or {}) do
        catalog[#catalog + 1] = mapper(key, entry)
    end
    table.sort(catalog, function(a, b)
        return a.label < b.label
    end)
    return catalog
end

local function buildJobsCatalog(jobsShared)
    return buildCatalog(jobsShared, function(key, entry)
        return {
            key = key,
            label = entry.label or key,
            type = entry.type,
            defaultDuty = entry.defaultDuty == true,
            offDutyPay = entry.offDutyPay == true,
            grades = normalizeGrades(entry.grades),
        }
    end)
end

local function buildGangsCatalog(gangsShared)
    return buildCatalog(gangsShared, function(key, entry)
        return {
            key = key,
            label = entry.label or key,
            grades = normalizeGrades(entry.grades),
        }
    end)
end

local function buildItemsCatalog(itemsShared)
    return buildCatalog(itemsShared, function(key, entry)
        return {
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
    end)
end

local function buildVehiclesCatalog(vehiclesShared)
    return buildCatalog(vehiclesShared, function(key, entry)
        return {
            key = key,
            brand = entry.brand or '',
            label = entry.name or entry.label or key,
            price = tonumber(entry.price) or 0,
        }
    end)
end

local function clampPercent(value)
    return math.max(0, math.min(100, tonumber(value) or 0))
end

local function getPlayerPawnAndHealthComponent(player)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return nil, nil
    end
    return pawn, FindHealthComponent(pawn)
end

local function getPlayerHealthPercent(player)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return nil
    end

    local normalizedHealth = tonumber(GetHealthNormalized(pawn))
    if normalizedHealth then
        return clampPercent(normalizedHealth * 100)
    end

    local currentHealth = tonumber(GetHealth(pawn)) or 0
    local maxHealth = tonumber(GetMaxHealth(pawn)) or 0
    if maxHealth <= 0 then
        return nil
    end
    return clampPercent((currentHealth / maxHealth) * 100)
end

local function getPlayerArmorValue(player)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return nil
    end

    return tonumber(GetArmor(pawn))
end

local function healPlayerToFull(player)
    local pawn = GetPlayerPawn(player)
    if not pawn or GetHealth(pawn) == nil then
        return false
    end
    if IsDeadOrDying(pawn) then
        return false
    end
    local currentHealth = tonumber(GetHealth(pawn)) or 0
    local maxHealth = tonumber(GetMaxHealth(pawn)) or 0
    if maxHealth <= 0 then
        return false
    end
    local healAmount = maxHealth - currentHealth
    if healAmount > 0 then
        return HealTarget(pawn, healAmount)
    end
    return HealTarget(pawn, maxHealth)
end

local function killPlayerOnServer(player)
    local pawn = GetPlayerPawn(player)
    if not pawn or GetHealth(pawn) == nil then
        return false
    end

    if IsDeadOrDying(pawn) then
        return true
    end

    local currentHealth = tonumber(GetHealth(pawn)) or 0
    local maxHealth = tonumber(GetMaxHealth(pawn)) or 100
    local currentArmor = tonumber(GetArmor(pawn)) or 0
    local lethalDamage = math.max(currentHealth + currentArmor, maxHealth) + 1
    local params = {
        DamageAmount = lethalDamage,
    }

    if not DamageTarget(pawn, pawn, params) then
        return false
    end

    if IsDowned(pawn) then
        return DamageTarget(pawn, pawn, params)
    end

    return true
end

local function replenishPlayerArmorToFull(player)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return false
    end

    local currentArmor = tonumber(GetArmor(pawn))
    local maxArmor = tonumber(GetMaxArmor(pawn))
    if not currentArmor or not maxArmor or maxArmor <= 0 then
        return false
    end

    local armorAmount = maxArmor - currentArmor
    if armorAmount <= 0 then
        return true
    end

    return GiveArmorToTarget(pawn, armorAmount)
end

local function setPlayerFrozenOnServer(player, frozen)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return false
    end
    local isFrozen = frozen == true
    local applied = false
    pcall(function()
        local movement = pawn:GetComponentByClass(UE.UCharacterMovementComponent)
        if movement then
            movement:SetMovementMode(isFrozen and UE.EMovementMode.MOVE_None or UE.EMovementMode.MOVE_Walking, nil)
            applied = true
        end
    end)
    local controller = player
    pcall(function()
        local pawnController = pawn:GetController()
        if pawnController then
            controller = pawnController
        end
    end)
    pcall(function()
        controller:SetIgnoreMoveInput(isFrozen)
        controller:SetIgnoreLookInput(isFrozen)
        applied = true
    end)
    pcall(function()
        if isFrozen then
            pawn:DisableInput(controller)
        else
            pawn:EnableInput(controller)
        end
        applied = true
    end)
    return applied
end

local function getAdminQuickActionState(player)
    local playerId = GetPlayerId(player)
    local stateKey = tostring(playerId or player)
    adminQuickActionStates[stateKey] = adminQuickActionStates[stateKey] or {}
    return adminQuickActionStates[stateKey]
end

local function toggleAdminQuickActionState(player, stateName)
    local state = getAdminQuickActionState(player)
    state[stateName] = not state[stateName]
    return state[stateName]
end

local function setPlayerGodModeOnServer(player, enabled)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return false
    end
    SetEntityInvincible(pawn, enabled == true)
    return true
end

local function setPlayerInvisibilityOnServer(player, enabled)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return false
    end
    pawn:SetActorHiddenInGame(enabled == true)
    return true
end

local function getOccupiedVehicle(player)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return nil
    end
    local ok, vehicle = pcall(function()
        return pawn:GetAttachParentActor()
    end)
    if ok and vehicle and vehicle:IsValid() then
        return vehicle
    end
    return nil
end

local function repairOccupiedVehicle(player)
    local vehicle = getOccupiedVehicle(player)
    if not vehicle then
        return false
    end
    local repaired = false
    pcall(function()
        if vehicle.Repair then
            vehicle:Repair()
            repaired = true
        end
    end)
    local vehicleWrapper = HVehicle and HVehicle.wrap and HVehicle.wrap(vehicle) or nil
    if vehicleWrapper then
        pcall(function()
            local healthComp = vehicleWrapper:GetVehicleHealthComponent()
            if healthComp then
                healthComp:SetHealth(healthComp:GetMaxHealth())
                repaired = true
            end
        end)
        pcall(function()
            vehicleWrapper:SetEngineHealth(1.0)
            repaired = true
        end)
    end
    return repaired
end

local function refuelOccupiedVehicle(player)
    local vehicle = getOccupiedVehicle(player)
    if not vehicle then
        return false
    end
    local refueled = false
    local vehicleWrapper = HVehicle and HVehicle.wrap and HVehicle.wrap(vehicle) or nil
    if vehicleWrapper then
        pcall(function()
            vehicleWrapper:SetFuel(100.0)
            refueled = true
        end)
    end
    pcall(function()
        if vehicle.SetFuel then
            vehicle:SetFuel(100.0)
            refueled = true
        elseif vehicle.SetFuelLevel then
            vehicle:SetFuelLevel(100.0)
            refueled = true
        end
    end)
    return refueled
end

local function deleteOccupiedVehicle(player)
    local vehicle = getOccupiedVehicle(player)
    if not vehicle then
        return false
    end
    vehicle:DestroyActor()
    return true
end

local function cleanupNearbyEntities(player, cleanType, radius)
    local pawn = GetPlayerPawn(player)
    if not pawn then
        return 0
    end
    local coords = GetEntityCoords(pawn)
    if not coords then
        return 0
    end
    local radiusCm = (tonumber(radius) or 50) * 100
    local targetType = tostring(cleanType or 'all')
    local removed = 0
    pcall(function()
        local objectTypes = UE.TArray(0)
        objectTypes:Add(UE.ECollisionChannel.ECC_WorldDynamic)
        local hits = UE.TArray(UE.AActor)
        UE.UKismetSystemLibrary.SphereOverlapActors(HWorld, coords, radiusCm, objectTypes, nil, nil, hits)
        for i = 1, hits:Length() do
            local actor = hits:Get(i)
            if actor and actor:IsValid() and actor ~= pawn then
                local isVehicle = pcall(function()
                    return actor:IsA(UE.AHVehicleCar)
                end) and actor:IsA(UE.AHVehicleCar)
                local isCharacter = pcall(function()
                    return actor:IsA(UE.ACharacter)
                end) and actor:IsA(UE.ACharacter)
                local isPlayer = isCharacter and actor:IsPlayerControlled()
                if not isPlayer then
                    if targetType == 'vehicles' and isVehicle then
                        actor:DestroyActor()
                        removed = removed + 1
                    elseif targetType == 'peds' and isCharacter then
                        actor:DestroyActor()
                        removed = removed + 1
                    elseif targetType == 'objects' and not isVehicle and not isCharacter then
                        actor:DestroyActor()
                        removed = removed + 1
                    elseif targetType == 'all' and (isVehicle or isCharacter) then
                        actor:DestroyActor()
                        removed = removed + 1
                    end
                end
            end
        end
    end)
    return removed
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
        local healthPercent = getPlayerHealthPercent(playerId)
        local armorValue = getPlayerArmorValue(playerId)
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
                health = healthPercent or tonumber(metadata.health) or 100,
                armor = armorValue or tonumber(metadata.armor) or 0,
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

local function mapList(source, limit, mapper)
    local mapped = {}
    for i = 1, math.min(#source, limit or #source) do
        mapped[#mapped + 1] = mapper(source[i])
    end
    return mapped
end

local function buildOpenAdminContext(src)
    local qbPlayers = getQBPlayers()
    local players = buildPlayerList(qbPlayers, jobsShared, gangsShared)
    local playersOnline = #players
    local serverUptime = formatUptime(os.time() - resourceStartTime)
    local ping = math.max(0, math.floor((tonumber(GetPlayerPing(src)) or 0) + 0.5))
    local adminName = GetPlayerName(src)
    local adminPlayer = exports['qb-core']:GetPlayer(src)
    local adminNetId = (adminPlayer and tonumber(adminPlayer.PlayerData.netId)) or 0
    local jobsCatalog = buildJobsCatalog(jobsShared)
    local gangsCatalog = buildGangsCatalog(gangsShared)
    local itemsCatalog = buildItemsCatalog(itemsShared)
    local vehiclesCatalog = buildVehiclesCatalog(vehiclesShared)
    local jobOptions = mapList(jobsCatalog, nil, function(job)
        return { name = job.label }
    end)
    local gangOptions = mapList(gangsCatalog, nil, function(gang)
        return { name = gang.label }
    end)
    local itemOptions = mapList(itemsCatalog, 200, function(item)
        return { name = item.label }
    end)
    local spawnVehicleOptions = mapList(vehiclesCatalog, 200, function(vehicle)
        return { name = vehicle.label, model = vehicle.key }
    end)
    local leaderboardPlayers = mapList(players, nil, function(player)
        return { name = player.character, cash = player.financials.cash, bank = player.financials.bank, crypto = player.financials.crypto }
    end)
    local skyInfo = getCurrentSkyInfo()
    return {
        page = 'dashboard',
        currentAdminName = adminName,
        stats = {
            { label = 'Players Online', value = tostring(playersOnline) },
            { label = 'Server Uptime', value = serverUptime },
            { label = 'Admin Ping', value = tostring(ping) .. 'ms' },
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
        currentWeather = skyInfo.weather,
        timeValue = skyInfo.uiTime,
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
        -- TO DO: Build object spawn options from a configured object catalog.
        spawnObjectOptions = {},
        currentCoordinates = 0,
        currentRotation = 0,
        currentHeading = 0,
    }
end

local function getSourceByPlayerId(targetId)
    local targetNum = tonumber(targetId)
    if not targetNum then
        return nil
    end
    local qbPlayers = getQBPlayers()
    for _, src in ipairs(qbPlayers) do
        local player = exports['qb-core']:GetPlayer(src)
        if player and tonumber(player.PlayerData.netId) == targetNum then
            return src
        end
    end
    return nil
end

local function findSharedKey(shared, nameOrKey)
    local lower = tostring(nameOrKey or ''):lower()
    if lower == '' then
        return nil
    end
    for key, entry in pairs(shared or {}) do
        if key:lower() == lower or (entry.label and entry.label:lower() == lower) then
            return key
        end
    end
    return nil
end

local function findJobKey(nameOrKey)
    return findSharedKey(jobsShared, nameOrKey)
end
local function findGangKey(nameOrKey)
    return findSharedKey(gangsShared, nameOrKey)
end

local function getActionAndTarget(data)
    local action = tostring(data and data.action or '')
    local targetPlayerId = tonumber(data and data.playerId)
    if action == '' or not targetPlayerId then
        return nil, nil
    end
    return action, targetPlayerId
end

local function getTargetContext(targetPlayerId, playerMode)
    local targetSrc = getSourceByPlayerId(targetPlayerId)
    if not targetSrc then
        return nil, nil, nil
    end
    local targetPlayer = playerMode and exports['qb-core']:GetPlayer(targetSrc) or nil
    if playerMode == true and not targetPlayer then
        return nil, nil, nil
    end
    return targetSrc, targetPlayer, GetPlayerName(targetSrc)
end

local function teleportAdminToTarget(source, targetSrc)
    local targetPawn = GetPlayerPawn(targetSrc)
    if not targetPawn then
        return false
    end
    local targetCoords = GetEntityCoords(targetPawn)
    if not targetCoords then
        return false
    end
    TeleportToInterior(source, targetCoords.X + 200, targetCoords.Y, targetCoords.Z)
    return true
end

local function bringTargetToAdmin(source, targetSrc)
    local adminPawn = GetPlayerPawn(source)
    if not adminPawn then
        return false
    end
    local adminCoords = GetEntityCoords(adminPawn)
    if not adminCoords then
        return false
    end
    local targetPawn = GetPlayerPawn(targetSrc)
    if not targetPawn then
        return false
    end
    SetEntityCoords(targetPawn, Vector(adminCoords.X + 200, adminCoords.Y, adminCoords.Z))
    return true
end

local function setPlayerMetadata(player, metadata)
    if not player then
        return
    end
    for key, value in pairs(metadata or {}) do
        player.SetMetaData(key, value)
    end
end

local function healWithMetadata(targetSrc, metadata)
    if not healPlayerToFull(targetSrc) then
        return false
    end
    setPlayerMetadata(exports['qb-core']:GetPlayer(targetSrc), metadata)
    return true
end

local function updateReportForTicket(ticket, claimed, resolved)
    local reportId = tostring(ticket.reportId or '')
    for i = 1, #reportsState do
        local report = reportsState[i]
        local reportMatches = (reportId ~= '' and tostring(report.id) == reportId) or (tostring(report.playerId) == tostring(ticket.playerId))
        if reportMatches then
            report.claimed = claimed
            report.resolved = resolved
            break
        end
    end
end

local function getTicketTarget(data)
    data = data or {}
    local ticketId = tostring(data.ticketId or '')
    local targetPlayerId = tonumber(data.playerId)
    if not targetPlayerId and ticketId ~= '' and type(ticketsState[ticketId]) == 'table' then
        targetPlayerId = tonumber(ticketsState[ticketId].playerId)
    end
    return ticketId, targetPlayerId
end
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

RegisterServerEvent('qb-admin:server:developer:teleportToLocation', function(source, data)
    local location = resolveTeleportLocationByKey(data.key)
    if type(location) ~= 'table' then
        return
    end
    local x, y, z = getLocationCoordinates(location)
    if x and y and z then
        TeleportToInterior(source, x, y, z)
    end
end)

RegisterServerEvent('qb-admin:server:developer:teleportToCoordinates', function(source, data)
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if x and y and z then
        TeleportToInterior(source, x, y, z)
    end
end)

RegisterServerEvent('qb-admin:server:chat:send', function(source, data)
    local message = tostring(data.message or '')
    if message == '' then
        return
    end
    local entry = { id = nextChatMessageId, author = GetPlayerName(source), message = message, time = formatClockTime() }
    nextChatMessageId = nextChatMessageId + 1
    pushChatMessage(entry)
    pushFeedEntry(('Admin chat: %s'):format(message))
    pushLogEntry('Admin Chat', tostring(source), message)
    BroadcastEvent('qb-admin:client:chatMessage', entry)
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
    -- TO DO: Spawn the selected object model once an object catalog/asset mapping exists.
end)

local contextActions = {
    spectate = function(source, targetPlayerId, adminName)
        TriggerClientEvent(source, 'qb-admin:client:spectatePlayer', targetPlayerId)
        pushLogEntry('Spectate', 'Player #' .. targetPlayerId, adminName .. ' started spectating')
        pushFeedEntry(adminName .. ' spectated player #' .. targetPlayerId)
    end,
    ['quick-kick'] = function(_, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc then
            return
        end
        targetSrc:Kick('Kicked by admin')
        pushLogEntry('Quick Kick', targetName, 'Kicked by ' .. adminName)
        pushFeedEntry(adminName .. ' kicked ' .. targetName)
    end,
    bring = function(source, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc or not bringTargetToAdmin(source, targetSrc) then
            return
        end
        pushLogEntry('Bring', targetName, 'Brought by ' .. adminName)
        pushFeedEntry(adminName .. ' brought player #' .. targetPlayerId)
    end,
    freeze = function(_, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc or not setPlayerFrozenOnServer(targetSrc, true) then
            return
        end
        pushLogEntry('Freeze', targetName, 'Frozen by ' .. adminName)
        pushFeedEntry(adminName .. ' froze player #' .. targetPlayerId)
    end,
    heal = function(_, targetPlayerId, adminName)
        local targetSrc, targetPlayer, targetName = getTargetContext(targetPlayerId, true)
        if not targetSrc or not healPlayerToFull(targetSrc) then
            return
        end
        setPlayerMetadata(targetPlayer, { hunger = 100, thirst = 100, stress = 0, isdead = false })
        pushLogEntry('Heal', targetName, 'Healed by ' .. adminName)
        pushFeedEntry(adminName .. ' healed player #' .. targetPlayerId)
    end,
}

RegisterServerEvent('qb-admin:server:players:context-action', function(source, data)
    local action, targetPlayerId = getActionAndTarget(data)
    local handler = action and contextActions[action]
    if handler then
        handler(source, targetPlayerId, GetPlayerName(source))
    end
end)

local vehicleActions = {
    repair = function(_, targetSrc, targetName, adminName)
        if repairOccupiedVehicle(targetSrc) then
            pushLogEntry('Vehicle Repair', targetName, 'Repaired by ' .. adminName)
        end
    end,
    refuel = function(_, targetSrc, targetName, adminName)
        if refuelOccupiedVehicle(targetSrc) then
            pushLogEntry('Vehicle Refuel', targetName, 'Refueled by ' .. adminName)
        end
    end,
    ownership = function(source, _, targetName, adminName, targetPlayerId)
        -- TO DO: Implement the client-side vehicle ownership viewer.
        TriggerClientEvent(source, 'qb-admin:client:openVehicleOwnership', targetPlayerId)
        pushLogEntry('Vehicle Ownership', targetName, 'Ownership viewed by ' .. adminName)
    end,
    glovebox = function(_, targetSrc, targetName, adminName)
        -- TO DO: Implement admin vehicle glovebox inspection/opening.
        TriggerClientEvent(targetSrc, 'qb-admin:client:openVehicleGlovebox')
        pushLogEntry('Vehicle Glovebox', targetName, 'Opened by ' .. adminName)
    end,
    trunk = function(_, targetSrc, targetName, adminName)
        -- TO DO: Implement admin vehicle trunk inspection/opening.
        TriggerClientEvent(targetSrc, 'qb-admin:client:openVehicleTrunk')
        pushLogEntry('Vehicle Trunk', targetName, 'Opened by ' .. adminName)
    end,
    delete = function(_, targetSrc, targetName, adminName)
        if not deleteOccupiedVehicle(targetSrc) then
            return
        end
        pushLogEntry('Vehicle Delete', targetName, 'Vehicle deleted by ' .. adminName)
        pushFeedEntry(adminName .. ' deleted vehicle of ' .. targetName)
    end,
}

RegisterServerEvent('qb-admin:server:players:vehicleAction', function(source, data)
    local action, targetPlayerId = getActionAndTarget(data)
    local handler = action and vehicleActions[action]
    if not handler then
        return
    end
    local targetSrc, _, targetName = getTargetContext(targetPlayerId)
    if targetSrc then
        handler(source, targetSrc, targetName, GetPlayerName(source), targetPlayerId)
    end
end)
local gangActions = {
    remove = function(targetPlayer, targetName, adminName)
        targetPlayer.SetGang('none', 0)
        pushLogEntry('Gang Remove', targetName, 'Removed from gang by ' .. adminName)
        pushFeedEntry(adminName .. ' removed ' .. targetName .. ' from their gang')
    end,
    change = function(targetPlayer, targetName, adminName, data)
        local gangName, gradeLevel = tostring(data.gang or ''), tonumber(data.grade) or 0
        local gangKey = gangName ~= '' and findGangKey(gangName) or nil
        if not gangKey then
            return
        end
        targetPlayer.SetGang(gangKey, gradeLevel)
        pushLogEntry('Gang Change', targetName, 'Set to ' .. gangKey .. ' grade ' .. gradeLevel .. ' by ' .. adminName)
        pushFeedEntry(adminName .. ' set ' .. targetName .. ' gang to ' .. gangName)
    end,
}

RegisterServerEvent('qb-admin:server:players:gangAction', function(source, data)
    local action, targetPlayerId = getActionAndTarget(data)
    local handler = action and gangActions[action]
    if not handler then
        return
    end
    local _, targetPlayer, targetName = getTargetContext(targetPlayerId, true)
    if targetPlayer then
        handler(targetPlayer, targetName, GetPlayerName(source), data)
    end
end)
local jobActions = {
    fire = function(targetPlayer, targetName, adminName)
        targetPlayer.SetJob('unemployed', 0)
        pushLogEntry('Job Fire', targetName, 'Fired by ' .. adminName)
        pushFeedEntry(adminName .. ' fired ' .. targetName)
    end,
    change = function(targetPlayer, targetName, adminName, data)
        local jobName, gradeLevel = tostring(data.job or ''), tonumber(data.grade) or 0
        local jobKey = jobName ~= '' and findJobKey(jobName) or nil
        if not jobKey then
            return
        end
        targetPlayer.SetJob(jobKey, gradeLevel)
        pushLogEntry('Job Change', targetName, 'Set to ' .. jobKey .. ' grade ' .. gradeLevel .. ' by ' .. adminName)
        pushFeedEntry(adminName .. ' set ' .. targetName .. ' job to ' .. jobName)
    end,
}
RegisterServerEvent('qb-admin:server:players:jobAction', function(source, data)
    local action, targetPlayerId = getActionAndTarget(data)
    local handler = action and jobActions[action]
    if not handler then
        return
    end
    local _, targetPlayer, targetName = getTargetContext(targetPlayerId, true)
    if targetPlayer then
        handler(targetPlayer, targetName, GetPlayerName(source), data)
    end
end)

local quickControlActions = {
    ['teleport-to'] = function(source, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc or not teleportAdminToTarget(source, targetSrc) then
            return
        end
        pushLogEntry('Teleport To', targetName, adminName .. ' teleported to target')
        pushFeedEntry(adminName .. ' teleported to player #' .. targetPlayerId)
    end,
    ['bring-to-you'] = function(source, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc or not bringTargetToAdmin(source, targetSrc) then
            return
        end
        pushLogEntry('Bring To You', targetName, 'Brought by ' .. adminName)
        pushFeedEntry(adminName .. ' brought player #' .. targetPlayerId)
    end,
    spectate = function(source, targetPlayerId, adminName)
        TriggerClientEvent(source, 'qb-admin:client:spectatePlayer', targetPlayerId)
        pushLogEntry('Spectate', 'Player #' .. targetPlayerId, adminName .. ' started spectating')
        pushFeedEntry(adminName .. ' started spectating player #' .. targetPlayerId)
    end,
    kick = function(_, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc then
            return
        end
        targetSrc:Kick('Kicked by admin')
        pushLogEntry('Kick', targetName, 'Kicked by ' .. adminName)
        pushFeedEntry(adminName .. ' kicked ' .. targetName)
    end,
    ban = function(_, targetPlayerId, adminName)
        local targetSrc, targetPlayer, targetName = getTargetContext(targetPlayerId, 'optional')
        if not targetSrc then
            return
        end
        local citizenId = targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.citizenid or 'unknown'
        -- TO DO: Persist bans in the bans table and honor ban duration/reason.
        TriggerLocalServerEvent('qb-log:server:CreateLog', 'admin', 'Player Banned', 'red', adminName .. ' banned ' .. targetName .. ' (citizenid: ' .. citizenId .. ')')
        targetSrc:Kick('Banned by admin')
        pushLogEntry('Ban', targetName, 'Banned by ' .. adminName)
        pushFeedEntry(adminName .. ' banned ' .. targetName)
    end,
    freeze = function(_, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc or not setPlayerFrozenOnServer(targetSrc, true) then
            return
        end
        pushLogEntry('Freeze', targetName, 'Frozen by ' .. adminName)
        pushFeedEntry(adminName .. ' froze player #' .. targetPlayerId)
    end,
    clothing = function(_, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc then
            return
        end
        TriggerClientEvent(targetSrc, 'qb-admin:client:openClothing')
        pushLogEntry('Clothing', targetName, 'Opened by ' .. adminName)
    end,
    inventory = function(source, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc then
            return
        end
        if not exports['qb-inventory']:OpenInventoryById(source, targetPlayerId) then
            return
        end
        TriggerClientEvent(source, 'qb-admin:client:closePanel')
        pushLogEntry('Inventory', targetName, 'Viewed by ' .. adminName)
    end,
    revive = function(_, targetPlayerId, adminName)
        local targetSrc, _, targetName = getTargetContext(targetPlayerId)
        if not targetSrc or not healWithMetadata(targetSrc, { isdead = false }) then
            return
        end
        pushLogEntry('Revive', targetName, 'Revived by ' .. adminName)
        pushFeedEntry(adminName .. ' revived player #' .. targetPlayerId)
    end,
    kill = function(_, targetPlayerId, adminName)
        local targetSrc, targetPlayer, targetName = getTargetContext(targetPlayerId, 'optional')
        if not targetSrc or not killPlayerOnServer(targetSrc) then
            return
        end
        setPlayerMetadata(targetPlayer, { isdead = true })
        pushLogEntry('Kill', targetName, 'Killed by ' .. adminName)
        pushFeedEntry(adminName .. ' killed player #' .. targetPlayerId)
    end,
}

RegisterServerEvent('qb-admin:server:players:quickControl', function(source, data)
    local action, targetPlayerId = getActionAndTarget(data)
    local handler = action and quickControlActions[action]
    if handler then
        handler(source, targetPlayerId, GetPlayerName(source))
    end
end)

local vitalActions = {
    health = function(targetSrc, targetPlayer, targetName, adminName)
        if not healPlayerToFull(targetSrc) then
            return
        end
        targetPlayer.SetMetaData('isdead', false)
        pushLogEntry('Replenish Health', targetName, 'By ' .. adminName)
        pushFeedEntry(adminName .. ' replenished health of ' .. targetName)
    end,
    armor = function(targetSrc, targetPlayer, targetName, adminName)
        if not replenishPlayerArmorToFull(targetSrc) then
            return
        end
        targetPlayer.SetMetaData('armor', 100)
        pushLogEntry('Replenish Armor', targetName, 'By ' .. adminName)
    end,
    hunger = function(_, targetPlayer, targetName, adminName)
        targetPlayer.SetMetaData('hunger', 100)
        pushLogEntry('Replenish Hunger', targetName, 'By ' .. adminName)
    end,
    thirst = function(_, targetPlayer, targetName, adminName)
        targetPlayer.SetMetaData('thirst', 100)
        pushLogEntry('Replenish Thirst', targetName, 'By ' .. adminName)
    end,
}

RegisterServerEvent('qb-admin:server:players:replenishVital', function(source, data)
    local targetPlayerId, vitalKey = tonumber(data and data.playerId), tostring(data and data.vital or '')
    local handler = vitalActions[vitalKey]
    if not targetPlayerId or not handler then
        return
    end
    local targetSrc, targetPlayer, targetName = getTargetContext(targetPlayerId, true)
    if targetSrc then
        handler(targetSrc, targetPlayer, targetName, GetPlayerName(source))
    end
end)

local moneyTypes = { cash = 'cash', bank = 'bank', crypto = 'crypto' }

RegisterServerEvent('qb-admin:server:players:currencyAdjust', function(source, data)
    local targetPlayerId, moneyType = tonumber(data and data.playerId), moneyTypes[tostring(data and data.currency or '')]
    local delta, nextValue = tonumber(data and data.delta), tonumber(data and data.value)
    if not targetPlayerId or not moneyType or not delta or not nextValue then
        return
    end
    local _, targetPlayer, targetName = getTargetContext(targetPlayerId, true)
    if not targetPlayer then
        return
    end
    local adminName = GetPlayerName(source)
    if delta > 0 then
        targetPlayer.AddMoney(moneyType, delta, 'admin-adjustment by ' .. adminName)
    elseif delta < 0 then
        targetPlayer.RemoveMoney(moneyType, math.abs(delta), 'admin-adjustment by ' .. adminName)
    else
        targetPlayer.SetMoney(moneyType, nextValue, 'admin-set by ' .. adminName)
    end
    pushLogEntry('Currency Adjust ' .. moneyType, targetName, adminName .. ' delta=' .. delta)
    pushFeedEntry(adminName .. ' adjusted ' .. moneyType .. ' of ' .. targetName .. ' by ' .. delta)
end)

RegisterServerEvent('qb-admin:server:dashboard:announce', function(_, data)
    local message = tostring(data and data.message or '')
    if message == '' then
        return
    end
    BroadcastEvent('QBCore:Notify', { text = message, caption = 'Announcement' }, 'announcement', 10000)
end)

local dashboardActions = {
    noclip = function(source, adminName)
        TriggerClientEvent(source, 'qb-admin:client:toggleNoclip')
        pushLogEntry('Noclip', adminName, 'Toggled noclip')
    end,
    ['god-mode'] = function(source, adminName)
        local enabled = toggleAdminQuickActionState(source, 'godMode')
        if setPlayerGodModeOnServer(source, enabled) then
            pushLogEntry('God Mode', adminName, enabled and 'Enabled god mode' or 'Disabled god mode')
        end
    end,
    invisibility = function(source, adminName)
        local enabled = toggleAdminQuickActionState(source, 'invisibility')
        if setPlayerInvisibilityOnServer(source, enabled) then
            pushLogEntry('Invisibility', adminName, enabled and 'Enabled invisibility' or 'Disabled invisibility')
        end
    end,
    ['admin-duty'] = function(source, adminName)
        local enabled = toggleAdminQuickActionState(source, 'adminDuty')
        -- TO DO: Apply an actual admin-duty state/effect instead of only logging it.
        pushLogEntry('Admin Duty', adminName, enabled and 'Enabled admin duty' or 'Disabled admin duty')
        pushFeedEntry(adminName .. ' toggled admin duty')
    end,
    ['overhead-names'] = function(source, adminName)
        TriggerClientEvent(source, 'qb-admin:client:toggleOverheadNames')
        pushLogEntry('Overhead Names', adminName, 'Toggled overhead names')
    end,
    ['self-heal'] = function(source, adminName)
        if healWithMetadata(source, { hunger = 100, thirst = 100, stress = 0, isdead = false }) then
            pushLogEntry('Self Heal', adminName, 'Healed self')
        end
    end,
    ['self-revive'] = function(source, adminName)
        if healWithMetadata(source, { isdead = false }) then
            pushLogEntry('Self Revive', adminName, 'Revived self')
        end
    end,
}

RegisterServerEvent('qb-admin:server:dashboard:quickAction', function(source, data)
    local handler = dashboardActions[tostring(data and data.action or '')]
    if handler then
        handler(source, GetPlayerName(source))
    end
end)

local cleanupActions = {
    ['vehicles-50m'] = { 'vehicles', 50, 'Cleared vehicles within 50m', 'cleared vehicles within 50m' },
    ['peds-50m'] = { 'peds', 50, 'Cleared peds within 50m', 'cleared peds within 50m' },
    ['objects-50m'] = { 'objects', 50, 'Cleared objects within 50m', 'cleared objects within 50m' },
    ['everything-100m'] = { 'all', 100, 'Cleared all entities within 100m', 'cleared all entities within 100m' },
}

RegisterServerEvent('qb-admin:server:environment:cleanup', function(source, data)
    local cleanup = cleanupActions[tostring(data and data.action or '')]
    if not cleanup then
        return
    end
    local adminName = GetPlayerName(source)
    cleanupNearbyEntities(source, cleanup[1], cleanup[2])
    pushLogEntry('Cleanup', adminName, cleanup[3])
    pushFeedEntry(adminName .. ' ' .. cleanup[4])
end)

RegisterServerEvent('qb-admin:server:changeTime', function(_, hour)
    local nextTime = setCurrentSkyTime(hour)
    if nextTime == nil then
        return
    end
    BroadcastEvent('qb-admin:client:changeTime', nextTime)
end)

RegisterServerEvent('qb-admin:server:changeWeather', function(_, weatherType)
    local nextWeather = setCurrentSkyWeather(weatherType)
    BroadcastEvent('qb-admin:client:changeWeather', nextWeather)
end)

local investigationActions = {
    ['goto'] = function(source, targetSrc, targetName, adminName)
        if not teleportAdminToTarget(source, targetSrc) then
            return
        end
        pushLogEntry('Goto Reporter', targetName, adminName .. ' teleported to reporter')
        pushFeedEntry(adminName .. ' went to report player ' .. targetName)
    end,
    bring = function(source, targetSrc, targetName, adminName)
        if not bringTargetToAdmin(source, targetSrc) then
            return
        end
        pushLogEntry('Bring Reporter', targetName, 'Brought by ' .. adminName)
        pushFeedEntry(adminName .. ' brought report player ' .. targetName)
    end,
    heal = function(_, targetSrc, targetName, adminName)
        if not healWithMetadata(targetSrc, { hunger = 100, thirst = 100, isdead = false }) then
            return
        end
        pushLogEntry('Heal Reporter', targetName, 'Healed by ' .. adminName)
        pushFeedEntry(adminName .. ' healed report player ' .. targetName)
    end,
    freeze = function(_, targetSrc, targetName, adminName)
        if not setPlayerFrozenOnServer(targetSrc, true) then
            return
        end
        pushLogEntry('Freeze Reporter', targetName, 'Frozen by ' .. adminName)
        pushFeedEntry(adminName .. ' froze report player ' .. targetName)
    end,
}

RegisterServerEvent('qb-admin:server:reports:investigationAction', function(source, data)
    local action = tostring(data and data.action or '')
    local _, targetPlayerId = getTicketTarget(data)
    local handler = investigationActions[action]
    if not targetPlayerId or not handler then
        return
    end
    local targetSrc, _, targetName = getTargetContext(targetPlayerId)
    if targetSrc then
        handler(source, targetSrc, targetName, GetPlayerName(source))
    end
end)

RegisterServerEvent('qb-admin:server:reports:updateState', function(_, data)
    data = data or {}
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
    updateReportForTicket(ticket, column == 'in-progress', column == 'resolved')
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
    data = data or {}
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
    updateReportForTicket(ticket, false, true)
    BroadcastEvent('qb-admin:client:reportResolved', {
        id = ticketId,
        reportId = ticket.reportId,
        playerId = ticket.playerId,
        column = ticket.column,
        resolution = ticket.resolution,
    })
end)

RegisterServerEvent('qb-admin:server:reports:clearResolved', function(_, data)
    local ids = {}
    if type(data and data.ids) == 'table' then
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

RegisterCallback('syncRequest', function(_)
    return getCurrentSkyInfo()
end)

RegisterCallback('getOpenContext', function(source, _)
    return {
        success = true,
        context = buildOpenAdminContext(source),
    }
end)
