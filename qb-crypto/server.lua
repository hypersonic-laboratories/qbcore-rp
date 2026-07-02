local Lang = require('locales/en')
local coin = Crypto.Coin
local sharedItems = exports['qb-core']:GetShared('Items')
local rebootTimer = nil
local priceTimer = nil

local function DecodeJson(value, fallback)
    if not value or value == '' then
        return fallback
    end

    local ok, decoded = pcall(JSON.parse, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return fallback
end

local function EncodeJson(value)
    return JSON.stringify(value or {})
end

local function Notify(source, text, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType or 'primary', length)
end

local function BroadcastWorth(name)
    BroadcastEvent('qb-crypto:client:UpdateCryptoWorth', name, Crypto.Worth[name], Crypto.History[name])
end

local function SaveCrypto(name)
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO crypto (crypto, worth, history) VALUES (?, ?, ?) ON CONFLICT(crypto) DO UPDATE SET worth = excluded.worth, history = excluded.history', { name, Crypto.Worth[name], EncodeJson(Crypto.History[name]) })
end

local function RefreshCrypto(name)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM crypto WHERE crypto = ? LIMIT 1', { name }) or {}
    local row = rows[1]

    if row then
        Crypto.Worth[name] = tonumber(row.worth) or Crypto.Worth[name]
        Crypto.History[name] = DecodeJson(row.history, Crypto.History[name] or {})
    else
        Crypto.History[name] = Crypto.History[name] or {}
        SaveCrypto(name)
    end

    BroadcastWorth(name)
end

local function AddHistory(name, previousWorth, newWorth)
    Crypto.History[name] = Crypto.History[name] or {}
    Crypto.History[name][#Crypto.History[name] + 1] = {
        PreviousWorth = previousWorth,
        NewWorth = newWorth,
    }

    while #Crypto.History[name] > 4 do
        table.remove(Crypto.History[name], 1)
    end
end

local function SetCryptoWorth(name, worth)
    local previousWorth = Crypto.Worth[name] or 0

    Crypto.Worth[name] = worth
    AddHistory(name, previousWorth, worth)
    SaveCrypto(name)
    BroadcastWorth(name)

    return previousWorth
end

local function SetRebootState(state, percentage)
    Crypto.Exchange.RebootInfo.state = state
    Crypto.Exchange.RebootInfo.percentage = percentage or 0
    BroadcastEvent('qb-crypto:client:GetRebootState', Crypto.Exchange.RebootInfo)
end

local function StopRebootTimer()
    if rebootTimer then
        Timer.ClearInterval(rebootTimer)
        rebootTimer = nil
    end
end

local function StartReboot()
    if Crypto.Exchange.RebootInfo.state then
        return
    end

    StopRebootTimer()
    SetRebootState(true, 0)
    BroadcastEvent('qb-crypto:client:SyncReboot')

    rebootTimer = Timer.SetInterval(function()
        local nextPercentage = (Crypto.Exchange.RebootInfo.percentage or 0) + 1

        if nextPercentage > 100 then
            StopRebootTimer()
            SetRebootState(false, 0)
            return
        end

        SetRebootState(true, nextPercentage)
    end, 1200)
end

local function GetPlayer(source)
    return exports['qb-core']:GetPlayer(source)
end

local function BuildCryptoData(Player, name)
    return {
        History = Crypto.History[name],
        Worth = Crypto.Worth[name],
        Portfolio = Player.PlayerData.money.crypto,
        WalletId = Player.PlayerData.metadata.walletid,
    }
end

local function GetCoins(data)
    local coins = tonumber(data and data.Coins)
    if not coins or coins <= 0 then
        return nil
    end

    return coins
end

local function SanitizeWalletTransfer(data)
    local coins = tostring(data and data.Coins or '')
    local walletId = tostring(data and data.WalletId or '')

    coins = coins:gsub('[%%$;]', '')
    walletId = walletId:gsub('[%%$;]', '')

    return tonumber(coins), walletId
end

local function AddPhoneTransaction(source, Player, data, message, transactionType)
    local playerData = Player and Player.PlayerData or {}
    TriggerLocalServerEvent('qb-crypto:server:PhoneTransaction', source, {
        citizenid = playerData.citizenid,
        name = playerData.name,
        charinfo = playerData.charinfo,
        money = playerData.money,
    }, data or {}, message, transactionType)
end

local function HandlePriceChange()
    local currentValue = Crypto.Worth[coin]
    local previousValue = Crypto.Worth[coin]
    local trend = math.random(0, 100)
    local event = math.random(0, 100)
    local chance = event - Crypto.ChanceOfCrashOrLuck

    if event > chance then
        if trend <= Crypto.ChanceOfDown then
            currentValue = currentValue - math.random(Crypto.CasualDown[1], Crypto.CasualDown[2])
        elseif trend >= Crypto.ChanceOfUp then
            currentValue = currentValue + math.random(Crypto.CasualUp[1], Crypto.CasualUp[2])
        end
    elseif math.random(0, 1) == 1 then
        currentValue = currentValue + math.random(Crypto.Luck[1], Crypto.Luck[2])
    else
        currentValue = currentValue - math.random(Crypto.Crash[1], Crypto.Crash[2])
    end

    currentValue = math.max(Crypto.Lower, math.min(Crypto.Upper, currentValue))

    Crypto.Worth[coin] = currentValue
    AddHistory(coin, previousValue, currentValue)
    SaveCrypto(coin)
    BroadcastWorth(coin)
end

RegisterCommand('setcryptoworth', 'Set crypto value', function(source, args)
    local crypto = tostring(args and args[1] or '')
    local newWorth = math.ceil(tonumber(args and args[2]) or 0)

    if crypto == '' then
        Notify(source, Lang.t('text.you_have_not_provided_crypto_available_qbit'))
        return
    end

    if Crypto.Worth[crypto] == nil then
        Notify(source, Lang.t('text.this_crypto_does_not_exist'))
        return
    end

    if newWorth <= 0 then
        Notify(source, Lang.t('text.you_have_not_given_a_new_value', { crypto = Crypto.Worth[crypto] }))
        return
    end

    local oldWorth = Crypto.Worth[crypto]
    local percentageChange = 0
    local changeLabel = ''

    if oldWorth ~= 0 then
        percentageChange = math.ceil(((newWorth - oldWorth) / oldWorth) * 100)
        changeLabel = percentageChange < 0 and '-' or '+'
        percentageChange = math.abs(percentageChange)
    end

    SetCryptoWorth(crypto, newWorth)
    Notify(
        source,
        Lang.t('text.changed_crypto_value', {
            cryptoLabel = Crypto.Labels[crypto] or crypto,
            oldWorth = oldWorth,
            newWorth = newWorth,
            changeLabel = changeLabel,
            percentageChange = percentageChange,
        })
    )
end, true)

RegisterCommand('checkcryptoworth', '', function(source)
    Notify(source, Lang.t('text.the_qbit_has_a_value_of', { crypto = Crypto.Worth.qbit }))
end)

RegisterCommand('crypto', '', function(source)
    local Player = GetPlayer(source)
    if not Player then
        return
    end

    local myPocket = math.ceil(Player.PlayerData.money.crypto * Crypto.Worth.qbit)
    Notify(
        source,
        Lang.t('text.you_have_with_a_value_of', {
            playerPlayerDataMoneyCrypto = Player.PlayerData.money.crypto,
            mypocket = myPocket,
        })
    )
end)

RegisterServerEvent('qb-crypto:server:FetchWorth', function()
    for name in pairs(Crypto.Worth) do
        RefreshCrypto(name)
    end
end)

RegisterServerEvent('qb-crypto:server:ExchangeFail', function(source)
    local Player = GetPlayer(source)
    if not Player then
        return
    end

    if Player:GetItemByName('cryptostick') then
        Player:RemoveItem('cryptostick', 1)
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems.cryptostick, 'remove')
        Notify(source, Lang.t('error.cryptostick_malfunctioned'), 'error')
    end
end)

RegisterServerEvent('qb-crypto:server:Rebooting', function(_, state, percentage)
    SetRebootState(state, percentage)
end)

RegisterServerEvent('qb-crypto:server:GetRebootState', function(source)
    TriggerClientEvent(source, 'qb-crypto:client:GetRebootState', Crypto.Exchange.RebootInfo)
end)

RegisterServerEvent('qb-crypto:server:SyncReboot', function()
    StartReboot()
end)

RegisterServerEvent('qb-crypto:server:ExchangeSuccess', function(source, luckChance)
    local Player = GetPlayer(source)
    if not Player then
        return
    end

    if not Player:GetItemByName('cryptostick') then
        return
    end

    local amount = math.random(611111, 1599999) / 1000000
    if luckChance == math.random(1, 10) then
        amount = math.random(1599999, 2599999) / 1000000
    end

    Player:RemoveItem('cryptostick', 1)
    Player:AddMoney('crypto', amount, 'qb-crypto:server:ExchangeSuccess')
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems.cryptostick, 'remove')
    Notify(source, Lang.t('success.you_have_exchanged_your_cryptostick_for', { amount = amount }), 'success', 3500)
    AddPhoneTransaction(source, Player, {}, Lang.t('credit.there_are_amount_credited', { amount = amount }), 'Credit')
end)

RegisterCallback('qb-crypto:server:HasSticky', function(source)
    local Player = GetPlayer(source)
    return Player and Player:GetItemByName('cryptostick') ~= nil or false
end)

RegisterCallback('qb-crypto:server:GetCryptoData', function(source, name)
    local Player = GetPlayer(source)
    name = name or 'qbit'

    if not Player or not Crypto.Worth[name] then
        return false
    end

    return BuildCryptoData(Player, name)
end)

RegisterCallback('qb-crypto:server:BuyCrypto', function(source, data)
    local Player = GetPlayer(source)
    local coins = GetCoins(data)
    if not Player or not coins then
        return false
    end

    local totalPrice = math.floor(coins * tonumber(Crypto.Worth.qbit))
    if Player.PlayerData.money.bank < totalPrice then
        return false
    end

    Player:RemoveMoney('bank', totalPrice, 'bought crypto')
    Player:AddMoney('crypto', coins, 'bought crypto')
    AddPhoneTransaction(source, Player, data, Lang.t('credit.you_have_qbit_purchased', { dataCoins = coins }), 'Credit')

    return BuildCryptoData(Player, 'qbit')
end)

RegisterCallback('qb-crypto:server:SellCrypto', function(source, data)
    local Player = GetPlayer(source)
    local coins = GetCoins(data)
    if not Player or not coins then
        return false
    end

    if Player.PlayerData.money.crypto < coins then
        return false
    end

    Player:RemoveMoney('crypto', coins, 'sold crypto')
    Player:AddMoney('bank', math.floor(coins * tonumber(Crypto.Worth.qbit)), 'sold crypto')
    AddPhoneTransaction(source, Player, data, Lang.t('debit.you_have_sold', { dataCoins = coins }), 'Debit')

    return BuildCryptoData(Player, 'qbit')
end)

RegisterCallback('qb-crypto:server:TransferCrypto', function(source, data)
    local coins, walletId = SanitizeWalletTransfer(data)
    local Player = GetPlayer(source)

    if not Player or not coins or coins <= 0 then
        return 'notenough'
    end

    if Player.PlayerData.money.crypto < coins then
        return 'notenough'
    end

    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid, money FROM players WHERE metadata LIKE ? LIMIT 1', { '%"walletid":"' .. walletId .. '"%' }) or {}
    local row = rows[1]

    if not row then
        return 'notvalid'
    end

    Player:RemoveMoney('crypto', coins, 'transfer crypto')
    AddPhoneTransaction(source, Player, data, 'You have ' .. coins .. ' Qbit(s) transferred!', 'Debit')

    local Target = exports['qb-core']:GetPlayerByCitizenId(row.citizenid)
    if Target then
        Target:AddMoney('crypto', coins, 'transfer crypto')
        AddPhoneTransaction(Target.PlayerData.source, Player, data, 'There are ' .. coins .. ' Qbit(s) credited!', 'Credit')
    else
        local moneyData = DecodeJson(row.money, {})
        moneyData.crypto = (tonumber(moneyData.crypto) or 0) + coins
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE players SET money = ? WHERE citizenid = ?', { EncodeJson(moneyData), row.citizenid })
    end

    return BuildCryptoData(Player, 'qbit')
end)

for name in pairs(Crypto.Worth) do
    RefreshCrypto(name)
end

priceTimer = Timer.SetInterval(HandlePriceChange, Crypto.RefreshTimer * 60000)

if Ticker.Enabled then
    print('[qb-crypto] ' .. Lang.t('error.ticker_unavailable'))
    Ticker.Enabled = false
end

local exchangePed = nil
local exchangePedInitialised = false

RegisterServerEvent('HEvent:PlayerPossessed', function()
    if exchangePedInitialised then
        return
    end
    exchangePedInitialised = true

    local pedName = Crypto.Exchange.pedName or 'Crypto Exchange'
    HPawn(Crypto.Exchange.coords, Rotator(0, Crypto.Exchange.pedHeading or 0, 0), function(npc)
        if not npc then
            return
        end

        exchangePed = npc
        npc:SetCharacterName(pedName)
        SetEntityInvincible(npc, true)
    end, { CharacterName = pedName, bShowNameplate = true })
end)

RegisterCallback('getPeds', function()
    return exchangePed
end)

function onShutdown()
    StopRebootTimer()
    if priceTimer then
        Timer.ClearInterval(priceTimer)
        priceTimer = nil
    end

    if exchangePed and (not exchangePed.IsValid or exchangePed:IsValid()) then
        DeleteEntity(exchangePed)
    end
    exchangePed = nil
end
