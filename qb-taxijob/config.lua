Config = {
    Job = 'taxi',
    Vehicle = '/abcca-qbcore-veh/QBCoreVehicles/BP_Taxi.BP_Taxi_C',
    TargetDistance = 1000,
    PickupMarkerColor = LinearColor(0.15, 0.6, 1.0, 1.0),
    DropoffMarkerColor = LinearColor(0.2, 0.85, 0.35, 1.0),
    Rate = 125.0, -- price per mile
    MaxFarePadding = 2, -- adjust this as needed to account for turns, etc.
    Locations = {
        Depots = {
            {
                label = 'Taxi Depot',
                pedSpawn = Vector(521031, 608426, 4841),
                pedHeading = 9,
                vehicleSpawn = Vector(522224, 608081, 4841),
                vehicleHeading = -81,
                showBlip = true,
                blipIcon = 'taxi',
                blipColor = LinearColor(1.0, 0.85, 0.1, 1.0),
                description = 'Pick up & return taxi vehicles',
            },
        },

        Benches = {
            { coords = Vector(-357440, -132210, -2970), heading = -90, npc = nil },
            { coords = Vector(-357440, -122370, -2970), heading = -90, npc = nil },
            { coords = Vector(-357440, -111940, -2970), heading = -90, npc = nil },
        },
    },
}
