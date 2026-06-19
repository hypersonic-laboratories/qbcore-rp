local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

local activeMelts = {}
local readyMelts = {}

local function ItemLabel(itemName)
    local item = sharedItems[itemName]
    return item and item.label or itemName
end

local function FindPawnItem(itemName)
    for i = 1, #Config.PawnItems do
        local item = Config.PawnItems[i]
        if item.item == itemName then
            return item
        end
    end
end

local function FindMeltingItem(itemName)
    for i = 1, #Config.MeltingItems do
        local item = Config.MeltingItems[i]
        if item.item == itemName then
            return item
        end
    end
end

local function IsNearPawnshop(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return false
    end

    local playerCoords = GetEntityCoords(pawn)
    for _, value in pairs(Config.PawnLocation) do
        local distance = GetDistanceBetweenCoords(playerCoords, value.coords)
        if distance <= (value.serverDistance or 750) then
            return true
        end
    end

    return false
end

local function Notify(source, text, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType or 'primary', length)
end

local function ExploitBan(source, reason)
    local Player = exports['qb-core']:GetPlayer(source)
    local playerName = exports['qb-core']:GetPlayerName(source) or tostring(source)
    local license = Player and Player.PlayerData and Player.PlayerData.license or nil

    exports['qb-core']:DatabaseAction(
        'Execute',
        'INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { playerName, license or '', '', '', reason, 2147483647, 'qb-pawnshop' }
    )
    TriggerLocalServerEvent('qb-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red',
        string.format('%s was banned by qb-pawnshop for %s', playerName, reason), true)
    source:Kick('You were permanently banned by the server for: Exploiting')
end

local function SendMeltNotification(source)
    if Config.SendMeltingEmail then
        local Player = exports['qb-core']:GetPlayer(source)
        if Player and Player.PlayerData then
            local mailId = tostring(math.random(100000, 999999))
            exports['qb-core']:DatabaseAction(
                'Execute',
                'INSERT INTO player_mails (citizenid, sender, sender_number, subject, message, read, starred, mailid) VALUES (?, ?, ?, ?, ?, 0, 0, ?)',
                {
                    Player.PlayerData.citizenid,
                    Lang.t('info.title'),
                    'pawnshop',
                    Lang.t('info.subject'),
                    Lang.t('info.message'),
                    mailId,
                }
            )
            TriggerClientEvent(source, 'qb-phone:client:emailReceived', JSON.stringify({
                id = tonumber(mailId),
                from = Lang.t('info.title'),
                fromNumber = 'pawnshop',
                subject = Lang.t('info.subject'),
                snippet = Lang.t('info.message'),
                body = Lang.t('info.message'),
                time = os.date('%H:%M'),
                read = false,
                starred = false,
            }))
            return
        end
    end

    Notify(source, Lang.t('info.message'), 'success')
end

RegisterServerEvent('qb-pawnshop:server:sellPawnItems', function(source, itemName, itemAmount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    if not IsNearPawnshop(source) then
        ExploitBan(source, 'sellPawnItems exploiting')
        return
    end

    local pawnItem = FindPawnItem(itemName)
    local amount = tonumber(itemAmount)
    if not pawnItem or not amount or amount <= 0 then
        Notify(source, Lang.t('error.invalid_item'), 'error')
        return
    end

    local totalPrice = amount * pawnItem.price
    if Player:RemoveItem(itemName, amount, false) then
        if Config.BankMoney then
            Player:AddMoney('bank', totalPrice, 'qb-pawnshop:server:sellPawnItems')
        else
            Player:AddMoney('cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')
        end
        Notify(source, Lang.t('success.sold', { value = amount, value2 = ItemLabel(itemName), value3 = totalPrice }), 'success')
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[itemName], 'remove')
    else
        Notify(source, Lang.t('error.no_items'), 'error')
    end
    TriggerClientEvent(source, 'qb-pawnshop:client:openMenu')
end)

RegisterServerEvent('qb-pawnshop:server:meltItemRemove', function(source, itemName, itemAmount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    if not IsNearPawnshop(source) then
        ExploitBan(source, 'meltItemRemove exploiting')
        return
    end

    if activeMelts[source] or readyMelts[source] then
        Notify(source, Lang.t('error.already_melting'), 'error')
        return
    end

    local meltItem = FindMeltingItem(itemName)
    local amount = tonumber(itemAmount)
    if not meltItem or not amount or amount <= 0 then
        Notify(source, Lang.t('error.invalid_item'), 'error')
        return
    end

    if Player:RemoveItem(itemName, amount, false) then
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[itemName], 'remove')
        local meltTime = amount * meltItem.meltTime
        activeMelts[source] = true
        TriggerClientEvent(source, 'qb-pawnshop:client:startMelting')
        Notify(source, Lang.t('info.melt_wait', { value = meltTime }), 'primary')

        Timer.SetTimeout(function()
            if not activeMelts[source] or not exports['qb-core']:GetPlayer(source) then
                activeMelts[source] = nil
                return
            end

            activeMelts[source] = nil
            readyMelts[source] = {
                {
                    item = itemName,
                    amount = amount,
                    rewards = meltItem.rewards,
                },
            }
            TriggerClientEvent(source, 'qb-pawnshop:client:meltReady')
            SendMeltNotification(source)
        end, math.floor(meltTime * 60000))
    else
        Notify(source, Lang.t('error.no_items'), 'error')
    end
end)

RegisterServerEvent('qb-pawnshop:server:pickupMelted', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    if not IsNearPawnshop(source) then
        ExploitBan(source, 'pickupMelted exploiting')
        return
    end

    local meltedItems = readyMelts[source]
    if not meltedItems then
        Notify(source, Lang.t('error.no_melt'), 'error')
        return
    end

    for _, melted in pairs(meltedItems) do
        for _, reward in pairs(melted.rewards or {}) do
            local rewardAmount = melted.amount * reward.amount
            if Player:AddItem(reward.item, rewardAmount, false, false) then
                TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[reward.item], 'add')
                Notify(source, Lang.t('success.items_received', { value = rewardAmount, value2 = ItemLabel(reward.item) }), 'success')
            else
                Notify(source, Lang.t('error.inventory_full', { value = ItemLabel(reward.item) }), 'warning', 7500)
            end
        end
    end

    readyMelts[source] = nil
    TriggerClientEvent(source, 'qb-pawnshop:client:resetPickup')
    TriggerClientEvent(source, 'qb-pawnshop:client:openMenu')
end)

RegisterCallback('qb-pawnshop:server:getShopData', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return {
            inventory = {},
            pawnItems = Config.PawnItems,
            meltingItems = Config.MeltingItems,
            isMelting = false,
            canTake = false,
        }
    end
    return {
        inventory = Player.PlayerData.items or {},
        pawnItems = Config.PawnItems,
        meltingItems = Config.MeltingItems,
        isMelting = activeMelts[source] == true,
        canTake = readyMelts[source] ~= nil,
    }
end)

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    activeMelts[source] = nil
    readyMelts[source] = nil
end)
