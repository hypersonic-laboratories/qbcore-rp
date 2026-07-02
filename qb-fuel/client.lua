local registeredZones = {}
local fuelMarkers = {}

local function Notify(text, notifyType, length)
    exports['qb-core']:Notify(text, notifyType or 'primary', length)
end

local function GetFuelOptions(stationKey, pumpIndex)
    return {
        {
            type = 'client',
            icon = 'container',
            label = 'Fuel Can',
            event = 'qb-fuel:client:FuelCan',
            station = stationKey,
            pump = pumpIndex,
        },
        {
            type = 'server',
            icon = 'fuel',
            label = 'Refuel',
            event = 'qb-fuel:server:Refuel',
            station = stationKey,
            pump = pumpIndex,
        },
    }
end

local function RegisterFuelStations()
    for stationKey, station in pairs(Config.Locations) do
        for i, pumpCoords in ipairs(station.pumps or {}) do
            local zoneName = 'fuel_' .. stationKey .. '_' .. i
            exports['qb-target']:AddSphereZone(zoneName, pumpCoords, station.pumpRadius or Config.defaultPumpRadius, {
                distance = station.pumpDistance or Config.defaultPumpDistance,
                debug = true,
            }, GetFuelOptions(stationKey, i))
            registeredZones[#registeredZones + 1] = zoneName
        end

        if station.showBlip ~= false then
            local markerId = exports['qb-hud']:AddMarker(station.coords, {
                title = station.label,
                description = station.description or '',
                icon = station.blipIcon or Config.defaultBlipIcon,
                color = station.blipColor,
                markerType = station.markerType or Config.defaultMarkerType,
            })
            if markerId then
                fuelMarkers[#fuelMarkers + 1] = markerId
            end
        end
    end
end

local function UnregisterFuelStations()
    for _, zoneName in ipairs(registeredZones) do
        exports['qb-target']:RemoveZone(zoneName)
    end
    registeredZones = {}

    for _, markerId in ipairs(fuelMarkers) do
        exports['qb-hud']:RemoveMarker(markerId)
    end
    fuelMarkers = {}
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    RegisterFuelStations()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    UnregisterFuelStations()
end)

RegisterClientEvent('qb-fuel:client:FuelCan', function(data)
    print(('[qb-fuel] Fuel Can selected: station=%s pump=%s'):format(tostring(data and data.station), tostring(data and data.pump)))
    Notify('Fuel cans are not wired up yet.', 'primary')
end)
