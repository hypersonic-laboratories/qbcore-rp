Config = {}

Config.PawnLocation = {
    {
        coords = Vector(574131, 525296, 4551),
        heading = 176,
        label = 'Pawnshop Dealer',
        distance = 500,
        serverDistance = 750,
        showBlip = true,
        blipIcon = 'jewelry-store',
        blipColor = LinearColor(0.95, 0.76, 0.28, 1.0),
        description = 'Sell valuables and melt jewelry',
    },
}

Config.BankMoney = false -- Set to true if you want the money to go into the players bank
Config.UseTimes = false -- Set to false if you want the pawnshop open 24/7
Config.TimeOpen = 7 -- Opening Time
Config.TimeClosed = 17 -- Closing Time
Config.SendMeltingEmail = true

Config.PawnItems = {
    {
        item = 'goldchain',
        price = math.random(50, 100),
    },
    {
        item = 'diamond_ring',
        price = math.random(50, 100),
    },
    {
        item = 'rolex',
        price = math.random(50, 100),
    },
    {
        item = 'tenkgoldchain',
        price = math.random(50, 100),
    },
    {
        item = 'tablet',
        price = math.random(50, 100),
    },
    {
        item = 'iphone',
        price = math.random(50, 100),
    },
    {
        item = 'samsungphone',
        price = math.random(50, 100),
    },
    {
        item = 'laptop',
        price = math.random(50, 100),
    },
}

Config.MeltingItems = { -- meltTime is amount of time in minutes per item
    {
        item = 'goldchain',
        rewards = {
            {
                item = 'goldbar',
                amount = 2,
            },
        },
        meltTime = 0.15,
    },
    {
        item = 'diamond_ring',
        rewards = {
            {
                item = 'diamond',
                amount = 1,
            },
            {
                item = 'goldbar',
                amount = 1,
            },
        },
        meltTime = 0.15,
    },
    {
        item = 'rolex',
        rewards = {
            {
                item = 'diamond',
                amount = 1,
            },
            {
                item = 'goldbar',
                amount = 1,
            },
            {
                item = 'electronickit',
                amount = 1,
            },
        },
        meltTime = 0.15,
    },
    {
        item = 'tenkgoldchain',
        rewards = {
            {
                item = 'diamond',
                amount = 5,
            },
            {
                item = 'goldbar',
                amount = 1,
            },
        },
        meltTime = 0.15,
    },
}
