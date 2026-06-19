local Lang = require('locales/en')

-- State
local isWearingSuit = false
local OxygenLevel = 0
local oxygenTimer = nil
local oxygenDisplayTimer = nil

local CurrentDivingLocation = {
    area = 0,
    markers = {},
}

-- Helpers

local function Notify(text, ntype)
    exports['qb-core']:Notify(text, ntype or 'primary')
end

-- Oxygen display

local function stopOxygenDisplay()
    if oxygenDisplayTimer then
        Timer.ClearInterval(oxygenDisplayTimer)
        oxygenDisplayTimer = nil
    end
    exports['qb-core']:HideText()
end

local function startOxygenDisplay()
    if oxygenDisplayTimer then
        return
    end
    oxygenDisplayTimer = Timer.SetInterval(function()
        if isWearingSuit and OxygenLevel > 0 then
            exports['qb-core']:DrawText(OxygenLevel .. ' O2', 'right')
        else
            stopOxygenDisplay()
        end
    end, 1000)
end

-- Oxygen drain

local function stopOxygenDrain()
    if oxygenTimer then
        Timer.ClearInterval(oxygenTimer)
        oxygenTimer = nil
    end
end

local function startOxygenDrain()
    if oxygenTimer then
        return
    end
    oxygenTimer = Timer.SetInterval(function()
        if not isWearingSuit then
            stopOxygenDrain()
            return
        end
        OxygenLevel = OxygenLevel - 1
        if OxygenLevel <= 0 then
            OxygenLevel = 0
            isWearingSuit = false
            stopOxygenDrain()
            stopOxygenDisplay()
            Notify(Lang.t('error.need_otube'), 'error')
        elseif OxygenLevel == 60 then
            Notify(Lang.t('warning.oxygen_one_minute'), 'warning')
        elseif OxygenLevel == 30 then
            Notify(Lang.t('warning.oxygen_running_out'), 'warning')
        end
    end, 1000)
end

-- Cop alert

local function callCops()
    if math.random() > Config.CopsChance then
        return
    end
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end
    local c = GetEntityCoords(pawn)
    TriggerServerEvent('qb-diving:server:CallCops', { X = c.X, Y = c.Y, Z = c.Z })
end

-- Coral collection

local function takeCoral(coral)
    local coralData = Config.CoralLocations[CurrentDivingLocation.area]
    if not coralData then
        return
    end
    if coralData.coords.Coral[coral].PickedUp then
        return
    end
    callCops()
    coralData.coords.Coral[coral].PickedUp = true
    TriggerServerEvent('qb-diving:server:TakeCoral', CurrentDivingLocation.area, coral, true)
end

-- Selling

local function sellCoral()
    TriggerServerEvent('qb-diving:server:SellCorals')
end

-- Map markers

local function clearDivingMarkers()
    for _, id in ipairs(CurrentDivingLocation.markers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    CurrentDivingLocation.markers = {}
end

-- Location setup

local function setDivingLocation(divingLocation)
    if CurrentDivingLocation.area ~= 0 then
        for k in pairs(Config.CoralLocations[CurrentDivingLocation.area].coords.Coral) do
            exports['qb-target']:RemoveZone('diving_coral_zone_' .. k)
        end
    end

    clearDivingMarkers()
    CurrentDivingLocation.area = divingLocation

    local areaCoords = Config.CoralLocations[divingLocation].coords.Area
    local id = exports['qb-hud']:AddMarker(areaCoords, {
        title = Lang.t('info.diving_area'),
        markerType = 'Dive',
        size = 1.5,
    })
    CurrentDivingLocation.markers[#CurrentDivingLocation.markers + 1] = id

    for k, v in pairs(Config.CoralLocations[divingLocation].coords.Coral) do
        exports['qb-target']:AddBoxZone('diving_coral_zone_' .. k, v.coords, v.length, v.width, {
            name = 'diving_coral_zone_' .. k,
            heading = v.heading,
            debugPoly = false,
            minZ = v.coords.Z - 3,
            maxZ = v.coords.Z + 2,
        }, {
            options = {
                {
                    label = Lang.t('info.collect_coral'),
                    icon = 'fa-solid fa-water',
                    action = function()
                        takeCoral(k)
                    end,
                },
            },
            distance = 2.0,
        })
    end
end

-- Seller NPC

local function createSeller()
    for i = 1, #Config.SellLocations do
        local current = Config.SellLocations[i]
        HPawn(current.coords, Rotator(0, current.heading or 0, 0), function(npc)
            if not npc then
                return
            end
            exports['qb-target']:AddTargetEntity(npc, {
                options = {
                    {
                        label = Lang.t('info.sell_coral'),
                        icon = 'fa-solid fa-dollar-sign',
                        action = function()
                            sellCoral()
                        end,
                    },
                },
                distance = 2.0,
            })
        end)
    end
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerCallback('qb-diving:server:GetDivingConfig', function(result)
        if not result then
            return
        end
        Config.CoralLocations = result.locations
        setDivingLocation(result.area)
        createSeller()
    end)
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearDivingMarkers()
    isWearingSuit = false
    stopOxygenDrain()
    stopOxygenDisplay()
    OxygenLevel = 0
end)

RegisterClientEvent('qb-diving:client:NewLocations', function()
    TriggerCallback('qb-diving:server:GetDivingConfig', function(result)
        if not result then
            return
        end
        Config.CoralLocations = result.locations
        setDivingLocation(result.area)
    end)
end)

RegisterClientEvent('qb-diving:client:UpdateCoral', function(area, coral, bool)
    if Config.CoralLocations[area] then
        Config.CoralLocations[area].coords.Coral[coral].PickedUp = bool
    end
end)

RegisterClientEvent('qb-diving:client:CallCops', function(coords, msg)
    Notify(Lang.t('error.911_chatmessage') .. ': ' .. msg, 'error')
    local id = exports['qb-hud']:AddMarker(Vector(coords.X, coords.Y, coords.Z), {
        title = Lang.t('info.blip_text'),
        markerType = 'Alert',
    })
    Timer.SetTimeout(function()
        exports['qb-hud']:RemoveMarker(id)
    end, 72000)
end)

RegisterClientEvent('qb-diving:client:SetOxygenLevel', function()
    if OxygenLevel == 0 then
        OxygenLevel = Config.OxygenLevel
        Notify(Lang.t('success.tube_filled'), 'success')
        TriggerServerEvent('qb-diving:server:removeItemAfterFill')
    else
        Notify(Lang.t('error.oxygenlevel', { oxygenlevel = OxygenLevel }), 'error')
    end
end)

RegisterClientEvent('qb-diving:client:UseGear', function()
    if not isWearingSuit then
        if OxygenLevel <= 0 then
            Notify(Lang.t('error.need_otube'), 'error')
            return
        end
        isWearingSuit = true
        startOxygenDrain()
        startOxygenDisplay()
    else
        isWearingSuit = false
        stopOxygenDrain()
        stopOxygenDisplay()
        Notify(Lang.t('success.took_out'), 'success')
    end
end)

function onShutdown()
    clearDivingMarkers()
    stopOxygenDrain()
    stopOxygenDisplay()
end
