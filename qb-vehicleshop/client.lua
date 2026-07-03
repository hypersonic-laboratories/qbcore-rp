local Lang = require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')
local player_data = {}
local testDriveVeh, inTestDrive = 0, false
local shopMarkers = {}

local function clearShopMarkers()
    for _, id in ipairs(shopMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    shopMarkers = {}
end

-- Handlers

local function setupTargets()
    for shop, shopData in pairs(Config.Shops) do
        local vehicles = shopData['ShowroomVehicles']

        if shopData['ShowBlip'] then
            local markerId = exports['qb-hud']:AddMarker(shopData['BlipCoords'], {
                title = shopData['Label'] or shop,
                description = shopData['Description'] or '',
                icon = shopData['BlipIcon'] or 'car-rental',
                color = shopData['BlipColor'],
                markerType = 'Store',
            })
            if markerId then
                shopMarkers[#shopMarkers + 1] = markerId
            end
        end

        exports['qb-target']:AddSphereZone(shop .. '_finance', shopData['FinanceZone'], 0, {
            name = shop .. '_finance',
            useMesh = true,
            debug = true,
            distance = 1000,
        }, {
            {
                icon = 'clipboard',
                label = 'Manage Financed Vehicles',
                type = 'server',
                event = 'qb-vehicleshop:server:manageFinancedVehicles',
                shop = shop,
            },
        })

        for i = 1, #vehicles do
            local vehicleData = vehicles[i]

            local options = {
                {
                    type = 'server',
                    event = 'qb-vehicleshop:server:testDrive',
                    icon = 'timer',
                    label = Lang.t('menus.test_header'),
                    shop = shop,
                    index = i,
                },
                {
                    icon = 'shuffle',
                    label = 'Swap Vehicle',
                    event = 'qb-vehicleshop:client:vehMenu',
                    shop = shop,
                    index = i,
                },
                {
                    icon = 'dollar-sign',
                    label = 'Purchase Vehicle',
                    type = 'server',
                    event = 'qb-vehicleshop:server:purchaseVehicle',
                    shop = shop,
                    index = i,
                },
            }

            local zoneName = 'vehicle_shop_' .. shop .. '_' .. i
            local coords = vehicleData['targetZone'] or vehicleData['coords'].location

            exports['qb-target']:AddSphereZone(zoneName, coords, 0, {
                name = zoneName,
                useMesh = true,
                debug = true,
                distance = 1000,
            }, options)
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    player_data = exports['qb-core']:GetPlayerData()
    setupTargets()
    -- local citizenid = player_data.citizenid
    -- TriggerServerEvent('qb-vehicleshop:server:addPlayer', citizenid)
    -- TriggerServerEvent('qb-vehicleshop:server:checkFinance')
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    clearShopMarkers()
end)

-- Functions

-- Events

RegisterClientEvent('qb-vehicleshop:client:vehMenu', function(data)
    local shop = data.shop
    local index = data.index
    local vehMenu = {
        {
            isMenuHeader = true,
            header = 'Vehicles',
            icon = 'car',
        },
    }

    for vehicleName, vehicleData in pairs(Vehicles) do
        vehMenu[#vehMenu + 1] = {
            header = vehicleData.label,
            params = {
                isServer = true,
                event = 'qb-vehicleshop:server:swapVehicle',
                args = {
                    vehicle = vehicleName,
                    shop = shop,
                    index = index,
                },
            },
        }
    end

    exports['qb-menu']:openMenu(vehMenu, Config.SortAlphabetically, true)
end)
