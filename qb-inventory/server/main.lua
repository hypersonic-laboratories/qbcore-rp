Inventories = {}
Drops = {}
RegisteredShops = {}
local sharedItems = exports['qb-core']:GetShared('Items')
local sharedWeapons = exports['qb-core']:GetShared('Weapons')

Timer.CreateThread(function()
    local results = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM inventories')
    if type(results) ~= 'table' then
        print('No inventories found')
        return
    end

    for i = 1, #results do
        local inventory = results[i]
        local cacheKey = inventory.identifier
        Inventories[cacheKey] = {
            items = JSON.parse(inventory.items) or {},
            isOpen = false,
        }
    end
    print(#results .. ' inventories successfully loaded')
end)

Timer.SetInterval(function()
    for k, v in pairs(Drops) do
        if v and (v.createdTime + (Config.CleanupDropTime * 60) < os.time()) and not Drops[k].isOpen then
            if v.entity:IsValid() then
                DestroyActor(v.entity.Object)
            end
            Drops[k] = nil
        end
    end
end, Config.CleanupDropInterval * 60000)

-- Functions

local function checkWeapon(source, item)
    local currentWeapon = item
    local ped = GetPlayerPed(source)
    local weapon = GetSelectedPedWeapon(ped)
    local weaponInfo = sharedWeapons[weapon]
    local info = {}

    if type(item) == 'table' then
        currentWeapon = item.name
        info = item.info or {}
    end

    if weaponInfo and weaponInfo.name == currentWeapon then
        RemoveWeaponFromPed(ped, weapon)
        TriggerClientEvent('qb-weapons:client:UseWeapon', source, { name = currentWeapon, info = info }, false)
    end
end

-- Handlers

RegisterServerEvent('QBCore:Server:PlayerLoaded', function(Player)
    for dropId, drop in pairs(Drops) do
        TriggerClientEvent(Player.PlayerData.source, 'qb-inventory:client:registerDropTarget', drop.entity.Object, dropId)
    end

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'AddItem', function(item, amount, slot, info)
        return AddItem(Player.PlayerData.source, item, amount, slot, info)
    end)

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'RemoveItem', function(item, amount, slot)
        return RemoveItem(Player.PlayerData.source, item, amount, slot)
    end)

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'GetItemBySlot', function(slot)
        return GetItemBySlot(Player.PlayerData.source, slot)
    end)

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'GetItemByName', function(item)
        return GetItemByName(Player.PlayerData.source, item)
    end)

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'GetItemsByName', function(item)
        return GetItemsByName(Player.PlayerData.source, item)
    end)

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'ClearInventory', function(filterItems)
        ClearInventory(Player.PlayerData.source, filterItems)
    end)

    exports['qb-core']:AddPlayerMethod(Player.PlayerData.source, 'SetInventory', function(items)
        SetInventory(Player.PlayerData.source, items)
    end)
end)

-- Events

RegisterServerEvent('qb-inventory:server:openInventory', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.metadata['isdead'] or Player.PlayerData.metadata['inlaststand'] or Player.PlayerData.metadata['ishandcuffed'] then
        return
    end

    local player_ped = GetPlayerPawn(source)
    if not player_ped then
        return
    end

    if IsPedInAnyVehicle(player_ped) then
        local in_vehicle = GetVehiclePedIsIn(player_ped)
        if in_vehicle then
            local plate = in_vehicle.Plate
            if not plate then
                plate = tostring(math.random(111111, 9999999))
                rawset(getmetatable(in_vehicle), 'Plate', plate)
            end
            OpenInventory(source, 'glovebox-' .. plate)
            return
        end
    end

    local player_coords = GetEntityCoords(player_ped)
    if not player_coords then
        OpenInventory(source)
        return
    end

    local ClosestVehicle, ClosestDistance = GetClosestVehicle(player_coords, 500)
    if ClosestVehicle and ClosestDistance then
        local plate = ClosestVehicle.Plate
        if not plate then
            plate = tostring(math.random(111111, 9999999))
            rawset(getmetatable(ClosestVehicle), 'Plate', plate)
        end
        local trunkClass = LoadClass('/Game/SimpleVehicle/Blueprints/Components/Attachments/Trunk.Trunk_C')
        local Comps = GetComponentsByClass(ClosestVehicle, trunkClass)
        if Comps:ToTable()[1] then
            local Trunk = Comps[1]
            Trunk['Animate Trunk'](Trunk, UE.EOpenableState.Open)
        end
        OpenInventory(source, 'trunk-' .. plate)
        return
    end
    OpenInventory(source)
end)

RegisterServerEvent('qb-inventory:server:toggleHotbar', function(source)
    --if source:GetValue('inv_busy', false) then return end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.metadata['isdead'] or Player.PlayerData.metadata['inlaststand'] or Player.PlayerData.metadata['ishandcuffed'] then
        return
    end
    local hotbarItems = {
        Player.PlayerData.items[1],
        Player.PlayerData.items[2],
        Player.PlayerData.items[3],
        Player.PlayerData.items[4],
        Player.PlayerData.items[5],
    }
    TriggerClientEvent(source, 'qb-inventory:client:hotbar', hotbarItems)
end)

RegisterServerEvent('qb-inventory:server:openVending', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    CreateShop({
        name = 'vending',
        label = 'Vending Machine',
        coords = data.coords,
        slots = #Config.VendingItems,
        items = Config.VendingItems,
    })
    OpenShop(source, 'vending')
end)

RegisterServerEvent('qb-inventory:server:closeInventory', function(source, inventory)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    -- Player(source).state.inv_busy = false
    if not inventory then
        return
    end
    if inventory:find('shop%-') then
        return
    end
    if inventory:find('otherplayer%-') then
        local targetId = tonumber(inventory:match('otherplayer%-(.+)'))
        -- Player(targetId).state.inv_busy = false
        return
    end
    if Drops[inventory] then
        Drops[inventory].isOpen = false
        if #Drops[inventory].items == 0 and not Drops[inventory].isOpen then
            BroadcastEvent('qb-inventory:client:removeDropTarget', inventory)
            DestroyActor(Drops[inventory].entity.Object)
            Drops[inventory] = nil
        end
        return
    end
    if not Inventories[inventory] then
        return
    end
    Inventories[inventory].isOpen = false
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO inventories (identifier, items) VALUES (?, ?) ON CONFLICT(identifier) DO UPDATE SET items = ?', { inventory, JSON.stringify(Inventories[inventory].items), JSON.stringify(Inventories[inventory].items) })
end)

RegisterServerEvent('qb-inventory:server:useItem', function(source, item)
    local itemData = GetItemBySlot(source, item.slot)
    if not itemData then
        return
    end
    local itemInfo = sharedItems[itemData.name]
    if itemInfo.type == 'weapon' then
        -- TriggerClientEvent(source, 'qb-weapons:client:UseWeapon', itemData, itemData.info.quality and itemData.info.quality > 0)
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'use')
    else
        UseItem(itemData.name, source, itemData)
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'use')
    end
end)

RegisterServerEvent('qb-inventory:server:openDrop', function(source, dropId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    local drop = Drops[dropId]
    if not drop or drop.isOpen then
        return
    end
    if GetDistanceBetweenCoords(playerCoords, drop.coords) > 250 then
        return
    end
    local formattedInventory = {
        name = dropId,
        label = dropId,
        maxweight = drop.maxweight,
        slots = drop.slots,
        inventory = drop.items,
    }
    drop.isOpen = true
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', Player.PlayerData.items, formattedInventory)
end)

RegisterServerEvent('qb-inventory:server:updateDrop', function(source, dropId)
    local DropData = Drops[dropId]
    if not DropData then
        return
    end
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    DropData.coords = playerCoords
    DropData.isHeld = nil
    DetachActor(DropData.entity.Object, {
        Location = DetachmentRule.KeepWorld,
        Rotation = DetachmentRule.KeepWorld,
    })
    DropData.entity.Component:SetCollisionProfileName('BlockAllDynamic', true)
end)

RegisterServerEvent('qb-inventory:server:pickupDrop', function(source, data)
    local dropId = data and data.dropId
    if not dropId then
        return
    end
    local DropData = Drops[dropId]
    if not DropData or DropData.isOpen or DropData.isHeld then
        return
    end
    local playerPed = GetPlayerPawn(source)
    if not playerPed then
        return
    end
    local playerCoords = GetEntityCoords(playerPed)
    if GetDistanceBetweenCoords(playerCoords, DropData.coords) > 250 then
        return
    end
    local mesh = playerPed:GetCharacterBaseMesh()
    if not mesh then
        return
    end
    AttachActorToComponent(DropData.entity.Object, mesh, Vector(-35, 0, 10), Rotator(-95, 0, 0), 'hand_r', {
        Location = AttachmentRule.SnapToTarget,
        Rotation = AttachmentRule.SnapToTarget,
        Scale = AttachmentRule.SnapToTarget,
    })
    DropData.isHeld = true
    TriggerClientEvent(source, 'qb-inventory:client:holdDrop', dropId)
end)

-- Callbacks

RegisterCallback('GetCurrentDrops', function()
    return Drops
end)

RegisterCallback('createDrop', function(source, item)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    if RemoveItem(source, item.name, item.amount, item.fromSlot) then
        --if item.type == 'weapon' then SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true) end
        --TaskPlayAnim(playerPed, 'pickup_object', 'pickup_low', 8.0, -8.0, 2000, 0, 0, false, false, false)
        local PawnRotation = GetEntityRotation(playerPed)
        local ForwardVec = playerPed:GetActorForwardVector()
        local SpawnX = playerCoords.X + ForwardVec.X * 200
        local SpawnY = playerCoords.Y + ForwardVec.Y * 200
        local hit = Trace:LineSingle(Vector(SpawnX, SpawnY, playerCoords.Z + 200), Vector(SpawnX, SpawnY, playerCoords.Z - 500))
        local SpawnZ = (hit and hit.ImpactPoint) and hit.ImpactPoint.Z or (playerCoords.Z - 88)
        local SpawnPosition = Vector(SpawnX, SpawnY, SpawnZ)
        local bag = StaticMesh(SpawnPosition, PawnRotation, Config.ItemDropObject, CollisionType.StaticOnly, false)
        bag.Object:SetActorScale3D(Vector(0.8, 0.8, 0.8))
        local newDropId = 'drop-' .. GenerateId(8, 'mixed')
        if not Drops[newDropId] then
            Drops[newDropId] = {
                name = newDropId,
                label = 'Drop',
                items = { item },
                entity = bag,
                creator = source,
                createdTime = os.time(),
                coords = playerCoords,
                maxweight = Config.DropSize.maxweight,
                slots = Config.DropSize.slots,
                isOpen = false,
            }
        else
            table.insert(Drops[newDropId].items, item)
        end
        BroadcastEvent('qb-inventory:client:registerDropTarget', bag.Object, newDropId)
        Drops[newDropId].isOpen = true
        local formattedDrop = {
            name = newDropId,
            label = 'Drop',
            maxweight = Config.DropSize.maxweight,
            slots = Config.DropSize.slots,
            inventory = Drops[newDropId].items,
        }
        print('[createDrop] 1. firing openInventory client event for ' .. newDropId)
        TriggerClientEvent(source, 'qb-inventory:client:openInventory', Player.PlayerData.items, formattedDrop)
        print('[createDrop] 2. returning newDropId ' .. newDropId)
        return newDropId
    else
        return false
    end
end)

local recentPurchases = {}

RegisterCallback('attemptPurchase', function(source, data)
    local dedupKey = tostring(source) .. '_' .. tostring(data.item and data.item.slot) .. '_' .. tostring(data.shop)
    local now = os.time()
    if recentPurchases[dedupKey] and (now - recentPurchases[dedupKey]) < 2 then
        return false
    end
    recentPurchases[dedupKey] = now
    local itemInfo = data.item
    local amount = data.amount
    local shop = string.gsub(data.shop, 'shop%-', '')
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end

    local shopInfo = RegisteredShops[shop]
    if not shopInfo then
        return false
    end

    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    if shopInfo.coords then
        local shopCoords = Vector(shopInfo.coords.X, shopInfo.coords.Y, shopInfo.coords.Z)
        if GetDistanceBetweenCoords(playerCoords, shopCoords) > 650 then
            return false
        end
    end

    if shopInfo.items[itemInfo.slot].name ~= itemInfo.name then
        return false
    end

    if amount > shopInfo.items[itemInfo.slot].amount then
        return false
    end

    if not CanAddItem(source, itemInfo.name, amount) then
        TriggerClientEvent(source, 'QBCore:Notify', 'Cannot hold item', 'error')
        return false
    end

    local canAddToSlot = false
    if not Player.PlayerData.items[data.slot] then
        canAddToSlot = true
    end

    local price = shopInfo.items[itemInfo.slot].price * amount
    if Player.PlayerData.money.cash >= price then
        Player.RemoveMoney('cash', price, 'shop-purchase')
        AddItem(source, itemInfo.name, amount, canAddToSlot and data.slot, itemInfo.info)
        exports['qb-shops']:UpdateShopItems(shop, itemInfo, amount)
        shopInfo.items[itemInfo.slot].amount = shopInfo.items[itemInfo.slot].amount - amount
        TriggerClientEvent(source, 'qb-inventory:client:updateInventory', Player.PlayerData.items)
        TriggerClientEvent(source, 'qb-inventory:client:updateShopInventory', shopInfo.items)
        return true
    else
        TriggerClientEvent(source, 'QBCore:Notify', 'You do not have enough money', 'error')
        return false
    end
end)

RegisterCallback('giveItem', function(source, target, item, amount)
    local player = exports['qb-core']:GetPlayer(source)
    if not player or player.PlayerData.metadata['isdead'] or player.PlayerData.metadata['inlaststand'] or player.PlayerData.metadata['ishandcuffed'] then
        return false
    end
    local playerPed = GetPlayerPawn(source)
    local Target = exports['qb-core']:GetPlayer(target)
    if not Target or Target.PlayerData.metadata['isdead'] or Target.PlayerData.metadata['inlaststand'] or Target.PlayerData.metadata['ishandcuffed'] then
        return false
    end
    local targetPed = GetPlayerPawn(target)
    local pCoords = GetEntityCoords(playerPed)
    local tCoords = GetEntityCoords(targetPed)
    if GetDistanceBetweenCoords(pCoords, tCoords) > 1000 then
        return false
    end
    local itemInfo = sharedItems[item:lower()]
    if not itemInfo then
        return false
    end
    local hasItem = HasItem(source, item)
    if not hasItem then
        return false
    end
    local itemAmount = GetItemByName(source, item).amount
    if itemAmount <= 0 then
        return false
    end
    local giveAmount = tonumber(amount)
    if giveAmount > itemAmount then
        return false
    end
    local removeItem = RemoveItem(source, item, giveAmount)
    if not removeItem then
        return false
    end
    local giveItem = AddItem(target, item, giveAmount)
    if not giveItem then
        AddItem(source, item, giveAmount)
        return false
    end

    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'remove', giveAmount)
    TriggerClientEvent(target, 'qb-inventory:client:ItemBox', itemInfo, 'add', giveAmount)
    return true
end)

-- Item move logic

local function getItem(inventoryId, src, slot)
    local items = {}
    if inventoryId == 'player' then
        local Player = exports['qb-core']:GetPlayer(src)
        if Player and Player.PlayerData.items then
            items = Player.PlayerData.items
        end
    elseif inventoryId:find('otherplayer-') then
        local targetId = tonumber(inventoryId:match('otherplayer%-(.+)'))
        local targetPlayer = exports['qb-core']:GetPlayer(targetId)
        if targetPlayer and targetPlayer.PlayerData.items then
            items = targetPlayer.PlayerData.items
        end
    elseif inventoryId:find('drop-') == 1 then
        if Drops[inventoryId] and Drops[inventoryId]['items'] then
            items = Drops[inventoryId]['items']
        end
    else
        if Inventories[inventoryId] and Inventories[inventoryId]['items'] then
            items = Inventories[inventoryId]['items']
        end
    end

    for _, item in pairs(items) do
        if item.slot == slot then
            return item
        end
    end
    return nil
end

local function getIdentifier(inventoryId, src)
    if inventoryId == 'player' then
        return src
    elseif inventoryId:find('otherplayer-') then
        return tonumber(inventoryId:match('otherplayer%-(.+)'))
    else
        return inventoryId
    end
end

RegisterServerEvent('qb-inventory:server:SetInventoryData', function(source, fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
    if toInventory:find('shop%-') then
        return
    end
    if not fromInventory or not toInventory or not fromSlot or not toSlot or not fromAmount or not toAmount or fromAmount < 0 or toAmount < 0 then
        return
    end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    fromSlot, toSlot, fromAmount, toAmount = tonumber(fromSlot), tonumber(toSlot), tonumber(fromAmount), tonumber(toAmount)

    local fromItem = getItem(fromInventory, source, fromSlot)
    local toItem = getItem(toInventory, source, toSlot)

    if fromItem then
        if not toItem and toAmount > fromItem.amount then
            return
        end
        if fromInventory == 'player' and toInventory ~= 'player' then
            --checkWeapon(source, fromItem)
        end

        local fromId = getIdentifier(fromInventory, source)
        local toId = getIdentifier(toInventory, source)

        if toItem and fromItem.name == toItem.name then
            if RemoveItem(fromId, fromItem.name, toAmount, fromSlot, 'stacked item') then
                AddItem(toId, toItem.name, toAmount, toSlot, toItem.info, 'stacked item')
            end
        elseif not toItem and toAmount < fromAmount then
            if RemoveItem(fromId, fromItem.name, toAmount, fromSlot, 'split item') then
                AddItem(toId, fromItem.name, toAmount, toSlot, fromItem.info, 'split item')
            end
        else
            if toItem then
                local fromItemAmount = fromItem.amount
                local toItemAmount = toItem.amount

                if RemoveItem(fromId, fromItem.name, fromItemAmount, fromSlot, 'swapped item') and RemoveItem(toId, toItem.name, toItemAmount, toSlot, 'swapped item') then
                    AddItem(toId, fromItem.name, fromItemAmount, toSlot, fromItem.info, 'swapped item')
                    AddItem(fromId, toItem.name, toItemAmount, fromSlot, toItem.info, 'swapped item')
                end
            else
                if RemoveItem(fromId, fromItem.name, toAmount, fromSlot, 'moved item') then
                    AddItem(toId, fromItem.name, toAmount, toSlot, fromItem.info, 'moved item')
                end
            end
        end
    end
end)
