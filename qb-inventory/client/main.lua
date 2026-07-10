local Lang = require('locales/en')
local PlayerData = {}
local hotbarShown = false
local inv_open = false
local sharedItems = exports['qb-core']:GetShared('Items')
local my_webui = WebUI('Inventory', 'qb-inventory/html/index.html')

-- Handlers

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = exports['qb-core']:GetPlayerData() or {}
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, value)
    if key == 'all' then
        PlayerData = value or {}
        return
    end
    if key == 'items' then
        if type(PlayerData) ~= 'table' then
            PlayerData = {}
        end
        PlayerData.items = value
    end
end)

-- Functions

--- Checks if the player has a certain item or items in their inventory with a specified amount.
--- @param items string|table - The item(s) to check for. Can be a table of items or a single item as a string.
--- @param amount number [optional] - The minimum amount required for each item. If not provided, any amount greater than 0 will be considered.
--- @return boolean - Returns true if the player has the item(s) with the specified amount, false otherwise.
function HasItem(items, amount)
    local isTable = type(items) == 'table'
    local isArray = isTable and table.type(items) == 'array' or false
    local totalItems = isArray and #items or 0
    local count = 0

    if isTable and not isArray then
        for _ in pairs(items) do
            totalItems = totalItems + 1
        end
    end

    if PlayerData and type(PlayerData.items) == 'table' then
        for _, itemData in pairs(PlayerData.items) do
            if isTable then
                for k, v in pairs(items) do
                    if itemData and itemData.name == (isArray and v or k) and ((amount and itemData.amount >= amount) or (not isArray and itemData.amount >= v) or (not amount and isArray)) then
                        count = count + 1
                        if count == totalItems then
                            return true
                        end
                    end
                end
            else -- Single item as string
                if itemData and itemData.name == items and (not amount or (itemData and amount and itemData.amount >= amount)) then
                    return true
                end
            end
        end
    end

    return false
end

exports('qb-inventory', 'HasItem', HasItem)

local function FormatWeaponAttachments(itemdata)
    -- TODO
end

local function GetLocalInventoryOwner()
    return HPlayer or GetLocalPlayer()
end

local function IsInventoryBusy()
    local player = GetLocalInventoryOwner()
    return inv_open or (player and GetValue(player, 'inv_busy') == true) or false
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
                label = sharedItems[items[k].name]['label'],
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
    inv_open = false
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end)

RegisterClientEvent('qb-inventory:client:closeIfBusy', function()
    if not IsInventoryBusy() then
        return
    end
    if my_webui == nil then
        return
    end
    inv_open = false
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end)

RegisterClientEvent('qb-inventory:client:updateInventory', function(items)
    if my_webui == nil then
        return
    end
    if not items and PlayerData and type(PlayerData.items) == 'table' then
        items = PlayerData.items
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
    local pawn = GetPlayerPawn()
    local coords = pawn and GetEntityCoords(pawn)
    local targetPawn = GetClosestPawn(coords, 1000)
    if targetPawn and targetPawn.PlayerState and targetPawn:IsPlayerControlled() and data and data.item then
        local playerId = targetPawn.PlayerState:GetPlayerId()
        TriggerCallback('giveItem', function(success)
            my_webui:SendEvent('giveItemResult', { success = success or false })
        end, playerId, data.item.name, data.amount, data.slot or data.item.slot)
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

RegisterClientEvent('qb-inventory:client:openVending', function(data)
    if IsInventoryBusy() then
        return
    end
    TriggerServerEvent('qb-inventory:server:openVending', data)
end)

for _, model in pairs(Config.VendingObjects) do
    exports['qb-target']:AddTargetModel(model, {
        options = {
            {
                type = 'client',
                event = 'qb-inventory:client:openVending',
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
        my_webui:SendEvent('close')
    else
        if IsInventoryBusy() then
            return
        end
        TriggerServerEvent('qb-inventory:server:openInventory')
    end
end, 'Released')

Input.BindKey(Config.Keybinds.Hotbar, function()
    if IsInventoryBusy() then
        return
    end
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
        local itemData = PlayerData.items[i]
        if not itemData then
            return
        end
        TriggerServerEvent('qb-inventory:server:useItem', itemData)
    end)
end
