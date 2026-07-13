local pendingRimPaint = {}

local function configEntry(entries, key)
    for _, entry in ipairs(entries) do
        if entry.key == key then
            return entry
        end
    end
end

local function notify(source, message, notificationType)
    TriggerClientEvent(source, 'QBCore:Notify', message, notificationType or 'primary')
end

local function vehicleIsNearPlayer(source, vehicle)
    local playerPawn = GetPlayerPawn(source)
    if not playerPawn or not vehicle then
        return false
    end

    local validOk, valid = pcall(function()
        return vehicle:IsValid()
    end)
    if not validOk or not valid then
        return false
    end

    local distanceOk, distance = pcall(function()
        return playerPawn:GetDistanceTo(vehicle)
    end)
    return distanceOk and tonumber(distance) and distance <= Config.VehicleSearchRadius + 100
end

local function beginRimPaint(source, itemData)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local itemSlot = type(itemData) == 'table' and tonumber(itemData.slot) or nil
    local inventoryItem = itemSlot and Player.GetItemBySlot(itemSlot) or nil
    if not inventoryItem or inventoryItem.name ~= Config.RimPaintItem then
        notify(source, 'You do not have any rim paint', 'error')
        return
    end

    local currentSelection = pendingRimPaint[source]
    if currentSelection and currentSelection.expiresAt >= os.time() then
        return
    end

    local playerPawn = GetPlayerPawn(source)
    local playerCoords = playerPawn and GetEntityCoords(playerPawn) or nil
    if not playerCoords then
        notify(source, 'Unable to locate your character', 'error')
        return
    end

    local vehicle, distance = GetClosestVehicle(playerCoords, Config.VehicleSearchRadius)
    if not vehicle or not distance then
        notify(source, 'No vehicle close enough to paint', 'error')
        return
    end

    local selection = {
        vehicle = vehicle,
        slot = itemSlot,
        expiresAt = os.time() + Config.SelectionTimeout,
    }
    pendingRimPaint[source] = selection

    Timer.SetTimeout(function()
        if pendingRimPaint[source] == selection then
            pendingRimPaint[source] = nil
        end
    end, Config.SelectionTimeout * 1000)

    TriggerClientEvent(source, 'qb-mechanicjob:client:openRimPaintMenu', vehicle)
end

RegisterServerEvent('qb-mechanicjob:server:useRimPaint', function(source, itemData)
    beginRimPaint(source, itemData)
end)

exports['qb-core']:CreateUseableItem(Config.RimPaintItem, {
    event = 'qb-mechanicjob:server:useRimPaint',
})

RegisterServerEvent('qb-mechanicjob:server:applyRimPaint', function(source, rimKey, colorKey)
    local selection = pendingRimPaint[source]
    if not selection or selection.expiresAt < os.time() then
        pendingRimPaint[source] = nil
        notify(source, 'Rim paint selection expired', 'error')
        return
    end

    local rim = rimKey ~= 'all' and configEntry(Config.RimComponents, rimKey) or true
    local color = configEntry(Config.RimColors, colorKey)
    if not rim or not color then
        return
    end

    if not vehicleIsNearPlayer(source, selection.vehicle) then
        pendingRimPaint[source] = nil
        notify(source, 'Move closer to the vehicle', 'error')
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local inventoryItem = Player and Player.GetItemBySlot(selection.slot) or nil
    if not inventoryItem or inventoryItem.name ~= Config.RimPaintItem then
        pendingRimPaint[source] = nil
        notify(source, 'You no longer have the rim paint', 'error')
        return
    end

    if Config.ConsumePaintOnApply and not Player.RemoveItem(Config.RimPaintItem, 1, selection.slot) then
        notify(source, 'Unable to use the rim paint', 'error')
        return
    end

    pendingRimPaint[source] = nil
    BroadcastEvent('qb-mechanicjob:client:applyRimPaint', selection.vehicle, rimKey, colorKey)
    notify(source, ('Applied %s rim paint'):format(color.label), 'success')
end)
