local function Notify(source, text, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType or 'primary', length)
end

local function GetStation(data)
    local stationKey = data and data.station
    return stationKey and Config.Locations[stationKey] or nil
end

local function GetPumpCoords(data)
    local station = GetStation(data)
    local pumpIndex = data and tonumber(data.pump)
    return station and pumpIndex and station.pumps and station.pumps[pumpIndex] or nil
end

local function GetRefuelVehicle(source, data)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return nil, nil
    end

    local station = GetStation(data) or {}
    local searchRadius = station.vehicleSearchRadius or Config.defaultVehicleSearchRadius
    local searchCoords = GetPumpCoords(data) or GetEntityCoords(pawn)

    return GetClosestVehicle(searchCoords, searchRadius)
end

local function RefuelVehicle(vehicle, amount)
    -- TODO: Wire this once HELIX exposes a real fuel API for Chaos vehicles.
    return false
end

RegisterServerEvent('qb-fuel:server:Refuel', function(source, data)
    local vehicle, distance = GetRefuelVehicle(source, data)
    if not vehicle then
        print(('[qb-fuel] Refuel failed: no server-side vehicle found source=%s station=%s pump=%s'):format(tostring(source), tostring(data and data.station), tostring(data and data.pump)))
        Notify(source, 'No vehicle found to refuel.', 'error')
        return
    end

    local station = GetStation(data) or {}
    local refuelAmount = station.refuelAmount or Config.defaultRefuelAmount or 100.0

    print(('[qb-fuel] Refuel TODO: station=%s pump=%s distance=%s amount=%s'):format(tostring(data and data.station), tostring(data and data.pump), tostring(distance), tostring(refuelAmount)))

    local refueled = RefuelVehicle(vehicle, refuelAmount)
    if not refueled then
        Notify(source, 'Vehicle fuel API is not available yet.', 'primary')
        return
    end

    Notify(source, 'Vehicle refueled.', 'success')
end)
