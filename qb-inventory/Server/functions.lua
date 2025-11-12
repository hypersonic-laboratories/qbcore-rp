-- Local Functions

local function InitializeInventory(inventoryId, data)
    Inventories[inventoryId] = {
        items = {},
        isOpen = false,
        label = data and data.label or inventoryId,
        maxweight = data and data.maxweight or Config.StashSize.maxweight,
        slots = data and data.slots or Config.StashSize.slots
    }
    return Inventories[inventoryId]
end

local function GetFirstFreeSlot(items, maxSlots)
    for i = 1, maxSlots do
        if items[i] == nil then
            return i
        end
    end
    return nil
end

local function SetupShopItems(shopItems)
    local items = {}
    local slot = 1
    if shopItems and next(shopItems) then
        for _, item in pairs(shopItems) do
            local itemInfo = SharedItems[item.name:lower()]
            if itemInfo then
                items[slot] = {
                    name = itemInfo['name'],
                    amount = tonumber(item.amount),
                    info = item.info or {},
                    label = itemInfo['label'],
                    description = itemInfo['description'] or '',
                    weight = itemInfo['weight'],
                    type = itemInfo['type'],
                    unique = itemInfo['unique'],
                    useable = itemInfo['useable'],
                    price = item.price,
                    image = itemInfo['image'],
                    slot = slot,
                }
                slot = slot + 1
            end
        end
    end
    return items
end

-- Exported Functions

function GetSlotsByItem(items, itemName)
    local slotsFound = {}
    if not items then return slotsFound end
    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            slotsFound[#slotsFound + 1] = slot
        end
    end
    return slotsFound
end

exports('qb-inventory', 'GetSlotsByItem', GetSlotsByItem)

function GetFirstSlotByItem(items, itemName)
    if not items then return nil end
    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            return tonumber(slot)
        end
    end
    return nil
end

exports('qb-inventory', 'GetFirstSlotByItem', GetFirstSlotByItem)

function GetItemBySlot(source, slot)
    return exports['qb-core']:GetPlayer(source).PlayerData.items[tonumber(slot)]
end

exports('qb-inventory', 'GetItemBySlot', GetItemBySlot)

function GetItemByName(source, item)
    local PlayerItems = exports['qb-core']:GetPlayer(source).PlayerData.items
    local slot = GetFirstSlotByItem(PlayerItems, tostring(item):lower())
    return PlayerItems[slot]
end

exports('qb-inventory', 'GetItemByName', GetItemByName)

function GetItemsByName(source, item)
    local PlayerItems = exports['qb-core']:GetPlayer(source).PlayerData.items
    item = tostring(item):lower()
    local items = {}

    for _, slot in pairs(GetSlotsByItem(PlayerItems, item)) do
        if slot then
            items[#items + 1] = PlayerItems[slot]
        end
    end

    return items
end

exports('qb-inventory', 'GetItemsByName', GetItemsByName)

function GetItemCount(source, items)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local isTable = type(items) == 'table'
    local itemsSet = isTable and {} or nil
    if isTable then
        for _, item in pairs(items) do
            itemsSet[item] = true
        end
    end
    local count = 0
    for _, item in pairs(Player.PlayerData.items) do
        if (isTable and itemsSet[item.name]) or (not isTable and items == item.name) then
            count = count + item.amount
        end
    end
    return count
end

exports('qb-inventory', 'GetItemCount', GetItemCount)

function GetTotalWeight(items)
    if not items then return 0 end
    local weight = 0
    for _, item in pairs(items) do
        weight = weight + (item.weight * item.amount)
    end
    return tonumber(weight)
end

exports('qb-inventory', 'GetTotalWeight', GetTotalWeight)

function CanAddItem(source, item, amount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return false end
    local itemData = SharedItems[item:lower()]
    if not itemData then return false end
    local weight = itemData.weight * amount
    local totalWeight = GetTotalWeight(Player.PlayerData.items) + weight
    if totalWeight > Config.MaxWeight then
        return false, 'weight'
    end
    local slotsUsed = 0
    for _, v in pairs(Player.PlayerData.items) do
        if v then
            slotsUsed = slotsUsed + 1
        end
    end
    if slotsUsed >= Config.MaxSlots then
        return false, 'slots'
    end
    return true
end

exports('qb-inventory', 'CanAddItem', CanAddItem)

function ClearInventory(source, filterItems)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local savedItemData = {}
    if filterItems then
        if type(filterItems) == 'string' then
            local item = GetItemByName(source, filterItems)
            if item then savedItemData[item.slot] = item end
        elseif type(filterItems) == 'table' then
            for _, itemName in ipairs(filterItems) do
                local item = GetItemByName(source, itemName)
                if item then savedItemData[item.slot] = item end
            end
        end
    end

    exports['qb-core']:Player('SetPlayerData', 'items', savedItemData)

    if not Player.Offline then
        local logMessage = string.format('**%s (citizenid: %s | id: %s)** inventory cleared', source:GetAccountName(), Player.PlayerData.citizenid, source)
        --Events.Call('qb-log:server:CreateLog', 'playerinventory', 'ClearInventory', 'red', logMessage)
    end
end

exports('qb-inventory', 'ClearInventory', ClearInventory)

function SetInventory(source, items)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    exports['qb-core']:Player('SetPlayerData', 'items', items)
    if not Player.Offline then
        local logMessage = string.format('**%s (citizenid: %s | id: %s)** items set: %s', source:GetAccountName(), Player.PlayerData.citizenid, source, json.encode(items))
        --Events.Call('qb-log:server:CreateLog', 'playerinventory', 'SetInventory', 'blue', logMessage)
    end
end

exports('qb-inventory', 'SetInventory', SetInventory)

function SetItemData(source, itemName, key, val)
    if not itemName or not key then return false end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local item = GetItemByName(source, itemName)
    if not item then return false end
    item[key] = val
    Player.PlayerData.items[item.slot] = item
    exports['qb-core']:Player('SetPlayerData', 'items', Player.PlayerData.items)
    return true
end

exports('qb-inventory', 'SetItemData', SetItemData)

function HasItem(source, items, amount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return false end
    local isTable = type(items) == 'table'
    local isArray = isTable and table.type(items) == 'array' or false
    local totalItems = isArray and #items or 0
    local count = 0

    if isTable and not isArray then
        for _ in pairs(items) do totalItems = totalItems + 1 end
    end

    for _, itemData in pairs(Player.PlayerData.items) do
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

    return false
end

exports('qb-inventory', 'HasItem', HasItem)

function CreateUsableItem(itemName, data)
    exports['qb-core']:CreateUseableItem(itemName, data)
end

exports('qb-inventory', 'CreateUsableItem', CreateUsableItem)

function GetUsableItem(itemName)
    return exports['qb-core']:CanUseItem(itemName)
end

exports('qb-inventory', 'GetUsableItem', GetUsableItem)

function UseItem(itemName, ...)
    local itemData = GetUsableItem(itemName)
    local callback = type(itemData) == 'table' and (rawget(itemData, '__cfx_functionReference') and itemData or itemData.cb or itemData.callback) or type(itemData) == 'function' and itemData
    if not callback then return end
    callback(...)
end

exports('qb-inventory', 'UseItem', UseItem)

function CloseInventory(source, identifier)
    local player_ped = GetPlayerPawn(source)
    --player_ped:SetInputEnabled(true)
    --source:SetValue('inv_busy', false, true)
    if identifier and Inventories[identifier] then
        Inventories[identifier].isOpen = false
    end
    TriggerClientEvent(source, 'qb-inventory:client:closeInv')
end

exports('qb-inventory', 'CloseInventory', CloseInventory)

function OpenInventoryById(source, targetId)
    local Player = exports['qb-core']:GetPlayer(source)
    local TargetPlayer = exports['qb-core']:GetPlayer(targetId)
    if not Player or not TargetPlayer then return end
    local playerItems = Player.PlayerData.items
    local targetItems = TargetPlayer.PlayerData.items
    local formattedInventory = {
        name = 'otherplayer-' .. targetId,
        label = targetId:GetAccountName(),
        maxweight = Config.MaxWeight,
        slots = Config.MaxSlots,
        inventory = targetItems
    }
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', playerItems, formattedInventory)
end

exports('qb-inventory', 'OpenInventoryById', OpenInventoryById)

local function CreateShop(shopData)
    if shopData.name then
        RegisteredShops[shopData.name] = {
            name = shopData.name,
            label = shopData.label,
            coords = shopData.coords,
            slots = #shopData.items,
            items = SetupShopItems(shopData.items)
        }
    else
        for key, data in pairs(shopData) do
            if type(data) == 'table' then
                if data.name then
                    local shopName = type(key) == 'number' and data.name or key
                    RegisteredShops[shopName] = {
                        name = shopName,
                        label = data.label,
                        coords = data.coords,
                        slots = #data.items,
                        items = SetupShopItems(data.items)
                    }
                else
                    CreateShop(data)
                end
            end
        end
    end
end

exports('qb-inventory', 'CreateShop', CreateShop)

local function OpenShop(source, name)
    if not name then return end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if not RegisteredShops[name] then return end
    local player = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(player)
    if RegisteredShops[name].coords then
        local shopDistance = RegisteredShops[name].coords
        if shopDistance then
            if GetDistanceBetweenCoords(playerCoords, shopDistance) > 1000.0 then return end
        end
    end
    local formattedInventory = {
        name = 'shop-' .. RegisteredShops[name].name,
        label = RegisteredShops[name].label,
        maxweight = 5000000,
        slots = #RegisteredShops[name].items,
        inventory = RegisteredShops[name].items
    }
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', Player.PlayerData.items, formattedInventory)
end

exports('qb-inventory', 'OpenShop', OpenShop)

function OpenInventory(source, identifier, data)
    local QBPlayer = exports['qb-core']:GetPlayer(source)
    if not QBPlayer then return end
    local player_ped = GetPlayerPawn(source)

    if not identifier then
        TriggerClientEvent(source, 'qb-inventory:client:openInventory', QBPlayer.PlayerData.items)
        --player_ped:SetInputEnabled(false)
        --source:SetValue('inv_busy', true, true)
        return
    end

    if type(identifier) ~= 'string' then
        print('Inventory tried to open an invalid identifier')
        return
    end

    local inventory = Inventories[identifier]

    if inventory and inventory.isOpen then
        TriggerClientEvent(source, 'QBCore:Notify', 'This inventory is currently in use', 'error')
        return
    end

    if not inventory then inventory = InitializeInventory(identifier, data) end
    inventory.maxweight = (inventory and inventory.maxweight) or (data and data.maxweight) or Config.StashSize.maxweight
    inventory.slots = (inventory and inventory.slots) or (data and data.slots) or Config.StashSize.slots
    inventory.label = (inventory and inventory.label) or (data and data.label) or identifier
    inventory.isOpen = true

    local formattedInventory = {
        name = identifier,
        label = inventory.label,
        maxweight = inventory.maxweight,
        slots = inventory.slots,
        inventory = inventory.items
    }
    --player_ped:SetInputEnabled(false)
    --source:SetValue('inv_busy', true, true)
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', QBPlayer.PlayerData.items, formattedInventory)
end

exports('qb-inventory', 'OpenInventory', OpenInventory)

function AddItem(identifier, item, amount, slot, info, reason)
    local itemInfo = SharedItems[item:lower()]
    if not itemInfo then
        print('AddItem: Invalid item')
        return false
    end
    local inventory, inventoryWeight, inventorySlots
    local player = exports['qb-core']:GetPlayer(identifier)

    if player then
        inventory = player.PlayerData.items
        inventoryWeight = Config.MaxWeight
        inventorySlots = Config.MaxSlots
    elseif Inventories[identifier] then
        inventory = Inventories[identifier].items
        inventoryWeight = Inventories[identifier].maxweight
        inventorySlots = Inventories[identifier].slots
    elseif Drops[identifier] then
        inventory = Drops[identifier].items
        inventoryWeight = Drops[identifier].maxweight
        inventorySlots = Drops[identifier].slots
    end

    if not inventory then
        print('AddItem: Inventory not found')
        return false
    end

    local totalWeight = GetTotalWeight(inventory)
    if totalWeight + (itemInfo.weight * amount) > inventoryWeight then
        print('AddItem: Not enough weight available')
        return false
    end

    amount = tonumber(amount) or 1
    local updated = false

    if not itemInfo.unique then
        slot = slot or GetFirstSlotByItem(inventory, item)
        if slot then
            for _, invItem in pairs(inventory) do
                if invItem.slot == slot then
                    invItem.amount = invItem.amount + amount
                    updated = true
                    break
                end
            end
        end
    end

    if not updated then
        slot = slot or GetFirstFreeSlot(inventory, inventorySlots)
        if not slot then
            print('AddItem: No free slot available')
            return false
        end

        inventory[slot] = {
            name = item,
            amount = amount,
            info = info or {},
            label = itemInfo.label,
            description = itemInfo.description or '',
            weight = itemInfo.weight,
            type = itemInfo.type,
            unique = itemInfo.unique,
            useable = itemInfo.useable,
            image = itemInfo.image,
            shouldClose = itemInfo.shouldClose,
            slot = slot,
            combinable = itemInfo.combinable
        }

        if itemInfo.type == 'weapon' then
            if not inventory[slot].info.serie then
                inventory[slot].info.serie = exports['qb-core']:CreateSerialNumber()
            end
            if not inventory[slot].info.quality then
                inventory[slot].info.quality = 100
            end
        end
    end

    if player then exports['qb-core']:Player(identifier, 'SetPlayerData', 'items', inventory) end
    -- local invName = player and identifier:GetName() .. ' (' .. identifier:GetID() .. ')' or identifier
    -- local addReason = reason or 'No reason specified'
    -- local resourceName = 'qb-inventory'
    -- Events.Call(
    --     'qb-log:server:CreateLog',
    --     'playerinventory',
    --     'Item Added',
    --     'green',
    --     '**Inventory:** ' .. invName .. ' (Slot: ' .. slot .. ')\n' ..
    --     '**Item:** ' .. item .. '\n' ..
    --     '**Amount:** ' .. amount .. '\n' ..
    --     '**Reason:** ' .. addReason .. '\n' ..
    --     '**Resource:** ' .. resourceName
    -- )
    return true
end

exports('qb-inventory', 'AddItem', AddItem)

function RemoveItem(identifier, item, amount, slot, reason)
    if not SharedItems[item:lower()] then
        print('RemoveItem: Invalid item')
        return false
    end
    local inventory
    local player = exports['qb-core']:GetPlayer(identifier)

    if player then
        inventory = player.PlayerData.items
    elseif Inventories[identifier] then
        inventory = Inventories[identifier].items
    elseif Drops[identifier] then
        inventory = Drops[identifier].items
    end

    if not inventory then
        print('RemoveItem: Inventory not found')
        return false
    end

    slot = tonumber(slot) or GetFirstSlotByItem(inventory, item)

    if not slot then
        print('RemoveItem: Slot not found')
        return false
    end

    local inventoryItem = inventory[slot]
    if not inventoryItem or inventoryItem.name:lower() ~= item:lower() then
        print('RemoveItem: Item not found in slot')
        return false
    end

    amount = tonumber(amount)
    if inventoryItem.amount < amount then
        print('RemoveItem: Not enough items in slot')
        return false
    end

    inventoryItem.amount = inventoryItem.amount - amount
    if inventoryItem.amount <= 0 then
        inventory[slot] = nil
    end

    if player then exports['qb-core']:Player(identifier, 'SetPlayerData', 'items', inventory) end
    -- local invName = player and identifier:GetName() .. ' (' .. identifier:GetID() .. ')' or identifier
    -- local removeReason = reason or 'No reason specified'
    -- local resourceName = 'qb-inventory'
    -- Events.Call(
    --     'qb-log:server:CreateLog',
    --     'playerinventory',
    --     'Item Removed',
    --     'red',
    --     '**Inventory:** ' .. invName .. ' (Slot: ' .. slot .. ')\n' ..
    --     '**Item:** ' .. item .. '\n' ..
    --     '**Amount:** ' .. amount .. '\n' ..
    --     '**Reason:** ' .. removeReason .. '\n' ..
    --     '**Resource:** ' .. resourceName
    -- )
    return true
end

exports('qb-inventory', 'RemoveItem', RemoveItem)
