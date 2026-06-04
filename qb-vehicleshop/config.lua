Config = {}
Config.Commission = 0.10               -- Percent that goes to sales person from a full car sale 10%
Config.FinanceCommission = 0.05        -- Percent that goes to sales person from a finance sale 5%
Config.PaymentWarning = 10             -- time in minutes that player has to make payment before repo
Config.PaymentInterval = 24            -- time in hours between payment being due
Config.MinimumDown = 10                -- minimum percentage allowed down
Config.MaximumPayments = 24            -- maximum payments allowed
Config.PreventFinanceSelling = false   -- allow/prevent players from using /transfervehicle if financed
Config.FilterByMake = false            -- adds a make list before selecting category in shops
Config.SortAlphabetically = true       -- will sort make, category, and vehicle selection menus alphabetically
Config.HideCategorySelectForOne = true -- will hide the category selection menu if a shop only sells one category of vehicle or a make has only one category
Config.Shops = {
    ['pdm'] = {
        ['Label'] = 'Premium Deluxe Motorsport',
        ['Type'] = 'free-use',
        ['Job'] = 'none',
        ['ShowBlip'] = true,
        ['BlipCoords'] = Vector(566599, 543296, 4564),
        ['BlipIcon'] = 'car-rental',
        ['BlipColor'] = LinearColor(0.2, 0.6, 1.0, 1.0),
        ['TestDriveTimeLimit'] = 0.5,
        ['ReturnLocation'] = Vector(566599, 543296, 4564),
        ['VehicleSpawn'] = {
            location = Vector(566528, 542426, 4467),
            rotation = Rotator(0, -90, 0)
        },
        ['TestDriveSpawn'] = {
            location = Vector(566528, 542426, 4467),
            rotation = Rotator(0, -90, 0)
        },
        ['FinanceZone'] = Vector(567958, 543877, 4564),
        ['ShowroomVehicles'] = {
            {
                coords = {
                    location = Vector(567561, 545062, 4470),
                    rotation = Rotator(0, 0, 0)
                },
                defaultVehicle = 'bp_merc',
                chosenVehicle = 'bp_merc',
            },
            -- {
            --     coords = {
            --         location = Vector(-3590, 13306, -400),
            --         rotation = Rotator(0, 1, 0)
            --     },
            --     defaultVehicle = 'bp_police',
            --     chosenVehicle = 'bp_police',
            -- },
        },
    },
}
