Config = {
    MaxWeight = 120000,
    MaxSlots = 40,

    StashSize = {
        maxweight = 1000000,
        slots = 50
    },

    DropSize = {
        maxweight = 1000000,
        slots = 50
    },

    Keybinds = {
        Open = 'Tab',
        Hotbar = 'Q',
    },

    CleanupDropTime = 15,    -- in minutes
    CleanupDropInterval = 1, -- in minutes

    ItemDropObject = '/QBCoreAssets/Meshes/SM_DuffelBag.SM_DuffelBag',

    VendingObjects = { 'SM_Soda_Machine', 'SM_Snack_Machine', 'SM_Coffee_Machine', 'SM_Vending_Machine_01', 'SM_MM00200_Drinks_Vending_Machine' },
    VendingItems = {
        { name = 'kurkakola',    price = 4, amount = 50 },
        { name = 'water_bottle', price = 4, amount = 50 },
    },
}

VehicleStorage = {
    default = {
        gloveboxSlots = 5,
        gloveboxWeight = 10000,
        trunkSlots = 35,
        trunkWeight = 60000
    },
}
