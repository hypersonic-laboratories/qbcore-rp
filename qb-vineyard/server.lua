local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

-- Callbacks

RegisterCallback('qb-vineyard:server:getPlayerJob', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return nil
    end
    return Player.PlayerData.job
end)

RegisterCallback('qb-vineyard:server:loadIngredients', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end

    if Player.PlayerData.job.name ~= 'vineyard' then
        TriggerClientEvent(source, 'QBCore:Notify', Lang.t('error.invalid_job'), 'error')
        return false
    end

    local grape = Player.GetItemByName('grapejuice')
    if not grape or grape.amount < 23 then
        TriggerClientEvent(source, 'QBCore:Notify', Lang.t('error.invalid_items'), 'error')
        return false
    end

    Player.RemoveItem('grapejuice', 23)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['grapejuice'], 'remove')
    return true
end)

RegisterCallback('qb-vineyard:server:grapeJuice', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end

    if Player.PlayerData.job.name ~= 'vineyard' then
        TriggerClientEvent(source, 'QBCore:Notify', Lang.t('error.invalid_job'), 'error')
        return false
    end

    local grape = Player.GetItemByName('grape')
    if not grape or grape.amount < 16 then
        TriggerClientEvent(source, 'QBCore:Notify', Lang.t('error.invalid_items'), 'error')
        return false
    end

    Player.RemoveItem('grape', 16)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['grape'], 'remove')
    return true
end)

-- Events

RegisterServerEvent('qb-vineyard:server:getGrapes', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if Player.PlayerData.job.name ~= 'vineyard' then
        return
    end

    local amount = math.random(Config.GrapeAmount.min, Config.GrapeAmount.max)
    Player.AddItem('grape', amount)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['grape'], 'add')
end)

RegisterServerEvent('qb-vineyard:server:receiveGrapeJuice', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if Player.PlayerData.job.name ~= 'vineyard' then
        return
    end

    local amount = math.random(Config.GrapeJuiceAmount.min, Config.GrapeJuiceAmount.max)
    Player.AddItem('grapejuice', amount)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['grapejuice'], 'add')
end)

RegisterServerEvent('qb-vineyard:server:receiveWine', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if Player.PlayerData.job.name ~= 'vineyard' then
        return
    end

    local amount = math.random(Config.WineAmount.min, Config.WineAmount.max)
    Player.AddItem('wine', amount)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['wine'], 'add')
end)
