local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

local isMelting = false
local canTake = false
local registered = false
local pawnPeds = {}
local markerIds = {}

local function Notify(text, notifyType, length)
    exports['qb-core']:Notify(text, notifyType or 'primary', length)
end

local function ItemLabel(itemName)
    local item = sharedItems[itemName]
    return item and item.label or itemName
end

local function IsPawnshopOpen()
    if not Config.UseTimes then
        return true
    end

    local hour
    if type(GetClockHours) == 'function' then
        hour = GetClockHours()
    else
        hour = tonumber(os.date('%H')) or Config.TimeOpen
    end

    return hour >= Config.TimeOpen and hour <= Config.TimeClosed
end

local function SetupPeds()
    TriggerCallback('getPeds', function(jobPeds)
        if not registered then
            return
        end

        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc
            local location = Config.PawnLocation[jobPeds[i].shop]
            pawnPeds[#pawnPeds + 1] = ped
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-pawnshop:client:openMenu',
                        icon = 'gem',
                        label = Lang.t('info.title'),
                    },
                },
                distance = location and location.distance or 500,
            })
        end
    end)
end

local function RegisterPawnshop()
    if registered then
        return
    end
    registered = true

    SetupPeds()

    for _, value in pairs(Config.PawnLocation) do
        if value.showBlip ~= false then
            local markerId = exports['qb-hud']:AddMarker(value.coords, {
                title = Lang.t('info.title'),
                description = value.description or '',
                icon = value.blipIcon or 'jewelry-store',
                color = value.blipColor,
                markerType = 'Store',
            })
            if markerId then
                markerIds[#markerIds + 1] = markerId
            end
        end
    end
end

local function UnregisterPawnshop()
    for _, ped in ipairs(pawnPeds) do
        exports['qb-target']:RemoveTargetEntity(ped)
    end
    pawnPeds = {}

    for _, markerId in ipairs(markerIds) do
        exports['qb-hud']:RemoveMarker(markerId)
    end
    markerIds = {}
    registered = false
end

local function OpenPawnshopMenu()
    if not IsPawnshopOpen() then
        Notify(Lang.t('info.pawn_closed', { value = Config.TimeOpen, value2 = Config.TimeClosed }))
        return
    end

    TriggerCallback('qb-pawnshop:server:getShopData', function(shopData)
        shopData = shopData or {}
        isMelting = shopData.isMelting == true
        canTake = shopData.canTake == true

        local pawnShop = {
            {
                header = Lang.t('info.title'),
                isMenuHeader = true,
            },
            {
                header = Lang.t('info.sell'),
                txt = Lang.t('info.sell_pawn'),
                params = {
                    event = 'qb-pawnshop:client:openPawn',
                    args = {
                        items = shopData.pawnItems or Config.PawnItems,
                    },
                },
            },
        }

        if not isMelting then
            pawnShop[#pawnShop + 1] = {
                header = Lang.t('info.melt'),
                txt = Lang.t('info.melt_pawn'),
                params = {
                    event = 'qb-pawnshop:client:openMelt',
                    args = {
                        items = shopData.meltingItems or Config.MeltingItems,
                    },
                },
            }
        end

        if canTake then
            pawnShop[#pawnShop + 1] = {
                header = Lang.t('info.melt_pickup'),
                txt = '',
                params = {
                    isServer = true,
                    event = 'qb-pawnshop:server:pickupMelted',
                },
            }
        end

        exports['qb-menu']:openMenu(pawnShop)
    end)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    RegisterPawnshop()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    UnregisterPawnshop()
    isMelting = false
    canTake = false
end)

RegisterClientEvent('qb-pawnshop:client:openMenu', function()
    OpenPawnshopMenu()
end)

RegisterClientEvent('qb-pawnshop:client:openPawn', function(data)
    TriggerCallback('qb-pawnshop:server:getShopData', function(shopData)
        local inventory = shopData and shopData.inventory or {}
        local pawnItems = (shopData and shopData.pawnItems) or (data and data.items) or {}
        local pawnMenu = {
            {
                header = Lang.t('info.title'),
                isMenuHeader = true,
            },
        }

        for _, invItem in pairs(inventory or {}) do
            for i = 1, #pawnItems do
                local pawnItem = pawnItems[i]
                if invItem.name == pawnItem.item then
                    pawnMenu[#pawnMenu + 1] = {
                        header = ItemLabel(invItem.name),
                        txt = Lang.t('info.sell_items', { value = pawnItem.price }),
                        params = {
                            event = 'qb-pawnshop:client:pawnitems',
                            args = {
                                label = ItemLabel(invItem.name),
                                price = pawnItem.price,
                                name = invItem.name,
                                amount = invItem.amount,
                            },
                        },
                    }
                end
            end
        end

        pawnMenu[#pawnMenu + 1] = {
            header = Lang.t('info.back'),
            params = {
                event = 'qb-pawnshop:client:openMenu',
            },
        }
        exports['qb-menu']:openMenu(pawnMenu)
    end)
end)

RegisterClientEvent('qb-pawnshop:client:openMelt', function(data)
    TriggerCallback('qb-pawnshop:server:getShopData', function(shopData)
        local inventory = shopData and shopData.inventory or {}
        local meltingItems = (shopData and shopData.meltingItems) or (data and data.items) or {}
        local meltMenu = {
            {
                header = Lang.t('info.melt'),
                isMenuHeader = true,
            },
        }

        for _, invItem in pairs(inventory or {}) do
            for i = 1, #meltingItems do
                local meltItem = meltingItems[i]
                if invItem.name == meltItem.item then
                    meltMenu[#meltMenu + 1] = {
                        header = ItemLabel(invItem.name),
                        txt = Lang.t('info.melt_item', { value = ItemLabel(invItem.name) }),
                        params = {
                            event = 'qb-pawnshop:client:meltItems',
                            args = {
                                label = ItemLabel(invItem.name),
                                name = invItem.name,
                                amount = invItem.amount,
                            },
                        },
                    }
                end
            end
        end

        meltMenu[#meltMenu + 1] = {
            header = Lang.t('info.back'),
            params = {
                event = 'qb-pawnshop:client:openMenu',
            },
        }
        exports['qb-menu']:openMenu(meltMenu)
    end)
end)

RegisterClientEvent('qb-pawnshop:client:pawnitems', function(item)
    local sellingItem = exports['qb-input']:ShowInput({
        header = Lang.t('info.title'),
        submitText = Lang.t('info.sell'),
        inputs = {
            {
                type = 'number',
                isRequired = false,
                name = 'amount',
                text = Lang.t('info.max', { value = item.amount }),
            },
        },
    })

    if not sellingItem or not sellingItem.amount then
        return
    end

    local amount = tonumber(sellingItem.amount)
    if not amount or amount <= 0 then
        Notify(Lang.t('error.negative'), 'error')
        return
    end

    if amount > item.amount then
        Notify(Lang.t('error.no_items'), 'error')
        return
    end

    TriggerServerEvent('qb-pawnshop:server:sellPawnItems', item.name, amount)
end)

RegisterClientEvent('qb-pawnshop:client:meltItems', function(item)
    local meltingItem = exports['qb-input']:ShowInput({
        header = Lang.t('info.melt'),
        submitText = Lang.t('info.submit'),
        inputs = {
            {
                type = 'number',
                isRequired = false,
                name = 'amount',
                text = Lang.t('info.max', { value = item.amount }),
            },
        },
    })

    if not meltingItem or not meltingItem.amount then
        return
    end

    local amount = tonumber(meltingItem.amount)
    if not amount or amount <= 0 then
        Notify(Lang.t('error.no_melt'), 'error')
        return
    end

    if amount > item.amount then
        Notify(Lang.t('error.no_items'), 'error')
        return
    end

    TriggerServerEvent('qb-pawnshop:server:meltItemRemove', item.name, amount)
end)

RegisterClientEvent('qb-pawnshop:client:startMelting', function()
    isMelting = true
    canTake = false
end)

RegisterClientEvent('qb-pawnshop:client:meltReady', function()
    isMelting = false
    canTake = true
end)

RegisterClientEvent('qb-pawnshop:client:resetPickup', function()
    canTake = false
end)

Timer.SetTimeout(RegisterPawnshop, 1000)

function onShutdown()
    UnregisterPawnshop()
end
