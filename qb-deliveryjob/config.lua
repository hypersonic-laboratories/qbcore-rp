Config = {
    Job = 'delivery',
    TargetDistance = 1500,
    VehicleTargetDistance = 4000,
    VehiclePlatePrefix = 'D-',
    VehicleSpawnZOffset = 20,
    DeliveryMarkerIcon = 'marker',
    DeliveryMarkerColor = LinearColor(0.2, 0.85, 0.35, 1.0),
    Stops = { Minimum = 3, Maximum = 5 },

    Depots = {
        {
            label = 'Delivery Job',
            pedSpawn = Vector(521127, 607939, 4841),
            pedHeading = 13,
            vehicleSpawn = Vector(522224, 608081, 4841),
            vehicleHeading = -81,
            showBlip = true,
            blipIcon = 'boxes-stacked',
            blipColor = LinearColor(0.55, 0.35, 0.95, 1.0),
            description = 'Pick up & return delivery trucks',
        },
    },

    -- Key of vehicle in qb-core/Shared Vehicles table
    Vehicles = {
        'bp_deliverytruck',
    },

    Prop = {
        Mesh = '/Engine/BasicShapes/Cube.Cube',
        HoldingAnimation = '/Game/Characters/Heroes/Unified/Animations/Package_Deliveryman/Carrying/A_Carrying_BothArms_LargeBox_Holding_Idle.A_Carrying_BothArms_LargeBox_Holding_Idle',
    },

    Payout = { Minimum = 500, Maximum = 1000 },

    Locations = {
        Vector(-316430.68, -130243.49, -3391.50),
        Vector(-314462.63, -120730.97, -3358.08),
        Vector(-314610.22, -119405.93, -3356.28),
        Vector(-315755.85, -112270.68, -3346.73),
        Vector(-343143.34, -145299.86, -2882.38),
    },
}
