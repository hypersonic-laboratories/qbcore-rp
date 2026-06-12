local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

-- Tracks active bench per player: { mesh = StaticMesh wrapper, benchType = string }
local ActiveBenches = {}

-- Functions

local function IncreasePlayerXP(source, xpGain, xpType)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        local currentXP = Player.GetRep(xpType)
        local newXP = currentXP + xpGain
        Player.AddRep(xpType, newXP)
        TriggerClientEvent(source, 'QBCore:Notify', string.format(Lang:t('notifications.xpGain'), xpGain, xpType), 'success')
    end
end

local function PickupBench(source)
    local bench = ActiveBenches[source]
    if not bench then
        return
    end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if not exports['qb-inventory']:AddItem(source, bench.benchType, 1, false, false, 'qb-crafting:pickup') then
        return
    end
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[bench.benchType], 'add')
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('notifications.pickupBench'), 'success')
    DestroyActor(bench.mesh.Object)
    TriggerClientEvent(source, 'qb-crafting:client:removeBench')
    ActiveBenches[source] = nil
end

local function SpawnBench(source, benchType)
    local Pawn = GetPlayerPawn(source)
    if not Pawn then
        return
    end

    local Location = GetEntityCoords(Pawn)
    local Rotation = GetEntityRotation(Pawn)
    local Forward = Pawn:GetActorForwardVector()
    local SpawnX = Location.X + Forward.X * 150
    local SpawnY = Location.Y + Forward.Y * 150

    local hit = Trace:LineSingle(Vector(SpawnX, SpawnY, Location.Z + 200), Vector(SpawnX, SpawnY, Location.Z - 500))
    local SpawnZ = (hit and hit.ImpactPoint) and hit.ImpactPoint.Z or (Location.Z - 88)

    local SpawnLoc = Vector(SpawnX, SpawnY, SpawnZ)
    local SpawnRot = Rotator(0, Rotation.Yaw + 90, 0)

    if ActiveBenches[source] then
        DestroyActor(ActiveBenches[source].mesh.Object)
        TriggerClientEvent(source, 'qb-crafting:client:removeBench')
    end

    local mesh = StaticMesh(SpawnLoc, SpawnRot, Config[benchType].meshPath)
    ActiveBenches[source] = { mesh = mesh, benchType = benchType }
    TriggerClientEvent(source, 'qb-crafting:client:registerBench', mesh.Object, benchType)
end

-- Callbacks

RegisterCallback('getPlayerInventory', function(source)
    local player = exports['qb-core']:GetPlayer(source)
    if player then
        return player.PlayerData.items
    end
    return {}
end)

-- Events

RegisterServerEvent('qb-crafting:server:pickupBench', function(source)
    PickupBench(source)
end)

RegisterServerEvent('qb-crafting:server:removeMaterials', function(source, itemName, amount)
    local Player = exports['qb-core']:GetPlayer(source)
    if Player then
        exports['qb-inventory']:RemoveItem(source, itemName, amount, false, 'qb-crafting:server:removeMaterials')
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[itemName], 'remove')
    end
end)

RegisterServerEvent('qb-crafting:server:receiveItem', function(source, craftedItem, requiredItems, amountToCraft, xpGain, xpType)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    for _, requiredItem in ipairs(requiredItems) do
        if not exports['qb-inventory']:RemoveItem(source, requiredItem.item, requiredItem.amount, false, 'qb-crafting:server:receiveItem') then
            return
        end
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[requiredItem.item], 'remove')
    end
    if not exports['qb-inventory']:AddItem(source, craftedItem, amountToCraft, false, false, 'qb-crafting:server:receiveItem') then
        return
    end
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[craftedItem], 'add')
    TriggerClientEvent(source, 'QBCore:Notify', string.format(Lang:t('notifications.craftMessage'), sharedItems[craftedItem].label), 'success')
    IncreasePlayerXP(source, xpGain, xpType)
end)

-- Items

for benchType, v in pairs(Config) do
    if type(v) == 'table' and v.recipes then
        exports['qb-core']:CreateUseableItem(benchType, { event = 'qb-crafting:server:useBench' })
    end
end

RegisterServerEvent('qb-crafting:server:useBench', function(source, itemData)
    local benchType = itemData.name
    if not Config[benchType] or not Config[benchType].recipes then
        return
    end
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    exports['qb-inventory']:RemoveItem(source, benchType, itemData.slot)
    TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems[benchType], 'remove')
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('notifications.tablePlace'), 'success')
    SpawnBench(source, benchType)
end)
