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

-- Opens the character customization UI and saves on close
local function OpenClothing()
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
    System:ShowCharacterCustomizationUI()
end

-- Serializes the current cosmetics and persists to the server
local function SaveCurrentSkin()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local System = pawn:GetCosmeticsSystem()
    if not System then return end
    TriggerServerEvent('qb-clothing:server:SaveSkin', SerializeSkin(System))
end

-- Fetches saved skin from the server and applies it; opens customization if none exists
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

exports('qb-clothing', 'OpenClothing',    OpenClothing)
exports('qb-clothing', 'SaveCurrentSkin', SaveCurrentSkin)
exports('qb-clothing', 'LoadAndApplySkin', LoadAndApplySkin)

-- Shop / barbershop target zone registration

local registeredZones = {}
local shopMarkers = {}

local function RegisterShopZone(zoneId, coords, heading, options)
    if registeredZones[zoneId] then return end
    exports['qb-target']:AddBoxZone(zoneId, coords, 1.5, 1.5, {
        name     = zoneId,
        heading  = heading or 0,
        distance = 2.5,
    }, options)
    registeredZones[zoneId] = true
end

local function RegisterAllShopZones()
    for id, shop in pairs(Config.ClothingShops or {}) do
        RegisterShopZone('clothingShop_' .. id, shop.coords, shop.heading, {
            {
                type   = 'client',
                event  = 'qb-clothing:client:OpenShop',
                icon   = 'shirt',
                label  = shop.label,
                shopId = id,
            },
        })
        local markerId = exports['qb-hud']:AddMarker(shop.coords, {
            title      = shop.label,
            icon       = 'clothing-store',
            markerType = 'Store',
        })
        if markerId then shopMarkers[#shopMarkers + 1] = markerId end
    end

    for id, shop in pairs(Config.Barbershops or {}) do
        RegisterShopZone('barbershop_' .. id, shop.coords, shop.heading, {
            {
                type   = 'client',
                event  = 'qb-clothing:client:OpenBarbershop',
                icon   = 'scissors',
                label  = shop.label,
                shopId = id,
            },
        })
        local markerId = exports['qb-hud']:AddMarker(shop.coords, {
            title      = shop.label,
            icon       = 'hairdresser',
            markerType = 'Store',
        })
        if markerId then shopMarkers[#shopMarkers + 1] = markerId end
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

-- Opens the full character creator; slot list in Config available for future filtered UI
RegisterClientEvent('qb-clothing:client:OpenShop', function(_)
    OpenClothing()
end)

RegisterClientEvent('qb-clothing:client:OpenBarbershop', function(_)
    OpenClothing()
end)
