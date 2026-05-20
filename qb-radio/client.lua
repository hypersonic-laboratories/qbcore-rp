local Lang = require('locales/en')
local my_webui = WebUI('qb-radio', 'qb-radio/html/index.html')
local isLoggedIn = false
local player_data = {}
local onRadio = false
local RadioChannel = 0
--local RadioVolume = 50
local radioOpen = false

-- Functions

local function leaveradio()
    if RadioChannel == 0 then return end
    TriggerCallback('LeaveVoiceChannel', function(success)
        if not success then return end
        RadioChannel = 0
        onRadio = false
        exports['qb-core']:Notify(Lang.t('you_leave'), 'error')
        TriggerLocalClientEvent('qb-hud:client:onRadio', onRadio)
    end, RadioChannel)
end

local function connecttoradio(channel)
    if channel <= 0 then return false end

    -- if Config.RestrictedChannels[channel] ~= nil then
    --     if not Config.RestrictedChannels[channel][player_data.job.name] or not player_data.job.onduty then
    --         exports['qb-core']:Notify(Lang.t('restricted_channel_error'), 'error')
    --         return false
    --     end
    -- end

    local intChannel = math.floor(channel)

    TriggerCallback('JoinVoiceChannel', function(success)
        if not success then return end
        RadioChannel = intChannel
        onRadio = true
        exports['qb-core']:Notify(Lang.t('joined_to_radio', { channel = intChannel .. ' MHz' }), 'success')
        TriggerLocalClientEvent('qb-hud:client:onRadio', onRadio)
        return true
    end, intChannel)

    return false
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    player_data = exports['qb-core']:GetPlayerData()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    player_data = nil
end)

-- UI

my_webui:RegisterEventHandler('joinRadio', function(data, cb)
    local rchannel = math.floor(tonumber(data.channel))
    if not rchannel then return end
    if rchannel < 0 then return end
    if rchannel == RadioChannel then return end

    local canaccess = connecttoradio(rchannel)
    if canaccess then
        cb({ canaccess = canaccess, channel = RadioChannel })
    else
        cb({ canaccess = false, channel = RadioChannel })
    end
end)

my_webui:RegisterEventHandler('leaveRadio', function()
    if RadioChannel == 0 then return end
    leaveradio()
end)

-- my_webui:RegisterEventHandler('volumeUp', function()
--     if RadioVolume <= 95 then
--         RadioVolume = RadioVolume + 5
--         exports['qb-core']:Notify(Lang.t('volume_radio', { value = RadioVolume }), 'success')
--     else
--         exports['qb-core']:Notify(Lang.t('decrease_radio_volume'), 'error')
--     end
-- end)

-- my_webui:RegisterEventHandler('volumeDown', function()
--     if RadioVolume >= 10 then
--         RadioVolume = RadioVolume - 5
--         exports['qb-core']:Notify(Lang.t('volume_radio', { value = RadioVolume }), 'success')
--     else
--         exports['qb-core']:Notify(Lang.t('increase_radio_volume'), 'error')
--     end
-- end)

my_webui:RegisterEventHandler('increaseradiochannel', function(_, cb)
    if not onRadio then return end
    local newChannel = math.floor(RadioChannel + 1)
    local canaccess = connecttoradio(newChannel)
    cb({ canaccess = canaccess, channel = newChannel })
end)

my_webui:RegisterEventHandler('decreaseradiochannel', function(_, cb)
    if not onRadio then return end
    local newChannel = math.floor(RadioChannel - 1)
    local canaccess = connecttoradio(newChannel)
    cb({ canaccess = canaccess, channel = newChannel })
end)

my_webui:RegisterEventHandler('poweredOff', function()
    leaveradio()
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
    radioOpen = false
end)

my_webui:RegisterEventHandler('closeRadio', function()
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
    radioOpen = false
end)

-- Input

Input.BindKey(Config.KeyBind, function()
    if not isLoggedIn then return end
    if HPlayer:GetInputMode() == 1 and not radioOpen then return end
    radioOpen = not radioOpen
    if radioOpen then
        my_webui:BringToFront()
        my_webui:SetInputMode(1)
        my_webui:SendEvent('open')
    else
        my_webui:SetInputMode(0)
        my_webui:SendEvent('close')
    end
end, 'Pressed')

exports('qb-radio', 'onRadio', function()
    return onRadio
end)
