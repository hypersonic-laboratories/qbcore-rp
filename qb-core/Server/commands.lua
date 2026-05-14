local Lang = require('Shared/locales/en')

-- Commands

RegisterCommand('clearprops', '', function(source)
    local ped = source:GetControlledCharacter()
    if not ped then
        return
    end
    local attached = ped:GetAttachedEntities()
    for i = 1, #attached do
        attached[i]:Detach()
        attached[i]:Destroy()
    end
end)

RegisterCommand('dm', 'DM Player', function(source, args)
    local targetId = tonumber(args[1])
    local message = table.concat(args, ' ', 2)
    local target = QBCore.Functions.GetPlayer(targetId)
    if not target then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    local sourcePlayer = QBCore.Functions.GetPlayer(source)
    if not sourcePlayer then
        return
    end
    local targetPlayer = target.PlayerData.source
    local prefix = sourcePlayer.PlayerData.charinfo.firstname .. ' ' .. sourcePlayer.PlayerData.charinfo.lastname
    Chat.SendMessage(targetPlayer, '(' .. source:GetID() .. ') ' .. prefix .. ': ' .. message)
end)

RegisterCommand('id', 'Check ID', function(source)
    local PlayerState = source:GetLyraPlayerState()
    local player_id = PlayerState:GetPlayerId()
    TriggerClientEvent(source, 'QBCore:Notify', 'Your ID is: ' .. player_id)
end)

-- Permissions

RegisterCommand('addpermission', Lang:t('command.addpermission.help'), function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    local permission = tostring(args[2]):lower()
    AddPermission(Player.PlayerData.source, permission)
end, true)

RegisterCommand('removepermission', Lang:t('command.removepermission.help'), function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    local permission = tostring(args[2]):lower()
    RemovePermission(Player.PlayerData.source, permission)
end, true)

-- Vehicle

RegisterCommand('car', Lang:t('command.car.help'), function(source, args)

end, true)

RegisterCommand('weapon', Lang:t('command.weapon.help'), function(source, args)

end, true)

RegisterCommand('maxammo', 'Max Ammo', function(source)

end, true)

-- Delete

RegisterCommand('dv', Lang:t('command.dv.help'), function(source)
    local pawn = GetPlayerPawn(source)
    local coords = GetEntityCoords(pawn)
    local closest_vehicle, distance = GetClosestVehicle(coords)
    if distance < 1000 then
        DeleteVehicle(closest_vehicle)
    end
end, true)

RegisterCommand('dvall', Lang:t('command.dvall.help'), function(source)
    local vehicles = GetAllVehicles()
    for _, vehicle in ipairs(vehicles) do
        DeleteVehicle(vehicle)
    end
end, true)

RegisterCommand('dvp', Lang:t('command.dvp.help'), function(source)
    local peds = GetAllPawns()
    for _, ped in ipairs(peds) do
        if ped ~= GetPlayerPawn(source) then
            DeleteEntity(ped)
        end
    end
end, true)

-- Money

RegisterCommand('givemoney', Lang:t('command.givemoney.help'), function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    Player:AddMoney(tostring(args[2]), tonumber(args[3]), 'Admin give money')
end, true)

RegisterCommand('setmoney', Lang:t('command.setmoney.help'), function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    Player:SetMoney(tostring(args[2]), tonumber(args[3]))
end, true)

-- Job

RegisterCommand('job', Lang:t('command.job.help'), function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerJob = Player.PlayerData.job
    TriggerClientEvent(
        source,
        'QBCore:Notify',
        Lang:t('info.job_info', { value = PlayerJob.label, value2 = PlayerJob.grade.name, value3 = PlayerJob.onduty })
    )
end)

RegisterCommand('setjob', Lang:t('command.setjob.help'), function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    Player:SetJob(tostring(args[2]), tonumber(args[3]))
end, true)

-- Gang

RegisterCommand('gang', Lang:t('command.gang.help'), function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return
    end
    local PlayerGang = Player.PlayerData.gang
    TriggerClientEvent(
        source,
        'QBCore:Notify',
        Lang:t('info.gang_info', { value = PlayerGang.label, value2 = PlayerGang.grade.name })
    )
end)

RegisterCommand('setgang', Lang:t('command.setgang.help'), function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
        return
    end
    Player:SetGang(tostring(args[2]), tonumber(args[3]))
end, true)
