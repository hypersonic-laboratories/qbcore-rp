local my_webui = WebUI('qb-admin', 'qb-admin/html/index.html')
local ui_open = false
local sky

-- Spawn Sky

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerCallback('syncRequest', function(skyInfo)
        sky = Sky()
        sky:SetTimeOfDay(skyInfo.time)
        sky:SetAnimateTimeOfDay(Config.Weather.AnimateTime)
        sky:ChangeWeather(Config.Weather.WeatherTypes[skyInfo.weather])
    end)
end)

-- Events

RegisterClientEvent('qb-admin:client:changeTime', function(hour)
    if not sky then
        return
    end
    sky:SetTimeOfDay(hour)
end)

RegisterClientEvent('qb-admin:client:changeWeather', function(weatherType)
    if not sky then
        return
    end
    local enumWeather = Config.Weather.WeatherTypes[weatherType] or WeatherType.ClearSkies
    sky:ChangeWeather(enumWeather, Config.Weather.TransitionDelay)
end)

-- NUI Events

my_webui:RegisterEventHandler('developer:teleportToLocation', function(data)
    local locationKey = tostring(data.key or data.name or '')
    if locationKey == '' then
        return
    end

    TriggerServerEvent('qb-admin:server:developer:teleportToLocation', {
        key = locationKey,
    })
end)

my_webui:RegisterEventHandler('developer:teleportToCoordinates', function(data)
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if not x or not y or not z then
        return
    end

    TriggerServerEvent('qb-admin:server:developer:teleportToCoordinates', {
        x = x,
        y = y,
        z = z,
    })
end)

my_webui:RegisterEventHandler('developer:spawnVehicle', function(data)
    TriggerServerEvent('qb-admin:server:developer:spawnVehicle', data)
end)

my_webui:RegisterEventHandler('developer:spawnObject', function(data)
    TriggerServerEvent('qb-admin:server:developer:spawnObject', data)
end)

my_webui:RegisterEventHandler('developer:copyCoords', function()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end
    local coords = GetEntityCoords(pawn)
    CopyToClipboard(('%s, %s, %s'):format(math.modf(coords.X), math.modf(coords.Y), math.modf(coords.Z)))
end)

my_webui:RegisterEventHandler('developer:copyRotation', function()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end
    local rot = GetEntityRotation(pawn)
    CopyToClipboard(('%s, %s, %s'):format(math.modf(rot.Yaw), math.modf(rot.Roll), math.modf(rot.Pitch)))
end)

my_webui:RegisterEventHandler('developer:copyHeading', function()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end
    local heading = GetEntityHeading(pawn)
    CopyToClipboard(('%s'):format(math.modf(heading)))
end)

my_webui:RegisterEventHandler('developer:runConsoleCommand', function(data)
    local command = tostring(data.command or '')
    if command == '' then
        return
    end

    local Console = GetActorByTag('HConsole')
    if not Console then
        return
    end

    Console:Execute(command)
end)

my_webui:RegisterEventHandler('players:context-action', function(data)
    TriggerServerEvent('qb-admin:server:players:context-action', data)
end)

my_webui:RegisterEventHandler('players:vehicleAction', function(data)
    TriggerServerEvent('qb-admin:server:players:vehicleAction', data)
end)

my_webui:RegisterEventHandler('players:gangAction', function(data)
    TriggerServerEvent('qb-admin:server:players:gangAction', data)
end)

my_webui:RegisterEventHandler('players:jobAction', function(data)
    TriggerServerEvent('qb-admin:server:players:jobAction', data)
end)

my_webui:RegisterEventHandler('players:quickControl', function(data)
    TriggerServerEvent('qb-admin:server:players:quickControl', data)
end)

my_webui:RegisterEventHandler('players:replenishVital', function(data)
    TriggerServerEvent('qb-admin:server:players:replenishVital', data)
end)

my_webui:RegisterEventHandler('players:currencyAdjust', function(data)
    TriggerServerEvent('qb-admin:server:players:currencyAdjust', data)
end)

my_webui:RegisterEventHandler('items:giveSelf', function(data)
    TriggerServerEvent('qb-admin:server:items:giveSelf', data)
end)

my_webui:RegisterEventHandler('dashboard:announce', function(data)
    TriggerServerEvent('qb-admin:server:dashboard:announce', data)
end)

my_webui:RegisterEventHandler('dashboard:quickAction', function(data)
    TriggerServerEvent('qb-admin:server:dashboard:quickAction', data)
end)

my_webui:RegisterEventHandler('chat:send', function(data)
    TriggerServerEvent('qb-admin:server:chat:send', data)
end)

my_webui:RegisterEventHandler('environment:cleanup', function(data)
    TriggerServerEvent('qb-admin:server:environment:cleanup', data)
end)

my_webui:RegisterEventHandler('environment:changeWeather', function(data)
    TriggerServerEvent('qb-admin:server:changeWeather', data.weather)
end)

my_webui:RegisterEventHandler('environment:changeTime', function(data)
    TriggerServerEvent('qb-admin:server:changeTime', data.hour)
end)

my_webui:RegisterEventHandler('reports:updateState', function(data)
    TriggerServerEvent('qb-admin:server:reports:updateState', data)
end)

my_webui:RegisterEventHandler('reports:resolved', function(data)
    TriggerServerEvent('qb-admin:server:reports:resolved', data)
end)

my_webui:RegisterEventHandler('reports:investigationAction', function(data)
    TriggerServerEvent('qb-admin:server:reports:investigationAction', data)
end)

my_webui:RegisterEventHandler('reports:clearResolved', function(data)
    TriggerServerEvent('qb-admin:server:reports:clearResolved', data)
end)

my_webui:RegisterEventHandler('ui:close', function()
    ui_open = false
    my_webui:SetInputMode(0)
end)

-- Inputs

Input.BindKey('F3', function()
    if not ui_open then
        ui_open = true
        my_webui:BringToFront()
        my_webui:SetInputMode(1)
        TriggerCallback('getOpenContext', function(response)
            my_webui:SendEvent('openAdmin', response.context)
        end)
    end
end, 'Released')

RegisterClientEvent('qb-admin:client:chatMessage', function(entry)
    my_webui:SendEvent('qb-admin:chatMessage', entry)
end)

RegisterClientEvent('qb-admin:client:reportFiled', function(payload)
    my_webui:SendEvent('qb-admin:reportFiled', payload)
end)

RegisterClientEvent('qb-admin:client:reportsUpdateState', function(payload)
    my_webui:SendEvent('qb-admin:reportsUpdateState', payload)
end)

RegisterClientEvent('qb-admin:client:reportResolved', function(payload)
    my_webui:SendEvent('qb-admin:reportResolved', payload)
end)

RegisterClientEvent('qb-admin:client:reportsClearedResolved', function(payload)
    my_webui:SendEvent('qb-admin:reportsClearedResolved', payload)
end)

RegisterClientEvent('qb-admin:client:openClothing', function()
    exports['qb-clothing']:OpenClothing()
end)

RegisterClientEvent('qb-admin:client:closePanel', function()
    ui_open = false
    my_webui:SetInputMode(0)
    my_webui:SendEvent('closeAdmin')
end)

local noclipActive = false
RegisterClientEvent('qb-admin:client:toggleNoclip', function()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end
    noclipActive = not noclipActive
    pcall(function()
        local movComp = pawn:GetMovementComponent()
        if noclipActive then
            movComp:SetMovementMode(UE.EMovementMode.MOVE_Flying)
            pawn:SetActorEnableCollision(false)
        else
            movComp:SetMovementMode(UE.EMovementMode.MOVE_Walking)
            pawn:SetActorEnableCollision(true)
        end
    end)
end)

local overheadNamesActive = false
RegisterClientEvent('qb-admin:client:toggleOverheadNames', function()
    overheadNamesActive = not overheadNamesActive
    -- TO DO: Implement overhead names functionality
end)

local spectateTargetId = nil

local function getPawnByPlayerId(playerId)
    local targetId = tonumber(playerId)
    if not targetId then
        return nil
    end

    for _, pawn in pairs(GetAllPawns() or {}) do
        if pawn.PlayerState and tonumber(pawn.PlayerState:GetPlayerId()) == targetId then
            return pawn
        end
    end

    return nil
end

local function restoreSpectateView()
    local controller = HPlayer
    if not controller then
        return
    end

    local pawn = GetPlayerPawn()
    if pawn then
        controller:SetViewTargetWithBlend(pawn, 0.0, 0, 0.0, false)
    end
end

local function stopSpectating()
    restoreSpectateView()
    spectateTargetId = nil
end

local function startSpectating(targetPlayerId)
    local targetPawn = getPawnByPlayerId(targetPlayerId)
    if not targetPawn then
        exports['qb-core']:Notify('Spectate target is not available.', 'error')
        return
    end

    stopSpectating()
    spectateTargetId = tonumber(targetPlayerId)
    if not HPlayer then
        spectateTargetId = nil
        exports['qb-core']:Notify('Unable to start spectate view.', 'error')
        return
    end

    ui_open = false
    my_webui:SetInputMode(0)
    my_webui:SendEvent('closeAdmin')

    HPlayer:SetViewTargetWithBlend(targetPawn, 0.0, 0, 0.0, false)
end

RegisterClientEvent('qb-admin:client:spectatePlayer', function(targetPlayerId)
    if spectateTargetId == tonumber(targetPlayerId) then
        stopSpectating()
        return
    end

    startSpectating(targetPlayerId)
end)

Input.BindKey('Backspace', function()
    if spectateTargetId then
        stopSpectating()
    end
end, 'Released')

-- Commands

local HConsole = GetActorByTag('HConsole')

if HConsole then
    HConsole:RegisterCommand('report', 'Make a report', nil, {
        HWorld,
        function()
            TriggerServerEvent('qb-admin:server:fileReport', { message = 'Test' })
        end,
    })
end
