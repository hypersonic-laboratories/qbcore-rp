Inventories = {}
Drops = {}
RegisteredShops = {}
require('Shared/locales/en')
--require('Server/commands')

SharedItems = exports['qb-core']:GetShared('Items')

-- Handlers

RegisterServerEvent('QBCore:Server:PlayerLoaded', function(Player)
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
    if not Player or Player.PlayerData.metadata['isdead'] or
        Player.PlayerData.metadata['inlaststand'] or
        Player.PlayerData.metadata['ishandcuffed'] then
        return
    end

    local player_ped = GetPlayerPawn(source)
    if not player_ped then return end

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
        local Comps = ClosestVehicle:K2_GetComponentsByClass(UE.UClass.Load('/Game/SimpleVehicle/Blueprints/Components/Attachments/Trunk.Trunk_C'))
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
    if not Player or Player.PlayerData.metadata['isdead'] or Player.PlayerData.metadata['inlaststand'] or Player.PlayerData.metadata['ishandcuffed'] then return end
    local hotbarItems = {
        Player.PlayerData.items[1],
        Player.PlayerData.items[2],
        Player.PlayerData.items[3],
        Player.PlayerData.items[4],
        Player.PlayerData.items[5],
    }
    TriggerClientEvent(source, 'qb-inventory:client:hotbar', hotbarItems)
end)

RegisterServerEvent('qb-inventory:server:openVending', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    CreateShop({
        name = 'vending',
        label = 'Vending Machine',
        coords = vendingMachineCoords,
        slots = #Config.VendingItems,
        items = Config.VendingItems
    })
    OpenShop(source, 'vending')
end)

RegisterServerEvent('qb-inventory:server:closeInventory', function(source, inventory)
    local QBPlayer = exports['qb-core']:GetPlayer(source)
    if not QBPlayer then return end
    local player_ped = GetPlayerPawn(source)
    --[[     player_ped:SetInputEnabled(true)
    source:SetValue('inv_busy', false, true) ]]
    if not inventory then return end
    if inventory:find('shop-') then return end
    if inventory:find('otherplayer-') then
        local targetId = tonumber(inventory:match('otherplayer%-(.+)'))
        --targetId:SetValue('inv_busy', false, true)
        return
    end
    if Drops[inventory] then
        if #Drops[inventory].items == 0 then
            if Drops[inventory].entity then DeleteEntity(Drops[inventory].entity) end
            if Drops[inventory].interactable then DeleteEntity(Drops[inventory].interactable) end
        end
        Drops[inventory].isOpen = false
        return
    end
    if not Inventories[inventory] then return end
    Inventories[inventory].isOpen = false
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO inventories (identifier, items) VALUES (?, ?) ON CONFLICT(identifier) DO UPDATE SET items = ?', { inventory, JSON.stringify(Inventories[inventory].items), JSON.stringify(Inventories[inventory].items) })
end)

RegisterServerEvent('qb-inventory:server:useItem', function(source, item)
    local itemData = GetItemBySlot(source, item.slot)
    if not itemData then return end
    local itemInfo = SharedItems[itemData.name]
    if itemInfo.type == 'weapon' then
        --Events.Call('qb-weapons:server:equipWeapon', source, itemData)
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'use')
        --TriggerClientEvent('qb-inventory:client:useItem', source, true, itemData)
    else
        UseItem(itemData.name, source, itemData)
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'use')
        --TriggerClientEvent('qb-inventory:client:useItem', source, true, itemData)
    end
end)

RegisterServerEvent('qb-inventory:server:openDrop', function(source, dropId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    local drop = Drops[dropId]
    if not drop or drop.isOpen then return end
    if GetDistanceBetweenCoords(playerCoords, drop.coords) > 250 then return end

    local formattedInventory = {
        name = dropId,
        label = dropId,
        maxweight = drop.maxweight,
        slots = drop.slots,
        inventory = drop.items
    }
    drop.isOpen = true
    TriggerClientEvent(source, 'qb-inventory:client:openInventory', Player.PlayerData.items, formattedInventory)
end)

RegisterServerEvent('qb-inventory:server:updateDrop', function(source, dropId)
    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    local DropData = Drops[dropId]
    DropData.coords = playerCoords
    DropData.isHeld = nil
    if DropData.entity:IsValid() then
        DropData.entity:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
        local Mesh = DropData.entity:GetComponentByClass(UE.UStaticMeshComponent)
        local Box = DropData.interactable.BoxCollision
        if Mesh then Mesh:SetCollisionProfileName('BlockAllDynamic', true) end
        if Box then Box:SetCollisionProfileName('BlockAllDynamic', true) end
    end
end)

-- Callbacks

RegisterCallback('server.GetCurrentDrops', function(_)
    return Drops
end)

RegisterCallback('server.createDrop', function(source, item)
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
        local SpawnPosition = playerCoords + (ForwardVec * 200)
        PawnRotation.Yaw = PawnRotation.Yaw

        local bag = StaticMesh(SpawnPosition, PawnRotation, Config.ItemDropObject, CollisionType.StaticOnly)
        bag:SetActorScale3D(Vector(0.8, 0.8, 0.8))
        local newDropId = string.format('drop-%d', math.random(111111, 9999999))
        local bagInteractable = Interactable({
            {
                Text = 'Open Drop',
                Input = '/Game/Helix/Input/Actions/IA_Interact.IA_Interact',
                Action = function(Drop, Instigator)
                    local Controller = Instigator and Instigator:GetController()
                    if Controller then
                        TriggerClientEvent(Controller, 'qb-inventory:client:openDrop', { dropId = newDropId })
                    end
                end,
            },
            {
                Text = 'Pick Up Bag',
                Input = '/Game/Helix/Input/Actions/IA_Weapon_Reload.IA_Weapon_Reload',
                Action = function(Drop, Instigator)
                    local DropData = Drops[newDropId]
                    if DropData.isOpen then return end
                    if DropData.isHeld then return end
                    local mesh = Instigator:GetCharacterBaseMesh()
                    TriggerClientEvent(source, 'qb-inventory:client:holdDrop', newDropId)
                    Drop.InteractableProp:SetMobility(UE.EComponentMobility.Movable)
                    Drop.InteractableProp:K2_AttachToComponent(mesh, 'hand_r', UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, true)
                    Drop.InteractableProp:K2_SetActorRelativeLocation(Vector(-35, 0, 10), false, nil, true)
                    Drop.InteractableProp:K2_SetActorRelativeRotation(Rotator(-95, 0, 0), false, nil, true)
                    Drop.InteractableProp:SetActorScale3D(Vector(0.8, 0.8, 0.8))
                    Drop:K2_AttachToActor(Drop.InteractableProp, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, true)
                    DropData.isHeld = Instigator
                    local MeshComponent = Drop.InteractableProp:GetComponentByClass(UE.UStaticMeshComponent)
                    if MeshComponent then MeshComponent:SetCollisionProfileName('HandAttachedMesh', true) end
                    if Drop.BoxCollision then Drop.BoxCollision:SetCollisionProfileName('HandAttachedMesh', true) end
                end
            }
        })
        bagInteractable:SetInteractableProp(bag)
        bagInteractable.BoxCollision:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Overlap)
        if not Drops[newDropId] then
            Drops[newDropId] = {
                name = newDropId,
                label = 'Drop',
                items = { item },
                entity = bag,
                interactable = bagInteractable,
                creator = source,
                createdTime = os.time(),
                coords = playerCoords,
                maxweight = Config.DropSize.maxweight,
                slots = Config.DropSize.slots,
                isOpen = true
            }
            --BroadcastRemote('qb-inventory:client:setupDropTarget', bag.Object)
        else
            table.insert(Drops[newDropId].items, item)
        end
        return newDropId
    else
        return false
    end
end)

RegisterCallback('server.attemptPurchase', function(source, data)
    local itemInfo = data.item
    local amount = data.amount
    local shop = string.gsub(data.shop, 'shop%-', '')
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end

    local shopInfo = RegisteredShops[shop]
    if not shopInfo then return false end

    local playerPed = GetPlayerPawn(source)
    local playerCoords = GetEntityCoords(playerPed)
    if shopInfo.coords then
        local shopCoords = Vector(shopInfo.coords.X, shopInfo.coords.Y, shopInfo.coords.Z)
        if GetDistanceBetweenCoords(playerCoords, shopCoords) > 650 then return false end
    end

    if shopInfo.items[itemInfo.slot].name ~= itemInfo.name then return false end -- check item name in slot passed

    if amount > shopInfo.items[itemInfo.slot].amount then return false end

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
        exports['qb-core']:Player(source, 'RemoveMoney', 'cash', price, 'shop-purchase')
        AddItem(source, itemInfo.name, amount, canAddToSlot and data.slot, itemInfo.info)
        exports['qb-shops']:UpdateShopItems(shop, itemInfo, amount)
        return true
    else
        TriggerClientEvent(source, 'QBCore:Notify', 'You do not have enough money', 'error')
        return false
    end
end)

RegisterCallback('server.giveItem', function(source, target, item, amount)
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

    local itemInfo = SharedItems[item:lower()]
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

    local giveItem = AddItem(target, item, giveAmount)
    if not giveItem then
        return false
    end

    local removeItem = RemoveItem(source, item, giveAmount)
    if not removeItem then
        return false
    end

    --if itemInfo.type == 'weapon' then SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true) end
    --TriggerClientEvent('qb-inventory:client:giveAnim', source)
    --TriggerClientEvent('qb-inventory:client:ItemBox', source, itemInfo, 'remove', giveAmount)
    --TriggerClientEvent('qb-inventory:client:giveAnim', target)
    --TriggerClientEvent('qb-inventory:client:ItemBox', target, itemInfo, 'add', giveAmount)
    --if Player(target).state.inv_busy then TriggerClientEvent('qb-inventory:client:updateInventory', target) end
    return true
end)

-- Item move logic

local function getItem(inventoryId, src, slot)
    local item
    if inventoryId == 'player' then
        local Player = exports['qb-core']:GetPlayer(src)
        item = Player.PlayerData.items[slot]
    elseif inventoryId:find('otherplayer-') then
        local targetId = tonumber(inventoryId:match('otherplayer%-(.+)'))
        local targetPlayer = exports['qb-core']:GetPlayer(targetId)
        if targetPlayer then
            item = targetPlayer.PlayerData.items[slot]
        end
    elseif inventoryId:find('drop-') then
        item = Drops[inventoryId]['items'][slot]
    else
        item = Inventories[inventoryId]['items'][slot]
    end
    return item
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
    if not fromInventory or not toInventory or not fromSlot or not toSlot or not fromAmount or not toAmount then return end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    fromSlot, toSlot, fromAmount, toAmount = tonumber(fromSlot), tonumber(toSlot), tonumber(fromAmount), tonumber(toAmount)
    local fromItem = getItem(fromInventory, source, fromSlot)
    local toItem = getItem(toInventory, source, toSlot)

    if fromItem then
        if not toItem and toAmount > fromItem.amount then return end

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
                if RemoveItem(fromId, fromItem.name, fromAmount, fromSlot, 'swapped item') and RemoveItem(toId, toItem.name, toAmount, toSlot, 'swapped item') then
                    AddItem(toId, fromItem.name, fromAmount, toSlot, fromItem.info, 'swapped item')
                    AddItem(fromId, toItem.name, toAmount, fromSlot, toItem.info, 'swapped item')
                end
            else
                if RemoveItem(fromId, fromItem.name, toAmount, fromSlot, 'moved item') then
                    AddItem(toId, fromItem.name, toAmount, toSlot, fromItem.info, 'moved item')
                end
            end
        end
    end
end)
