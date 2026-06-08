Config = {

    AvailableJobs = {
        'trucker',
        'taxi',
        'tow',
        'reporter',
        'garbage',
        'bus',
        'hotdog',
        'police',
        'ambulance',
        'realestate',
        'cardealer',
        'mechanic',
        'delivery'
    },

    Cityhalls = {
        {
            marker = {
                coords = Vector(567287, 572779, 4672),
                blipData = {
                    title = 'City Hall',
                    description = 'City services, licenses & jobs',
                    markerType = 'Objective',
                    icon = 'city',
                    color = LinearColor(0.2, 0.5, 1.0, 1.0),
                },
            },
            spots = {
                { coords = Vector(567321, 573059, 4672), heading = 90 },
                { coords = Vector(567287, 572779, 4672), heading = 90 },
                { coords = Vector(567290, 572465, 4672), heading = 90 },
            },
            licenses = {
                id_card = {
                    label = 'ID Card',
                    cost = 50,
                },
                driver_license = {
                    label = 'Driver License',
                    cost = 50,
                    metadata = 'driver'
                },
                weaponlicense = {
                    label = 'Weapon License',
                    cost = 50,
                    metadata = 'weapon'
                },
            }
        },
        -- {
        --     marker = {
        --         coords = Vector(0, 0, 0),
        --         blipData = {
        --             title = 'City Hall',
        --             description = 'City services, licenses & jobs',
        --             markerType = 'Objective',
        --             icon = 'city',
        --         },
        --     },
        --     spots = {
        --         { coords = Vector(0, 0, 0), heading = 90 },
        --     },
        --     licenses = {
        --         id_card = {
        --             label = 'ID Card',
        --             cost = 50,
        --         },
        --         driver_license = {
        --             label = 'Driver License',
        --             cost = 50,
        --             metadata = 'driver'
        --         },
        --         weaponlicense = {
        --             label = 'Weapon License',
        --             cost = 50,
        --             metadata = 'weapon'
        --         },
        --     }
        -- },
    }
}
