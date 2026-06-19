Config = {
    fishingTime = 10000,
    mapMarker = {
        description = 'Fishing spot',
        icon = 'beach',
        color = LinearColor(0.15, 0.55, 0.95, 1.0),
        markerType = 'Store',
    },
    waterTypes = {
        ocean = {
            id = 'ocean',
            label = 'Ocean',
            reward = 'fish',
            zones = {
                Vector(605737, 628637, 4600),
                Vector(605452, 628637, 4600),
                Vector(605176, 628637, 4600),
                Vector(604880, 628637, 4600),
                Vector(604619, 628637, 4600),
                Vector(604332, 628637, 4600),
                Vector(604055, 628637, 4600),
                Vector(603765, 628637, 4600),
            },
        },
        lake = {
            id = 'lake',
            label = 'Lake',
            reward = 'fish',
            zones = {
                Vector(526826, 513713, 4570),
                Vector(526984, 516069, 4570),
                Vector(527165, 518553, 4570),
                Vector(527263, 519796, 4570),
            },
        },
        river = {
            id = 'river',
            label = 'River',
            reward = 'fish',
            zones = {
                Vector(526857, 502417, 4594),
                Vector(527152, 502330, 4594),
                Vector(527161, 502457, 4594),
                Vector(527655, 502283, 4594),
                Vector(527662, 502412, 4594),
            },
        },
        swamp = {
            id = 'swamp',
            label = 'Swamp',
            reward = 'fish',
            zones = {
                Vector(526212, 505121, 4570),
                Vector(526211, 505321, 4570),
                Vector(526378, 506387, 4570),
                Vector(526503, 508843, 4570),
                Vector(526661, 511149, 4570),
            },
        },
        deep_sea = {
            id = 'deep_sea',
            label = 'Deep Sea',
            reward = 'fish',
            zones = {
                Vector(624520, 627591, 4394),
                Vector(625256, 627634, 4392),
                Vector(625961, 627677, 4391),
            },
        },
    },
}
