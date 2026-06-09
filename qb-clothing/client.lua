-- Variables

local Callbacks      = {}
local GENDER_NAMES   = { [1] = 'Male', [2] = 'Female' }
local BODYTYPE_NAMES = { [0] = 'Underweight', [1] = 'Average' }

local SHOP_TYPES     = {
    -- Clothing store: only Outfits
    clothing    = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Accessories":{}},"Visibility":false,"Default":"Outfits"}',
    -- Barbershop: Head (Hair, Eyes, Makeup) — no face presets, no head shape, no face tattoos
    barbershop  = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Preset.Head":{},"Cosmetic.Slot.Body.Head":{},"Cosmetic.Slot.Appearance.Skin.FaceTattoo":{}},"Body":{},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Head"}',
    -- Tattoo parlor: Face tattoos and body tattoos only
    tattoo      = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Preset.Head":{},"Cosmetic.Slot.Body.Head":{},"Cosmetic.Slot.Appearance.Eyes":{},"Cosmetic.Slot.Appearance.Hair":{},"Cosmetic.Slot.Appearance.Makeup":{}},"Body":{"Cosmetic.Preset.Body":{}},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Body"}',
    -- Surgeon: structural face changes (face presets, head shape, eyes) — no hair, no makeup, no tattoos
    surgeon     = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Slot.Appearance.Eyes":{},"Cosmetic.Slot.Appearance.Hair":{},"Cosmetic.Slot.Appearance.Makeup":{},"Cosmetic.Slot.Appearance.Skin.FaceTattoo":{}},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Head"}',
    -- Accessories store: only the Accessories tab
    accessories = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Outfits":{}},"Visibility":false,"Default":"Accessories"}',
    -- Shoe store: only Shoes slot within Outfits
    shoes       = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Accessories":{},"Outfits":{"Cosmetic.Preset.Outfit":{},"Cosmetic.Slot.Clothing.Top":{},"Cosmetic.Slot.Clothing.Set":{},"Cosmetic.Slot.Clothing.Bottoms":{},"Cosmetic.Slot.Clothing.Backpack":{},"Cosmetic.Slot.Clothing.Socks":{},"Cosmetic.Slot.Clothing.Underwear.Leg":{},"Cosmetic.Slot.Clothing.Underwear.Top":{},"Cosmetic.Slot.Clothing.Underwear.Bottom":{}}},"Visibility":false,"Default":"Outfits"}',
    -- Hat store: only Hat slot within Accessories
    hats        = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Outfits":{},"Accessories":{"Cosmetic.Slot.Accessory.Face.Mask":{},"Cosmetic.Slot.Accessory.Face.Eyewear":{},"Cosmetic.Slot.Accessory.Neck.Necklace":{},"Cosmetic.Slot.Accessory.Ears.Earrings":{},"Cosmetic.Slot.Accessory.Hands.Nails":{},"Cosmetic.Slot.Accessory.Hands.Gloves":{}}},"Visibility":false,"Default":"Accessories"}',
    -- Makeup/beauty store: only Makeup sub-slots within Head
    makeup      = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Preset.Head":{},"Cosmetic.Slot.Body.Head":{},"Cosmetic.Slot.Appearance.Hair":{},"Cosmetic.Slot.Appearance.Skin.FaceTattoo":{}},"Body":{},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Head"}',
    -- Eyewear store: only Face.Eyewear within Accessories
    eyewear     = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Outfits":{},"Accessories":{"Cosmetic.Slot.Accessory.Head.Hat":{},"Cosmetic.Slot.Accessory.Face.Mask":{},"Cosmetic.Slot.Accessory.Neck.Necklace":{},"Cosmetic.Slot.Accessory.Ears.Earrings":{},"Cosmetic.Slot.Accessory.Hands.Nails":{},"Cosmetic.Slot.Accessory.Hands.Gloves":{}}},"Visibility":false,"Default":"Accessories"}',
    -- Tops store: only Top and Set slots within Outfits
    tops        = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Accessories":{},"Outfits":{"Cosmetic.Preset.Outfit":{},"Cosmetic.Slot.Clothing.Bottoms":{},"Cosmetic.Slot.Clothing.Backpack":{},"Cosmetic.Slot.Clothing.Underwear.Leg":{},"Cosmetic.Slot.Clothing.Underwear.Top":{},"Cosmetic.Slot.Clothing.Underwear.Bottom":{},"Cosmetic.Slot.Clothing.Socks":{},"Cosmetic.Slot.Clothing.Shoes":{}}},"Visibility":false,"Default":"Outfits"}',
    -- Bottoms store: only Bottoms slot within Outfits
    bottoms     = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Accessories":{},"Outfits":{"Cosmetic.Preset.Outfit":{},"Cosmetic.Slot.Clothing.Top":{},"Cosmetic.Slot.Clothing.Set":{},"Cosmetic.Slot.Clothing.Backpack":{},"Cosmetic.Slot.Clothing.Underwear.Leg":{},"Cosmetic.Slot.Clothing.Underwear.Top":{},"Cosmetic.Slot.Clothing.Underwear.Bottom":{},"Cosmetic.Slot.Clothing.Socks":{},"Cosmetic.Slot.Clothing.Shoes":{}}},"Visibility":false,"Default":"Outfits"}',
    -- Nail salon: only Hands.Nails within Accessories
    nails       = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Outfits":{},"Accessories":{"Cosmetic.Slot.Accessory.Head.Hat":{},"Cosmetic.Slot.Accessory.Face.Mask":{},"Cosmetic.Slot.Accessory.Face.Eyewear":{},"Cosmetic.Slot.Accessory.Neck.Necklace":{},"Cosmetic.Slot.Accessory.Ears.Earrings":{},"Cosmetic.Slot.Accessory.Hands.Gloves":{}}},"Visibility":false,"Default":"Accessories"}',
    -- Mask shop: only Face.Mask within Accessories
    mask        = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Outfits":{},"Accessories":{"Cosmetic.Slot.Accessory.Head.Hat":{},"Cosmetic.Slot.Accessory.Face.Eyewear":{},"Cosmetic.Slot.Accessory.Neck.Necklace":{},"Cosmetic.Slot.Accessory.Ears.Earrings":{},"Cosmetic.Slot.Accessory.Hands.Nails":{},"Cosmetic.Slot.Accessory.Hands.Gloves":{}}},"Visibility":false,"Default":"Accessories"}',
}

-- Functions

local function GetCosmeticsSystem()
    local pawn = GetPlayerPawn()
    if not pawn then return nil end
    return pawn:GetCosmeticsSystem()
end

local function SerializeSkin(System)
    local Loadout = System:GetCosmeticLoadout()
    local data = {
        gender   = GENDER_NAMES[Loadout.Gender] or 'Male',
        bodyType = BODYTYPE_NAMES[Loadout.BodyType] or 'Underweight',
        items    = {}
    }
    local Slots = Loadout.Slots
    for i = 1, Slots:Length() do
        local Entry = Slots:Get(i)
        if Entry.ItemID ~= '' then
            data.items[#data.items + 1] = {
                slot   = tostring(Entry.SlotTag.TagName),
                itemId = Entry.ItemID
            }
        end
    end
    return JSON.stringify(data)
end

local function ApplySkinToSystem(System, skinJson)
    local data = JSON.parse(skinJson)
    local Items = UE.TArray(UE.FString)
    for _, entry in ipairs(data.items) do
        Items:Add(entry.itemId)
    end
    System:EquipCosmeticItems(Items)
end

local function BindCosmeticsEvents()
    local System = GetCosmeticsSystem()
    if not System then return false end

    Callbacks.OnUpdated = function(_, NewLoadout)
        print('[CC] Loadout updated — Gender:', GENDER_NAMES[NewLoadout.Gender] or NewLoadout.Gender, 'BodyType:', BODYTYPE_NAMES[NewLoadout.BodyType] or NewLoadout.BodyType)
    end

    Callbacks.OnGenderChanged = function(_, NewGender)
        print('[CC] Gender changed —', GENDER_NAMES[NewGender] or NewGender)
    end

    Callbacks.OnBodyTypeChanged = function(_, NewBodyType)
        print('[CC] Body type changed —', BODYTYPE_NAMES[NewBodyType] or NewBodyType)
    end

    Callbacks.OnCustomizationStarted = function(_)
        print('[CC] UI opened')
    end

    Callbacks.OnCustomizationFinished = function(_, bCancelled)
        if bCancelled then
            print('[CC] UI closed — changes DISCARDED')
        else
            print('[CC] UI closed — changes SAVED')
            TriggerServerEvent('qb-clothing:server:SaveSkin', SerializeSkin(System))
        end
    end

    System:BindOnCosmeticsUpdated(Callbacks.OnUpdated)
    System:BindOnCosmeticsGenderChanged(Callbacks.OnGenderChanged)
    System:BindOnCosmeticsBodyTypeChanged(Callbacks.OnBodyTypeChanged)
    System:BindOnCosmeticsCustomizationStarted(Callbacks.OnCustomizationStarted)
    System:BindOnCosmeticsCustomizationFinished(Callbacks.OnCustomizationFinished)

    Callbacks.System = System
    return true
end

local function UnbindCosmeticsEvents()
    local System = Callbacks.System
    if not System then return end

    System:UnbindOnCosmeticsUpdated(Callbacks.OnUpdated)
    System:UnbindOnCosmeticsGenderChanged(Callbacks.OnGenderChanged)
    System:UnbindOnCosmeticsBodyTypeChanged(Callbacks.OnBodyTypeChanged)
    System:UnbindOnCosmeticsCustomizationStarted(Callbacks.OnCustomizationStarted)
    System:UnbindOnCosmeticsCustomizationFinished(Callbacks.OnCustomizationFinished)

    Callbacks = {}
end

local function WaitForCosmeticsAndRun(fn)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local checkId
    local attempts = 0
    checkId = Timer.SetInterval(function()
        attempts = attempts + 1
        if attempts > 20 then
            Timer.ClearInterval(checkId)
            return
        end
        if not pawn:IsInitialCosmeticsLoadDone() then return end
        Timer.ClearInterval(checkId)
        local System = pawn:GetCosmeticsSystem()
        if not System then return end
        BindCosmeticsEvents()
        fn(System)
    end, 500)
end

local function OpenClothing(shopType)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local System = pawn:GetCosmeticsSystem()
    if not System then return end
    local visibilityJson = shopType and (SHOP_TYPES[shopType] or shopType)
    if visibilityJson then
        local BP_JsonObjectWrapper = LoadClass('/HelixRemoteResourceModel/Utility/BP_JsonObjectWrapper.BP_JsonObjectWrapper_C')
        local wrapper = NewObject(BP_JsonObjectWrapper)
        if wrapper:LoadFromString(visibilityJson) then
            System:ShowCharacterCustomizationUIEx(wrapper)
        else
            System:ShowCharacterCustomizationUI()
        end
    else
        System:ShowCharacterCustomizationUI()
    end
end

local function SaveCurrentSkin()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local System = pawn:GetCosmeticsSystem()
    if not System then return end
    TriggerServerEvent('qb-clothing:server:SaveSkin', SerializeSkin(System))
end

local function LoadAndApplySkin()
    local handled = false

    local function onSkinReceived(skinJson)
        if handled then return end
        handled = true
        WaitForCosmeticsAndRun(function(System)
            if skinJson then
                ApplySkinToSystem(System, skinJson)
            else
                System:ShowCharacterCustomizationUI()
            end
        end)
    end

    Timer.SetTimeout(function()
        if not handled then
            onSkinReceived(nil)
        end
    end, 3000)

    TriggerCallback('GetPlayerSkin', onSkinReceived)
end

exports('qb-clothing', 'OpenClothing', OpenClothing)
exports('qb-clothing', 'SaveCurrentSkin', SaveCurrentSkin)
exports('qb-clothing', 'LoadAndApplySkin', LoadAndApplySkin)

-- Zone registration

local registeredZones = {}
local shopMarkers = {}

local function RegisterShopZone(zoneId, coords, heading, options)
    if registeredZones[zoneId] then return end
    if not coords then return end
    exports['qb-target']:AddBoxZone(zoneId, coords, 1.5, 1.5, {
        heading  = heading or 0,
        distance = 2.5,
    }, options)
    registeredZones[zoneId] = true
end

-- Add a new row here to support a new shop type. Each entry in Config.Shops
-- references one of these by its 'type' field.
local SHOP_DEFS = {
    clothing    = { zonePrefix = 'clothingShop', targetIcon = 'shirt', markerIcon = 'clothing-store', markerDesc = 'Browse & purchase clothing', markerColor = LinearColor(1.0, 0.5, 0.8, 1.0) },
    barbershop  = { zonePrefix = 'barbershop', targetIcon = 'scissors', markerIcon = 'hairdresser', markerDesc = 'Haircuts & styling', markerColor = LinearColor(0.6, 0.4, 1.0, 1.0) },
    tattoo      = { zonePrefix = 'tattooShop', targetIcon = 'pen', markerIcon = 'art-gallery', markerDesc = 'Tattoo parlor', markerColor = LinearColor(0.3, 0.3, 0.3, 1.0) },
    surgeon     = { zonePrefix = 'plasticSurgeon', targetIcon = 'stethoscope', markerIcon = 'hospital', markerDesc = 'Cosmetic surgery', markerColor = LinearColor(0.2, 0.8, 0.8, 1.0) },
    accessories = { zonePrefix = 'accessoriesShop', targetIcon = 'gem', markerIcon = 'jewelry-store', markerDesc = 'Accessories & jewelry', markerColor = LinearColor(0.9, 0.75, 0.2, 1.0) },
    shoes       = { zonePrefix = 'shoeShop', targetIcon = 'shoe', markerIcon = 'shoe-store', markerDesc = 'Footwear & shoes', markerColor = LinearColor(0.6, 0.4, 0.2, 1.0) },
    hats        = { zonePrefix = 'hatShop', targetIcon = 'hat', markerIcon = 'hat-store', markerDesc = 'Hats & headwear', markerColor = LinearColor(0.4, 0.7, 0.4, 1.0) },
    makeup      = { zonePrefix = 'makeupShop', targetIcon = 'lipstick', markerIcon = 'beauty-salon', markerDesc = 'Makeup & cosmetics', markerColor = LinearColor(1.0, 0.4, 0.6, 1.0) },
    eyewear     = { zonePrefix = 'eyewearShop', targetIcon = 'glasses', markerIcon = 'optician', markerDesc = 'Glasses & sunglasses', markerColor = LinearColor(0.3, 0.6, 0.9, 1.0) },
    tops        = { zonePrefix = 'topsShop', targetIcon = 'shirt', markerIcon = 'clothing-store', markerDesc = 'Tops & shirts', markerColor = LinearColor(0.8, 0.4, 0.4, 1.0) },
    bottoms     = { zonePrefix = 'bottomsShop', targetIcon = 'pants', markerIcon = 'clothing-store', markerDesc = 'Pants & bottoms', markerColor = LinearColor(0.4, 0.4, 0.8, 1.0) },
    nails       = { zonePrefix = 'nailSalon', targetIcon = 'hand', markerIcon = 'nail-salon', markerDesc = 'Nail salon', markerColor = LinearColor(1.0, 0.6, 0.7, 1.0) },
    mask        = { zonePrefix = 'maskShop', targetIcon = 'mask', markerIcon = 'store', markerDesc = 'Masks & face coverings', markerColor = LinearColor(0.5, 0.5, 0.5, 1.0) },
}

local function RegisterAllShopZones()
    for id, shop in pairs(Config.Shops) do
        local def = SHOP_DEFS[shop.type]
        if not def then goto continue end
        RegisterShopZone(def.zonePrefix .. '_' .. id, shop.coords, shop.heading, {
            {
                type     = 'client',
                event    = 'qb-clothing:client:OpenShop',
                icon     = def.targetIcon,
                label    = shop.label,
                shopId   = id,
                shopType = shop.type,
            },
        })
        local markerId = exports['qb-hud']:AddMarker(shop.coords, {
            title       = shop.label or '',
            description = shop.description or def.markerDesc or '',
            icon        = def.markerIcon or 'store',
            color       = shop.color or def.markerColor,
            markerType  = 'Store',
        })
        if markerId then shopMarkers[#shopMarkers + 1] = markerId end
        ::continue::
    end
end

local function UnregisterAllShopZones()
    for zoneId in pairs(registeredZones) do
        exports['qb-target']:RemoveZone(zoneId)
    end
    registeredZones = {}
    for _, id in ipairs(shopMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    shopMarkers = {}
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    RegisterAllShopZones()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    UnbindCosmeticsEvents()
    UnregisterAllShopZones()
end)

-- Single event for all shop types; shopType comes from the target zone data
RegisterClientEvent('qb-clothing:client:OpenShop', function(data)
    OpenClothing(data and data.shopType)
end)
