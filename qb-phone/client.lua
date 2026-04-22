local my_webui = WebUI('qb-phone', 'qb-phone/html/index.html')
local phoneOpen = false

local function openPhone()
    phoneOpen = true
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('open')
end

local function closePhone()
    phoneOpen = false
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end

-- WebUI Events

my_webui:RegisterEventHandler('close', function()
    closePhone()
end)

my_webui:RegisterEventHandler('dial', function(data)
    TriggerServerEvent('qb-phone:server:dial', data.number)
end)

my_webui:RegisterEventHandler('acceptCall', function()
    TriggerServerEvent('qb-phone:server:accept')
end)

my_webui:RegisterEventHandler('hangup', function()
    TriggerServerEvent('qb-phone:server:hangup')
end)

-- Call Events

RegisterClientEvent('qb-phone:client:incomingCall', function(callerName, callerNumber)
    if not phoneOpen then openPhone() end
    my_webui:SendEvent('incomingCall', callerName, callerNumber)
end)

RegisterClientEvent('qb-phone:client:callRinging', function(targetName, targetNumber)
    my_webui:SendEvent('callRinging', targetName, targetNumber)
end)

RegisterClientEvent('qb-phone:client:callStarted', function(channel)
    my_webui:SendEvent('callStarted', channel)
end)

RegisterClientEvent('qb-phone:client:callEnded', function()
    my_webui:SendEvent('callEnded')
end)

RegisterClientEvent('qb-phone:client:callFailed', function(reason)
    my_webui:SendEvent('callFailed', reason)
end)

-- Lifecycle

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

-- Input

Input.BindKey('O', function()
    if HPlayer:GetInputMode() == 1 and not phoneOpen then return end
    if phoneOpen then
        closePhone()
    else
        openPhone()
    end
end, 'Pressed')
