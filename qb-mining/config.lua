Config = {
    NetworkedRocks = true,
    miningTime = 5000,
    miningZones = {
        {
            id = 1,
            name = 'Main Mining Area',
            center = Vector(575778, 620372, 4440),
            radius = 1000,
            maxRocks = 25,
            minDistanceBetweenRocks = 200,
            rockTypes = {
                {
                    mesh = '/Game/Pacifica/Environment/Mesh/Rock/Tropical/SM_Beach_Rock_02A.SM_Beach_Rock_02A',
                    item = 'copper_ore',
                    weight = 40,
                    scale = Vector(2.0, 2.0, 2.0)
                },
                {
                    mesh = '/Game/Pacifica/Environment/Mesh/Rock/Tropical/SM_Beach_Rock_02A.SM_Beach_Rock_02A',
                    item = 'gold_ore',
                    weight = 35,
                    scale = Vector(2.0, 2.0, 2.0)
                },
                {
                    mesh = '/Game/Pacifica/Environment/Mesh/Rock/Tropical/SM_Beach_Rock_02A.SM_Beach_Rock_02A',
                    item = 'diamond',
                    weight = 25,
                    scale = Vector(2.0, 2.0, 2.0)
                },
                {
                    mesh = '/Game/Pacifica/Environment/Mesh/Rock/Tropical/SM_Beach_Rock_02A.SM_Beach_Rock_02A',
                    item = 'iron_ore',
                    weight = 45,
                    scale = Vector(2.0, 2.0, 2.0)
                },
            }
        }
    }
}
