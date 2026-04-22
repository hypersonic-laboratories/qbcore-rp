local QBCore = exports['qb-core']:GetCoreObject()

local pendingCalls = {}
local activeCalls  = {}

local function genChannel()
    return math.random(50000, 99999)
end

RegisterServerEvent('qb-phone:server:dial', function(source, targetNumber)
    local caller = QBCore.Functions.GetPlayer(source)
    if not caller then return end

    local target = QBCore.Functions.GetPlayerByPhone(targetNumber)
    if not target then
        TriggerClientEvent('qb-phone:client:callFailed', caller.PlayerData.source, 'unavailable')
        return
    end

    local callerIntSrc = caller.PlayerData.source
    local targetIntSrc = target.PlayerData.source

    if targetIntSrc == callerIntSrc then return end

    if pendingCalls[targetIntSrc] then
        TriggerClientEvent('qb-phone:client:callFailed', callerIntSrc, 'busy')
        return
    end

    local callerName   = caller.PlayerData.charinfo.firstname .. ' ' .. caller.PlayerData.charinfo.lastname
    local callerNumber = caller.PlayerData.charinfo.phone
    local targetName   = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname

    pendingCalls[targetIntSrc] = {
        callerSrc    = source,
        callerIntSrc = callerIntSrc,
        channel      = genChannel(),
        callerName   = callerName,
        callerNumber = callerNumber,
    }

    TriggerClientEvent('qb-phone:client:incomingCall', targetIntSrc, callerName, callerNumber)
    TriggerClientEvent('qb-phone:client:callRinging',  callerIntSrc, targetName, targetNumber)
end)

RegisterServerEvent('qb-phone:server:accept', function(source)
    local player = QBCore.Functions.GetPlayer(source)
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

    TriggerClientEvent('qb-phone:client:callStarted', pending.callerIntSrc, pending.channel)
    TriggerClientEvent('qb-phone:client:callStarted', targetIntSrc,         pending.channel)
end)

RegisterServerEvent('qb-phone:server:hangup', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end

    local intSrc = player.PlayerData.source

    for channel, call in pairs(activeCalls) do
        if call.callerIntSrc == intSrc or call.targetIntSrc == intSrc then
            activeCalls[channel] = nil
            call.callerSrc:LeaveVoiceChannel(channel)
            call.targetSrc:LeaveVoiceChannel(channel)
            TriggerClientEvent('qb-phone:client:callEnded', call.callerIntSrc)
            TriggerClientEvent('qb-phone:client:callEnded', call.targetIntSrc)
            return
        end
    end

    for targetSrc, pending in pairs(pendingCalls) do
        if pending.callerIntSrc == intSrc or targetSrc == intSrc then
            pendingCalls[targetSrc] = nil
            TriggerClientEvent('qb-phone:client:callEnded', pending.callerIntSrc)
            TriggerClientEvent('qb-phone:client:callEnded', targetSrc)
            return
        end
    end
end)
