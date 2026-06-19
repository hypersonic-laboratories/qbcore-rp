local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')
local currentDivingArea = math.random(1, #Config.CoralLocations)

-- Helpers

local function getItemPrice(amount, price)
    for k, v in pairs(Config.BonusTiers) do
        local isLastTier = #Config.BonusTiers == k
        local modifier = isLastTier and amount >= v.minAmount or (amount >= v.minAmount and amount <= v.maxAmount)
        if modifier then
            local percent = math.random(v.minBonus, v.maxBonus) / 100
            price = math.ceil(price + price * percent)
        end
    end
    return price
end

local function hasCoral(Player)
    local found = {}
    for _, v in pairs(Config.CoralTypes) do
        local item = Player.GetItemByName(v.item)
        if item then
            found[#found + 1] = { type = v, item = item }
        end
    end
    return #found > 0, found
end

-- Events

RegisterServerEvent('qb-diving:server:CallCops', function(source, coords)
    for _, Player in pairs(exports['qb-core']:GetQBPlayers()) do
        if Player and Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            local msg = Lang.t('info.cop_msg')
            TriggerClientEvent(Player.PlayerData.source, 'qb-diving:client:CallCops', coords, msg)
            BroadcastEvent('qb-phone:client:addPoliceAlert', {
                title = Lang.t('info.cop_title'),
                coords = coords,
                description = msg,
            })
        end
    end
end)

RegisterServerEvent('qb-diving:server:SellCorals', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local ok, corals = hasCoral(Player)
    if not ok then
        TriggerClientEvent(source, 'QBCore:Notify', Lang.t('error.no_coral'), 'error')
        return
    end

    for _, entry in ipairs(corals) do
        local amount = entry.item.amount
        local price = amount * entry.type.price
        local reward = getItemPrice(amount, price)
        Player.RemoveItem(entry.type.item, amount)
        Player.AddMoney('cash', reward, 'qb-diving:SellCorals')
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[entry.type.item], 'remove')
    end
end)

RegisterServerEvent('qb-diving:server:TakeCoral', function(source, area, coral, bool)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local coralType = Config.CoralTypes[math.random(1, #Config.CoralTypes)]
    local amount = math.random(1, coralType.maxAmount)
    local ItemData = sharedItems[coralType.item]

    Player.AddItem(coralType.item, amount)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', ItemData, 'add')

    local loc = Config.CoralLocations[area]
    if (loc.TotalCoral - 1) <= 0 then
        -- reset current location
        for _, v in pairs(Config.CoralLocations[currentDivingArea].coords.Coral) do
            v.PickedUp = false
        end
        Config.CoralLocations[currentDivingArea].TotalCoral = Config.CoralLocations[currentDivingArea].DefaultCoral

        -- pick a new location different from the current
        local newLocation
        repeat
            newLocation = math.random(1, #Config.CoralLocations)
        until newLocation ~= currentDivingArea

        currentDivingArea = newLocation
        BroadcastEvent('qb-diving:client:NewLocations')
    else
        Config.CoralLocations[area].coords.Coral[coral].PickedUp = bool
        Config.CoralLocations[area].TotalCoral = Config.CoralLocations[area].TotalCoral - 1
    end

    BroadcastEvent('qb-diving:client:UpdateCoral', area, coral, bool)
end)

RegisterServerEvent('qb-diving:server:removeItemAfterFill', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    Player.RemoveItem('diving_fill', 1)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['diving_fill'], 'remove')
end)

-- Usable items

exports['qb-core']:CreateUseableItem('diving_gear', { event = 'qb-diving:server:useDivingGear' })
exports['qb-core']:CreateUseableItem('diving_fill', { event = 'qb-diving:server:useDivingFill' })

RegisterServerEvent('qb-diving:server:useDivingGear', function(source)
    TriggerClientEvent(source, 'qb-diving:client:UseGear')
end)

RegisterServerEvent('qb-diving:server:useDivingFill', function(source)
    TriggerClientEvent(source, 'qb-diving:client:SetOxygenLevel')
end)

-- Callback

RegisterCallback('qb-diving:server:GetDivingConfig', function(source)
    return { locations = Config.CoralLocations, area = currentDivingArea }
end)
