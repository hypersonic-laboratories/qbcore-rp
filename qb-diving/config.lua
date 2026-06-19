Config = Config or {}
Config.CopsChance = 0.5
Config.OxygenLevel = 200
Config.RemoveDivingGear = false

Config.CoralLocations = {
    {
        label = 'This is Location 1',
        coords = {
            Area = Vector(-2838.8, -376.1, 3.55),
            Coral = {
                { coords = Vector(-2849.25, -377.58, -40.23), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-2838.43, -363.63, -39.45), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-2887.04, -394.87, -40.91), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-2808.99, -385.56, -39.32), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 4,
        TotalCoral = 4,
    },
    {
        label = 'Location 2',
        coords = {
            Area = Vector(-3288.2, -67.58, 2.79),
            Coral = {
                { coords = Vector(-3275.03, -38.58, -19.21), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-3273.73, -76.0, -26.81), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-3346.53, -50.4, -35.84), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 3,
        TotalCoral = 3,
    },
    {
        label = 'Location 3',
        coords = {
            Area = Vector(-3367.24, 1617.89, 1.39),
            Coral = {
                { coords = Vector(-3388.01, 1635.88, -39.41), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-3354.19, 1549.3, -38.21), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(-3326.04, 1636.43, -40.98), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 3,
        TotalCoral = 3,
    },
    {
        label = 'Location 4',
        coords = {
            Area = Vector(3002.5, -1538.28, -27.36),
            Coral = {
                { coords = Vector(2978.05, -1509.07, -24.96), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(3004.42, -1576.95, -29.36), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(2951.65, -1560.69, -28.36), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 3,
        TotalCoral = 3,
    },
    {
        label = 'Location 5',
        coords = {
            Area = Vector(3421.58, 1975.68, 0.86),
            Coral = {
                { coords = Vector(3421.69, 1976.54, -50.64), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(3424.07, 1957.46, -53.04), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(3434.65, 1993.73, -49.84), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(3415.42, 1965.25, -52.04), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 4,
        TotalCoral = 4,
    },
    {
        label = 'Location 6',
        coords = {
            Area = Vector(2720.14, -2136.28, 0.74),
            Coral = {
                { coords = Vector(2724.0, -2134.95, -19.33), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(2710.68, -2156.06, -18.63), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(2702.84, -2139.29, -18.51), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(2736.27, -2153.91, -20.88), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 4,
        TotalCoral = 4,
    },
    {
        label = 'Location 7',
        coords = {
            Area = Vector(536.69, 7253.75, 1.69),
            Coral = {
                { coords = Vector(542.31, 7245.37, -30.01), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(528.21, 7223.26, -29.51), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(510.36, 7254.97, -32.11), length = 3, width = 3, heading = 100.0, PickedUp = false },
                { coords = Vector(525.37, 7259.12, -30.51), length = 3, width = 3, heading = 100.0, PickedUp = false },
            },
        },
        DefaultCoral = 4,
        TotalCoral = 4,
    },
}

Config.CoralTypes = {
    {
        item = 'dendrogyra_coral',
        maxAmount = math.random(1, 5),
        price = math.random(70, 100),
    },
    {
        item = 'antipatharia_coral',
        maxAmount = math.random(2, 7),
        price = math.random(50, 70),
    },
}

Config.BonusTiers = {
    { minAmount = 5, maxAmount = 10, minBonus = 5, maxBonus = 10 },
    { minAmount = 11, maxAmount = 15, minBonus = 10, maxBonus = 15 },
    { minAmount = 16, minBonus = 15, maxBonus = 20 },
}

Config.SellLocations = {
    {
        coords = Vector(-1684.13, -1068.91, 13.15),
        heading = 100.0,
        zoneOptions = { length = 3, width = 3 },
    },
}
