local Lang = require('locales/en')
local player_data = {}
local hotbarShown = false
local inv_open = false
local my_webui = WebUI('Inventory', 'qb-inventory/html/index.html')

-- Handlers

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    player_data = exports['qb-core']:GetPlayerData()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    player_data = nil
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, value)
    if key == 'items' then
        player_data.items = value
        return
    end
    if key ~= 'all' then
        return
    end
    player_data = value
end)

-- Functions

local function FormatWeaponAttachments(itemdata)
    -- TODO
end

-- Events

RegisterClientEvent('qb-inventory:client:openInventory', function(items, other)
    if my_webui == nil then
        return
    end
    my_webui:SetInputMode(1)
    my_webui:SendEvent('open', {
        inventory = items,
        slots = Config.MaxSlots,
        maxweight = Config.MaxWeight,
        other = other,
    })
    inv_open = true
end)

RegisterClientEvent('qb-inventory:client:requiredItems', function(items, bool)
    local itemTable = {}
    if bool then
        for k in pairs(items) do
            itemTable[#itemTable + 1] = {
                item = items[k].name,
                label = QBShared.Items[items[k].name]['label'],
                image = items[k].image,
            }
        end
    end
    if my_webui == nil then
        return
    end
    my_webui:SendEvent('requiredItem', { items = itemTable, toggle = bool })
end)

RegisterClientEvent('qb-inventory:client:hotbar', function(items)
    hotbarShown = not hotbarShown
    if my_webui == nil then
        return
    end
    my_webui:SendEvent('toggleHotbar', { open = hotbarShown, items = items })
end)

RegisterClientEvent('qb-inventory:client:closeInv', function()
    if my_webui == nil then
        return
    end
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end)

RegisterClientEvent('qb-inventory:client:updateInventory', function(items)
    if my_webui == nil then
        return
    end
    if not items and player_data and type(player_data.items) == 'table' then
        items = player_data.items
    end
    my_webui:SendEvent('updateInventory', { inventory = items or {} })
end)

RegisterClientEvent('qb-inventory:client:ItemBox', function(itemData, type, amount)
    if my_webui == nil then
        return
    end
    my_webui:SendEvent('itemBox', { item = itemData, type = type, amount = amount })
end)

-- NUI Events

my_webui:RegisterEventHandler('SetInventoryData', function(data)
    TriggerServerEvent('qb-inventory:server:SetInventoryData', data.fromInventory, data.toInventory, data.fromSlot, data.toSlot, data.fromAmount, data.toAmount)
end)

my_webui:RegisterEventHandler('CloseInventory', function(data)
    local name = data.name
    inv_open = false
    my_webui:SetInputMode(0)
    if name then
        TriggerServerEvent('qb-inventory:server:closeInventory', name)
    elseif CurrentDrop then
        TriggerServerEvent('qb-inventory:server:closeInventory', CurrentDrop)
        CurrentDrop = nil
    else
        TriggerServerEvent('qb-inventory:server:closeInventory')
    end
end)

my_webui:RegisterEventHandler('UseItem', function(data)
    TriggerServerEvent('qb-inventory:server:useItem', data.item)
end)

my_webui:RegisterEventHandler('DropItem', function(item)
    TriggerCallback('createDrop', function(dropId)
        my_webui:SendEvent('dropCreated', { dropId = dropId or false })
    end, item)
end)

my_webui:RegisterEventHandler('AttemptPurchase', function(data)
    TriggerCallback('attemptPurchase', function(canPurchase)
        my_webui:SendEvent('purchaseResult', { success = canPurchase })
    end, data)
end)

my_webui:RegisterEventHandler('GiveItem', function(data)
    local player, distance = exports['qb-core']:GetClosestPlayer()
    if player and distance < 500 then
        local playerId = GetPlayerId(player)
        TriggerCallback('giveItem', function(success)
            my_webui:SendEvent('giveItemResult', { success = success or false })
        end, playerId, data.item.name, data.amount)
    else
        exports['qb-core']:Notify(Lang.t('notify.nonb'), 'error')
        my_webui:SendEvent('giveItemResult', { success = false })
    end
end)

my_webui:RegisterEventHandler('PlayDropFail', function()
    -- TODO
end)

my_webui:RegisterEventHandler('GetWeaponData', function()
    -- TODO
end)

my_webui:RegisterEventHandler('RemoveAttachment', function()
    -- TODO
end)

-- Vending

for _, model in pairs(Config.VendingObjects) do
    exports['qb-target']:AddTargetModel(model, {
        options = {
            {
                type = 'server',
                event = 'qb-inventory:server:openVending',
                icon = 'cash-register',
                label = Lang.t('menu.vending'),
            },
        },
        distance = 1000,
    })
end

-- Controls

Input.BindKey(Config.Keybinds.Open, function()
    if inv_open then
        my_webui:SendEvent('closeInventory')
    else
        TriggerServerEvent('qb-inventory:server:openInventory')
    end
end, 'Released')

Input.BindKey(Config.Keybinds.Hotbar, function()
    TriggerServerEvent('qb-inventory:server:toggleHotbar')
end)

local keyTable = {
    [1] = 'One',
    [2] = 'Two',
    [3] = 'Three',
    [4] = 'Four',
    [5] = 'Five',
}

for i = 1, 5 do
    Input.BindKey(keyTable[i], function()
        if inv_open then
            return
        end
        local itemData = player_data.items[i]
        if not itemData then
            return
        end
        TriggerServerEvent('qb-inventory:server:useItem', itemData)
    end)
end
