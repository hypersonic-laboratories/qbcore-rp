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
            blipIcon = 'post',
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
        Vector(553314, 526791, 4552),
        Vector(553062, 524788, 4566),
        Vector(553202, 521543, 4643),
        Vector(553032, 519548, 4597),
        Vector(549602, 520456, 4592),
        Vector(549095, 522051, 4605),
        Vector(549524, 523766, 4552),
    },
}
