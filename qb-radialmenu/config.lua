Config = {}
Config.Keybind = 'H' -- FiveM Keyboard, this is registered keymapping, so needs changed in keybindings if player already has this mapped.
Config.Toggle = false -- use toggle mode. False requires hold of key
Config.UseWhilstWalking = false -- use whilst walking
Config.EnableExtraMenu = true
Config.Fliptime = 15000

local function ToggleCosmeticSlotItem(id, title, icon, slot)
    return {
        id = id,
        title = title,
        icon = icon,
        type = 'client',
        event = 'qb-radialmenu:client:ToggleCosmeticSlot',
        shouldClose = true,
        slot = slot,
    }
end

Config.MenuItems = {
    {
        id = 'citizen',
        title = 'Citizen',
        icon = 'user',
        items = {
            {
                id = 'givenum',
                title = 'Give Contact Details',
                icon = 'address-book',
                type = 'client',
                event = 'qb-phone:client:GiveContactDetails',
                shouldClose = true,
            },
            {
                id = 'getintrunk',
                title = 'Get In Trunk',
                icon = 'car',
                type = 'client',
                event = 'qb-trunk:client:GetIn',
                shouldClose = true,
            },
            {
                id = 'cornerselling',
                title = 'Corner Selling',
                icon = 'cannabis',
                type = 'client',
                event = 'qb-drugs:client:cornerselling',
                shouldClose = true,
            },
            {
                id = 'togglehotdogsell',
                title = 'Hotdog Selling',
                icon = 'hotdog',
                type = 'client',
                event = 'qb-hotdogjob:client:ToggleSell',
                shouldClose = true,
            },
            {
                id = 'interactions',
                title = 'Interaction',
                icon = 'triangle-exclamation',
                items = {
                    {
                        id = 'handcuff',
                        title = 'Cuff',
                        icon = 'user-lock',
                        type = 'client',
                        event = 'qb-policejob:client:CuffPlayerSoft',
                        shouldClose = true,
                    },
                    {
                        id = 'playerinvehicle',
                        title = 'Put In Vehicle',
                        icon = 'car-side',
                        type = 'client',
                        event = 'qb-policejob:client:PutPlayerInVehicle',
                        shouldClose = true,
                    },
                    {
                        id = 'playeroutvehicle',
                        title = 'Take Out Of Vehicle',
                        icon = 'car-side',
                        type = 'client',
                        event = 'qb-policejob:client:SetPlayerOutVehicle',
                        shouldClose = true,
                    },
                    {
                        id = 'stealplayer',
                        title = 'Rob',
                        icon = 'mask',
                        type = 'client',
                        event = 'qb-policejob:client:RobPlayer',
                        shouldClose = true,
                    },
                    {
                        id = 'escort',
                        title = 'Kidnap',
                        icon = 'user-group',
                        type = 'client',
                        event = 'qb-policejob:client:KidnapPlayer',
                        shouldClose = true,
                    },
                    {
                        id = 'escort2',
                        title = 'Escort',
                        icon = 'user-group',
                        type = 'client',
                        event = 'qb-policejob:client:EscortPlayer',
                        shouldClose = true,
                    },
                    {
                        id = 'escort554',
                        title = 'Hostage',
                        icon = 'child',
                        type = 'client',
                        event = 'A5:Client:TakeHostage',
                        shouldClose = true,
                    },
                },
            },
        },
    },
    {
        id = 'general',
        title = 'General',
        icon = 'rectangle-list',
        items = {
            {
                id = 'house',
                title = 'House Interaction',
                icon = 'house',
                items = {
                    {
                        id = 'givehousekey',
                        title = 'Give House Keys',
                        icon = 'key',
                        type = 'client',
                        event = 'qb-houses:client:giveHouseKey',
                        shouldClose = true,
                    },
                    {
                        id = 'removehousekey',
                        title = 'Remove House Keys',
                        icon = 'key',
                        type = 'client',
                        event = 'qb-houses:client:removeHouseKey',
                        shouldClose = true,
                    },
                    {
                        id = 'togglelock',
                        title = 'Toggle Doorlock',
                        icon = 'door-closed',
                        type = 'client',
                        event = 'qb-houses:client:toggleDoorlock',
                        shouldClose = true,
                    },
                    {
                        id = 'decoratehouse',
                        title = 'Decorate House',
                        icon = 'box',
                        type = 'client',
                        event = 'qb-houses:client:decorate',
                        shouldClose = true,
                    },
                    {
                        id = 'houseLocations',
                        title = 'Interaction Locations',
                        icon = 'house',
                        items = {
                            {
                                id = 'setstash',
                                title = 'Set Stash',
                                icon = 'box-open',
                                type = 'client',
                                event = 'qb-houses:client:setLocation',
                                shouldClose = true,
                            },
                            {
                                id = 'setoutift',
                                title = 'Set Wardrobe',
                                icon = 'shirt',
                                type = 'client',
                                event = 'qb-houses:client:setLocation',
                                shouldClose = true,
                            },
                            {
                                id = 'setlogout',
                                title = 'Set Logout',
                                icon = 'door-open',
                                type = 'client',
                                event = 'qb-houses:client:setLocation',
                                shouldClose = true,
                            },
                        },
                    },
                },
            },
            {
                id = 'clothesmenu',
                title = 'Clothing Slots',
                icon = 'shirt',
                items = {
                    {
                        id = 'clothing_slots',
                        title = 'Clothing',
                        icon = 'shirt',
                        items = {
                            ToggleCosmeticSlotItem('slot_clothing_top', 'Top', 'shirt', 'Cosmetic.Slot.Clothing.Top'),
                            ToggleCosmeticSlotItem('slot_clothing_bottoms', 'Bottoms', 'user', 'Cosmetic.Slot.Clothing.Bottoms'),
                            ToggleCosmeticSlotItem('slot_clothing_set', 'Full Set', 'user', 'Cosmetic.Slot.Clothing.Set'),
                            ToggleCosmeticSlotItem('slot_clothing_backpack', 'Backpack', 'bag-shopping', 'Cosmetic.Slot.Clothing.Backpack'),
                            ToggleCosmeticSlotItem('slot_clothing_socks', 'Socks', 'shoe-prints', 'Cosmetic.Slot.Clothing.Socks'),
                            ToggleCosmeticSlotItem('slot_clothing_shoes', 'Shoes', 'shoe-prints', 'Cosmetic.Slot.Clothing.Shoes'),
                            ToggleCosmeticSlotItem('slot_clothing_underwear_top', 'Underwear Top', 'shirt', 'Cosmetic.Slot.Clothing.Underwear.Top'),
                            ToggleCosmeticSlotItem('slot_clothing_underwear_bottom', 'Underwear Bottom', 'user', 'Cosmetic.Slot.Clothing.Underwear.Bottom'),
                            ToggleCosmeticSlotItem('slot_clothing_underwear_leg', 'Underwear Leg', 'user', 'Cosmetic.Slot.Clothing.Underwear.Leg'),
                        },
                    },
                    {
                        id = 'accessory_slots',
                        title = 'Accessories',
                        icon = 'glasses',
                        items = {
                            ToggleCosmeticSlotItem('slot_accessory_hat', 'Hat', 'hat-cowboy-side', 'Cosmetic.Slot.Accessory.Head.Hat'),
                            ToggleCosmeticSlotItem('slot_accessory_mask', 'Face Mask', 'masks-theater', 'Cosmetic.Slot.Accessory.Face.Mask'),
                            ToggleCosmeticSlotItem('slot_accessory_face_eyewear', 'Face Eyewear', 'glasses', 'Cosmetic.Slot.Accessory.Face.Eyewear'),
                            ToggleCosmeticSlotItem('slot_accessory_eyewear', 'Eyewear', 'glasses', 'Cosmetic.Slot.Accessory.Eyewear'),
                            ToggleCosmeticSlotItem('slot_accessory_necklace', 'Necklace', 'user-tie', 'Cosmetic.Slot.Accessory.Neck.Necklace'),
                            ToggleCosmeticSlotItem('slot_accessory_earrings', 'Earrings', 'ear-deaf', 'Cosmetic.Slot.Accessory.Ears.Earrings'),
                            ToggleCosmeticSlotItem('slot_accessory_gloves', 'Gloves', 'mitten', 'Cosmetic.Slot.Accessory.Hands.Gloves'),
                            ToggleCosmeticSlotItem('slot_accessory_nails', 'Nails', 'user', 'Cosmetic.Slot.Accessory.Hands.Nails'),
                        },
                    },
                    {
                        id = 'appearance_slots',
                        title = 'Appearance',
                        icon = 'user',
                        items = {
                            {
                                id = 'hair_slots',
                                title = 'Hair',
                                icon = 'user',
                                items = {
                                    ToggleCosmeticSlotItem('slot_appearance_hair_main', 'Main Hair', 'user', 'Cosmetic.Slot.Appearance.Hair.Main'),
                                    ToggleCosmeticSlotItem('slot_appearance_beard', 'Beard', 'user', 'Cosmetic.Slot.Appearance.Hair.Facial.Beard'),
                                    ToggleCosmeticSlotItem('slot_appearance_mustache', 'Mustache', 'user', 'Cosmetic.Slot.Appearance.Hair.Facial.Mustache'),
                                },
                            },
                            {
                                id = 'eye_slots',
                                title = 'Eyes',
                                icon = 'eye',
                                items = {
                                    ToggleCosmeticSlotItem('slot_appearance_eyebrows', 'Eyebrows', 'eye', 'Cosmetic.Slot.Appearance.Eyes.Eyebrows'),
                                    ToggleCosmeticSlotItem('slot_appearance_eyelashes', 'Eyelashes', 'eye', 'Cosmetic.Slot.Appearance.Eyes.Eyelashes'),
                                    ToggleCosmeticSlotItem('slot_appearance_iris', 'Iris', 'eye', 'Cosmetic.Slot.Appearance.Eyes.Iris'),
                                },
                            },
                            {
                                id = 'skin_slots',
                                title = 'Skin',
                                icon = 'user',
                                items = {
                                    ToggleCosmeticSlotItem('slot_appearance_body_tattoo', 'Body Tattoo', 'user', 'Cosmetic.Slot.Appearance.Skin.BodyTattoo'),
                                    ToggleCosmeticSlotItem('slot_appearance_face_tattoo', 'Face Tattoo', 'user', 'Cosmetic.Slot.Appearance.Skin.FaceTattoo'),
                                },
                            },
                            {
                                id = 'makeup_slots',
                                title = 'Makeup',
                                icon = 'user',
                                items = {
                                    ToggleCosmeticSlotItem('slot_appearance_lipstick', 'Lipstick', 'user', 'Cosmetic.Slot.Appearance.Makeup.Lipstick'),
                                    ToggleCosmeticSlotItem('slot_appearance_eyeliner', 'Eyeliner', 'eye', 'Cosmetic.Slot.Appearance.Makeup.Eyeliner'),
                                    ToggleCosmeticSlotItem('slot_appearance_eyeshadow', 'Eyeshadow', 'eye', 'Cosmetic.Slot.Appearance.Makeup.Eyeshadow'),
                                    ToggleCosmeticSlotItem('slot_appearance_blush', 'Blush', 'user', 'Cosmetic.Slot.Appearance.Makeup.Blush'),
                                },
                            },
                        },
                    },
                    {
                        id = 'body_slots',
                        title = 'Body',
                        icon = 'user',
                        items = {
                            ToggleCosmeticSlotItem('slot_body_head', 'Head', 'user', 'Cosmetic.Slot.Body.Head'),
                            ToggleCosmeticSlotItem('slot_body_upper', 'Upper Body', 'shirt', 'Cosmetic.Slot.Body.Upper'),
                            ToggleCosmeticSlotItem('slot_body_lower', 'Lower Body', 'user', 'Cosmetic.Slot.Body.Lower'),
                            ToggleCosmeticSlotItem('slot_body_hands', 'Hands', 'mitten', 'Cosmetic.Slot.Body.Hands'),
                            ToggleCosmeticSlotItem('slot_body_feet', 'Feet', 'shoe-prints', 'Cosmetic.Slot.Body.Feet'),
                        },
                    },
                    ToggleCosmeticSlotItem('slot_custom_mesh', 'Custom Mesh', 'user', 'Cosmetic.Slot.Custom'),
                },
            },
        },
    },
}

Config.VehicleDoors = {
    id = 'vehicledoors',
    title = 'Vehicle Doors',
    icon = 'car-side',
    items = {
        {
            id = 'door0',
            title = 'Drivers door',
            icon = 'car-side',
            type = 'client',
            event = 'qb-radialmenu:client:openDoor',
            shouldClose = false,
        },
        {
            id = 'door4',
            title = 'Hood',
            icon = 'car',
            type = 'client',
            event = 'qb-radialmenu:client:openDoor',
            shouldClose = false,
        },
        {
            id = 'door1',
            title = 'Passengers door',
            icon = 'car-side',
            type = 'client',
            event = 'qb-radialmenu:client:openDoor',
            shouldClose = false,
        },
        {
            id = 'door3',
            title = 'Right rear',
            icon = 'car-side',
            type = 'client',
            event = 'qb-radialmenu:client:openDoor',
            shouldClose = false,
        },
        {
            id = 'door5',
            title = 'Trunk',
            icon = 'car',
            type = 'client',
            event = 'qb-radialmenu:client:openDoor',
            shouldClose = false,
        },
        {
            id = 'door2',
            title = 'Left rear',
            icon = 'car-side',
            type = 'client',
            event = 'qb-radialmenu:client:openDoor',
            shouldClose = false,
        },
    },
}

Config.VehicleExtras = {
    id = 'vehicleextras',
    title = 'Vehicle Extras',
    icon = 'plus',
    items = {
        {
            id = 'extra1',
            title = 'Extra 1',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra2',
            title = 'Extra 2',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra3',
            title = 'Extra 3',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra4',
            title = 'Extra 4',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra5',
            title = 'Extra 5',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra6',
            title = 'Extra 6',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra7',
            title = 'Extra 7',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra8',
            title = 'Extra 8',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra9',
            title = 'Extra 9',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra10',
            title = 'Extra 10',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra11',
            title = 'Extra 11',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra12',
            title = 'Extra 12',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
        {
            id = 'extra13',
            title = 'Extra 13',
            icon = 'box-open',
            type = 'client',
            event = 'qb-radialmenu:client:setExtra',
            shouldClose = false,
        },
    },
}

Config.VehicleSeats = {
    id = 'vehicleseats',
    title = 'Vehicle Seats',
    icon = 'chair',
    items = {},
}

Config.JobInteractions = {
    ['ambulance'] = {
        {
            id = 'emergencybutton2',
            title = 'Emergency button',
            icon = 'bell',
            type = 'client',
            event = 'qb-policejob:client:SendPoliceEmergencyAlert',
            shouldClose = true,
        },
        {
            id = 'stretcheroptions',
            title = 'Stretcher',
            icon = 'bed-pulse',
            items = {
                {
                    id = 'spawnstretcher',
                    title = 'Spawn Stretcher',
                    icon = 'plus',
                    type = 'client',
                    event = 'qb-radialmenu:client:TakeStretcher',
                    shouldClose = false,
                },
                {
                    id = 'despawnstretcher',
                    title = 'Remove Stretcher',
                    icon = 'minus',
                    type = 'client',
                    event = 'qb-radialmenu:client:RemoveStretcher',
                    shouldClose = false,
                },
            },
        },
    },
    ['taxi'] = {
        {
            id = 'togglemeter',
            title = 'Show/Hide Meter',
            icon = 'eye-slash',
            type = 'client',
            event = 'qb-taxijob:client:toggleMeter',
            shouldClose = false,
        },
        {
            id = 'togglemouse',
            title = 'Start/Stop Meter',
            icon = 'hourglass-start',
            type = 'client',
            event = 'qb-taxijob:client:enableMeter',
            shouldClose = true,
        },
        {
            id = 'npc_mission',
            title = 'NPC Mission',
            icon = 'taxi',
            type = 'server',
            event = 'qb-taxijob:server:startWork',
            shouldClose = true,
        },
    },
    ['tow'] = {
        {
            id = 'togglenpc',
            title = 'Toggle NPC',
            icon = 'toggle-on',
            type = 'client',
            event = 'jobs:client:ToggleNpc',
            shouldClose = true,
        },
        {
            id = 'towvehicle',
            title = 'Tow vehicle',
            icon = 'truck-pickup',
            type = 'client',
            event = 'qb-tow:client:TowVehicle',
            shouldClose = true,
        },
    },
    ['mechanic'] = {
        {
            id = 'towvehicle',
            title = 'Tow vehicle',
            icon = 'truck-pickup',
            type = 'client',
            event = 'qb-tow:client:TowVehicle',
            shouldClose = true,
        },
    },
    ['realestate'] = {
        {
            id = 'createhouse',
            title = 'Create House',
            icon = 'house',
            type = 'client',
            event = 'qb-houses:client:houseMenu',
            shouldClose = true,
        },
        {
            id = 'addgarage',
            title = 'Add Garage',
            icon = 'warehouse',
            type = 'client',
            event = 'qb-houses:client:addGarage',
            shouldClose = true,
        },
    },
    ['police'] = {
        {
            id = 'emergencybutton',
            title = 'Emergency button',
            icon = 'bell',
            type = 'client',
            event = 'qb-policejob:client:SendPoliceEmergencyAlert',
            shouldClose = true,
        },
        {
            id = 'checkvehstatus',
            title = 'Check Tune Status',
            icon = 'circle-info',
            type = 'client',
            event = 'qb-tunerchip:client:TuneStatus',
            shouldClose = true,
        },
        {
            id = 'resethouse',
            title = 'Reset house lock',
            icon = 'key',
            type = 'client',
            event = 'qb-houses:client:ResetHouse',
            shouldClose = true,
        },
        {
            id = 'takedriverlicense',
            title = 'Revoke Drivers License',
            icon = 'id-card',
            type = 'client',
            event = 'qb-policejob:client:SeizeDriverLicense',
            shouldClose = true,
        },
        {
            id = 'policeinteraction',
            title = 'Police Actions',
            icon = 'list-check',
            items = {
                {
                    id = 'statuscheck',
                    title = 'Check Health Status',
                    icon = 'heart-pulse',
                    type = 'client',
                    event = 'hospital:client:CheckStatus',
                    shouldClose = true,
                },
                {
                    id = 'checkstatus',
                    title = 'Check status',
                    icon = 'question',
                    type = 'client',
                    event = 'qb-policejob:client:CheckStatus',
                    shouldClose = true,
                },
                {
                    id = 'escort',
                    title = 'Escort',
                    icon = 'user-group',
                    type = 'client',
                    event = 'qb-policejob:client:EscortPlayer',
                    shouldClose = true,
                },
                {
                    id = 'searchplayer',
                    title = 'Search',
                    icon = 'magnifying-glass',
                    type = 'server',
                    event = 'qb-policejob:server:SearchPlayer',
                    shouldClose = true,
                },
                {
                    id = 'jailplayer',
                    title = 'Jail',
                    icon = 'user-lock',
                    type = 'client',
                    event = 'qb-policejob:client:JailPlayer',
                    shouldClose = true,
                },
            },
        },
        {
            id = 'policeobjects',
            title = 'Objects',
            icon = 'road',
            items = {
                {
                    id = 'spawnpion',
                    title = 'Cone',
                    icon = 'triangle-exclamation',
                    type = 'client',
                    event = 'qb-policejob:client:spawnCone',
                    shouldClose = false,
                },
                {
                    id = 'spawnhek',
                    title = 'Gate',
                    icon = 'torii-gate',
                    type = 'client',
                    event = 'qb-policejob:client:spawnBarrier',
                    shouldClose = false,
                },
                {
                    id = 'spawnschotten',
                    title = 'Speed Limit Sign',
                    icon = 'sign-hanging',
                    type = 'client',
                    event = 'qb-policejob:client:spawnRoadSign',
                    shouldClose = false,
                },
                {
                    id = 'spawntent',
                    title = 'Tent',
                    icon = 'campground',
                    type = 'client',
                    event = 'qb-policejob:client:spawnTent',
                    shouldClose = false,
                },
                {
                    id = 'spawnverlichting',
                    title = 'Lighting',
                    icon = 'lightbulb',
                    type = 'client',
                    event = 'qb-policejob:client:spawnLight',
                    shouldClose = false,
                },
                {
                    id = 'spikestrip',
                    title = 'Spike Strips',
                    icon = 'caret-up',
                    type = 'client',
                    event = 'qb-policejob:client:SpawnSpikeStrip',
                    shouldClose = false,
                },
                {
                    id = 'deleteobject',
                    title = 'Remove object',
                    icon = 'trash',
                    type = 'client',
                    event = 'qb-policejob:client:deleteObject',
                    shouldClose = false,
                },
            },
        },
    },
    ['hotdog'] = {
        {
            id = 'togglesell',
            title = 'Toggle sell',
            icon = 'hotdog',
            type = 'client',
            event = 'qb-hotdogjob:client:ToggleSell',
            shouldClose = true,
        },
    },
}

Config.TrunkClasses = {
    [0] = { allowed = true, x = 0.0, y = -1.5, z = 0.0 }, -- Coupes
    [1] = { allowed = true, x = 0.0, y = -2.0, z = 0.0 }, -- Sedans
    [2] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- SUVs
    [3] = { allowed = true, x = 0.0, y = -1.5, z = 0.0 }, -- Coupes
    [4] = { allowed = true, x = 0.0, y = -2.0, z = 0.0 }, -- Muscle
    [5] = { allowed = true, x = 0.0, y = -2.0, z = 0.0 }, -- Sports Classics
    [6] = { allowed = true, x = 0.0, y = -2.0, z = 0.0 }, -- Sports
    [7] = { allowed = true, x = 0.0, y = -2.0, z = 0.0 }, -- Super
    [8] = { allowed = false, x = 0.0, y = -1.0, z = 0.25 }, -- Motorcycles
    [9] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Off-road
    [10] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Industrial
    [11] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Utility
    [12] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Vans
    [13] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Cycles
    [14] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Boats
    [15] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Helicopters
    [16] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Planes
    [17] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Service
    [18] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Emergency
    [19] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Military
    [20] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Commercial
    [21] = { allowed = true, x = 0.0, y = -1.0, z = 0.25 }, -- Trains
}

Config.ExtrasEnabled = true

Config.Commands = {
    ['top'] = {
        Func = function()
            ToggleClothing('Top')
        end,
        Sprite = 'top',
        Desc = 'Take your shirt off/on',
        Button = 1,
        Name = 'Torso',
    },
    ['gloves'] = {
        Func = function()
            ToggleClothing('gloves')
        end,
        Sprite = 'gloves',
        Desc = 'Take your gloves off/on',
        Button = 2,
        Name = 'Gloves',
    },
    ['visor'] = {
        Func = function()
            ToggleProps('visor')
        end,
        Sprite = 'visor',
        Desc = 'Toggle hat variation',
        Button = 3,
        Name = 'Visor',
    },
    ['bag'] = {
        Func = function()
            ToggleClothing('Bag')
        end,
        Sprite = 'bag',
        Desc = 'Opens or closes your bag',
        Button = 8,
        Name = 'Bag',
    },
    ['shoes'] = {
        Func = function()
            ToggleClothing('Shoes')
        end,
        Sprite = 'shoes',
        Desc = 'Take your shoes off/on',
        Button = 5,
        Name = 'Shoes',
    },
    ['vest'] = {
        Func = function()
            ToggleClothing('Vest')
        end,
        Sprite = 'vest',
        Desc = 'Take your vest off/on',
        Button = 14,
        Name = 'Vest',
    },
    ['hair'] = {
        Func = function()
            ToggleClothing('hair')
        end,
        Sprite = 'hair',
        Desc = 'Put your hair up/down/in a bun/ponytail.',
        Button = 7,
        Name = 'Hair',
    },
    ['hat'] = {
        Func = function()
            ToggleProps('Hat')
        end,
        Sprite = 'hat',
        Desc = 'Take your hat off/on',
        Button = 4,
        Name = 'Hat',
    },
    ['glasses'] = {
        Func = function()
            ToggleProps('Glasses')
        end,
        Sprite = 'glasses',
        Desc = 'Take your glasses off/on',
        Button = 9,
        Name = 'Glasses',
    },
    ['ear'] = {
        Func = function()
            ToggleProps('Ear')
        end,
        Sprite = 'ear',
        Desc = 'Take your ear accessory off/on',
        Button = 10,
        Name = 'Ear',
    },
    ['neck'] = {
        Func = function()
            ToggleClothing('Neck')
        end,
        Sprite = 'neck',
        Desc = 'Take your neck accessory off/on',
        Button = 11,
        Name = 'Neck',
    },
    ['watch'] = {
        Func = function()
            ToggleProps('Watch')
        end,
        Sprite = 'watch',
        Desc = 'Take your watch off/on',
        Button = 12,
        Name = 'Watch',
        Rotation = 5.0,
    },
    ['bracelet'] = {
        Func = function()
            ToggleProps('Bracelet')
        end,
        Sprite = 'bracelet',
        Desc = 'Take your bracelet off/on',
        Button = 13,
        Name = 'Bracelet',
    },
    ['mask'] = {
        Func = function()
            ToggleClothing('Mask')
        end,
        Sprite = 'mask',
        Desc = 'Take your mask off/on',
        Button = 6,
        Name = 'Mask',
    },
}

local bags = { [40] = true, [41] = true, [44] = true, [45] = true }

Config.ExtraCommands = {
    ['pants'] = {
        Func = function()
            ToggleClothing('Pants', true)
        end,
        Sprite = 'pants',
        Desc = 'Take your pants off/on',
        Name = 'Pants',
        OffsetX = -0.04,
        OffsetY = 0.0,
    },
    ['shirt'] = {
        Func = function()
            ToggleClothing('Shirt', true)
        end,
        Sprite = 'shirt',
        Desc = 'Take your shirt off/on',
        Name = 'shirt',
        OffsetX = 0.04,
        OffsetY = 0.0,
    },
    ['reset'] = {
        Func = function()
            if not ResetClothing(true) then
                Notify('Nothing To Reset', 'error')
            end
        end,
        Sprite = 'reset',
        Desc = 'Revert everything back to normal',
        Name = 'reset',
        OffsetX = 0.12,
        OffsetY = 0.2,
        Rotate = true,
    },
    ['bagoff'] = {
        Func = function()
            ToggleClothing('Bagoff', true)
        end,
        Sprite = 'bagoff',
        SpriteFunc = function()
            local Bag = GetPedDrawableVariation(PlayerPedId(), 5)
            local BagOff = LastEquipped['Bagoff']
            if LastEquipped['Bagoff'] then
                if bags[BagOff.Drawable] then
                    return 'bagoff'
                else
                    return 'paraoff'
                end
            end
            if Bag ~= 0 then
                if bags[Bag] then
                    return 'bagoff'
                else
                    return 'paraoff'
                end
            else
                return false
            end
        end,
        Desc = 'Take your bag off/on',
        Name = 'bagoff',
        OffsetX = -0.12,
        OffsetY = 0.2,
    },
}
