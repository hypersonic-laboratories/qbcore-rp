local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items') or {}

local function notify(source, text, notifyType)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType)
end

local function isLeoOnDuty(Player)
    return Player and Player.PlayerData.job and Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty
end

local function DnaHash(s)
    return string.gsub(tostring(s or ''), '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
end

local function canManageLicense(Player)
    return Player and Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.grade.level >= Config.LicenseRank
end

RegisterServerEvent('qb-policejob:server:GrantLicense', function(source, targetId, licenseType)
    -- TODO(helix): Wire this to a qb-target/menu flow; original command was /grantlicense.
    local Player = exports['qb-core']:GetPlayer(source)
    if not canManageLicense(Player) then
        notify(source, Lang.t('error.rank_license'), 'error')
        return
    end

    if licenseType ~= 'driver' and licenseType ~= 'weapon' then
        notify(source, Lang.t('error.error_license_type'), 'error')
        return
    end

    local SearchedPlayer = exports['qb-core']:GetPlayer(tonumber(targetId))
    if not SearchedPlayer then
        return
    end

    local licenseTable = SearchedPlayer.PlayerData.metadata['licences'] or {}
    if licenseTable[licenseType] then
        notify(source, Lang.t('error.license_already'), 'error')
        return
    end

    licenseTable[licenseType] = true
    SearchedPlayer.SetMetaData(SearchedPlayer, 'licences', licenseTable)
    notify(SearchedPlayer.PlayerData.source, Lang.t('success.granted_license'), 'success')
    notify(source, Lang.t('success.grant_license'), 'success')
end)

RegisterServerEvent('qb-policejob:server:RevokeLicense', function(source, targetId, licenseType)
    -- TODO(helix): Wire this to a qb-target/menu flow; original command was /revokelicense.
    local Player = exports['qb-core']:GetPlayer(source)
    if not canManageLicense(Player) then
        notify(source, Lang.t('error.rank_revoke'), 'error')
        return
    end

    if licenseType ~= 'driver' and licenseType ~= 'weapon' then
        notify(source, Lang.t('error.error_license'), 'error')
        return
    end

    local SearchedPlayer = exports['qb-core']:GetPlayer(tonumber(targetId))
    if not SearchedPlayer then
        return
    end

    local licenseTable = SearchedPlayer.PlayerData.metadata['licences'] or {}
    if not licenseTable[licenseType] then
        notify(source, Lang.t('error.error_license'), 'error')
        return
    end

    licenseTable[licenseType] = false
    SearchedPlayer.SetMetaData(SearchedPlayer, 'licences', licenseTable)
    notify(SearchedPlayer.PlayerData.source, Lang.t('error.revoked_license'), 'error')
    notify(source, Lang.t('success.revoke_license'), 'success')
end)

RegisterServerEvent('qb-policejob:server:SetCallsign', function(source, callsign)
    -- TODO(helix): Wire this to a UI flow; original command was /callsign.
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    Player.SetMetaData(Player, 'callsign', tostring(callsign or ''))
end)

RegisterServerEvent('qb-policejob:server:TakeDna', function(source, targetId)
    -- TODO(helix): Wire this to a qb-target/menu flow; original command was /takedna.
    local Player = exports['qb-core']:GetPlayer(source)
    local OtherPlayer = exports['qb-core']:GetPlayer(tonumber(targetId))
    if not OtherPlayer or not isLeoOnDuty(Player) then
        return
    end

    if exports['qb-inventory']:RemoveItem(source, 'empty_evidence_bag', 1, false, 'qb-policejob:takedna') then
        local info = {
            label = Lang.t('info.dna_sample'),
            type = 'dna',
            dnalabel = DnaHash(OtherPlayer.PlayerData.citizenid),
        }
        if exports['qb-inventory']:AddItem(source, 'filled_evidence_bag', 1, false, info, 'qb-policejob:takedna') then
            TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['filled_evidence_bag'], 'add')
        end
    else
        notify(source, Lang.t('error.have_evidence_bag'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:RequestTrackerLocation', function(source, citizenid)
    -- TODO(helix): Wire this to a UI flow; original command was /ankletlocation.
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeoOnDuty(Player) then
        notify(source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end

    local Target = exports['qb-core']:GetPlayerByCitizenId(citizenid)
    if not Target then
        return
    end
    if Target.PlayerData.metadata['tracker'] then
        TriggerClientEvent(Target.PlayerData.source, 'qb-policejob:client:SendTrackerLocation', source)
    else
        notify(source, Lang.t('error.no_anklet'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:FinePlayer', function(source, targetId, amount)
    -- TODO(helix): Wire this to a UI flow; original command was /fine.
    local biller = exports['qb-core']:GetPlayer(source)
    local billed = exports['qb-core']:GetPlayer(tonumber(targetId))
    amount = tonumber(amount)

    if not isLeoOnDuty(biller) then
        notify(source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end

    if not billed then
        notify(source, Lang.t('error.not_online'), 'error')
        return
    end

    if biller.PlayerData.citizenid == billed.PlayerData.citizenid then
        notify(source, Lang.t('error.fine_yourself'), 'error')
        return
    end

    if not amount or amount <= 0 then
        notify(source, Lang.t('error.amount_higher'), 'error')
        return
    end

    if billed.RemoveMoney(billed, 'bank', amount, 'paid-fine') or billed.RemoveMoney(billed, 'cash', amount, 'paid-fine') then
        notify(source, Lang.t('info.fine_issued'), 'success')
        notify(billed.PlayerData.source, Lang.t('info.received_fine'))
        exports['qb-banking']:AddMoney(biller.PlayerData.job.name, amount, 'Fine')
    end
end)

RegisterServerEvent('qb-policejob:server:PayTow', function(source, targetId)
    -- TODO(helix): Wire this to a UI flow; original command was /paytow.
    local Player = exports['qb-core']:GetPlayer(source)
    local OtherPlayer = exports['qb-core']:GetPlayer(tonumber(targetId))
    if not isLeoOnDuty(Player) or not OtherPlayer then
        return
    end

    if OtherPlayer.PlayerData.job.name == 'tow' then
        OtherPlayer.AddMoney(OtherPlayer, 'bank', 500, 'police-tow-paid')
        notify(OtherPlayer.PlayerData.source, Lang.t('success.tow_paid'), 'success')
        notify(source, Lang.t('info.tow_driver_paid'))
    else
        notify(source, Lang.t('error.not_towdriver'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:PayLawyer', function(source, targetId)
    -- TODO(helix): Wire this to a UI flow; original command was /paylawyer.
    local Player = exports['qb-core']:GetPlayer(source)
    local OtherPlayer = exports['qb-core']:GetPlayer(tonumber(targetId))
    if not Player or not OtherPlayer then
        return
    end
    if Player.PlayerData.job.type ~= 'leo' and Player.PlayerData.job.name ~= 'judge' then
        notify(source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end

    if OtherPlayer.PlayerData.job.name == 'lawyer' then
        OtherPlayer.AddMoney(OtherPlayer, 'bank', 500, 'police-lawyer-paid')
        notify(OtherPlayer.PlayerData.source, Lang.t('success.tow_paid'), 'success')
        notify(source, Lang.t('info.paid_lawyer'))
    else
        notify(source, Lang.t('error.not_lawyer'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:PoliceReport', function(source, message)
    -- TODO(helix): Wire this to a UI flow; original command was /911p.
    message = tostring(message or Lang.t('commands.civilian_call'))
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end

    local coords = GetEntityCoords(pawn)
    for _, v in pairs(exports['qb-core']:GetQBPlayers()) do
        if isLeoOnDuty(v) then
            local alertData = { title = Lang.t('commands.emergency_call'), coords = { x = coords.X, y = coords.Y, z = coords.Z }, description = message }
            TriggerClientEvent(v.PlayerData.source, 'qb-phone:client:addPoliceAlert', alertData)
            TriggerClientEvent(v.PlayerData.source, 'qb-policejob:client:policeAlert', coords, message)
        end
    end
end)

-- TODO(helix): The original command names are intentionally not registered:
-- grantlicense, revokelicense, takedrivinglicense, spikestrip, pobject, cuff,
-- escort, callsign, jail, unjail, seizecash, sc, fine, clearcasings,
-- clearblood, takedna, anklet, ankletlocation, depot, impound, cam, paytow,
-- paylawyer, and 911p.
