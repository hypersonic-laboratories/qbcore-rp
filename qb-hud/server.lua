-- Commands

RegisterCommand('cash', '', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local cashAmount = Player.PlayerData.money['cash']
    TriggerClientEvent(source, 'qb-hud:client:ShowAccounts', 'cash', cashAmount)
end)

RegisterCommand('bank', '', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local bankAmount = Player.PlayerData.money['bank']
    TriggerClientEvent(source, 'qb-hud:client:ShowAccounts', 'bank', bankAmount)
end)

-- Events

RegisterServerEvent('qb-hud:server:GainStress', function(source, amount)
    if Config.DisableStress then return end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local Job = Player.PlayerData.job.name
    local JobType = Player.PlayerData.job.type
    local newStress
    if not Player or Config.WhitelistedJobs[JobType] or Config.WhitelistedJobs[Job] then return end
    if not ResetStress then
        if not Player.PlayerData.metadata['stress'] then
            Player.PlayerData.metadata['stress'] = 0
        end
        newStress = Player.PlayerData.metadata['stress'] + amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then
        newStress = 100
    end
    Player.SetMetaData('stress', newStress)
end)

RegisterServerEvent('qb-hud:server:RelieveStress', function(source, amount)
    if Config.DisableStress then return end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local newStress
    if not ResetStress then
        if not Player.PlayerData.metadata['stress'] then
            Player.PlayerData.metadata['stress'] = 0
        end
        newStress = Player.PlayerData.metadata['stress'] - amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then
        newStress = 100
    end
    Player.SetMetaData('stress', newStress)
end)
