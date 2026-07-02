Config = Config or {}

Config.DefaultZone = 'SandyOccasions'

Config.Zones = {
    SandyOccasions = {
        BusinessName = 'Used Car Lot',
        SellVehicle = {
            coords = Vector(560837, 552796, 4559),
            heading = 0.42,
        },
        BuyVehicle = {
            coords = Vector(561863, 552712, 4559),
            heading = 182.5,
        },
        ShowBlip = true,
        BlipIcon = 'car',
        BlipColor = LinearColor(0.1, 0.75, 0.45, 1.0),
        Description = 'Player vehicle sales lot',

        VehicleSpots = {
            { coords = Vector(561850, 552059, 4465), heading = 180 },
            { coords = Vector(561850, 551699, 4465), heading = 180 },
            { coords = Vector(561850, 551339, 4465), heading = 180 },
            { coords = Vector(561850, 550979, 4465), heading = 180 },
            { coords = Vector(561850, 550619, 4465), heading = 180 },
            { coords = Vector(561850, 550259, 4465), heading = 180 },
            { coords = Vector(561850, 549899, 4465), heading = 180 },
            { coords = Vector(561850, 549539, 4465), heading = 180 },
            { coords = Vector(560730, 552480, 4465), heading = 0 },
            { coords = Vector(560730, 552110, 4465), heading = 0 },
            { coords = Vector(560730, 551780, 4465), heading = 0 },
            { coords = Vector(560730, 551450, 4465), heading = 0 },
            { coords = Vector(560730, 551120, 4465), heading = 0 },
            { coords = Vector(560730, 550790, 4465), heading = 0 },
            { coords = Vector(560730, 550460, 4465), heading = 0 },
            { coords = Vector(560730, 550130, 4465), heading = 0 },
        },
    },
}
