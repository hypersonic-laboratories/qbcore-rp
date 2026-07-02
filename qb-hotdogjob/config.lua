Config = {
    Job = 'hotdog',
    TargetDistance = 1000,
    ServerDistance = 700,
    AdminRemoveDistance = 1200,
    StandDeposit = 250,
    MyLevel = 1,
    MaxReputation = 200,

    Stand = {
        Mesh = '/QBCoreAssets/Meshes/SM_CraftingBench.SM_CraftingBench',
        Scale = Vector(0.8, 0.8, 0.8),
        InteractionDistance = 450,
        PushOffset = Vector(130, 0, -60),
        PushRotation = Rotator(0, 90, 0),
        CustomerOffset = Vector(180, 0, 0),
    },

    Customer = {
        Name = 'Hotdog Customer',
        SpawnDistanceMin = 1500,
        SpawnDistanceMax = 3000,
        AcceptanceRadius = 150,
        RequestDistance = 900,
        TargetDistance = 1000,
        MoveTickMs = 500,
        NextDelayMs = 2500,
        MaxHotdogsPerSale = 3,
    },

    Locations = {
        take = {
            label = 'Hotdog Stand',
            pedName = 'Hotdog Manager',
            coords = Vector(520986, 608711, 4841),
            heading = 10,
            showBlip = true,
            blipIcon = 'fast-food',
            blipColor = LinearColor(1.0, 0.38, 0.08, 1.0),
            description = 'Pick up and return a hotdog stand',
        },
        spawn = {
            coords = Vector(521276, 608815, 4750),
            heading = 0,
        },
    },

    Stock = {
        exotic = {
            Current = 0,
            Max = {
                [1] = 15,
                [2] = 30,
                [3] = 45,
                [4] = 60,
            },
            Label = 'Perfect (A)',
            Price = {
                { min = 8, max = 12 },
                { min = 9, max = 13 },
                { min = 10, max = 14 },
                { min = 11, max = 15 },
            },
        },
        rare = {
            Current = 0,
            Max = {
                [1] = 15,
                [2] = 30,
                [3] = 45,
                [4] = 60,
            },
            Label = 'Rare (B)',
            Price = {
                { min = 6, max = 9 },
                { min = 7, max = 10 },
                { min = 8, max = 11 },
                { min = 9, max = 12 },
            },
        },
        common = {
            Current = 0,
            Max = {
                [1] = 15,
                [2] = 30,
                [3] = 45,
                [4] = 60,
            },
            Label = 'Common (C)',
            Price = {
                { min = 4, max = 6 },
                { min = 5, max = 7 },
                { min = 6, max = 9 },
                { min = 7, max = 9 },
            },
        },
    },
}
