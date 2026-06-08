Config = {}
Config.AutoRespawn = true        -- true == stores cars in garage on restart | false == doesnt modify car states
Config.VisuallyDamageCars = true -- true == damage car on spawn | false == no damage on spawn
Config.SharedGarages = false     -- true == take any car from any garage | false == only take car from garage stored in
Config.ClassSystem = false       -- true == restrict vehicles by class | false == any vehicle class in any garage
Config.Warp = true               -- true == warp player into vehicle | false == vehicle spawns without warping

Config.VehicleClass = UE.EHelixVehicleType

Config.Garages = {
    apartment1 = {
        label = 'Brightside Motel',
        takeVehicle = Vector(576131, 597559, 4553),
        spawnPoint = {
            {
                coords = Vector(576031, 596919, 4553),
                heading = 177,
            }
        },
        showBlip = true,
        blipName = 'Brightside Motel Parking',
        blipIcon = 'parking',
        blipColor = LinearColor(0.2, 0.6, 1.0, 1.0),
        description = 'Park & retrieve your vehicle',
        type = 'public', -- public, gang, job, depot
        category = Config.VehicleClass.Car
    },
    apartment2 = {
        label = 'Marlin Hotel',
        takeVehicle = Vector(580545, 551062, 4536),
        spawnPoint = {
            {
                coords = Vector(580550, 550006, 4536),
                heading = 88,
            }
        },
        showBlip = true,
        blipName = 'Marlin Hotel Parking',
        blipIcon = 'parking',
        blipColor = LinearColor(0.2, 0.6, 1.0, 1.0),
        description = 'Park & retrieve your vehicle',
        type = 'public', -- public, gang, job, depot
        category = Config.VehicleClass.Car
    },
    apartment3 = {
        label = 'Docks Condo',
        takeVehicle = Vector(545400, 504731, 4552),
        spawnPoint = {
            {
                coords = Vector(544788, 504793, 4552),
                heading = 87,
            }
        },
        showBlip = true,
        blipName = 'Docks Condo Parking',
        blipIcon = 'parking',
        blipColor = LinearColor(0.2, 0.6, 1.0, 1.0),
        description = 'Park & retrieve your vehicle',
        type = 'public', -- public, gang, job, depot
        category = Config.VehicleClass.Car
    },

    -- Middle Machines
    parkinggarageA = {
        label = 'Parking Garage',
        takeVehicle = Vector(566196, 527552, 4573),
        spawnPoint = { { coords = Vector(566567, 527181, 4553), heading = 357, } },
        showBlip = true,
        blipName = 'Parking Garage',
        blipIcon = 'parking-garage',
        blipColor = LinearColor(0.2, 0.6, 1.0, 1.0),
        description = 'Public parking garage',
        type = 'public',
        category = Config.VehicleClass.Car
    },

    cardealer = {
        label = 'Car Dealer',
        takeVehicle = Vector(-301186, -213380, -2882),
        spawnPoint = {
            {
                coords = Vector(-301169, -213000, -2989),
                heading = 180,
            }
        },
        showBlip = true,
        blipName = 'Car Dealer Parking',
        blipIcon = 'parking',
        blipColor = LinearColor(0.2, 0.6, 1.0, 1.0),
        description = 'Dealership parking',
        type = 'public', -- public, gang, job, depot
        category = Config.VehicleClass.Car
    },
    hospital = {
        label = 'Hospital',
        takeVehicle = Vector(-345356, -139671, -2883),
        spawnPoint = {
            coords = Vector(-345374, -139326, -2883),
            heading = 358,
        },
        showBlip = false,
        blipName = 'Hospital Garage',
        blipIcon = 'hospital',
        blipColor = LinearColor(1.0, 0.2, 0.2, 1.0),
        type = 'job',
        category = Config.VehicleClass['car'], --car, air, sea, rig
        job = 'ambulance',
        jobType = 'ems'
    },
    police = {
        label = 'Police',
        takeVehicle = Vector(-340755, -145572, -2885),
        spawnPoint = {
            coords = Vector(-340842, -145021, -2885),
            heading = 180,
        },
        showBlip = false,
        blipName = 'Police Garage',
        blipIcon = 'police',
        blipColor = LinearColor(0.2, 0.4, 1.0, 1.0),
        type = 'job',
        category = Config.VehicleClass['car'], --car, air, sea, rig
        job = 'police',
        jobType = 'leo'
    },
}
