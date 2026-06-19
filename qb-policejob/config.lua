Config = {}
Config.MaxSpikes = 5
Config.HandCuffItem = 'handcuffs'
Config.LicenseRank = 2
Config.ArmoryWhitelist = {}
Config.WhitelistedVehicles = {}

Config.AmmoLabels = {
    AMMO_PISTOL = '9x19mm parabellum bullet',
    AMMO_SMG = '9x19mm parabellum bullet',
    AMMO_RIFLE = '7.62x39mm bullet',
    AMMO_MG = '7.92x57mm mauser bullet',
    AMMO_SHOTGUN = '12-gauge bullet',
    AMMO_SNIPER = 'Large caliber bullet',
}

Config.Objects = {
    cone = { model = '', freeze = true },
    barrier = { model = '', freeze = true },
    roadsign = { model = '', freeze = true },
    tent = { model = '', freeze = true },
    light = { model = '', freeze = true },
}

Config.Locations = {
    south_beach_pd = {
        label = 'South Beach Police Department',
        duty = { Vector(562851, 571954, 4653) },
        stash = { Vector(563241, 572137, 4656) },
        clothing = { Vector(562797, 572536, 4654) },
        fingerprint = { Vector(562118, 571225, 4700) },
        camera = { Vector(562164, 571455, 4653) },
        evidence = { Vector(561937, 571572, 4653) },
        trash = { Vector(0, 0, 0) },
        vehicle = { Vector(0, 0, 0) },
        vehicleSpawn = { coords = Vector(0, 0, 0), rotation = Rotator(0, 90, 0) },
        impound = { Vector(0, 0, 0) },
        helicopter = { Vector(0, 0, 0) },
        helicopterSpawn = { coords = Vector(0, 0, 0), rotation = Rotator(0, 0, 0) },
        authorizedVehicles = {
            [0] = { bp_police = 'Police Car' },
        },
        authorizedHelicopters = {
            [0] = { bp_pheli = 'Police Heli' },
        },
    },
}

Config.SecurityCameras = {
    hideradar = false,
    cameras = {
        { label = 'Jet Stop East', coords = Vector(564045, 562060, 4741), rotation = Rotator(-25, -136, 0), canRotate = false, isOnline = true },
        { label = 'Jet Stop West', coords = Vector(570907, 459284, 4687), rotation = Rotator(-25, 51, 0), canRotate = false, isOnline = true },
    },
}

Config.EnableRadars = true -- alerts for flagged plates
Config.SpeedCamera = {
    Vector(13438.7, -46440.2, 209.7),
}

Config.CarItems = {
    [1] = { name = 'heavyarmor', amount = 2, info = {}, type = 'item', slot = 1 },
    [2] = { name = 'empty_evidence_bag', amount = 10, info = {}, type = 'item', slot = 2 },
    [3] = { name = 'police_stormram', amount = 1, info = {}, type = 'item', slot = 3 },
}
