Config = {
    Starting = true,
    InitialOffset = 15000,
    SpawnOffset = 2500,
    DoorMarker = { type = 'cylinder', offset = { z = -100 } },
    Apartments = {
        starter_apt = {
            label = 'Starting Apartment',
            price = 100,
            description = 'A small and cozy apartment, perfect for starting out in the city.',
            garage = 2,
            storage = 50,
            images = {
                'https://r2.fivemanage.com/YtimKhIfkqxWsDgisjdPU/Screenshot2026-02-04151714.png'
            },
            coords = { 567758, 552840, 4561 }, -- Vector(567758, 552840, 4561)
            storeVehicle = { coords = Vector(566642, 553526, 4573), heading = 90.0 },
        },
        level_two = {
            label = 'Marina Apartment',
            price = 200,
            description = 'A stylish apartment with plenty of space for creativity.',
            garage = 2,
            storage = 100,
            images = {
                'https://r2.fivemanage.com/YtimKhIfkqxWsDgisjdPU/Screenshot2026-02-04151746.png'
            },
            coords = { 538057, 518168, 4550 }, -- should be { 538528, 523514, 4627 }
            storeVehicle = { coords = Vector(539308, 513002, 4550), heading = 90.0 },
        },
        level_three = {
            label = 'Mid-Level Residential Apartment',
            price = 300,
            description = 'A luxurious apartment with top-notch amenities and a great view.',
            garage = 5,
            storage = 200,
            images = {
                'https://r2.fivemanage.com/YtimKhIfkqxWsDgisjdPU/Screenshot2026-02-04152019.png'
            },
            coords = { 549909, 527857, 4554 }, -- Vector(549909, 527857, 4554)
            storeVehicle = { coords = Vector(551214, 528127, 4536), heading = 90.0 },
        },
        level_four = {
            label = 'Ocean Drive Penthouse',
            price = 300,
            description = 'A luxurious apartment with top-notch amenities and a great view.',
            garage = 5,
            storage = 200,
            images = {
                'https://r2.fivemanage.com/YtimKhIfkqxWsDgisjdPU/Screenshot2026-02-04152019.png'
            },
            coords = { 581603, 510428, 4598 }, -- Vector(581603, 510428, 4598)
            storeVehicle = { coords = Vector(573828, 508182, 4562), heading = 90.0 },
        },
        level_five = {
            label = 'Villa Apartment',
            price = 300,
            description = 'A luxurious apartment with top-notch amenities and a great view.',
            garage = 5,
            storage = 200,
            images = {
                'https://r2.fivemanage.com/YtimKhIfkqxWsDgisjdPU/Screenshot2026-02-04152019.png'
            },
            coords = { 522322, 564704, 4548 },
            storeVehicle = { coords = Vector(520927, 564553, 4550), heading = 90.0 },
        },
    },
    Shells = {
        starter_apt = {
            label = 'Starting Apartment',
            shell = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_StarterApartment_01_Interior.BPP_Miami_StarterApartment_01_Interior_C',
            light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_ApartmentLevel1_01_Lighting.BP_ApartmentLevel1_01_Lighting_C',
            exitOffset = { x = 0, y = 100, z = 100 },
            garage = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageStarterApartment_01_Interior.BPP_Miami_GarageStarterApartment_01_Interior_C',
            garageLight = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageStarterApartment_01_Lighting.BP_Miami_GarageStarterApartment_01_Lighting_C',
            garageExitOffset = { x = 416, y = -172, z = 107 },
            garageOffset = 1050,
            garageVehicleOffsets = {
                { offset = { x = 158.19, y = -444.19, z = 10.0 },  heading = 90.0 }, -- 567489.812, 553290.188
                { offset = { x = -211.75, y = -434.31, z = 10.0 }, heading = 90.0 }, -- 567859.75, 553280.312
            },
            stashOffset = { x = 239.54, y = 642.01, z = 0 },
            furnitureOffset = { x = 369, y = 475, z = 0 },
            kitchenOffset = { x = 847.63, y = 618.64, z = 0 },
            fridgeOffset = { x = 669.00, y = 470.54, z = 0 },
            --outfitOffset = { x = 0, y = 0, z = 0 },
            --logoutOffset = { x = 0, y = 0, z = 0 },
            --totemOffset = { x = 0, y = 0, z = 0 },
        },
        level_two = {
            label = 'Marina Apartment',
            shell = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_MarinaApartment_01_Interior.BPP_Miami_MarinaApartment_01_Interior_C',
            light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_ApartmentLevel2_Lighting.BP_ApartmentLevel2_Lighting_C',
            exitOffset = { x = 6.58, y = 101.13, z = 108.25 },
            garage = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageMarinaApartment_01_Interior.BPP_Miami_GarageMarinaApartment_01_Interior_C',
            garageLight = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageMarinaApartment_01_Lighting.BP_Miami_GarageMarinaApartment_01_Lighting_C',
            garageExitOffset = { x = 428, y = -153, z = 107 },
            garageOffset = 1050,
            garageVehicleOffsets = {
                { offset = { x = 187.94, y = -444.44, z = 10.0 },  heading = 90.0 }, -- 538340.062, 523958.438
                { offset = { x = -220.38, y = -444.50, z = 10.0 }, heading = 90.0 }, -- 538748.375, 523958.5
            },
            stashOffset = { x = -469.59, y = 421.84, z = 0 },
            furnitureOffset = { x = 454.25, y = -585.00, z = 0 },
            kitchenOffset = { x = 561.38, y = 473.25, z = 0 },
            fridgeOffset = { x = 414, y = 684, z = 0 },
            --outfitOffset = { x = 0, y = 0, z = 0 },
            --logoutOffset = { x = 0, y = 0, z = 0 },
            --totemOffset = { x = 0, y = 0, z = 0 },
        },
        level_three = {
            label = 'Mid-Level Residential Apartment',
            shell = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_ResidentialHouse_Mid_01_Interior.BPP_Miami_ResidentialHouse_Mid_01_Interior_C',
            light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_ResidentialHouse_Mid_01_Lighting.BP_Miami_ResidentialHouse_Mid_01_Lighting_C',
            exitOffset = { x = 276.25, y = -79.29, z = 92.82 },
            garage = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageResidentialHouse_Mid_01_Interior.BPP_Miami_GarageResidentialHouse_Mid_01_Interior_C',
            garageLight = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageResidentialHouse_Mid_01_Lighting.BP_Miami_GarageResidentialHouse_Mid_01_Lighting_C',
            garageExitOffset = { x = -395.46, y = -192.80, z = 93.02 },
            garageOffset = 1050,
            garageVehicleOffsets = {
                { offset = { x = 500.50, y = -1126.06, z = 10.0 },  heading = 45.0 },
                { offset = { x = -467.44, y = -1136.34, z = 10.0 }, heading = 135.0 },
                { offset = { x = 504.44, y = -555.59, z = 10.0 },   heading = 45.0 },
                { offset = { x = -467.94, y = -599.19, z = 10.0 },  heading = 135.0 },
                { offset = { x = 4.19, y = -425.81, z = 10.0 },     heading = 90.0 },
            },
            stashOffset = { x = 1253.03, y = -12.95, z = 0 },
            furnitureOffset = { x = 891.85, y = -467.04, z = 0 },
            kitchenOffset = { x = -794, y = 932, z = 0 },
            fridgeOffset = { x = -473, y = 810, z = 0 },
            --outfitOffset = { x = 0, y = 0, z = 0 },
            --logoutOffset = { x = 0, y = 0, z = 0 },
            --totemOffset = { x = 0, y = 0, z = 0 },
        },
        level_four = {
            label = 'Ocean Drive Penthouse',
            shell = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_OceanDrivePenthouse_01_Interior.BPP_Miami_OceanDrivePenthouse_01_Interior_C',
            light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_OceanDrivePenthouse_01_Lighting.BP_Miami_OceanDrivePenthouse_01_Lighting_C',
            exitOffset = { x = -5.28, y = 60.54, z = 93.65 },
            garage = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageOceanDrivePenthouse_01_Interior.BPP_Miami_GarageOceanDrivePenthouse_01_Interior_C',
            garageLight = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageOceanDrivePenthouse_01_Lighting_Final.BP_Miami_GarageOceanDrivePenthouse_01_Lighting_Final_C',
            garageExitOffset = { x = -736, y = -323, z = 97 },
            garageOffset = 1050,
            garageVehicleOffsets = {
                { offset = { x = 500.50, y = -1126.06, z = 10.0 },  heading = 45.0 },  -- 581102.5, 511554.062
                { offset = { x = -467.44, y = -1136.34, z = 10.0 }, heading = 135.0 }, -- 582070.438, 511564.344
                { offset = { x = 504.44, y = -555.59, z = 10.0 },   heading = 45.0 },  -- 581098.562, 510983.594
                { offset = { x = -467.94, y = -599.19, z = 10.0 },  heading = 135.0 }, -- 582070.938, 511027.188
                { offset = { x = 4.19, y = -425.81, z = 10.0 },     heading = 90.0 },  -- 581598.812, 510853.812
            },
            stashOffset = { x = -180.52, y = -309.90, z = 28.53 },
            furnitureOffset = { x = -417.31, y = -664.79, z = 0.00 },
            kitchenOffset = { x = -396.38, y = -364.52, z = 28.53 },
            fridgeOffset = { x = -285.66, y = -106.80, z = 28.53 },
            --outfitOffset = { x = 0, y = 0, z = 0 },
            --logoutOffset = { x = 0, y = 0, z = 0 },
            --totemOffset = { x = 0, y = 0, z = 0 },
        },
        level_five = {
            label = 'Villa Apartment',
            shell = '/Game/Pacifica/Environment/PLA/City/Villa/BPP_Villa_06_Interior_B.BPP_Villa_06_Interior_B_C',
            exterior = {
                '/Game/Pacifica/Environment/PLA/City/Villa/BPP_Villa_06.BPP_Villa_06_C',
                '/Game/Pacifica/PropertyCubemaps/Properties/Property05_StarIslandMansion/BP_Villa_06_Exterior_PropertyDressing.BP_Villa_06_Exterior_PropertyDressing_C'
            },
            light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Villa_06_Lighting.BP_Villa_06_Lighting_C',
            exitOffset = { x = -5, y = 2020, z = 92 },
            garage = '/Game/Pacifica/Environment/PLA/City/Villa/BPP_GarageVilla_06_Interior.BPP_GarageVilla_06_Interior_C',
            garageLight = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_GarageVilla_06_Lighting.BP_GarageVilla_06_Lighting_C',
            garageExitOffset = { x = -15, y = -101, z = 92 },
            garageOffset = 1300,
            garageVehicleOffsets = {
                { offset = { x = 474.66, y = -450.0, z = 10.0 },   heading = 60.0 },
                { offset = { x = -469.94, y = -450.0, z = 10.0 },  heading = 120.0 },
                { offset = { x = 492.03, y = -1035.0, z = 10.0 },  heading = 60.0 },
                { offset = { x = -502.59, y = -1035.0, z = 10.0 }, heading = 120.0 },
                { offset = { x = 474.66, y = -1620.0, z = 10.0 },  heading = 60.0 },
                { offset = { x = -469.94, y = -1620.0, z = 10.0 }, heading = 120.0 },
                { offset = { x = 492.03, y = -2205.0, z = 10.0 },  heading = 60.0 },
                { offset = { x = -502.59, y = -2205.0, z = 10.0 }, heading = 120.0 },
            },
            stashOffset = { x = 1049.18, y = 645.25, z = 0.15 },
            furnitureOffset = { x = 821.91, y = 843.50, z = 0.15 },
            kitchenOffset = { x = -1452, y = -1600, z = 0 },
            fridgeOffset = { x = -1061, y = -1748, z = 0 },
            --outfitOffset = { x = 0, y = 0, z = 0 },
            --logoutOffset = { x = 0, y = 0, z = 0 },
            --totemOffset = { x = 0, y = 0, z = 0 },
        },
    }
}

exports('qb-houses', 'GetPurchaseProperties', function()
    return Config.Apartments
end)

exports('qb-houses', 'GetGarageCapacity', function(entranceId)
    local shell = Config.Shells[entranceId]
    if not shell or not shell.garageVehicleOffsets then return 0 end
    return #shell.garageVehicleOffsets
end)
