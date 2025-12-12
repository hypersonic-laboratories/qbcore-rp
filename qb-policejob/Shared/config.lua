Config = {
    HandCuffItem = 'handcuffs',
    LicenseRank = 2,

    AmmoLabels = {
        AMMO_PISTOL = '9x19mm parabellum bullet',
        AMMO_SMG = '9x19mm parabellum bullet',
        AMMO_RIFLE = '7.62x39mm bullet',
        AMMO_MG = '7.92x57mm mauser bullet',
        AMMO_SHOTGUN = '12-gauge bullet',
        AMMO_SNIPER = 'Large caliber bullet',
    },

    Objects = {
        cone = { model = '', freeze = true },
        barrier = { model = '', freeze = true },
        roadsign = { model = '', freeze = true },
        tent = { model = '', freeze = true },
        light = { model = '', freeze = true },
    },

    Locations = {
        duty = {
            { coords = Vector(-340320.0, -147790.0, -2840.0), rotation = Rotator(0, 90, 90) },
        },
        vehicle = {
            {
                coords = Vector(-339350.0, -145760.0, -2970.0),
                rotation = Rotator(0, 0, 0),
                spawn = { coords = Vector(-339358.10, -144656.62, -2980.06), rotation = Rotator(0, 90, 0) },
            },
        },
        stash = {
            { coords = Vector(-339520.0, -148650.0, -2930.0),  rotation = Rotator(0, 90, 0) },
        },
        impound = {
            Vector(0, 0, 0)
        },
        helicopter = {
            Vector(0, 0, 0)
        },
        trash = {
            Vector(0, 0, 0)
        },
        fingerprint = {
            { coords = Vector(-339884.98, -148380.16, -2889.0),  rotation = Rotator(0, 90, 0) },
        },
        evidence = {
            { coords = Vector(-339641.0, -149006.58, -2912.50),  heading = 0 },
        },
        stations = {
            { label = 'Police Station', coords = Vector(-340540.36, -147839.66, -2884.60) },
        },
        
    },

    AuthorizedVehicles = { -- Grade is key, don't add same vehicle in multiple grades. Higher rank can see lower
        [0] = {
            ['bp_police'] = 'Police Car'
        },
    },

    AuthorizedHelicopters = { -- Grade is key, don't add same vehicle in multiple grades. Higher rank can see lower
        [0] = {
            ['bp_pheli'] = 'Police Heli'
        }
    },

    SpeedCamera = {
        Vector(13438.7, -46440.2, 209.7)
    },

    SecurityCameras = {
        cameras = {
            { label = 'Hansons',         coords = Vector(16386.9, -46857.0, 400),  rotation = Rotator(0.0, 48.991352081299, 0.0),  canRotate = false, isOnline = true },
            { label = 'Eastside Market', coords = Vector(-54437.3, -41350.1, 400), rotation = Rotator(0.0, -139.79696655273, 0.0), canRotate = false, isOnline = true },
        },
    }
}