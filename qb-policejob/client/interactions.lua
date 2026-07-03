local Lang = require('locales/en')
local isEscorting = false
local playerTargetsRegistered = false
local HOSTAGE_ANIM_PREFIX = '/HelixAnimation/Unified/Animations/HostageSet/'
local CUFF_START_OFFICER_ANIM = HOSTAGE_ANIM_PREFIX .. 'Paired_Handcuffs/Paired_HandcuffHostage_Start_Att.Paired_HandcuffHostage_Start_Att'
local CUFF_START_VICTIM_ANIM = HOSTAGE_ANIM_PREFIX .. 'Paired_Handcuffs/Paired_HandcuffHostage_Start_Vic.Paired_HandcuffHostage_Start_Vic'
local CUFF_LOOP_VICTIM_ANIM = HOSTAGE_ANIM_PREFIX .. 'Paired_Handcuffs/Paired_HandcuffHostage_Loop_Vic.Paired_HandcuffHostage_Loop_Vic'

exports('qb-policejob', 'IsHandcuffed', function()
    return isHandcuffed
end)

local function getPlayerIdFromEntity(entity)
    if not entity or not entity.PlayerState then
        return nil
    end
    return entity.PlayerState:GetPlayerId()
end

local function getClosestPlayerId(maxDistance)
    local pawn = GetPlayerPawn()
    if not pawn then
        return nil, -1
    end

    local closestPawn, distance = GetClosestPawn(GetEntityCoords(pawn), maxDistance or 250.0, pawn)
    if closestPawn and closestPawn.PlayerState then
        return closestPawn.PlayerState:GetPlayerId(), distance
    end

    return nil, -1
end

local function getTargetPlayerId(data, maxDistance)
    local entityPlayerId = getPlayerIdFromEntity(data and data.entity)
    if entityPlayerId then
        return entityPlayerId, 0.0
    end
    return getClosestPlayerId(maxDistance or 250.0)
end

local function notifyNoNearby()
    exports['qb-core']:Notify(Lang.t('error.none_nearby'), 'error')
end

local function getLocalPawn()
    local pawn = GetPlayerPawn()
    if pawn and pawn.IsValid and not pawn:IsValid() then
        return nil
    end
    return pawn
end

local function playPoliceAnimation(assetPath, loop, onEnded)
    local pawn = getLocalPawn()
    if not pawn or not Animation or not Animation.Play then
        return false
    end

    local animParams = UE.FHPlayAnimParams()
    animParams.LoopCount = loop and -1 or 1
    return Animation.Play(pawn, assetPath, animParams, onEnded)
end

local function stopPoliceAnimation()
    local pawn = getLocalPawn()
    if pawn and Animation and Animation.Stop then
        Animation.Stop(pawn)
    end
end

local function playCuffedLoop()
    playPoliceAnimation(CUFF_LOOP_VICTIM_ANIM, true)
end

local function refreshRestrainedAnimation()
    if isHandcuffed or isEscorted then
        playCuffedLoop()
    else
        stopPoliceAnimation()
    end
end

local function playCuffStartThenLoop()
    local started = playPoliceAnimation(CUFF_START_VICTIM_ANIM, false, function()
        if isHandcuffed then
            playCuffedLoop()
        end
    end)

    if not started then
        playCuffedLoop()
    end
end

local function triggerNearbyServer(eventName, data, ...)
    local playerId, distance = getTargetPlayerId(data)
    if playerId and distance < 250.0 then
        TriggerServerEvent(eventName, playerId, ...)
        return true
    end
    notifyNoNearby()
    return false
end

local function registerPlayerTargets()
    if playerTargetsRegistered then
        return
    end
    playerTargetsRegistered = true

    exports['qb-target']:AddGlobalPlayer({
        distance = 250,
        options = {
            {
                type = 'client',
                event = 'qb-policejob:client:SearchPlayer',
                icon = 'search',
                label = 'Search Player',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:CuffPlayer',
                icon = 'link',
                label = 'Cuff Player',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:CuffPlayerSoft',
                icon = 'link-2',
                label = 'Soft Cuff Player',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:EscortPlayer',
                icon = 'hand',
                label = 'Escort Player',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:SeizeCash',
                icon = 'wallet',
                label = 'Seize Cash',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:SeizeDriverLicense',
                icon = 'id-card',
                label = 'Seize Driver License',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:JailPlayer',
                icon = 'landmark',
                label = 'Jail Player',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:BillPlayer',
                icon = 'receipt',
                label = 'Bill Player',
                jobType = 'leo',
            },
            {
                type = 'client',
                event = 'qb-policejob:client:CheckDistance',
                icon = 'radio-tower',
                label = 'Toggle Tracker',
                jobType = 'leo',
            },
        },
    })
end

PoliceLoadedHandlers[#PoliceLoadedHandlers + 1] = function()
    registerPlayerTargets()
end

RegisterClientEvent('qb-policejob:client:SetOutVehicle', function()
    -- TODO(helix): Vehicle seat ejection needs Helix vehicle support.
    exports['qb-core']:Notify('TODO: Removing a player from a vehicle is not implemented in Helix yet.', 'primary')
end)

RegisterClientEvent('qb-policejob:client:PutInVehicle', function()
    -- TODO(helix): Vehicle seating needs Helix vehicle support.
    exports['qb-core']:Notify('TODO: Putting a player into a vehicle is not implemented in Helix yet.', 'primary')
end)

RegisterClientEvent('qb-policejob:client:SearchPlayer', function(data)
    triggerNearbyServer('qb-policejob:server:SearchPlayer', data)
end)

RegisterClientEvent('qb-policejob:client:SeizeCash', function(data)
    triggerNearbyServer('qb-policejob:server:SeizeCash', data)
end)

RegisterClientEvent('qb-policejob:client:SeizeDriverLicense', function(data)
    triggerNearbyServer('qb-policejob:server:SeizeDriverLicense', data)
end)

RegisterClientEvent('qb-policejob:client:RobPlayer', function(data)
    -- Progressbar is intentionally instant in Helix.
    triggerNearbyServer('qb-policejob:server:RobPlayer', data)
end)

RegisterClientEvent('qb-policejob:client:JailPlayer', function(data)
    local playerId, distance = getTargetPlayerId(data)
    if not playerId or distance >= 250.0 then
        notifyNoNearby()
        return
    end

    local dialog = exports['qb-input']:ShowInput({
        header = Lang.t('info.jail_time_input'),
        submitText = Lang.t('info.submit'),
        inputs = {
            {
                text = Lang.t('info.time_months'),
                name = 'jailtime',
                type = 'number',
                isRequired = true,
            },
        },
    })

    local jailtime = dialog and tonumber(dialog.jailtime)
    if jailtime and jailtime > 0 then
        TriggerServerEvent('qb-policejob:server:JailPlayer', playerId, jailtime)
    else
        exports['qb-core']:Notify(Lang.t('error.time_higher'), 'error')
    end
end)

RegisterClientEvent('qb-policejob:client:BillPlayer', function(data)
    local playerId, distance = getTargetPlayerId(data)
    if not playerId or distance >= 250.0 then
        notifyNoNearby()
        return
    end

    local dialog = exports['qb-input']:ShowInput({
        header = Lang.t('info.bill'),
        submitText = Lang.t('info.submit'),
        inputs = {
            {
                text = Lang.t('info.amount'),
                name = 'bill',
                type = 'number',
                isRequired = true,
            },
        },
    })

    local bill = dialog and tonumber(dialog.bill)
    if bill and bill > 0 then
        TriggerServerEvent('qb-policejob:server:BillPlayer', playerId, bill)
    else
        exports['qb-core']:Notify(Lang.t('error.amount_higher'), 'error')
    end
end)

RegisterClientEvent('qb-policejob:client:PutPlayerInVehicle', function(data)
    triggerNearbyServer('qb-policejob:server:PutPlayerInVehicle', data)
end)

RegisterClientEvent('qb-policejob:client:SetPlayerOutVehicle', function(data)
    triggerNearbyServer('qb-policejob:server:SetPlayerOutVehicle', data)
end)

RegisterClientEvent('qb-policejob:client:EscortPlayer', function(data)
    triggerNearbyServer('qb-policejob:server:EscortPlayer', data)
end)

RegisterClientEvent('qb-policejob:client:KidnapPlayer', function(data)
    triggerNearbyServer('qb-policejob:server:KidnapPlayer', data)
end)

RegisterClientEvent('qb-policejob:client:CuffPlayerSoft', function(data)
    triggerNearbyServer('qb-policejob:server:CuffPlayer', data, true)
end)

RegisterClientEvent('qb-policejob:client:CuffPlayer', function(data)
    triggerNearbyServer('qb-policejob:server:CuffPlayer', data, false)
end)

RegisterClientEvent('qb-policejob:client:PlayCuffingAnimation', function()
    playPoliceAnimation(CUFF_START_OFFICER_ANIM, false)
end)

RegisterClientEvent('qb-policejob:client:GetEscorted', function(escorted)
    if type(escorted) == 'boolean' then
        isEscorted = escorted
    else
        isEscorted = not isEscorted
    end
    refreshRestrainedAnimation()
end)

RegisterClientEvent('qb-policejob:client:DeEscort', function()
    isEscorted = false
    refreshRestrainedAnimation()
end)

RegisterClientEvent('qb-policejob:client:GetKidnappedTarget', function()
    isEscorted = not isEscorted
    -- TODO(helix): Kidnap carry animation/attachment needs a Helix implementation.
    exports['qb-core']:Notify(isEscorted and 'TODO: Kidnap carry state enabled.' or 'Kidnap carry state disabled.', 'primary')
end)

RegisterClientEvent('qb-policejob:client:GetKidnappedDragger', function()
    isEscorting = not isEscorting
    -- TODO(helix): Kidnap dragger animation needs a Helix implementation.
end)

RegisterClientEvent('qb-policejob:client:GetCuffed', function(_, isSoftcuff)
    if not isHandcuffed then
        isHandcuffed = true
        cuffType = isSoftcuff and 49 or 16
        TriggerServerEvent('qb-policejob:server:SetHandcuffStatus', true)
        exports['qb-core']:Notify(isSoftcuff and Lang.t('info.cuffed_walk') or Lang.t('info.cuff'), 'primary')
        playCuffStartThenLoop()
    else
        isHandcuffed = false
        isEscorted = false
        TriggerServerEvent('qb-policejob:server:SetHandcuffStatus', false)
        exports['qb-core']:Notify(Lang.t('success.uncuffed'), 'success')
        stopPoliceAnimation()
    end

    -- TODO(helix): Full handcuff input suppression still needs a Helix control-lock equivalent.
end)
