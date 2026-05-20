QBCore.Commands = {}
QBCore.Commands.List = {}

function QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission)
    RegisterCommand(name, help, function(args)
        if argsrequired and #args < #arguments then
            return
        end
        callback(nil, args)
    end)

    QBCore.Commands.List[name:lower()] = {
        name = name:lower(),
        permission = permission,
        help = help,
        arguments = arguments,
        argsrequired = argsrequired,
        callback = callback
    }
end

-- PVP

QBCore.Commands.Add('togglepvp', Lang:t('command.togglepvp.help'), {}, false, function()
    QBCore.Config.Server.PVP = not QBCore.Config.Server.PVP
    BroadcastEvent('QBCore:Client:PvpHasToggled', QBCore.Config.Server.PVP)
end, 'admin')

-- Permissions

QBCore.Commands.Add('addpermission', Lang:t('command.addpermission.help'), { { name = Lang:t('command.addpermission.params.id.name'), help = Lang:t('command.addpermission.params.id.help') }, { name = Lang:t('command.addpermission.params.permission.name'), help = Lang:t('command.addpermission.params.permission.help') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        QBCore.Functions.AddPermission(Player.PlayerData.source, permission)
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
    end
end, 'god')

QBCore.Commands.Add('removepermission', Lang:t('command.removepermission.help'), { { name = Lang:t('command.removepermission.params.id.name'), help = Lang:t('command.removepermission.params.id.help') }, { name = Lang:t('command.removepermission.params.permission.name'), help = Lang:t('command.removepermission.params.permission.help') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        QBCore.Functions.RemovePermission(Player.PlayerData.source, permission)
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
    end
end, 'god')

-- Open & Close Server

QBCore.Commands.Add('openserver', Lang:t('command.openserver.help'), {}, false, function(source)
    if not QBCore.Config.Server.Closed then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.server_already_open'), 'error')
        return
    end
    if QBCore.Functions.HasPermission(source, 'admin') then
        QBCore.Config.Server.Closed = false
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.server_opened'), 'success')
    else
        QBCore.Functions.Kick(source, Lang:t('error.no_permission'), nil, nil)
    end
end, 'admin')

QBCore.Commands.Add('closeserver', Lang:t('command.closeserver.help'), { { name = Lang:t('command.closeserver.params.reason.name'), help = Lang:t('command.closeserver.params.reason.help') } }, false, function(source, args)
    if QBCore.Config.Server.Closed then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.server_already_closed'), 'error')
        return
    end
    if QBCore.Functions.HasPermission(source, 'admin') then
        local reason = args[1] or 'No reason specified'
        QBCore.Config.Server.Closed = true
        QBCore.Config.Server.ClosedReason = reason
        for k in pairs(QBCore.Players) do
            if not QBCore.Functions.HasPermission(k, QBCore.Config.Server.WhitelistPermission) then
                QBCore.Functions.Kick(k, reason, nil, nil)
            end
        end
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.server_closed'), 'success')
    else
        QBCore.Functions.Kick(source, Lang:t('error.no_permission'), nil, nil)
    end
end, 'admin')

-- Money

QBCore.Commands.Add('givemoney', Lang:t('command.givemoney.help'), { { name = Lang:t('command.givemoney.params.id.name'), help = Lang:t('command.givemoney.params.id.help') }, { name = Lang:t('command.givemoney.params.moneytype.name'), help = Lang:t('command.givemoney.params.moneytype.help') }, { name = Lang:t('command.givemoney.params.amount.name'), help = Lang:t('command.givemoney.params.amount.help') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player:AddMoney(tostring(args[2]), tonumber(args[3]), 'Admin give money')
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
    end
end, 'admin')

QBCore.Commands.Add('setmoney', Lang:t('command.setmoney.help'), { { name = Lang:t('command.setmoney.params.id.name'), help = Lang:t('command.setmoney.params.id.help') }, { name = Lang:t('command.setmoney.params.moneytype.name'), help = Lang:t('command.setmoney.params.moneytype.help') }, { name = Lang:t('command.setmoney.params.amount.name'), help = Lang:t('command.setmoney.params.amount.help') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player:SetMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Job

QBCore.Commands.Add('job', Lang:t('command.job.help'), {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerJob = Player.PlayerData.job
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.job_info', { value = PlayerJob.label, value2 = PlayerJob.grade.name, value3 = PlayerJob.onduty }))
end, 'user')

QBCore.Commands.Add('setjob', Lang:t('command.setjob.help'), { { name = Lang:t('command.setjob.params.id.name'), help = Lang:t('command.setjob.params.id.help') }, { name = Lang:t('command.setjob.params.job.name'), help = Lang:t('command.setjob.params.job.help') }, { name = Lang:t('command.setjob.params.grade.name'), help = Lang:t('command.setjob.params.grade.help') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player:SetJob(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Gang

QBCore.Commands.Add('gang', Lang:t('command.gang.help'), {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerGang = Player.PlayerData.gang
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.gang_info', { value = PlayerGang.label, value2 = PlayerGang.grade.name }))
end, 'user')

QBCore.Commands.Add('setgang', Lang:t('command.setgang.help'), { { name = Lang:t('command.setgang.params.id.name'), help = Lang:t('command.setgang.params.id.help') }, { name = Lang:t('command.setgang.params.gang.name'), help = Lang:t('command.setgang.params.gang.help') }, { name = Lang:t('command.setgang.params.grade.name'), help = Lang:t('command.setgang.params.grade.help') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player:SetGang(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Out of Character Chat

QBCore.Commands.Add('ooc', Lang:t('command.ooc.help'), {}, false, function(source, args)
    local message = table.concat(args, ' ')
    local Players = QBCore.Functions.GetPlayers()
    local Player = QBCore.Functions.GetPlayer(source)
    local playerCoords = GetEntityCoords(GetPlayerPawn(source))
    for _, v in pairs(Players) do
        if v == source or #(playerCoords - GetEntityCoords(GetPlayerPawn(v))) < 20.0 then
            TriggerClientEvent(v, 'QBCore:Notify', 'OOC | ' .. GetPlayerName(source) .. ': ' .. message)
        elseif QBCore.Functions.HasPermission(v, 'admin') and QBCore.Functions.IsOptin(v) then
            TriggerClientEvent(v, 'QBCore:Notify', 'Proximity OOC | ' .. GetPlayerName(source) .. ': ' .. message)
            TriggerLocalServerEvent('qb-log:server:CreateLog', 'ooc', 'OOC', 'white', '**' .. GetPlayerName(source) .. '** (CitizenID: ' .. Player.PlayerData.citizenid .. ' | ID: ' .. source .. ') **Message:** ' .. message, false)
        end
    end
end, 'user')
