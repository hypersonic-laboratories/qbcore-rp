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
        cone     = { model = '', freeze = true },
        barrier  = { model = '', freeze = true },
        roadsign = { model = '', freeze = true },
        tent     = { model = '', freeze = true },
        light    = { model = '', freeze = true },
    },

    Locations = {
        ['south_beach_pd'] = {
            label                 = 'South Beach Police Department',
            duty                  = { Vector(562851, 571954, 4653) },
            stash                 = { Vector(563241, 572137, 4656) },
            fingerprint           = { Vector(562118, 571225, 4700) },
            evidence              = { Vector(561937, 571572, 4653) },
            trash                 = { Vector(0, 0, 0) },
            vehicle               = { Vector(0, 0, 0) },
            vehicleSpawn          = { coords = Vector(0, 0, 0), rotation = Rotator(0, 90, 0) },
            impound               = { Vector(0, 0, 0) },
            helicopter            = { Vector(0, 0, 0) },
            helicopterSpawn       = { coords = Vector(0, 0, 0), rotation = Rotator(0, 0, 0) },
            authorizedVehicles    = {
                [0] = { ['bp_police'] = 'Police Car' }
            },
            authorizedHelicopters = {
                [0] = { ['bp_pheli'] = 'Police Heli' }
            },
        },
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
