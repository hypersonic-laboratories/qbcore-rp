local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items') or {}

local function notify(source, text, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType, length)
end

local function isLeo(Player)
    return Player and Player.PlayerData.job and Player.PlayerData.job.type == 'leo'
end

local function isLeoOnDuty(Player)
    return isLeo(Player) and Player.PlayerData.job.onduty
end

local function isNear(source, targetId, maxDistance)
    local playerPawn = GetPlayerPawn(source)
    local targetPawn = GetPlayerPawn(targetId)
    if not playerPawn or not targetPawn then
        return false
    end
    return GetDistanceBetweenCoords(GetEntityCoords(playerPawn), GetEntityCoords(targetPawn)) <= (maxDistance or 300.0)
end

local function setPawnMovement(pawn, enabled)
    if not pawn then
        return
    end

    local movement = pawn:GetComponentByClass(UE.UCharacterMovementComponent)
    if movement then
        movement:SetMovementMode(enabled and UE.EMovementMode.MOVE_Walking or UE.EMovementMode.MOVE_None, nil)
    end

    if enabled then
        local root = pawn:K2_GetRootComponent()
        if root then
            root:SetCollisionProfileName('LyraPawnCapsule', true)
        end
    end
end

local function detachEscortedPawn(playerId, escortSource)
    local targetPawn = GetPlayerPawn(playerId)
    if not targetPawn then
        return
    end

    if targetPawn.GetAttachParentActor and targetPawn:GetAttachParentActor() then
        DetachActor(targetPawn)
    end

    local escortPawn = escortSource and GetPlayerPawn(escortSource) or nil
    if escortPawn then
        local escortCoords = GetEntityCoords(escortPawn)
        local escortRotation = GetEntityRotation(escortPawn)
        SetEntityCoords(targetPawn, escortCoords + (escortRotation:GetForwardVector() * 100))
    end

    setPawnMovement(targetPawn, true)
end

local function toggleEscortAttachment(source, targetId)
    local playerPawn = GetPlayerPawn(source)
    local targetPawn = GetPlayerPawn(targetId)
    if not playerPawn or not targetPawn then
        return false
    end

    if targetPawn.GetAttachParentActor and targetPawn:GetAttachParentActor() then
        detachEscortedPawn(targetId, source)
        return false
    end

    setPawnMovement(targetPawn, false)
    local success = AttachActorToActor(targetPawn, playerPawn, Vector(100, 50, 0), Rotator(), 'root')
    if not success then
        setPawnMovement(targetPawn, true)
        return false
    end

    return true
end

RegisterServerEvent('qb-policejob:server:SearchPlayer', function(source, playerId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeo(Player) then
        return
    end

    local SearchedPlayer = exports['qb-core']:GetPlayer(tonumber(playerId))
    if SearchedPlayer and isNear(source, playerId) then
        exports['qb-inventory']:OpenInventoryById(source, tonumber(playerId))
        notify(source, Lang.t('info.cash_found', { cash = SearchedPlayer.PlayerData.money['cash'] }))
        notify(playerId, Lang.t('info.being_searched'))
    else
        notify(source, Lang.t('error.none_nearby'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:CuffPlayer', function(source, playerId, isSoftcuff)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local CuffedPlayer = exports['qb-core']:GetPlayer(playerId)
    if not Player or not CuffedPlayer then
        return
    end
    if not isLeoOnDuty(Player) or not Player.GetItemByName(Player, 'handcuffs') then
        return
    end

    if CuffedPlayer.PlayerData.metadata['ishandcuffed'] then
        detachEscortedPawn(CuffedPlayer.PlayerData.source, source)
    else
        TriggerClientEvent(Player.PlayerData.source, 'qb-policejob:client:PlayCuffingAnimation')
    end
    TriggerClientEvent(CuffedPlayer.PlayerData.source, 'qb-policejob:client:GetCuffed', Player.PlayerData.source, isSoftcuff)
end)

RegisterServerEvent('qb-policejob:server:EscortPlayer', function(source, playerId)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local EscortPlayer = exports['qb-core']:GetPlayer(playerId)
    if not Player or not EscortPlayer then
        return
    end

    if (Player.PlayerData.job.type == 'leo' or Player.PlayerData.job.name == 'ambulance') or (EscortPlayer.PlayerData.metadata['ishandcuffed'] or EscortPlayer.PlayerData.metadata['isdead'] or EscortPlayer.PlayerData.metadata['inlaststand']) then
        local escorted = toggleEscortAttachment(source, EscortPlayer.PlayerData.source)
        TriggerClientEvent(EscortPlayer.PlayerData.source, 'qb-policejob:client:GetEscorted', escorted)
    else
        notify(source, Lang.t('error.not_cuffed_dead'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:KidnapPlayer', function(source, playerId)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local EscortPlayer = exports['qb-core']:GetPlayer(playerId)
    if not Player or not EscortPlayer then
        return
    end

    if EscortPlayer.PlayerData.metadata['ishandcuffed'] or EscortPlayer.PlayerData.metadata['isdead'] or EscortPlayer.PlayerData.metadata['inlaststand'] then
        TriggerClientEvent(EscortPlayer.PlayerData.source, 'qb-policejob:client:GetKidnappedTarget', Player.PlayerData.source)
        TriggerClientEvent(Player.PlayerData.source, 'qb-policejob:client:GetKidnappedDragger', EscortPlayer.PlayerData.source)
    else
        notify(source, Lang.t('error.not_cuffed_dead'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:SetPlayerOutVehicle', function(source, playerId)
    -- TODO(helix): Vehicle seat interactions need Helix vehicle support.
    notify(source, 'TODO: Removing players from vehicles is not implemented in Helix yet.', 'primary')
    TriggerClientEvent(playerId, 'qb-policejob:client:SetOutVehicle')
end)

RegisterServerEvent('qb-policejob:server:PutPlayerInVehicle', function(source, playerId)
    -- TODO(helix): Vehicle seat interactions need Helix vehicle support.
    notify(source, 'TODO: Putting players into vehicles is not implemented in Helix yet.', 'primary')
    TriggerClientEvent(playerId, 'qb-policejob:client:PutInVehicle')
end)

RegisterServerEvent('qb-policejob:server:BillPlayer', function(source, playerId, price)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local OtherPlayer = exports['qb-core']:GetPlayer(playerId)
    price = tonumber(price)
    if not Player or not OtherPlayer or not price or not isLeo(Player) then
        return
    end

    OtherPlayer.RemoveMoney(OtherPlayer, 'bank', price, 'paid-bills')
    exports['qb-banking']:AddMoney('police', price, 'Fine paid')
    notify(OtherPlayer.PlayerData.source, Lang.t('info.fine_received', { fine = price }))
end)

RegisterServerEvent('qb-policejob:server:JailPlayer', function(source, playerId, time)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local OtherPlayer = exports['qb-core']:GetPlayer(playerId)
    time = tonumber(time)
    if not Player or not OtherPlayer or not time or not isLeo(Player) then
        return
    end

    local currentDate = os.date('*t')
    if currentDate.day == 31 then
        currentDate.day = 30
    end

    OtherPlayer.SetMetaData(OtherPlayer, 'injail', time)
    OtherPlayer.SetMetaData(OtherPlayer, 'criminalrecord', {
        ['hasRecord'] = true,
        ['date'] = currentDate,
    })
    TriggerClientEvent(OtherPlayer.PlayerData.source, 'qb-policejob:client:SendToJail', time)
    notify(source, Lang.t('info.sent_jail_for', { time = time }))
end)

RegisterServerEvent('qb-policejob:server:SeizeCash', function(source, playerId)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local SearchedPlayer = exports['qb-core']:GetPlayer(playerId)
    if not Player or not SearchedPlayer or not isLeo(Player) then
        return
    end

    local moneyAmount = SearchedPlayer.PlayerData.money['cash']
    local info = { cash = moneyAmount }
    SearchedPlayer.RemoveMoney(SearchedPlayer, 'cash', moneyAmount, 'police-cash-seized')
    exports['qb-inventory']:AddItem(source, 'moneybag', 1, false, info, 'qb-policejob:server:SeizeCash')
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['moneybag'], 'add')
    notify(SearchedPlayer.PlayerData.source, Lang.t('info.cash_confiscated'))
end)

RegisterServerEvent('qb-policejob:server:SeizeDriverLicense', function(source, playerId)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local SearchedPlayer = exports['qb-core']:GetPlayer(playerId)
    if not Player or not SearchedPlayer or not isLeo(Player) then
        return
    end

    local licenses = SearchedPlayer.PlayerData.metadata['licences'] or {}
    if licenses.driver then
        licenses.driver = false
        SearchedPlayer.SetMetaData(SearchedPlayer, 'licences', licenses)
        notify(SearchedPlayer.PlayerData.source, Lang.t('info.driving_license_confiscated'))
    else
        notify(source, Lang.t('error.no_driver_license'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:RobPlayer', function(source, playerId)
    if not isNear(source, playerId) then
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local SearchedPlayer = exports['qb-core']:GetPlayer(playerId)
    if not Player or not SearchedPlayer then
        return
    end

    local money = SearchedPlayer.PlayerData.money['cash']
    Player.AddMoney(Player, 'cash', money, 'police-player-robbed')
    SearchedPlayer.RemoveMoney(SearchedPlayer, 'cash', money, 'police-player-robbed')
    exports['qb-inventory']:OpenInventoryById(source, playerId)
    notify(SearchedPlayer.PlayerData.source, Lang.t('info.cash_robbed', { money = money }))
    notify(Player.PlayerData.source, Lang.t('info.stolen_money', { stolen = money }))
end)
