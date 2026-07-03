local Lang = require('locales/en')
local my_webui = WebUI('qb-vehiclesales', 'qb-vehiclesales/html/ui.html')

local activeZone = Config.DefaultZone
local saleZoneTargets = {}
local saleMarkers = {}
local displayTargets = {}
local currentVehicle = nil
local initialized = false

local function getZone(zoneName)
    return Config.Zones[zoneName] or Config.Zones[Config.DefaultZone]
end

local function vehiclePayload(vehicleData)
    if not vehicleData then
        return nil
    end

    return {
        zone = vehicleData.zone or Config.DefaultZone,
        price = tonumber(vehicleData.price) or 0,
        owner = vehicleData.owner or vehicleData.seller,
        seller = vehicleData.seller or vehicleData.owner,
        model = vehicleData.model,
        plate = vehicleData.plate,
        oid = vehicleData.oid or vehicleData.occasionid,
        occasionid = vehicleData.occasionid or vehicleData.oid,
        desc = vehicleData.desc or vehicleData.description or '',
        description = vehicleData.description or vehicleData.desc or '',
        mods = vehicleData.mods or '{}',
    }
end

local function closeUi()
    if not my_webui then
        return
    end

    my_webui:SetInputMode(0)
end

local function openSellContract(plate)
    if not my_webui then
        return
    end

    local zone = getZone(activeZone)
    local playerData = exports['qb-core']:GetPlayerData() or {}
    local charinfo = playerData.charinfo or {}

    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('sellVehicle', {
        action = 'sellVehicle',
        showTakeBackOption = false,
        bizName = zone.BusinessName,
        sellerData = {
            firstname = charinfo.firstname or '',
            lastname = charinfo.lastname or '',
            account = charinfo.account or playerData.citizenid or '',
            phone = charinfo.phone or '',
        },
        plate = plate or '',
    })
end

local function openBuyContract(sellerData, vehicleData)
    if not my_webui then
        return
    end

    local zone = getZone(vehicleData.zone)
    local playerData = exports['qb-core']:GetPlayerData() or {}
    local sellerInfo = sellerData or {}
    local charinfo = sellerInfo.charinfo or {}

    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('buyVehicle', {
        action = 'buyVehicle',
        showTakeBackOption = sellerInfo.citizenid ~= nil and sellerInfo.citizenid == playerData.citizenid,
        bizName = zone.BusinessName,
        sellerData = {
            firstname = charinfo.firstname or Lang.t('charinfo.firstname'),
            lastname = charinfo.lastname or Lang.t('charinfo.lastname'),
            account = charinfo.account or Lang.t('charinfo.account'),
            phone = charinfo.phone or Lang.t('charinfo.phone'),
        },
        vehicleData = {
            desc = vehicleData.desc or '',
            price = vehicleData.price or 0,
        },
        plate = vehicleData.plate or '',
    })
end

local function clearDisplayTargets()
    for actor in pairs(displayTargets) do
        exports['qb-target']:RemoveTargetEntity(actor)
    end
    displayTargets = {}
end

local function registerDisplayVehicles(vehicles)
    clearDisplayTargets()

    if type(vehicles) ~= 'table' then
        return
    end

    for _, vehicleData in ipairs(vehicles) do
        local actor = vehicleData.actor
        if actor then
            displayTargets[actor] = true
            exports['qb-target']:AddTargetEntity(actor, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-vehiclesales:client:OpenContract',
                        icon = 'car',
                        label = Lang.t('menu.view_contract'),
                        vehicleData = vehiclePayload(vehicleData),
                    },
                },
                distance = 1000,
            })
        end
    end
end

local function requestDisplayVehicles()
    TriggerCallback('qb-occasions:server:getDisplayVehicles', function(vehicles)
        registerDisplayVehicles(vehicles)
    end)
end

local function setupSalesLots()
    if initialized then
        return
    end

    for zoneName, zone in pairs(Config.Zones) do
        if zone.ShowBlip ~= false then
            local markerId = exports['qb-hud']:AddMarker(zone.SellVehicle.coords, {
                title = Lang.t('info.used_vehicle_lot'),
                description = zone.Description or '',
                icon = zone.BlipIcon or 'car',
                color = zone.BlipColor,
                markerType = 'Store',
            })
            if markerId then
                saleMarkers[#saleMarkers + 1] = markerId
            end
        end

        local targetName = 'vehiclesales_sell_' .. zoneName
        exports['qb-target']:AddBoxZone(targetName, zone.SellVehicle.coords, 600, 600, {
            name = targetName,
            heading = zone.SellVehicle.heading or 0,
            minZ = zone.SellVehicle.coords.Z - 250,
            maxZ = zone.SellVehicle.coords.Z + 250,
            distance = 1000,
            useMesh = true,
        }, {
            {
                type = 'client',
                event = 'qb-occasions:client:MainMenu',
                icon = 'dollar-sign',
                label = Lang.t('menu.sell_vehicle'),
                zone = zoneName,
            },
        })

        saleZoneTargets[#saleZoneTargets + 1] = targetName
    end

    initialized = true
end

local function clearSalesLots()
    for _, targetName in ipairs(saleZoneTargets) do
        exports['qb-target']:RemoveZone(targetName)
    end
    saleZoneTargets = {}

    for _, markerId in ipairs(saleMarkers) do
        exports['qb-hud']:RemoveMarker(markerId)
    end
    saleMarkers = {}
    initialized = false
end

function onShutdown()
    clearDisplayTargets()
    clearSalesLots()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

my_webui:RegisterEventHandler('sellVehicle', function(data)
    closeUi()
    TriggerServerEvent('qb-occasions:server:sellVehicle', data and data.price, data and data.desc)
end)

my_webui:RegisterEventHandler('buyVehicle', function()
    closeUi()
    if currentVehicle then
        TriggerServerEvent('qb-occasions:server:buyVehicle', vehiclePayload(currentVehicle))
    end
end)

my_webui:RegisterEventHandler('takeVehicleBack', function()
    closeUi()
    if currentVehicle then
        TriggerServerEvent('qb-occasions:server:ReturnVehicle', vehiclePayload(currentVehicle))
    end
end)

my_webui:RegisterEventHandler('close', function()
    closeUi()
end)

RegisterClientEvent('qb-vehiclesales:client:setVehicles', function(vehicles)
    registerDisplayVehicles(vehicles)
end)

RegisterClientEvent('qb-occasion:client:refreshVehicles', function()
    requestDisplayVehicles()
end)

RegisterClientEvent('qb-vehiclesales:client:SellVehicle', function(data)
    activeZone = data and data.zone or activeZone or Config.DefaultZone

    TriggerCallback('qb-occasions:server:canListCurrentVehicle', function(result)
        if result and result.success then
            openSellContract(result.plate)
            return
        end

        exports['qb-core']:Notify((result and result.message) or Lang.t('error.not_your_vehicle'), 'error', 3500)
    end)
end)

RegisterClientEvent('qb-occasions:client:SellBackCar', function()
    TriggerServerEvent('qb-occasions:server:sellVehicleBack')
end)

RegisterClientEvent('qb-vehiclesales:client:OpenContract', function(data)
    currentVehicle = vehiclePayload(data and data.vehicleData or data)
    if not currentVehicle then
        exports['qb-core']:Notify(Lang.t('error.not_for_sale'), 'error', 7500)
        return
    end

    activeZone = currentVehicle.zone or Config.DefaultZone
    TriggerCallback('qb-occasions:server:getSellerInformation', function(info)
        openBuyContract(info, currentVehicle)
    end, currentVehicle.owner or currentVehicle.seller)
end)

RegisterClientEvent('qb-occasions:client:MainMenu', function(data)
    activeZone = data and data.zone or Config.DefaultZone
    local zone = getZone(activeZone)

    exports['qb-menu']:openMenu({
        {
            isMenuHeader = true,
            header = zone.BusinessName,
            icon = 'car',
        },
        {
            header = Lang.t('menu.sell_vehicle'),
            txt = Lang.t('menu.sell_vehicle_help'),
            icon = 'dollar-sign',
            params = {
                event = 'qb-vehiclesales:client:SellVehicle',
                args = {
                    zone = activeZone,
                },
            },
        },
        {
            header = Lang.t('menu.sell_back'),
            txt = Lang.t('menu.sell_back_help'),
            icon = 'rotate-ccw',
            params = {
                event = 'qb-occasions:client:SellBackCar',
            },
        },
    })
end)

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    setupSalesLots()
    requestDisplayVehicles()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearDisplayTargets()
    clearSalesLots()
end)
