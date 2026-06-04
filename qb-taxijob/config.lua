Config = {
    Vehicle = '/abcca-qbcore-veh/QBCoreVehicles/BP_Taxi.BP_Taxi_C',
    Rate = 125.0,       -- price per mile
    MaxFarePadding = 2, -- adjust this as needed to account for turns, etc.
    Locations = {
        Depots = {
            {
                label = 'Taxi Depot',
                pedSpawn = { coords = Vector(-355290, -131250, -2880), heading = 165 },
                vehicleSpawn = { coords = Vector(-355917, -130990, -2977), heading = 180 },
                showBlip = true,
                blipIcon = 'taxi',
                blipColor = LinearColor(1.0, 0.85, 0.1, 1.0),
            },
        },

        Benches = {
            { coords = Vector(-357440, -132210, -2970), heading = -90, npc = nil },
            { coords = Vector(-357440, -122370, -2970), heading = -90, npc = nil },
            { coords = Vector(-357440, -111940, -2970), heading = -90, npc = nil },
        },
    },
}
