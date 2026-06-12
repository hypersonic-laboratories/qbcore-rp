local sharedItems = exports['qb-core']:GetShared('Items')

-- Local Functions

local function InitializeInventory(inventoryId, data)
    Inventories[inventoryId] = {
        items = {},
        isOpen = false,
        label = data and data.label or inventoryId,
        maxweight = data and data.maxweight or Config.StashSize.maxweight,
        slots = data and data.slots or Config.StashSize.slots,
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
            local itemInfo = sharedItems[item.name:lower()]
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

function LoadInventory(source, citizenid)
    local inventory = MySQL.prepare.await('SELECT inventory FROM players WHERE citizenid = ?', { citizenid })
    local loadedInventory = {}
    local missingItems = {}
    inventory = json.decode(inventory)
    if not inventory or not next(inventory) then
        return loadedInventory
    end

    for _, item in pairs(inventory) do
        if item then
            local itemInfo = sharedItems[item.name:lower()]

            if itemInfo then
                loadedInventory[item.slot] = {
                    name = itemInfo['name'],
                    amount = item.amount,
                    info = item.info or '',
                    label = itemInfo['label'],
                    description = itemInfo['description'] or '',
                    weight = itemInfo['weight'],
                    type = itemInfo['type'],
                    unique = itemInfo['unique'],
                    useable = itemInfo['useable'],
                    image = itemInfo['image'],
                    shouldClose = itemInfo['shouldClose'],
                    slot = item.slot,
                    combinable = itemInfo['combinable'],
                }
            else
                missingItems[#missingItems + 1] = item.name:lower()
            end
        end
    end

    if #missingItems > 0 then
        print(('The following items were removed for player %s as they no longer exist: %s'):format(source and GetPlayerName(source) or citizenid, table.concat(missingItems, ', ')))
    end

    return loadedInventory
end

exports('qb-inventory', 'LoadInventory', LoadInventory)

function SaveInventory(source, offline)
    local PlayerData
    if offline then
        PlayerData = source
    else
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player then
            return
        end
        PlayerData = Player.PlayerData
    end

    local items = PlayerData.items
    local ItemsJson = {}

    if items and next(items) then
        for slot, item in pairs(items) do
            if item then
                ItemsJson[#ItemsJson + 1] = {
                    name = item.name,
                    amount = item.amount,
                    info = item.info,
                    type = item.type,
                    slot = slot,
                }
            end
        end
        MySQL.prepare('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode(ItemsJson), PlayerData.citizenid })
    else
        MySQL.prepare('UPDATE players SET inventory = ? WHERE citizenid = ?', { '[]', PlayerData.citizenid })
    end
end

exports('qb-inventory', 'SaveInventory', SaveInventory)

function GetSlotsByItem(items, itemName)
    local slotsFound = {}
    if not items then
        return slotsFound
    end
    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            slotsFound[#slotsFound + 1] = slot
        end
    end
    return slotsFound
end

exports('qb-inventory', 'GetSlotsByItem', GetSlotsByItem)

function GetFirstSlotByItem(items, itemName)
    if not items then
        return nil
    end
    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            return tonumber(slot)
        end
    end
    return nil
end

exports('qb-inventory', 'GetFirstSlotByItem', GetFirstSlotByItem)

function GetItemBySlot(source, slot)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    return Player.PlayerData.items[tonumber(slot)]
end

exports('qb-inventory', 'GetItemBySlot', GetItemBySlot)

function GetItemByName(source, item)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local PlayerItems = Player.PlayerData.items
    local slot = GetFirstSlotByItem(PlayerItems, tostring(item):lower())
    return PlayerItems[slot]
end

exports('qb-inventory', 'GetItemByName', GetItemByName)

function GetItemsByName(source, item)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local PlayerItems = Player.PlayerData.items
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
    if not Player then
        return
    end
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

function GetSlots(identifier)
    local inventory, maxSlots
    local player = exports['qb-core']:GetPlayer(identifier)
    if player then
        inventory = player.PlayerData.items
        maxSlots = Config.MaxSlots
    elseif Inventories[identifier] then
        inventory = Inventories[identifier].items
        maxSlots = Inventories[identifier].slots
    elseif Drops[identifier] then
        inventory = Drops[identifier].items
        maxSlots = Drops[identifier].slots
    end
    if not inventory then
        return 0, maxSlots
    end
    local slotsUsed = 0
    for _, v in pairs(inventory) do
        if v then
            slotsUsed = slotsUsed + 1
        end
    end
    local slotsFree = maxSlots - slotsUsed
    return slotsUsed, slotsFree
end

exports('qb-inventory', 'GetSlots', GetSlots)

function GetTotalWeight(items)
    if not items then
        return 0
    end
    local weight = 0
    for _, item in pairs(items) do
        local amount = item.amount
        if type(amount) ~= 'number' then
            amount = 1
        end
        weight = weight + (item.weight * amount)
    end
    return tonumber(weight)
end

exports('qb-inventory', 'GetTotalWeight', GetTotalWeight)

function GetFreeWeight(source)
    if not source then
        warn('Source was not passed into GetFreeWeight')
        return 0
    end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return 0
    end
    local totalWeight = GetTotalWeight(Player.PlayerData.items)
    local freeWeight = Config.MaxWeight - totalWeight
    return freeWeight
end

exports('qb-inventory', 'GetFreeWeight', GetFreeWeight)

function CanAddItem(identifier, item, amount)
    local Player = exports['qb-core']:GetPlayer(identifier)

    local itemData = sharedItems[item:lower()]
    if not itemData then
        return false
    end

    local inventory, items
    if Player then
        inventory = {
            maxweight = Config.MaxWeight,
            slots = Config.MaxSlots,
        }
        items = Player.PlayerData.items
    elseif Inventories[identifier] then
        inventory = Inventories[identifier]
        items = Inventories[identifier].items
    elseif Drops[identifier] then
        inventory = Drops[identifier]
        items = Drops[identifier].items
    end

    if not inventory then
        print('CanAddItem: Inventory not found')
        return false
    end

    local weight = itemData.weight * amount
    local totalWeight = GetTotalWeight(items) + weight
    if totalWeight > inventory.maxweight then
        return false, 'weight'
    end

    local slotsUsed, _ = GetSlots(identifier)

    if slotsUsed >= inventory.slots then
        local canStack = false
        for _, v in pairs(items) do
            if v.name == itemData.name and not itemData.unique then
                canStack = true
                break
            end
        end
        if not canStack then
            return false, 'slots'
        end
    end

    return true
end

exports('qb-inventory', 'CanAddItem', CanAddItem)

function ClearInventory(source, filterItems)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local savedItemData = {}
    if filterItems then
        if type(filterItems) == 'string' then
            local item = GetItemByName(source, filterItems)
            if item then
                savedItemData[item.slot] = item
            end
        elseif type(filterItems) == 'table' then
            for _, itemName in ipairs(filterItems) do
                local item = GetItemByName(source, itemName)
                if item then
                    savedItemData[item.slot] = item
                end
            end
        end
    end

    Player.SetPlayerData('items', savedItemData)

    if not Player.Offline then
        local logMessage = string.format('**%s (citizenid: %s | id: %s)** inventory cleared', source:GetAccountName(), Player.PlayerData.citizenid, source)
        --Events.Call('qb-log:server:CreateLog', 'playerinventory', 'ClearInventory', 'red', logMessage)
    end
end

exports('qb-inventory', 'ClearInventory', ClearInventory)

function ClearStash(identifier)
    if not identifier then
        return
    end
    local inventory = Inventories[identifier]
    if not inventory then
        return
    end
    inventory.items = {}
    MySQL.prepare('UPDATE inventories SET items = ? WHERE identifier = ?', { json.encode(inventory.items), identifier })
end

exports('qb-inventory', 'ClearStash', ClearStash)

function SetInventory(identifier, items, reason)
    local player = exports['qb-core']:GetPlayer(identifier)

    if not player and not Inventories[identifier] and not Drops[identifier] then
        print('SetInventory: Inventory not found')
        return
    end

    if player then
        player.SetPlayerData('items', items)
        if not player.Offline then
            --local logMessage = string.format('**%s (citizenid: %s | id: %s)** items set: %s', GetPlayerName(identifier), player.PlayerData.citizenid, identifier, json.encode(items))
            --TriggerLocalServerEvent('qb-log:server:CreateLog', 'playerinventory', 'SetInventory', 'blue', logMessage)
        end
    elseif Drops[identifier] then
        Drops[identifier].items = items
    elseif Inventories[identifier] then
        Inventories[identifier].items = items
    end
    -- local invName = player and player.PlayerData.name .. ' (' .. identifier .. ')' or identifier
    -- local setReason = reason or 'No reason specified'
    -- TriggerLocalServerEvent('qb-log:server:CreateLog', 'playerinventory', 'SetInventory', 'blue', ...)
end

exports('qb-inventory', 'SetInventory', SetInventory)

function SetItemData(source, itemName, key, val, slot)
    if not itemName or not key then
        return false
    end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local item
    if slot then
        item = Player.PlayerData.items[tonumber(slot)]
        if not item or item.name:lower() ~= itemName:lower() then
            return false
        end
    else
        item = GetItemByName(source, itemName)
        if not item then
            return false
        end
    end
    item[key] = val
    Player.PlayerData.items[item.slot] = item
    Player.SetPlayerData('items', Player.PlayerData.items)
    return true
end

exports('qb-inventory', 'SetItemData', SetItemData)

function HasItem(source, items, amount)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end
    local isTable = type(items) == 'table'
    local isArray = isTable and table.type(items) == 'array' or false
    local totalItems = isArray and #items or 0
    local count = 0

    if isTable and not isArray then
        for _ in pairs(items) do
            totalItems = totalItems + 1
        end
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

function GetUsableItem(itemName)
    return exports['qb-core']:CanUseItem(itemName)
end

exports('qb-inventory', 'GetUsableItem', GetUsableItem)

function UseItem(itemName, source, itemData)
    local item = GetUsableItem(itemName)
    if not item or not item.event then
        return
    end
    TriggerLocalServerEvent(item.event, source, itemData)
end

exports('qb-inventory', 'UseItem', UseItem)

function CloseInventory(source, identifier)
    if identifier and Inventories[identifier] then
        Inventories[identifier].isOpen = false
    end
    --source:SetValue('inv_busy', false, true)
    TriggerClientEvent(source, 'qb-inventory:client:closeInv')
end

exports('qb-inventory', 'CloseInventory', CloseInventory)

function OpenInventoryById(source, targetId)
    local Player = exports['qb-core']:GetPlayer(source)
    local TargetPlayer = exports['qb-core']:GetPlayer(targetId)
    if not Player or not TargetPlayer then
        return
    end
    -- if targetId:GetValue('inv_busy') then
    --     CloseInventory(targetId)
    -- end
    local playerItems = Player.PlayerData.items
    local targetItems = TargetPlayer.PlayerData.items
    local formattedInventory = {
        name = 'otherplayer-' .. targetId,
        label = GetPlayerName(targetId),
        maxweight = Config.MaxWeight,
        slots = Config.MaxSlots,
        inventory = targetItems,
    }
    --targetId:SetValue('inv_busy', true, true)
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', playerItems, formattedInventory)
end

exports('qb-inventory', 'OpenInventoryById', OpenInventoryById)

function CreateShop(shopData)
    if shopData.name then
        RegisteredShops[shopData.name] = {
            name = shopData.name,
            label = shopData.label,
            coords = shopData.coords,
            slots = #shopData.items,
            items = SetupShopItems(shopData.items),
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
                        items = SetupShopItems(data.items),
                    }
                else
                    CreateShop(data)
                end
            end
        end
    end
end

exports('qb-inventory', 'CreateShop', CreateShop)

function OpenShop(source, name)
    if not name then
        return
    end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if not RegisteredShops[name] then
        return
    end
    local player = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(player)
    if RegisteredShops[name].coords then
        local shopDistance = RegisteredShops[name].coords
        if shopDistance then
            if GetDistanceBetweenCoords(playerCoords, shopDistance) > 1000.0 then
                return
            end
        end
    end
    local formattedInventory = {
        name = 'shop-' .. RegisteredShops[name].name,
        label = RegisteredShops[name].label,
        maxweight = 5000000,
        slots = #RegisteredShops[name].items,
        inventory = RegisteredShops[name].items,
    }
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', Player.PlayerData.items, formattedInventory)
end

exports('qb-inventory', 'OpenShop', OpenShop)

function OpenInventory(source, identifier, data)
    --if source:GetValue('inv_busy') then return end
    local QBPlayer = exports['qb-core']:GetPlayer(source)
    if not QBPlayer then
        return
    end

    if not identifier then
        --source:SetValue('inv_busy', true, true)
        TriggerClientEvent(source, 'qb-inventory:client:openInventory', QBPlayer.PlayerData.items)
        return
    end

    if type(identifier) ~= 'string' then
        print('Inventory tried to open an invalid identifier')
        return
    end

    local inventory = Inventories[identifier]

    if inventory and inventory.isOpen then
        TriggerClientEvent(source, 'QBCore:Notify', Lang.t('notify.invinuse'), 'error')
        return
    end

    if not inventory then
        inventory = InitializeInventory(identifier, data)
    end
    inventory.maxweight = (data and data.maxweight) or inventory.maxweight or Config.StashSize.maxweight
    inventory.slots = (data and data.slots) or inventory.slots or Config.StashSize.slots
    inventory.label = (data and data.label) or inventory.label or identifier
    inventory.isOpen = source

    local formattedInventory = {
        name = identifier,
        label = inventory.label,
        maxweight = inventory.maxweight,
        slots = inventory.slots,
        inventory = inventory.items,
    }
    --source:SetValue('inv_busy', true, true)
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', QBPlayer.PlayerData.items, formattedInventory)
end

exports('qb-inventory', 'OpenInventory', OpenInventory)

function CreateInventory(identifier, data)
    if not identifier or Inventories[identifier] then
        return
    end
    Inventories[identifier] = InitializeInventory(identifier, data)
end

exports('qb-inventory', 'CreateInventory', CreateInventory)

function GetInventory(identifier)
    return Inventories[identifier]
end

exports('qb-inventory', 'GetInventory', GetInventory)

function RemoveInventory(identifier)
    if Inventories[identifier] then
        Inventories[identifier] = nil
    end
end

exports('qb-inventory', 'RemoveInventory', RemoveInventory)

function AddItem(identifier, item, amount, slot, info, reason)
    local itemInfo = sharedItems[item:lower()]
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
            combinable = itemInfo.combinable,
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

    if player then
        player.SetPlayerData('items', inventory)
    end
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
    if not sharedItems[item:lower()] then
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

    local inventoryItem, itemKey
    for key, invItem in pairs(inventory) do
        if invItem.slot == slot then
            inventoryItem = invItem
            itemKey = key
            break
        end
    end

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
        inventory[itemKey] = nil
    else
        inventory[itemKey] = inventoryItem
    end

    if player then
        player.SetPlayerData('items', inventory)
    end
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
