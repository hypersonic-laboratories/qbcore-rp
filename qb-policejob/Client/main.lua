local Lang = require('locales/en')

QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
isHandcuffed = false
cuffType = 1
isEscorted = false
PlayerJob = {}

local StationMarkers = {}

local function clearStationMarkers()
    for _, markerId in ipairs(StationMarkers) do
        exports['qb-hud']:RemoveMarker(markerId)
    end
    StationMarkers = {}
end

local function createStationMarkers()
    clearStationMarkers()
    for stationKey, station in pairs(Config.Locations) do
        local coords = station.coords or (station.duty and station.duty[1]) or (station.stash and station.stash[1])
        if coords then
            local markerId = exports['qb-hud']:AddMarker(coords, {
                title = station.label or stationKey,
                icon = 'police',
                markerType = 'Store',
            })
            if markerId then
                StationMarkers[#StationMarkers + 1] = markerId
            end
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    local player = exports['qb-core']:GetPlayerData()
    PlayerJob = player.job or {}
    isHandcuffed = false
    TriggerServerEvent('qb-policejob:server:SetHandcuffStatus', false)
    TriggerServerEvent('qb-policejob:server:UpdateBlips')
    TriggerServerEvent('qb-policejob:server:UpdateCurrentCops')
    createStationMarkers()

    -- TODO(helix): Tracker clothing/accessory application is not available yet.
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerServerEvent('qb-policejob:server:UpdateBlips')
    TriggerServerEvent('qb-policejob:server:SetHandcuffStatus', false)
    TriggerServerEvent('qb-policejob:server:UpdateCurrentCops')
    isHandcuffed = false
    isEscorted = false
    PlayerJob = {}
    clearStationMarkers()
end)

RegisterClientEvent('QBCore:Client:SetDuty', function(newDuty)
    PlayerJob.onduty = newDuty
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo or {}
    TriggerServerEvent('qb-policejob:server:UpdateBlips')
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'job' then
        PlayerJob = val or {}
        TriggerServerEvent('qb-policejob:server:UpdateBlips')
    elseif key == 'all' then
        PlayerJob = val.job or {}
        TriggerServerEvent('qb-policejob:server:UpdateBlips')
    end
end)

RegisterClientEvent('qb-policejob:client:sendBillingMail', function(amount)
    local playerData = exports['qb-core']:GetPlayerData()
    local charinfo = playerData.charinfo or {}
    local gender = Lang.t('info.mr')
    if charinfo.gender == 1 then
        gender = Lang.t('info.mrs')
    end
    TriggerServerEvent('qb-phone:server:sendNewMail', {
        sender = Lang.t('email.sender'),
        subject = Lang.t('email.subject'),
        message = Lang.t('email.message', { value = gender, value2 = charinfo.lastname or '', value3 = amount }),
        button = {},
    })
end)

RegisterClientEvent('qb-policejob:client:UpdateBlips', function(_)
    -- TODO(helix): Moving duty blips need a Helix map/player tracking API.
end)

RegisterClientEvent('qb-policejob:client:policeAlert', function(coords, text)
    exports['qb-core']:Notify({ text = text, caption = Lang.t('info.new_call') }, 'police')

    if not coords then
        return
    end
    local markerId = exports['qb-hud']:AddMarker(Vector(coords.X or coords.x, coords.Y or coords.y, coords.Z or coords.z), {
        title = Lang.t('info.blip_text', { value = text }),
        description = text,
        icon = 'police',
        markerType = 'Alert',
    })

    if markerId then
        Timer.SetTimeout(function()
            exports['qb-hud']:RemoveMarker(markerId)
        end, 180000)
    end
end)

RegisterClientEvent('qb-policejob:client:SendToJail', function(time)
    TriggerServerEvent('qb-policejob:server:SetHandcuffStatus', false)
    isHandcuffed = false
    isEscorted = false
    -- TODO(helix): Prison transport/instance flow is not implemented yet.
    exports['qb-core']:Notify(('TODO: Jail sentence received for %s months.'):format(tostring(time)), 'primary')
end)

RegisterClientEvent('qb-policejob:client:SendPoliceEmergencyAlert', function()
    local Player = exports['qb-core']:GetPlayerData()
    local charinfo = Player.charinfo or {}
    local metadata = Player.metadata or {}
    local message = Lang.t('info.officer_down', { lastname = charinfo.lastname or '', callsign = metadata.callsign or '' })
    TriggerServerEvent('qb-policejob:server:policeAlert', message)
    TriggerServerEvent('hospital:server:ambulanceAlert', message)
end)
