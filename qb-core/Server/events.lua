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

-- Events

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
end)

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
