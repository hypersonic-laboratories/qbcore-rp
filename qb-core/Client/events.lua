RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.IsLoggedIn = true
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    QBCore.IsLoggedIn = false
end)

RegisterClientEvent('QBCore:Client:PvpHasToggled', function(pvp_state)
    SetCanAttackFriendly(PlayerPedId(), pvp_state, false)
    NetworkSetFriendlyFireOption(pvp_state)
end)

-- Player Data

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'all' then
        QBCore.PlayerData = val
        TriggerLocalClientEvent('QBCore:Player:SetPlayerData', val)
        TriggerLocalClientEvent('QBCore:Client:OnJobUpdate', val.job)
        TriggerLocalClientEvent('QBCore:Client:OnGangUpdate', val.gang)
    elseif QBCore.PlayerData and key then
        QBCore.PlayerData[key] = val
        if key == 'job' then TriggerLocalClientEvent('QBCore:Client:OnJobUpdate', val) end
        if key == 'gang' then TriggerLocalClientEvent('QBCore:Client:OnGangUpdate', val) end
    end
end)

RegisterClientEvent('QBCore:Notify', function(text, type, length, icon)
    QBCore.Functions.Notify(text, type, length, icon)
end)

-- Callbacks

RegisterClientEvent('QBCore:Client:TriggerClientCallback', function(name, ...)
    if not QBCore.ClientCallbacks[name] then return end

    QBCore.ClientCallbacks[name](function(...)
        TriggerServerEvent('QBCore:Server:TriggerClientCallback', name, ...)
    end, ...)
end)

RegisterClientEvent('QBCore:Client:TriggerCallback', function(name, ...)
    if QBCore.ServerCallbacks[name] then
        QBCore.ServerCallbacks[name].promise:resolve(...)

        if QBCore.ServerCallbacks[name].callback then
            QBCore.ServerCallbacks[name].callback(...)
        end

        QBCore.ServerCallbacks[name] = nil
    end
end)

-- Shared Data Sync

RegisterClientEvent('QBCore:Client:OnSharedUpdate', function(tableName, key, value)
    QBCore.Shared[tableName][key] = value
    TriggerLocalClientEvent('QBCore:Client:UpdateObject')
end)

RegisterClientEvent('QBCore:Client:OnSharedUpdateMultiple', function(tableName, values)
    for key, value in pairs(values) do
        QBCore.Shared[tableName][key] = value
    end
    TriggerLocalClientEvent('QBCore:Client:UpdateObject')
end)

RegisterClientEvent('QBCore:Client:SharedUpdate', function(table)
    QBCore.Shared = table
end)

-- Vehicle State

RegisterClientEvent('HEvent:EnteredVehicle', function(vehicle, seat)
    -- if not QBCore.IsLoggedIn then return end
    -- local plate = QBCore.Functions.GetPlate(vehicle)
    -- local hasKeys = true
    -- if GetResourceState('qb-vehiclekeys') == 'started' then
    --     hasKeys = exports['qb-vehiclekeys']:HasKeys(plate)
    -- end
    -- TriggerLocalClientEvent('QBCore:Client:EnteredVehicle', {
    --     vehicle = vehicle,
    --     seat    = seat,
    --     name    = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
    --     plate   = plate,
    --     driver  = GetPedInVehicleSeat(vehicle, -1),
    --     inseat  = GetPedInVehicleSeat(vehicle, seat),
    --     haskeys = hasKeys,
    -- })
end)

RegisterClientEvent('HEvent:LeftVehicle', function(vehicle, seat)
    -- if not QBCore.IsLoggedIn then return end
    -- local plate = QBCore.Functions.GetPlate(vehicle)
    -- TriggerLocalClientEvent('QBCore:Client:LeftVehicle', {
    --     vehicle = vehicle,
    --     seat    = seat,
    --     name    = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
    --     plate   = plate,
    --     driver  = GetPedInVehicleSeat(vehicle, -1),
    --     inseat  = GetPedInVehicleSeat(vehicle, seat),
    --     haskeys = true,
    -- })
end)
