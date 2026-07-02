Inventories = {}
Drops = {}
RegisteredShops = {}
local sharedItems = exports['qb-core']:GetShared('Items')
local DROP_INTERACTION_ANIMATION = '/HelixAnimation/Unified/Animations/Actions/PickUp/A_PickUp_Low.A_PickUp_Low'
local DROP_INTERACTION_FALLBACK_MS = 2000

local function GetPlayerSource(source)
    if type(source) == 'number' then
        local Player = exports['qb-core']:GetPlayer(source)
        return Player and Player.PlayerData and Player.PlayerData.source
    end
    return source
end

local function SetInventoryBusy(source, busy)
    local playerSource = GetPlayerSource(source)
    if playerSource then
        SetValue(playerSource, 'inv_busy', busy)
    end
end

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

local function GetSourcePawn(source)
    if type(source) ~= 'number' and source and source.GetPawn then
        local pawn = source:GetPawn()
        if pawn then
            return pawn
        end
    end

    return GetPlayerPawn(source)
end

local function NormalizeWeaponDisplayName(name)
    if not name then
        return nil
    end

    return tostring(name):lower():gsub('[^%w]', '')
end

local function GetHeldWeaponName(pawn)
    local equippedItems = HInventory.GetEquippedItems(pawn)
    if not equippedItems or equippedItems:Length() == 0 then
        return nil
    end

    local equipmentInstance = equippedItems:Get(1)
    local owningItemInstance = equipmentInstance and HInventory.GetOwningItemFromEquipment(equipmentInstance)
    local itemDef = owningItemInstance and owningItemInstance:GetItemDef()
    return itemDef and itemDef.DisplayName
end

local function GetWeaponDisplayNameFromAssetName(assetName)
    if not assetName then
        return nil
    end

    return assetName:match('^ID_Weapon_[^_]+_(.+)$') or assetName:match('^ID_Weapon_(.+)$')
end

local function IsHeldWeaponItem(pawn, itemName, itemInfo)
    if not pawn or not itemInfo or itemInfo.type ~= 'weapon' then
        return false
    end

    local heldWeaponName = NormalizeWeaponDisplayName(GetHeldWeaponName(pawn))
    if not heldWeaponName then
        return false
    end

    local itemDisplayName = itemName and itemName:gsub('^weapon_', '')
    return heldWeaponName == NormalizeWeaponDisplayName(itemInfo.label) or heldWeaponName == NormalizeWeaponDisplayName(GetWeaponDisplayNameFromAssetName(itemInfo.asset_name)) or heldWeaponName == NormalizeWeaponDisplayName(itemDisplayName)
end

local function UnequipHeldWeaponItem(pawn, itemInfo)
    if not pawn or not itemInfo or not itemInfo.asset_name then
        return
    end

    HInventory.UnequipAllItems(pawn)
    HInventory.ClearQuickBar(pawn)
    HInventory.RemoveItemByName(pawn, itemInfo.asset_name, 1)
end

local function PlayDropInteractionAnimation(pawn, onEnded)
    if not pawn or not Animation or not Animation.Play then
        return false
    end

    return Animation.Play(pawn, DROP_INTERACTION_ANIMATION, nil, onEnded)
end

local function AfterDropInteractionAnimation(pawn, onComplete)
    local completed = false
    local function complete()
        if completed then
            return
        end

        completed = true
        onComplete()
    end

    if not PlayDropInteractionAnimation(pawn, complete) then
        complete()
        return
    end

    if Timer and Timer.SetTimeout then
        Timer.SetTimeout(complete, DROP_INTERACTION_FALLBACK_MS)
    end
end

local function EquipWeaponItem(source, itemData)
    if not itemData or not itemData.name then
        return
    end

    local itemInfo = sharedItems[itemData.name]
    if not itemInfo or itemInfo.type ~= 'weapon' or not itemInfo.asset_name then
        return
    end

    local pawn = GetSourcePawn(source)
    if not pawn then
        return
    end

    if IsHeldWeaponItem(pawn, itemData.name, itemInfo) then
        UnequipHeldWeaponItem(pawn, itemInfo)
        return
    end

    local itemDef = HInventory.GetItemDefinitionByAssetName(itemInfo.asset_name, true)
    if not itemDef then
        TriggerClientEvent(source, 'QBCore:Notify', 'Weapon definition not found', 'error')
        return
    end

    HInventory.ClearQuickBar(pawn)
    HInventory.ClearInventory(pawn)
    HInventory.UnequipAllItems(pawn)
    HInventory.GiveItem(pawn, itemDef, 1, nil)

    Timer.Delay(pawn, 0.2, function()
        local itemInstance = HInventory.GetFirstItemByDefinition(pawn, itemDef)
        if itemInstance then
            HInventory.AddItemToQuickBarFirstEmpty(pawn, itemInstance)
            HInventory.EquipItem(pawn, itemInstance)
        end
    end)
end

RegisterServerEvent('qb-inventory:server:useWeaponItem', function(source, itemData)
    EquipWeaponItem(source, itemData)
end)

for itemName, itemInfo in pairs(sharedItems) do
    if itemInfo.type == 'weapon' then
        exports['qb-core']:CreateUseableItem(itemName, { event = 'qb-inventory:server:useWeaponItem' })
    end
end

-- Handlers

RegisterServerEvent('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    for dropId, drop in pairs(Drops) do
        TriggerClientEvent(src, 'qb-inventory:client:registerDropTarget', drop.entity.Object, dropId)
    end
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
    SetInventoryBusy(source, false)
    if not inventory then
        return
    end
    if inventory:find('shop%-') then
        return
    end
    if inventory:find('otherplayer%-') then
        local targetId = tonumber(inventory:match('otherplayer%-(.+)'))
        local TargetPlayer = targetId and exports['qb-core']:GetPlayer(targetId)
        if TargetPlayer and TargetPlayer.PlayerData and TargetPlayer.PlayerData.source then
            SetInventoryBusy(TargetPlayer.PlayerData.source, false)
        end
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
    UseItem(itemData.name, source, itemData)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'use')
    if itemInfo.shouldClose then
        TriggerClientEvent(source, 'qb-inventory:client:closeInv')
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
    if not DropData or not DropData.isHeld or DropData.isPickupPending or DropData.isReleasing then
        return
    end
    local playerPed = GetPlayerPawn(source)
    if not playerPed then
        return
    end

    DropData.isReleasing = true
    AfterDropInteractionAnimation(playerPed, function()
        if Drops[dropId] ~= DropData then
            return
        end
        local currentPed = GetPlayerPawn(source) or playerPed
        if not currentPed or not DropData.entity or not DropData.entity.Object then
            DropData.isReleasing = nil
            return
        end

        local playerCoords = GetEntityCoords(currentPed)
        local PawnRotation = GetEntityRotation(currentPed)
        local ForwardVec = currentPed:GetActorForwardVector()
        local SpawnX = playerCoords.X + ForwardVec.X * 200
        local SpawnY = playerCoords.Y + ForwardVec.Y * 200
        local hit = Trace:LineSingle(Vector(SpawnX, SpawnY, playerCoords.Z + 200), Vector(SpawnX, SpawnY, playerCoords.Z - 500))
        local SpawnZ = (hit and hit.ImpactPoint) and hit.ImpactPoint.Z or (playerCoords.Z - 88)
        local DropPosition = Vector(SpawnX, SpawnY, SpawnZ)
        DropData.coords = DropPosition
        DropData.isHeld = nil
        DropData.isReleasing = nil
        DetachActor(DropData.entity.Object, {
            Location = DetachmentRule.KeepWorld,
            Rotation = DetachmentRule.KeepWorld,
        })
        SetEntityCoords(DropData.entity.Object, DropPosition)
        SetEntityRotation(DropData.entity.Object, Rotator(0, PawnRotation.Yaw, 0))
        DropData.entity.Component:SetCollisionProfileName('BlockAllDynamic', true)
    end)
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
    if not playerPed:GetCharacterBaseMesh() then
        return
    end
    DropData.isHeld = true
    DropData.isPickupPending = true
    AfterDropInteractionAnimation(playerPed, function()
        if Drops[dropId] ~= DropData then
            return
        end
        local currentPed = GetPlayerPawn(source) or playerPed
        local currentMesh = currentPed and currentPed:GetCharacterBaseMesh()
        if not currentMesh or not DropData.entity or not DropData.entity.Object then
            DropData.isHeld = nil
            DropData.isPickupPending = nil
            return
        end

        AttachActorToComponent(DropData.entity.Object, currentMesh, Vector(45, 0, 0), Rotator(-90, 0, 180), 'hand_l', {
            Location = AttachmentRule.SnapToTarget,
            Rotation = AttachmentRule.SnapToTarget,
            Scale = AttachmentRule.SnapToTarget,
        })
        DropData.isPickupPending = nil
        TriggerClientEvent(source, 'qb-inventory:client:holdDrop', dropId)
    end)
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
    if type(item) ~= 'table' or type(item.name) ~= 'string' then
        return false
    end
    local playerPed = GetPlayerPawn(source)
    if not playerPed then
        return false
    end
    local playerCoords = GetEntityCoords(playerPed)
    local itemInfo = sharedItems[item.name:lower()]
    local shouldUnequipHeldWeapon = IsHeldWeaponItem(playerPed, item.name, itemInfo)
    if RemoveItem(source, item.name, item.amount, item.fromSlot) then
        if shouldUnequipHeldWeapon then
            UnequipHeldWeaponItem(playerPed, itemInfo)
        end
        PlayDropInteractionAnimation(playerPed)
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
        TriggerClientEvent(source, 'qb-inventory:client:openInventory', Player.PlayerData.items, formattedDrop)
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

RegisterCallback('giveItem', function(source, target, item, amount, slot)
    local player = exports['qb-core']:GetPlayer(source)
    if not player or player.PlayerData.metadata['isdead'] or player.PlayerData.metadata['inlaststand'] or player.PlayerData.metadata['ishandcuffed'] then
        return false
    end
    local playerPed = GetPlayerPawn(source)
    if not playerPed then
        return false
    end
    local Target = exports['qb-core']:GetPlayer(target)
    if not Target or Target.PlayerData.metadata['isdead'] or Target.PlayerData.metadata['inlaststand'] or Target.PlayerData.metadata['ishandcuffed'] then
        return false
    end
    local targetSource = Target.PlayerData.source
    if not targetSource then
        return false
    end
    if targetSource == source or tonumber(target) == tonumber(player.PlayerData.netId) then
        return false
    end
    local targetPed = GetPlayerPawn(targetSource)
    if not targetPed then
        return false
    end
    local pCoords = GetEntityCoords(playerPed)
    local tCoords = GetEntityCoords(targetPed)
    if GetDistanceBetweenCoords(pCoords, tCoords) > 1000 then
        return false
    end
    if type(item) ~= 'string' then
        return false
    end
    local itemName = item:lower()
    local itemInfo = sharedItems[itemName]
    if not itemInfo then
        return false
    end

    local giveAmount = tonumber(amount)
    if not giveAmount or giveAmount <= 0 or giveAmount ~= math.floor(giveAmount) then
        return false
    end

    local selectedSlot = tonumber(slot)
    local itemData = selectedSlot and GetItemBySlot(source, selectedSlot) or GetItemByName(source, itemName)
    if not itemData or not itemData.name or itemData.name:lower() ~= itemName then
        return false
    end
    local itemMeta = type(itemData.info) == 'table' and itemData.info or {}

    local itemAmount = tonumber(itemData.amount) or 0
    if itemAmount <= 0 then
        return false
    end
    if giveAmount > itemAmount then
        return false
    end

    if not CanAddItem(targetSource, itemName, giveAmount) then
        return false
    end

    local shouldUnequipHeldWeapon = IsHeldWeaponItem(playerPed, itemName, itemInfo)
    local removeSlot = itemData.slot or selectedSlot
    local removeItem = RemoveItem(source, itemName, giveAmount, removeSlot)
    if not removeItem then
        return false
    end
    local giveItem = AddItem(targetSource, itemName, giveAmount, false, itemMeta)
    if not giveItem then
        AddItem(source, itemName, giveAmount, removeSlot, itemMeta)
        return false
    end

    if shouldUnequipHeldWeapon then
        UnequipHeldWeaponItem(playerPed, itemInfo)
    end
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', itemInfo, 'remove', giveAmount)
    TriggerClientEvent(targetSource, 'qb-inventory:client:ItemBox', itemInfo, 'add', giveAmount)
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
        local fromId = getIdentifier(fromInventory, source)
        local toId = getIdentifier(toInventory, source)

        local fromItemInfo = sharedItems[fromItem.name:lower()]
        if toItem and fromItem.name == toItem.name and not (fromItemInfo and fromItemInfo.unique) then
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
