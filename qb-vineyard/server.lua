local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

-- Job ped

local jobPeds = {}
local Initialised = false

local function deleteActor(actor)
    if actor and actor:IsValid() then
        DeleteEntity(actor)
    end
end

local function spawnJobPed(location)
    local pedName = location.pedName or 'Vineyard Foreman'
    HPawn(location.coords, Rotator(0, location.heading or 0, 0), function(npc)
        if not npc then
            return
        end

        jobPeds[#jobPeds + 1] = { npc = npc }
        npc:SetCharacterName(pedName)
        SetEntityInvincible(npc, true)
    end, { CharacterName = pedName, bShowNameplate = true })
end

RegisterServerEvent('HEvent:PlayerPossessed', function()
    if Initialised then
        return
    end
    spawnJobPed(Config.Vineyard.start)
    Initialised = true
end)

function onShutdown()
    for i = 1, #jobPeds do
        deleteActor(jobPeds[i].npc)
    end
    jobPeds = {}
end

-- Callbacks

RegisterCallback('getPeds', function()
    return jobPeds
end)

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
