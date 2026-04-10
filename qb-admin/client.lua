local my_webui = WebUI('qb-admin', 'qb-admin/html/index.html')
local ui_open = false
local sky

-- Spawn Sky

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerCallback('syncRequest', function(skyInfo)
        sky = Sky()
        sky:SetTimeOfDay(skyInfo.time)
        sky:SetAnimateTimeOfDay(Config.AnimateTime)
        sky:ChangeWeather(Config.Weather.WeatherTypes[skyInfo.weather])
    end)
end)

-- Events

RegisterClientEvent('qb-admin:client:changeTime', function(hour)
    if not sky then return end
    sky:SetTimeOfDay(hour)
end)

RegisterClientEvent('qb-admin:client:changeWeather', function(weatherType)
    if not sky then return end
    local enumWeather = Config.Weather.WeatherTypes[weatherType] or WeatherType.ClearSkies
    sky:ChangeWeather(enumWeather, Config.Weather.TransitionDelay)
end)

-- NUI Events

my_webui:RegisterEventHandler('developer:teleportToLocation', function(data)
    local eventName = 'developer:teleportToLocation'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))

    if type(data) ~= 'table' then
        return
    end

    local locationKey = tostring(data.key or data.name or '')
    if locationKey == '' then
        return
    end

    TriggerServerEvent('qb-admin:server:developer:teleportToLocation', {
        key = locationKey,
    })
end)

my_webui:RegisterEventHandler('developer:teleportToCoordinates', function(data)
    local eventName = 'developer:teleportToCoordinates'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))

    if type(data) ~= 'table' then
        return
    end

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
    local eventName = 'developer:spawnVehicle'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:developer:spawnVehicle', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('developer:spawnObject', function(data)
    local eventName = 'developer:spawnObject'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:developer:spawnObject', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('developer:copyCoords', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local coords = GetEntityCoords(pawn)
    CopyToClipboard(('%s, %s, %s'):format(math.modf(coords.X), math.modf(coords.Y), math.modf(coords.Z)))
end)

my_webui:RegisterEventHandler('developer:copyRotation', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local rot = GetEntityRotation(pawn)
    CopyToClipboard(('%s, %s, %s'):format(math.modf(rot.Yaw), math.modf(rot.Roll), math.modf(rot.Pitch)))
end)

my_webui:RegisterEventHandler('developer:copyHeading', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local heading = GetEntityHeading(pawn)
    CopyToClipboard(('%s'):format(math.modf(heading)))
end)

my_webui:RegisterEventHandler('players:context-action', function(data)
    local eventName = 'players:context-action'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:context-action', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('players:vehicleAction', function(data)
    local eventName = 'players:vehicleAction'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:vehicleAction', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('players:gangAction', function(data)
    local eventName = 'players:gangAction'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:gangAction', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('players:jobAction', function(data)
    local eventName = 'players:jobAction'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:jobAction', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('players:quickControl', function(data)
    local eventName = 'players:quickControl'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:quickControl', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('players:replenishVital', function(data)
    local eventName = 'players:replenishVital'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:replenishVital', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('players:currencyAdjust', function(data)
    local eventName = 'players:currencyAdjust'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:players:currencyAdjust', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('dashboard:announce', function(data)
    local eventName = 'dashboard:announce'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:dashboard:announce', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('dashboard:quickAction', function(data)
    local eventName = 'dashboard:quickAction'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:dashboard:quickAction', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('chat:send', function(data)
    local eventName = 'chat:send'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:chat:send', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('environment:cleanup', function(data)
    local eventName = 'environment:cleanup'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:environment:cleanup', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('environment:changeWeather', function(data)
    local eventName = 'environment:changeWeather'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data.weather)))
    TriggerServerEvent('qb-admin:server:changeWeather', data.weather)
end)

my_webui:RegisterEventHandler('environment:changeTime', function(data)
    local eventName = 'environment:changeTime'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data.hour)))
    TriggerServerEvent('qb-admin:server:changeTime', data.hour)
end)

my_webui:RegisterEventHandler('reports:updateState', function(data)
    local eventName = 'reports:updateState'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:reports:updateState', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('reports:resolved', function(data)
    local eventName = 'reports:resolved'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:reports:resolved', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('reports:investigationAction', function(data)
    local eventName = 'reports:investigationAction'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:reports:investigationAction', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('reports:clearResolved', function(data)
    local eventName = 'reports:clearResolved'
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
    TriggerServerEvent('qb-admin:server:reports:clearResolved', type(data) == 'table' and data or {})
end)

my_webui:RegisterEventHandler('ui:close', function(data)
    local eventName = 'ui:close'
    ui_open = false
    my_webui:SetInputMode(0)
    print(('[qb-admin] %s payload: %s'):format(eventName, tostring(data)))
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

RegisterClientEvent('qb-admin:client:dashboardAnnounce', function(message)
    local announcement = tostring(message or '')
    if announcement == '' then
        return
    end

    print(('[qb-admin] Announcement: %s'):format(announcement))
end)

-- Commands

local HConsole = GetActorByTag('HConsole')

if HConsole then
    HConsole:RegisterCommand('report', 'Make a report', nil, { HWorld, function()
        TriggerServerEvent('qb-admin:server:fileReport', { message = 'Test' })
    end })
end
