-- Helpers for building gameplay tags when slot-filtered store/barbershop UI is implemented
---@diagnostic disable-next-line: unused-local, unused-function
local function Tag(name)
    return UE.UHelixResourceUtility.RequestGameplayTag(name)
end

---@diagnostic disable-next-line: unused-local, unused-function
local function MakeTagContainer(names)
    local arr = {}
    for _, name in ipairs(names) do
        arr[#arr + 1] = Tag(name)
    end
    return UE.UBlueprintGameplayTagLibrary.MakeGameplayTagContainerFromArray(arr)
end

local function SerializeSkin(System)
    local Loadout = System:GetCosmeticLoadout()
    local data = {
        gender   = (Loadout.Gender == UE.EHCharacterCosmeticsGender.Female) and 'Female' or 'Male',
        bodyType = (Loadout.BodyType == UE.EHCosmeticBodyType.Underweight) and 'Underweight' or 'Average',
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
    local gender = data.gender == 'Female'
        and UE.EHCharacterCosmeticsGender.Female
        or UE.EHCharacterCosmeticsGender.Male
    local body = data.bodyType == 'Underweight'
        and UE.EHCosmeticBodyType.Underweight
        or UE.EHCosmeticBodyType.Average
    System:SetCosmeticGender(gender)
    System:SetCosmeticBodyType(body)
    System:ClearAllCosmeticSlots()
    local Items = UE.TArray(UE.FString)
    for _, entry in ipairs(data.items) do
        Items:Add(entry.itemId)
    end
    System:EquipCosmeticItems(Items)
end

local function WaitForCosmeticsAndRun(fn)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local checkId
    checkId = Timer.SetInterval(function()
        if not pawn:IsInitialCosmeticsLoadDone() then return end
        Timer.ClearInterval(checkId)
        local System = pawn:GetCosmeticsSystem()
        if not System then return end
        fn(System)
    end, 500)
end

-- Named visibility presets — each JSON lists widgets to HIDE (Visibility:false).
-- Anything not listed remains visible. Add entries here for new shop types.
-- Callers may also pass a raw JSON string directly instead of a preset name.
--
-- Full widget tree reference (from DA_CharacterCustomizationData):
--   Gender, Custom, Presets
--   Head > Cosmetic.Preset.Head | Cosmetic.Slot.Body.Head | Cosmetic.Slot.Appearance.Eyes (Eyebrows/Eyelashes/Iris) | Cosmetic.Slot.Appearance.Hair (Main/Mustache/Beard) | Cosmetic.Slot.Appearance.Makeup (Eyeshadow/Eyeliner/Lipstick/Blush) | Cosmetic.Slot.Appearance.Skin.FaceTattoo
--   Body > Cosmetic.Preset.Body | Cosmetic.Slot.Appearance.Skin.BodyTattoo
--   Outfits > Cosmetic.Preset.Outfit | Cosmetic.Slot.Clothing.Top/Set/Bottoms/Backpack/Socks/Shoes | Cosmetic.Slot.Clothing.Underwear.Leg/Top/Bottom
--   Accessories > Cosmetic.Slot.Accessory.Head.Hat | Cosmetic.Slot.Accessory.Face.Mask/Eyewear | Cosmetic.Slot.Accessory.Neck.Necklace | Cosmetic.Slot.Accessory.Ears.Earrings | Cosmetic.Slot.Accessory.Hands.Nails/Gloves
local SHOP_TYPES = {
    -- Clothing store: only Outfits
    clothing    = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Accessories":{}},"Visibility":false,"Default":"Outfits"}',
    -- Barbershop: Head (Hair, Eyes, Makeup) — no face presets, no head shape, no face tattoos
    barbershop  = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Preset.Head":{},"Cosmetic.Slot.Body.Head":{},"Cosmetic.Slot.Appearance.Skin.FaceTattoo":{}},"Body":{},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Head"}',
    -- Tattoo parlor: Face tattoos and body tattoos only
    tattoo      = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Preset.Head":{},"Cosmetic.Slot.Body.Head":{},"Cosmetic.Slot.Appearance.Eyes":{},"Cosmetic.Slot.Appearance.Hair":{},"Cosmetic.Slot.Appearance.Makeup":{}},"Body":{"Cosmetic.Preset.Body":{}},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Body"}',
    -- Surgeon: structural face changes (face presets, head shape, eyes) — no hair, no makeup, no tattoos
    surgeon     = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{"Cosmetic.Slot.Appearance.Hair":{},"Cosmetic.Slot.Appearance.Makeup":{},"Cosmetic.Slot.Appearance.Skin.FaceTattoo":{}},"Body":{},"Outfits":{},"Accessories":{}},"Visibility":false,"Default":"Head"}',
    -- Accessories store: only the Accessories tab
    accessories = '{"Widgets":{"Gender":{},"Custom":{},"Presets":{},"Head":{},"Body":{},"Outfits":{}},"Visibility":false,"Default":"Accessories"}',
}

local function OpenClothing(shopType)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local System = pawn:GetCosmeticsSystem()
    if not System then return end
    local onFinished
    onFinished = function(bCancelled)
        System:UnbindOnCosmeticsCustomizationFinished(onFinished)
        if not bCancelled then
            TriggerServerEvent('qb-clothing:server:SaveSkin', SerializeSkin(System))
        end
    end
    System:BindOnCosmeticsCustomizationFinished(onFinished)
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
    TriggerCallback('GetPlayerSkin', function(skinJson)
        WaitForCosmeticsAndRun(function(System)
            if skinJson then
                ApplySkinToSystem(System, skinJson)
            else
                Timer.SetTimeout(function()
                    System:ShowCharacterCustomizationUI()
                end, 3000)
            end
        end)
    end)
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

-- Descriptor table drives zone registration for every shop category.
-- Add a new row here (and a matching Config table) to support a new shop type.
local SHOP_DEFS = {
    { configKey = 'ClothingShops',    shopType = 'clothing',    zonePrefix = 'clothingShop',    targetIcon = 'shirt',       markerIcon = 'clothing-store', markerDesc = 'Browse & purchase clothing' },
    { configKey = 'Barbershops',      shopType = 'barbershop',  zonePrefix = 'barbershop',      targetIcon = 'scissors',    markerIcon = 'hairdresser',    markerDesc = 'Haircuts & styling' },
    { configKey = 'TattooShops',      shopType = 'tattoo',      zonePrefix = 'tattooShop',      targetIcon = 'pen',         markerIcon = 'art-gallery',    markerDesc = 'Tattoo parlor' },
    { configKey = 'PlasticSurgeons',  shopType = 'surgeon',     zonePrefix = 'plasticSurgeon',  targetIcon = 'stethoscope', markerIcon = 'hospital',       markerDesc = 'Cosmetic surgery' },
    { configKey = 'AccessoriesShops', shopType = 'accessories', zonePrefix = 'accessoriesShop', targetIcon = 'gem',         markerIcon = 'jewelry-store',  markerDesc = 'Accessories & jewelry' },
}

local function RegisterAllShopZones()
    for _, def in ipairs(SHOP_DEFS) do
        ---@diagnostic disable-next-line: assign-type-mismatch
        local shops = Config[def.configKey] or {}
        for id, shop in pairs(shops) do
            RegisterShopZone(def.zonePrefix .. '_' .. id, shop.coords, shop.heading, {
                {
                    type     = 'client',
                    event    = 'qb-clothing:client:OpenShop',
                    icon     = def.targetIcon,
                    label    = shop.label,
                    shopId   = id,
                    shopType = shop.type or def.shopType,
                },
            })
            local markerId = exports['qb-hud']:AddMarker(shop.coords, {
                title       = shop.label or '',
                description = shop.description or def.markerDesc or '',
                icon        = def.markerIcon or 'store',
                markerType  = 'Store',
            })
            if markerId then shopMarkers[#shopMarkers + 1] = markerId end
        end
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
    UnregisterAllShopZones()
end)

-- Single event for all shop types; shopType comes from the target zone data
RegisterClientEvent('qb-clothing:client:OpenShop', function(data)
    OpenClothing(data and data.shopType)
end)
