-- Player Dropped
AddEventHandler('playerDropped', function(reason)
    local src = source
    if not QBCore.Players[src] then return end
    local player = QBCore.Players[src]
    TriggerLocalServerEvent('qb-log:server:CreateLog', 'joinleave', 'Dropped', 'red', '**' .. GetPlayerName(src) .. '** (' .. player.PlayerData.license .. ') left..' .. '\n **Reason:** ' .. reason)
    player:Save()
    TriggerLocalServerEvent('QBCore:Server:OnPlayerUnload', src)
    QBCore.PlayersByCitizenId[player.PlayerData.citizenid] = nil
    QBCore.Players[src] = nil
end)

-- Open & Close Server (prevents players from joining)

RegisterServerEvent('QBCore:Server:CloseServer', function(source, reason)
    if QBCore.Functions.HasPermission(source, 'admin') then
        reason = reason or 'No reason specified'
        QBCore.Config.Server.Closed = true
        QBCore.Config.Server.ClosedReason = reason
        for k in pairs(QBCore.Players) do
            if not QBCore.Functions.HasPermission(k, QBCore.Config.Server.WhitelistPermission) then
                QBCore.Functions.Kick(k, reason, nil, nil)
            end
        end
    else
        QBCore.Functions.Kick(source, Lang:t('error.no_permission'), nil, nil)
    end
end)

RegisterServerEvent('QBCore:Server:OpenServer', function(source)
    if QBCore.Functions.HasPermission(source, 'admin') then
        QBCore.Config.Server.Closed = false
    else
        QBCore.Functions.Kick(source, Lang:t('error.no_permission'), nil, nil)
    end
end)

-- Hunger/Thirst Damage --

RegisterServerEvent('QBCore:Server:ApplyHungerThirstDamage', function(source, amount)
    local pawn = GetPlayerPawn(source)
    if not pawn then return end
    local healthComp = pawn:GetComponentByClass(UE.UHActorHealthComponent)
    if not healthComp then return end
    local currentHealth = healthComp:GetHealth()
    if currentHealth > 0 then
        healthComp:SetHealth(math.max(0, currentHealth - amount))
    end
end)

-- Callback Events --

-- Client Callback
RegisterServerEvent('QBCore:Server:TriggerClientCallback', function(source, name, ...)
    local ClientCallback = QBCore.ClientCallbacks[name .. source]
    if ClientCallback then
        ClientCallback.promise:resolve(...)

        if ClientCallback.callback then
            ClientCallback.callback(...)
        end

        QBCore.ClientCallbacks[name .. source] = nil
    end
end)

-- Server Callback
RegisterServerEvent('QBCore:Server:TriggerCallback', function(source, name, ...)
    if not QBCore.ServerCallbacks[name] then return end

    QBCore.ServerCallbacks[name](source, function(...)
        TriggerClientEvent(source, 'QBCore:Client:TriggerCallback', name, ...)
    end, ...)
end)

-- Player

local updateCooldowns = {}
RegisterServerEvent('QBCore:UpdatePlayer', function(source)
    local now = GetGameTimer()
    if updateCooldowns[source] and (now - updateCooldowns[source]) < 10000 then return end
    updateCooldowns[source] = now
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local newHunger = Player.PlayerData.metadata['hunger'] - QBCore.Config.Player.HungerRate
    local newThirst = Player.PlayerData.metadata['thirst'] - QBCore.Config.Player.ThirstRate
    if newHunger <= 0 then
        newHunger = 0
    end
    if newThirst <= 0 then
        newThirst = 0
    end
    Player.PlayerData.metadata['hunger'] = newHunger
    Player.PlayerData.metadata['thirst'] = newThirst
    Player:UpdateClient('metadata', Player.PlayerData.metadata)
    TriggerClientEvent(source, 'hud:client:UpdateNeeds', newHunger, newThirst)
    Player:Save()
end)

RegisterServerEvent('QBCore:ToggleDuty', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.onduty then
        Player:SetJobDuty(false)
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.off_duty'))
    else
        Player:SetJobDuty(true)
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.on_duty'))
    end

    TriggerLocalServerEvent('QBCore:Server:SetDuty', source, Player.PlayerData.job.onduty)
    TriggerClientEvent(source, 'QBCore:Client:SetDuty', Player.PlayerData.job.onduty)
end)

RegisterServerEvent('QBCore:Server:OnPlayerLoaded', function(source)
    if not QBCore.Players[source] then return end
    TriggerClientEvent(source, 'QBCore:Client:SharedUpdate', QBCore.Shared)
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerLoaded')
end)

-- Central server-side data change handler — re-fires legacy events for backward compat
AddEventHandler('QBCore:Server:OnPlayerUpdated', function(src, key, val)
    if key == 'job' then
        TriggerLocalServerEvent('QBCore:Server:OnJobUpdate', src, val)
    elseif key == 'gang' then
        TriggerLocalServerEvent('QBCore:Server:OnGangUpdate', src, val)
    elseif key == 'all' then
        TriggerLocalServerEvent('QBCore:Server:OnJobUpdate', src, val.job)
        TriggerLocalServerEvent('QBCore:Server:OnGangUpdate', src, val.gang)
    end
end)

-- Non-Chat Command Calling (ex: qb-adminmenu)

RegisterServerEvent('QBCore:CallCommand', function(source, command, args)
    if not QBCore.Commands.List[command] then return end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local hasPerm = QBCore.Functions.HasPermission(source, 'command.' .. QBCore.Commands.List[command].name)
    if hasPerm then
        if QBCore.Commands.List[command].argsrequired and #QBCore.Commands.List[command].arguments ~= 0 and not args[#QBCore.Commands.List[command].arguments] then
            TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.missing_args2'), 'error')
        else
            QBCore.Commands.List[command].callback(source, args)
        end
    else
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.no_access'), 'error')
    end
end)
