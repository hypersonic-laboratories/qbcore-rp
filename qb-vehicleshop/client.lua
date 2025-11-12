local Lang = require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')
local player_data = {}
local testDriveVeh, inTestDrive = 0, false

-- Handlers

local function setupTargets()
    for shop, shopData in pairs(Config.Shops) do
        local vehicles = shopData['ShowroomVehicles']
        for i = 1, #vehicles do
            local vehicleData = vehicles[i]

            local options = {
                {
                    type = 'server',
                    event = 'qb-vehicleshop:server:testDrive',
                    icon = 'fas fa-car',
                    label = Lang:t('menus.test_header'),
                    shop = shop,
                    index = i
                },
                {
                    icon = 'fas fa-shuffle',
                    label = 'Swap Vehicle',
                    event = 'qb-vehicleshop:client:vehMenu',
                    shop = shop,
                    index = i
                },
                {
                    icon = 'fas fa-basket-shopping',
                    label = 'Purchase Vehicle',
                    type = 'server',
                    event = 'qb-vehicleshop:server:purchaseVehicle',
                    shop = shop,
                    index = i
                },
            }

            local boxName = 'vehicle_shop_' .. shop .. '_' .. i
            local coords = vehicleData['coords'].location

            local boxData = {
                length = 500,
                width = 500,
                heading = 0,
                debug = true,
                distance = 1000,
            }

            exports['qb-target']:AddBoxZone(boxName, coords, boxData.length, boxData.width, {
                name = boxName,
                heading = boxData.heading,
                debug = boxData.debug,
                distance = boxData.distance,
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

-- Functions

-- Events

RegisterClientEvent('qb-vehicleshop:client:vehMenu', function(data)
    local shop = data.shop
    local index = data.index
    local vehMenu = {
        {
            isMenuHeader = true,
            header = 'Vehicles',
            icon = 'fas fa-car',
        }
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
                }
            }
        }
    end

    exports['qb-menu']:openMenu(vehMenu, Config.SortAlphabetically, true)
end)
