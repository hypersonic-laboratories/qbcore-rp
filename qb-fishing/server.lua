local activeFishers = {}
local TOOL_ID = 'ID_Misc_FishingRod'

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    if activeFishers[source] then
        HInventory.RemoveItemByName(source, TOOL_ID, 1)
        activeFishers[source] = nil
    end
end)

RegisterServerEvent('qb-fishing:server:startFishingItem', function(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end
    HInventory.GiveAndEquipItemByName(pawn, TOOL_ID)
    activeFishers[source] = true
end)

RegisterServerEvent('qb-fishing:server:completeFishing', function(source, waterTypeId)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    if activeFishers[source] then
        HInventory.RemoveItemByName(source, TOOL_ID, 1)
        activeFishers[source] = nil
    end

    local waterConfig = Config.waterTypes[waterTypeId]
    if not waterConfig or not waterConfig.reward then
        return
    end

    local caughtFish = waterConfig.reward

    exports['qb-inventory']:AddItem(source, caughtFish, 1)
    TriggerClientEvent(source, 'QBCore:Notify', 'You caught a ' .. caughtFish .. '!', 'success')
end)

function onShutdown()
    for src in pairs(activeFishers) do
        HInventory.RemoveItemByName(src, TOOL_ID, 1)
    end
    activeFishers = {}
end
