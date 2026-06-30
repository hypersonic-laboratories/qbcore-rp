Config = Config or {}
Config.Job = 'hotdog'
Config.TargetDistance = 1000
Config.ServerDistance = 700
Config.AdminRemoveDistance = 1200
Config.StandDeposit = 250
Config.MyLevel = 1
Config.MaxReputation = 200

Config.Stand = {
    Mesh = '/QBCoreAssets/Meshes/SM_CraftingBench.SM_CraftingBench',
    Scale = Vector(0.8, 0.8, 0.8),
    InteractionDistance = 450,
    PushOffset = Vector(130, 0, -60),
    PushRotation = Rotator(0, 90, 0),
    CustomerOffset = Vector(180, 0, 0),
}

Config.Customer = {
    Name = 'Hotdog Customer',
    SpawnLocation = Vector(579446, 558671, 4551),
    SpawnHeading = 180,
    SpawnRadius = 500,
    AcceptanceRadius = 150,
    RequestDistance = 900,
    TargetDistance = 500,
    MoveTickMs = 500,
    NextDelayMs = 2500,
    MaxHotdogsPerSale = 3,
}

Config.Locations = {
    take = {
        label = 'Hotdog Stand',
        pedName = 'Hotdog Manager',
        coords = Vector(582143, 562867, 4552),
        heading = 0,
        showBlip = true,
        blipIcon = 'fast-food',
        blipColor = LinearColor(1.0, 0.38, 0.08, 1.0),
        description = 'Pick up and return a hotdog stand',
    },
    spawn = {
        coords = Vector(582143, 562867, 4552),
        heading = 180,
    },
}

Config.Stock = {
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
            [1] = {
                min = 8,
                max = 12,
            },
            [2] = {
                min = 9,
                max = 13,
            },
            [3] = {
                min = 10,
                max = 14,
            },
            [4] = {
                min = 11,
                max = 15,
            },
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
            [1] = {
                min = 6,
                max = 9,
            },
            [2] = {
                min = 7,
                max = 10,
            },
            [3] = {
                min = 8,
                max = 11,
            },
            [4] = {
                min = 9,
                max = 12,
            },
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
            [1] = {
                min = 4,
                max = 6,
            },
            [2] = {
                min = 5,
                max = 7,
            },
            [3] = {
                min = 6,
                max = 9,
            },
            [4] = {
                min = 7,
                max = 9,
            },
        },
    },
}
