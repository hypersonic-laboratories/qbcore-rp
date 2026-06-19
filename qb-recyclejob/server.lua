local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

local Materials = {
    { item = 'metalscrap', min = 1, max = 5 },
    { item = 'plastic', min = 1, max = 5 },
    { item = 'copper', min = 1, max = 5 },
    { item = 'rubber', min = 1, max = 5 },
    { item = 'iron', min = 1, max = 5 },
    { item = 'aluminum', min = 1, max = 5 },
    { item = 'steel', min = 1, max = 5 },
    { item = 'glass', min = 1, max = 5 },
}

local luckyItem = 'cryptostick'
local maxReceived = 5
local luckyItemChance = 20
local uhohs = {}
local Sales = {}
local Stock = {}
local jobPeds = {}
local Initialised = false

local function DeleteActor(actor)
    if actor and actor:IsValid() then
        DeleteEntity(actor)
    end
end

local function SpawnJobPed(location, depotIndex, pedName)
    HPawn(location.coords, Rotator(0, location.heading or 0, 0), function(npc)
        if not npc then
            return
        end

        jobPeds[#jobPeds + 1] = { npc = npc, depot = depotIndex }
        npc:SetCharacterName(pedName)
        SetEntityInvincible(npc, true)
    end, { CharacterName = pedName, bShowNameplate = true })
end

function onShutdown()
    for i = 1, #jobPeds do
        DeleteActor(jobPeds[i].npc)
    end
    jobPeds = {}
end

if Config.SellMaterials then
    Sales = {
        metalscrap = 2,
        plastic = 2,
        copper = 2,
        rubber = 2,
        iron = 2,
        aluminum = 2,
        steel = 2,
        glass = 2,
    }
end

if Config.LimitedMaterials then
    Stock = {
        metalscrap = 3000,
        plastic = 3000,
        copper = 3000,
        rubber = 3000,
        iron = 3000,
        aluminum = 3000,
        steel = 3000,
        glass = 3000,
    }
end

RegisterServerEvent('HEvent:PlayerPossessed', function()
    if Initialised then
        return
    end

    if Config.SellMaterials and Config.SellPed then
        SpawnJobPed(Config.SellPed, 1, Config.SellPed.label or 'Recycling Buyer')
    end

    Initialised = true
end)

RegisterCallback('getPeds', function()
    return jobPeds
end)

local function ItemLabel(itemName)
    local item = sharedItems[itemName]
    return item and item.label or itemName
end

local function Notify(source, text, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType or 'primary', length)
end

local function ExploitBan(source, reason)
    local Player = exports['qb-core']:GetPlayer(source)
    local playerName = exports['qb-core']:GetPlayerName(source) or tostring(source)
    local license = Player and Player.PlayerData and Player.PlayerData.license or ''

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        playerName,
        license,
        '',
        '',
        reason,
        2147483647,
        'qb-recyclejob',
    })
    TriggerLocalServerEvent('qb-log:server:CreateLog', 'recyclejob', 'Player Banned', 'red', string.format('%s was banned by qb-recyclejob for %s', playerName, reason), true)

    if source and (type(source) == 'userdata' or type(source) == 'table') then
        pcall(function()
            source:Kick('You were permanently banned by the server for: Exploiting')
        end)
    end
end

local function Strike(source, reason)
    local Player = exports['qb-core']:GetPlayer(source)
    local key = Player and Player.PlayerData and Player.PlayerData.citizenid or tostring(source)

    uhohs[key] = (uhohs[key] or 0) + 1
    if uhohs[key] >= 3 then
        ExploitBan(source, reason)
    end
end

local function IsClose(source, loc)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return false
    end

    local targetCoords
    if loc == 'turnIn' then
        targetCoords = Config.DropLocation.coords
    elseif loc == 'sell' and Config.SellPed then
        targetCoords = Config.SellPed.coords
    else
        return false
    end

    local playerCoords = GetEntityCoords(pawn)
    if GetDistanceBetweenCoords(playerCoords, targetCoords) <= (Config.ServerDistance or 700) then
        return true
    end

    Strike(source, 'Exploiting distance on qb-recyclejob')
    return false
end

local function AdjustStock(item, change, amount)
    if not Config.LimitedMaterials or not Stock[item] then
        return
    end

    if change == 'add' then
        Stock[item] = Stock[item] + amount
    elseif change == 'remove' then
        Stock[item] = Stock[item] - amount
    end
end

local function CheckStock(source, item, amount)
    if not Config.LimitedMaterials then
        return true
    end

    if Stock[item] and Stock[item] >= amount then
        return true
    end

    Notify(source, Lang.t('error.out_of_stock', { item = ItemLabel(item) }), 'error')
    return false
end

local function AddRewardItem(source, item, amount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end

    if not CheckStock(source, item, amount) then
        return false
    end

    if not Player.CanAddItem(item, amount) then
        Notify(source, Lang.t('error.inventory_full'), 'error')
        return false
    end

    if not Player.AddItem(item, amount) then
        Notify(source, Lang.t('error.inventory_full'), 'error')
        return false
    end

    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[item], 'add', amount)
    AdjustStock(item, 'remove', amount)
    return true
end

local function SellMaterials(source, item, amount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        Notify(source, Lang.t('error.invalid_amount'), 'error')
        return
    end

    local pricePer = Sales[item]
    if not pricePer then
        return
    end

    local has = Player.GetItemByName(item)
    if not has or not has.amount or has.amount <= 0 then
        Notify(source, Lang.t('error.nothing_to_sell'), 'error')
        return
    end

    amount = math.min(amount, has.amount)
    local price = pricePer * amount

    if Player.RemoveItem(item, amount) then
        Player.AddMoney('cash', price, 'qb-recyclejob:sell-materials')
        Notify(source, Lang.t('success.sold', { amount = amount, item = ItemLabel(item), price = price }), 'success')
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[item], 'remove', amount)
        AdjustStock(item, 'add', amount)
    else
        Notify(source, Lang.t('error.nothing_to_sell'), 'error')
    end
end

RegisterCallback('qb-recyclejob:server:getPriceList', function(source)
    if not Config.SellMaterials or not IsClose(source, 'sell') then
        return false
    end

    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return {}
    end

    local saleItems = {}
    for _, material in ipairs(Materials) do
        local itemName = material.item
        local price = Sales[itemName]
        local inventoryItem = price and Player.GetItemByName(itemName) or nil
        if inventoryItem and inventoryItem.amount and inventoryItem.amount > 0 then
            saleItems[#saleItems + 1] = {
                item = itemName,
                amount = inventoryItem.amount,
                price = price,
            }
        end
    end

    return saleItems
end)

RegisterServerEvent('qb-recyclejob:server:getItem', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    if not IsClose(source, 'turnIn') then
        return
    end

    for _ = 1, math.random(1, maxReceived) do
        local material = Materials[math.random(1, #Materials)]
        local amount = math.random(material.min, material.max)
        AddRewardItem(source, material.item, amount)
    end

    if math.random(1, 100) <= luckyItemChance then
        AddRewardItem(source, luckyItem, 1)
    end
end)

RegisterServerEvent('qb-recyclejob:server:sellItem', function(source, item, amount)
    if not Config.SellMaterials then
        return
    end

    if type(item) == 'table' then
        amount = item.amount
        item = item.item
    end

    if not IsClose(source, 'sell') then
        return
    end

    SellMaterials(source, item, amount)
end)

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    local key = Player and Player.PlayerData and Player.PlayerData.citizenid or tostring(source)
    uhohs[key] = nil
end)
