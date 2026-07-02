local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')
local exchangePed = nil

local requiredItems = {
    {
        name = sharedItems.cryptostick.name,
        image = sharedItems.cryptostick.image,
    },
}

local function Notify(text, notifyType, length)
    exports['qb-core']:Notify(text, notifyType or 'primary', length)
end

local function SetRequiredItemsVisible(visible)
    TriggerLocalClientEvent('qb-inventory:client:requiredItems', requiredItems, visible)
end

local function RegisterExchangeTarget()
    if exchangePed then
        return
    end

    TriggerCallback('getPeds', function(ped)
        if not ped or exchangePed then
            return
        end

        exports['qb-target']:AddTargetEntity(ped, {
            distance = Crypto.Exchange.targetDistance or 400,
            options = {
                {
                    icon = 'bitcoin',
                    label = Lang.t('text.exchange_usb'),
                    type = 'client',
                    event = 'qb-crypto:client:startExchange',
                },
            },
        })

        exchangePed = ped
    end)
end

local function RemoveExchangeTarget()
    if not exchangePed then
        return
    end

    exports['qb-target']:RemoveTargetEntity(exchangePed)
    exchangePed = nil
end

local function ExchangeSuccess()
    TriggerServerEvent('qb-crypto:server:ExchangeSuccess', math.random(1, 10))
end

local function ExchangeFail()
    local odd = 5
    if math.random(1, odd) == math.random(1, odd) then
        TriggerServerEvent('qb-crypto:server:ExchangeFail')
        TriggerServerEvent('qb-crypto:server:SyncReboot')
    end
end

RegisterClientEvent('qb-crypto:client:startExchange', function()
    if Crypto.Exchange.RebootInfo.state then
        Notify(
            Lang.t('text.system_is_rebooting', {
                rebootInfoPercentage = Crypto.Exchange.RebootInfo.percentage or 0,
            }),
            'error'
        )
        return
    end

    SetRequiredItemsVisible(true)

    TriggerCallback('qb-crypto:server:HasSticky', function(hasItem)
        if not hasItem then
            SetRequiredItemsVisible(false)
            Notify(Lang.t('error.you_dont_have_a_cryptostick'), 'error')
            return
        end

        local success = exports['qb-minigames']:Hacking(5, 30)
        SetRequiredItemsVisible(false)

        if success then
            ExchangeSuccess()
        else
            ExchangeFail()
        end
    end)
end)

RegisterClientEvent('qb-crypto:client:SyncReboot', function()
    Crypto.Exchange.RebootInfo.state = true
end)

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    RegisterExchangeTarget()
    TriggerServerEvent('qb-crypto:server:FetchWorth')
    TriggerServerEvent('qb-crypto:server:GetRebootState')
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    SetRequiredItemsVisible(false)
    RemoveExchangeTarget()
end)

RegisterClientEvent('qb-crypto:client:UpdateCryptoWorth', function(crypto, amount, history)
    Crypto.Worth[crypto] = amount
    if history ~= nil then
        Crypto.History[crypto] = history
    end
end)

RegisterClientEvent('qb-crypto:client:GetRebootState', function(rebootInfo)
    if not rebootInfo then
        return
    end

    Crypto.Exchange.RebootInfo.state = rebootInfo.state
    Crypto.Exchange.RebootInfo.percentage = rebootInfo.percentage or 0
end)

function onShutdown()
    SetRequiredItemsVisible(false)
    RemoveExchangeTarget()
end
