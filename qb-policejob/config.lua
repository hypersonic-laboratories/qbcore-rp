Config = {}
Config.MaxSpikes = 5
Config.HandCuffItem = 'handcuffs'
Config.LicenseRank = 2
Config.ArmoryWhitelist = {}
Config.WhitelistedVehicles = {}

Config.Evidence = {
    ZoneRadius = 35,
    TargetDistance = 300,
    DebugZones = true,
    CasingDropChance = 35,
    CasingDropCooldown = 2,
}

Config.AmmoLabels = {
    pistol_ammo = '9x19mm parabellum bullet',
    smg_ammo = '9x19mm parabellum bullet',
    rifle_ammo = '7.62x39mm bullet',
    mg_ammo = '7.92x57mm mauser bullet',
    shotgun_ammo = '12-gauge bullet',
    snp_ammo = 'Large caliber bullet',
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
        { label = '9five Convenie', coords = Vector(564045, 562060, 4741), rotation = Rotator(-25, -136, 0), canRotate = false, isOnline = true },
        { label = 'Jet Stop', coords = Vector(570907, 459284, 4687), rotation = Rotator(-25, 51, 0), canRotate = false, isOnline = true },
    },
}

Config.EnableRadars = true -- alerts for flagged plates
Config.SpeedCamera = {
    Vector(13438.7, -46440.2, 209.7),
}

Config.CarItems = {
    { name = 'heavyarmor', amount = 2, info = {}, type = 'item', slot = 1 },
    { name = 'empty_evidence_bag', amount = 10, info = {}, type = 'item', slot = 2 },
    { name = 'police_stormram', amount = 1, info = {}, type = 'item', slot = 3 },
}

-- Mugshot stations. Officer targets the tripod (interact) -> live viewfinder
-- from camPos/camRot aimed at the height chart -> E captures -> photo uploads
-- and is stored in police_mugshots (latest per citizen readable by any
-- resource via exports['qb-policejob']:GetMugshot). Subject = ray test along
-- the camera sight line (camPos -> stand): the player CLOSEST to the lens
-- within corridorCm of that line wins, like a raycast's first hit.
-- Calibrate with /mugshotsetup in game: run it once standing AT the tripod
-- facing the chart (gives interact/camPos/camRot) and once standing ON the
-- chart mark (gives stand).
Config.Mugshot = {
    imageApi = {
        url = 'https://api.fivemanage.com/api/v3/file',
        key = 'Py4jfdWgiRLzTTboAofHBC2aoiCSfrar',
    },
    stations = {
        { -- South Beach PD booking room
            interact = Vector(562173, 570672, 4665),
            -- camPos z = subject face height (camera looks level, so aim
            -- height = camera height); fov 24 frames head + shoulders at the
            -- 1.6m tripod-to-chart distance. X nudged 25cm toward the chart
            -- so the lens clears the tripod prop.
            camPos = Vector(562148, 570672, 4725),
            camRot = Rotator(0, -179.5, 0),
            stand = Vector(562013, 570678, 4654),
            corridorCm = 100, -- sight-line half-width for the subject ray test
            fov = 24,
        },
    },
}
