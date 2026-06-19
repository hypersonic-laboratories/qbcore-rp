Config = {
    Job = 'bus',
    Vehicle = '/abcca-qbcore-veh/QBCoreVehicles/BP_Bus.BP_Bus_C',
    StopRadius = 450,
    StopInteractionDistance = 1500,
    PassengerOffset = Vector(150, 0, 0),

    Payment = {
        Min = 15,
        Max = 25,
        TipChance = 40,
        TipMin = 10,
        TipMax = 20,
    },

    Locations = {
        Depots = {
            {
                label = 'Bus Depot',
                pedSpawn = { coords = Vector(-355210, -132250, -2882), heading = 176 },
                vehicleSpawn = { coords = Vector(-356060, -132480, -2980), heading = 180 },
                showBlip = true,
                blipIcon = 'bus',
                blipColor = LinearColor(0.1, 0.45, 1.0, 1.0),
                description = 'Pick up & return bus vehicles',
            },
        },

        Stops = {
            { coords = Vector(-357440, -132210, -2970), heading = -90 },
            { coords = Vector(-357440, -122370, -2970), heading = -90 },
            { coords = Vector(-357440, -111940, -2970), heading = -90 },
            { coords = Vector(-360520, -119000, -2980), heading = 180 },
            { coords = Vector(-365830, -123200, -2980), heading = 0 },
        },
    },
}
