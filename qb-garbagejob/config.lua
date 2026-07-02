Config = {
    Job = 'garbage',
    Vehicle = '/abcca-qbcore-veh/QBCoreVehicles/BP_Garbage_Truck.BP_Garbage_Truck_C',
    TargetDistance = 1000,
    MinStops = 3,
    MaxStops = 10,
    BagLowerWorth = 300,
    BagUpperWorth = 1000,

    Locations = {
        Depots = {
            {
                label = 'West Garbage Depot',
                pedSpawn = Vector(521249, 607129, 4841),
                pedHeading = 9,
                vehicleSpawn = Vector(522224, 608081, 4841),
                vehicleHeading = -81,
                showBlip = true,
                blipIcon = 'waste-basket',
                blipColor = LinearColor(0.2, 0.55, 0.15, 1.0),
                description = 'Pick up & return garbage trucks',
            },
        },

        Dumpsters = {
            { coords = Vector(577000, 549370, 4470), heading = 90 },
            { coords = Vector(575890, 540010, 4460), heading = 90 },
            { coords = Vector(572580, 535920, 4470), heading = 90 },
            { coords = Vector(575150, 528240, 4460), heading = 0 },
            { coords = Vector(576350, 522310, 4470), heading = 180 },
            { coords = Vector(568490, 511690, 4470), heading = 0 },
            { coords = Vector(566680, 500300, 4620), heading = -90 },
            { coords = Vector(569280, 485420, 4470), heading = -173.5 },
            { coords = Vector(567440, 476240, 4460), heading = 95.6 },
            { coords = Vector(566860, 471900, 4470), heading = 96 },
            { coords = Vector(546280, 469790, 4450), heading = 8.5 },
            { coords = Vector(545980, 504510, 4470), heading = 84.4 },
        },
    },
}
