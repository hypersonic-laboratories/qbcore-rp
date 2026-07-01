local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items') or {}

QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })

local updatingCops = false

local function GetWeaponItem(weapon)
    if not weapon then
        return nil
    end

    local weaponName = tostring(weapon)
    local itemInfo = sharedItems[weaponName] or sharedItems[string.lower(weaponName)]
    if itemInfo and itemInfo.type == 'weapon' then
        return itemInfo
    end

    local loweredWeaponName = string.lower(weaponName)
    for _, sharedItem in pairs(sharedItems) do
        if sharedItem.type == 'weapon' and sharedItem.asset_name and string.lower(sharedItem.asset_name) == loweredWeaponName then
            return sharedItem
        end
    end

    return nil
end

local function notify(source, text, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType, length)
end

local function isLeo(Player)
    return Player and Player.PlayerData.job and Player.PlayerData.job.type == 'leo'
end

local function isLeoOnDuty(Player)
    return isLeo(Player) and Player.PlayerData.job.onduty
end

local function getPawnCoords(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return nil
    end
    return GetEntityCoords(pawn), GetEntityHeading(pawn)
end

local function UpdateBlips()
    local dutyPlayers = {}
    local players = exports['qb-core']:GetQBPlayers()
    for _, v in pairs(players) do
        if v and (v.PlayerData.job.type == 'leo' or v.PlayerData.job.type == 'ems') and v.PlayerData.job.onduty then
            local coords, heading = getPawnCoords(v.PlayerData.source)
            if coords then
                dutyPlayers[#dutyPlayers + 1] = {
                    source = v.PlayerData.source,
                    label = v.PlayerData.metadata['callsign'],
                    job = v.PlayerData.job.name,
                    location = {
                        x = coords.X,
                        y = coords.Y,
                        z = coords.Z,
                        w = heading or 0.0,
                    },
                }
            end
        end
    end
    BroadcastEvent('qb-policejob:client:UpdateBlips', dutyPlayers)
end

local function GetCurrentCops()
    local amount = 0
    local players = exports['qb-core']:GetQBPlayers()
    for _, v in pairs(players) do
        if isLeoOnDuty(v) then
            amount = amount + 1
        end
    end
    return amount
end

RegisterCallback('qb-policejob:GetDutyPlayers', function(_)
    local dutyPlayers = {}
    local players = exports['qb-core']:GetQBPlayers()
    for _, v in pairs(players) do
        if isLeoOnDuty(v) then
            dutyPlayers[#dutyPlayers + 1] = {
                source = v.PlayerData.source,
                label = v.PlayerData.metadata['callsign'],
                job = v.PlayerData.job.name,
            }
        end
    end
    return dutyPlayers
end)

RegisterCallback('qb-policejob:GetCops', function(_)
    return GetCurrentCops()
end)

RegisterCallback('qb-policejob:server:isPlayerDead', function(_, playerId)
    local Player = exports['qb-core']:GetPlayer(playerId)
    return Player and Player.PlayerData.metadata['isdead'] or false
end)

RegisterCallback('qb-policejob:IsSilencedWeapon', function(source, weapon)
    local Player = exports['qb-core']:GetPlayer(source)
    local weaponInfo = GetWeaponItem(weapon)
    if not Player or not weaponInfo then
        return false
    end

    local itemInfo = Player.GetItemByName(Player, weaponInfo.name)
    if itemInfo and itemInfo.info and itemInfo.info.attachments then
        for k in pairs(itemInfo.info.attachments) do
            local component = itemInfo.info.attachments[k].component
            if component == 'COMPONENT_AT_AR_SUPP_02' or component == 'COMPONENT_AT_AR_SUPP' or component == 'COMPONENT_AT_PI_SUPP_02' or component == 'COMPONENT_AT_PI_SUPP' then
                return true
            end
        end
    end
    return false
end)

RegisterCallback('qb-policejob:server:IsPoliceForcePresent', function(_)
    local players = exports['qb-core']:GetQBPlayers()
    for _, v in pairs(players) do
        if isLeo(v) and v.PlayerData.job.grade.level >= 2 then
            return true
        end
    end
    return false
end)

Timer.CreateThread(function()
    pcall(function()
        exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM inventories WHERE identifier = \'policetrash\'', {})
    end)
end)

RegisterServerEvent('qb-policejob:server:stash', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeo(Player) then
        return
    end

    local stashName = 'policestash_' .. Player.PlayerData.citizenid
    exports['qb-inventory']:OpenInventory(source, stashName)
end)

RegisterServerEvent('qb-policejob:server:trash', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeo(Player) then
        return
    end

    exports['qb-inventory']:OpenInventory(source, 'policetrash', {
        maxweight = 4000000,
        slots = 300,
    })
end)

RegisterServerEvent('qb-policejob:server:evidence', function(source, currentEvidence)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeo(Player) then
        return
    end

    exports['qb-inventory']:OpenInventory(source, currentEvidence, {
        maxweight = 4000000,
        slots = 500,
    })
end)

RegisterServerEvent('qb-policejob:server:policeAlert', function(source, text)
    local coords = getPawnCoords(source)
    if not coords then
        return
    end

    local players = exports['qb-core']:GetQBPlayers()
    for _, v in pairs(players) do
        if isLeoOnDuty(v) then
            local alertData = { title = Lang.t('info.new_call'), coords = { x = coords.X, y = coords.Y, z = coords.Z }, description = text }
            TriggerClientEvent(v.PlayerData.source, 'qb-phone:client:addPoliceAlert', alertData)
            TriggerClientEvent(v.PlayerData.source, 'qb-policejob:client:policeAlert', coords, text)
        end
    end
end)

RegisterServerEvent('qb-policejob:server:SendEmergencyMessage', function(_, coords, message)
    if not coords then
        return
    end

    local players = exports['qb-core']:GetQBPlayers()
    for _, v in pairs(players) do
        if isLeoOnDuty(v) then
            local alertData = { title = Lang.t('info.new_call'), coords = { x = coords.X or coords.x, y = coords.Y or coords.y, z = coords.Z or coords.z }, description = message }
            TriggerClientEvent(v.PlayerData.source, 'qb-phone:client:addPoliceAlert', alertData)
            TriggerClientEvent(v.PlayerData.source, 'qb-policejob:client:policeAlert', coords, message)
        end
    end
end)

RegisterServerEvent('qb-policejob:server:UpdateBlips', function(_)
    UpdateBlips()
end)

RegisterServerEvent('qb-policejob:server:UpdateCurrentCops', function(_)
    if updatingCops then
        return
    end
    updatingCops = true
    BroadcastEvent('qb-policejob:SetCopCount', GetCurrentCops())
    updatingCops = false
end)

RegisterServerEvent('qb-policejob:server:SetHandcuffStatus', function(source, handcuffed)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        Player.SetMetaData(Player, 'ishandcuffed', handcuffed)
    end
end)

RegisterServerEvent('qb-policejob:server:showFingerprint', function(source, playerId)
    TriggerClientEvent(playerId, 'qb-policejob:client:showFingerprint', source)
    TriggerClientEvent(source, 'qb-policejob:client:showFingerprint', playerId)
end)

RegisterServerEvent('qb-policejob:server:showFingerprintId', function(source, sessionId)
    local Player = exports['qb-core']:GetPlayer(source)
    local fid = Player and Player.PlayerData.metadata['fingerprint'] or nil
    TriggerClientEvent(sessionId, 'qb-policejob:client:showFingerprintId', fid)
    TriggerClientEvent(source, 'qb-policejob:client:showFingerprintId', fid)
end)

RegisterServerEvent('qb-policejob:server:SetTracker', function(source, targetId)
    local Target = exports['qb-core']:GetPlayer(targetId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not Target or not isLeoOnDuty(Player) then
        return
    end

    local TrackerMeta = Target.PlayerData.metadata['tracker']
    if TrackerMeta then
        Target.SetMetaData(Target, 'tracker', false)
        notify(targetId, Lang.t('success.anklet_taken_off'), 'success')
        notify(source, Lang.t('success.took_anklet_from', { firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname }), 'success')
        TriggerClientEvent(targetId, 'qb-policejob:client:SetTracker', false)
    else
        Target.SetMetaData(Target, 'tracker', true)
        notify(targetId, Lang.t('success.put_anklet'), 'success')
        notify(source, Lang.t('success.put_anklet_on', { firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname }), 'success')
        TriggerClientEvent(targetId, 'qb-policejob:client:SetTracker', true)
    end
end)

RegisterServerEvent('qb-policejob:server:SendTrackerLocation', function(source, coords, requestId)
    local Target = exports['qb-core']:GetPlayer(source)
    if not Target then
        return
    end

    local msg = Lang.t('info.target_location', { firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname })
    local alertData = {
        title = Lang.t('info.anklet_location'),
        coords = {
            x = coords.X or coords.x,
            y = coords.Y or coords.y,
            z = coords.Z or coords.z,
        },
        description = msg,
    }
    TriggerClientEvent(requestId, 'qb-policejob:client:TrackerMessage', msg, coords)
    TriggerClientEvent(requestId, 'qb-phone:client:addPoliceAlert', alertData)
end)

Timer.SetInterval(function()
    BroadcastEvent('qb-policejob:SetCopCount', GetCurrentCops())
end, 1000 * 60 * 10)

Timer.SetInterval(function()
    UpdateBlips()
end, 5000)

exports['qb-core']:CreateUseableItem('handcuffs', { event = 'qb-policejob:server:useHandcuffs' })
exports['qb-core']:CreateUseableItem('moneybag', { event = 'qb-policejob:server:useMoneyBag' })

RegisterServerEvent('qb-policejob:server:useHandcuffs', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not Player.GetItemByName(Player, 'handcuffs') then
        return
    end
    TriggerClientEvent(source, 'qb-policejob:client:CuffPlayerSoft')
end)

RegisterServerEvent('qb-policejob:server:useMoneyBag', function(source, item)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if not Player.GetItemByName(Player, 'moneybag') or not item or not item.info or item.info == '' then
        return
    end
    if Player.PlayerData.job.type ~= 'leo' then
        return
    end

    if not exports['qb-inventory']:RemoveItem(source, 'moneybag', 1, item.slot, 'qb-policejob:moneybag') then
        return
    end
    Player.AddMoney(Player, 'cash', tonumber(item.info.cash), 'qb-policejob:moneybag')
end)
