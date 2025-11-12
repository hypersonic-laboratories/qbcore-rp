local Lang = require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')

-- Functions

function onShutdown()
    for _, shopData in pairs(Config.Shops) do
        local vehicles = shopData['ShowroomVehicles']
        for i = 1, #vehicles do
            local vehicleData = vehicles[i]
            local location = vehicleData['coords'].location
            ClearAreaOfVehicles(location)
        end
    end
end

-- Spawn Vehicles

for _, shopData in pairs(Config.Shops) do
    local vehicles = shopData['ShowroomVehicles']
    for i = 1, #vehicles do
        local vehicleData  = vehicles[i]
        local vehicleInfo  = Vehicles[vehicleData['defaultVehicle']]
        local vehicleClass = vehicleInfo['asset_name']
        local location     = vehicleData['coords'].location
        local rotation     = vehicleData['coords'].rotation
        local vehicle      = HVehicle(location, rotation, vehicleClass)
        vehicle:SetSimulationEnabledForHelixEntity(false)
    end
end

-- Events

RegisterServerEvent('qb-vehicleshop:server:testDrive', function(_, data)
    local shop = data.shop
    local index = data.index
    local shopData = Config.Shops[shop]
    local coords = shopData['TestDriveSpawn']
    local vehicle = shopData['ShowroomVehicles'][index]['chosenVehicle']
    local vehicleInfo = Vehicles[vehicle]
    local vehicleClass = vehicleInfo['asset_name']
    local location = coords.location
    local rotation = coords.rotation
    HVehicle(location, rotation, vehicleClass)
end)

RegisterServerEvent('qb-vehicleshop:server:swapVehicle', function(_, data)
    local vehicleName  = data.vehicle
    local shop         = data.shop
    local index        = data.index
    local vehicleInfo  = Vehicles[vehicleName]
    local vehicleClass = vehicleInfo['asset_name']
    local location     = Config.Shops[shop]['ShowroomVehicles'][index]['coords'].location
    local rotation     = Config.Shops[shop]['ShowroomVehicles'][index]['coords'].rotation
    ClearAreaOfVehicles(location)
    local vehicle = HVehicle(location, rotation, vehicleClass)
    vehicle:SetSimulationEnabledForHelixEntity(false)
    Config.Shops[shop]['ShowroomVehicles'][index]['chosenVehicle'] = vehicleName
end)

RegisterServerEvent('qb-vehicleshop:server:purchaseVehicle', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local cash = Player.PlayerData.money.cash
    local bank = Player.PlayerData.money.bank

    local shop = data.shop
    local index = data.index
    local vehicle = Config.Shops[shop]['ShowroomVehicles'][index]['chosenVehicle']
    local spawnLocation = Config.Shops[shop]['VehicleSpawn']
    local vehicleInfo = Vehicles[vehicle]
    local price = vehicleInfo['price']

    local moneyType
    if cash >= price then moneyType = 'cash' elseif bank >= price then moneyType = 'bank' else moneyType = nil end

    if not moneyType then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.notenoughmoney'), 'error')
        return
    end

    local plate = exports['qb-core']:GeneratePlate()
    exports['qb-core']:Player(source, 'RemoveMoney', moneyType, price, 'vehicle-purchase')
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_vehicles (license, citizenid, vehicle, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        vehicle,
        '{}',
        plate,
        'apartments',
        0
    })
    local pVehicle = HVehicle(spawnLocation.location, spawnLocation.rotation, vehicleInfo.asset_name)
    pVehicle:SetPlate(plate)
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('success.purchased'), 'success')
end)

-- Callbacks
