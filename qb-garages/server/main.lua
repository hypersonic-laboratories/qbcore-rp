local SharedVehicles = exports['qb-core']:GetShared('Vehicles')
local OutsideVehicles = {}

-- Handler

Timer.CreateThread(function()
    Wait(100)
    if Config['AutoRespawn'] then
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE player_vehicles SET state = 1 WHERE state = 0', {})
    else
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE player_vehicles SET depotprice = 500 WHERE state = 0', {})
    end
end)

-- Functions

local function arrayToSet(array)
    local set = {}
    for _, item in ipairs(array) do
        set[item] = true
    end
    return set
end

local function filterVehiclesByCategory(vehicles, category)
    local filtered = {}
    local categorySet = arrayToSet(category)

    for _, vehicle in pairs(vehicles) do
        local vehicleData = SharedVehicles[vehicle.vehicle]
        local vehicleCategoryString = vehicleData and vehicleData.category or 'compacts'
        local vehicleCategoryNumber = vehicleClasses[vehicleCategoryString]

        if vehicleCategoryNumber and categorySet[vehicleCategoryNumber] then
            filtered[#filtered + 1] = vehicle
        end
    end

    return filtered
end

local function GetSpawnPoint(garageIndex)
    local location = nil
    local garage = Config.Garages[garageIndex]
    if not garage then return end
    if #garage.spawnPoint > 1 then
        local maxTries = #garage.spawnPoint
        for _ = 1, maxTries do
            local randomIndex = math.random(1, #garage.spawnPoint)
            local chosenSpawnPoint = garage.spawnPoint[randomIndex]
            local isOccupied = IsAreaClearOfVehicles(chosenSpawnPoint.coords, 500)
            if not isOccupied then
                location = chosenSpawnPoint
                break
            end
        end
    elseif #garage.spawnPoint == 1 then
        location = garage.spawnPoint[1]
    end

    return location
end

local function updateVehicleState(state, plate, citizenid)
    exports['qb-core']:DatabaseAction('Execute', 'UPDATE player_vehicles SET state = ?, depotprice = ? WHERE plate = ? AND citizenid = ?', {state, 0, plate, citizenid})
end

-- Callbacks

--[[ QBCore.Functions.CreateCallback('qb-garages:server:getHouseGarage', function(_, cb, house)
    local houseInfo = MySQL.single.await('SELECT * FROM houselocations WHERE name = ?', { house })
    cb(houseInfo)
end) ]]

RegisterCallback('server.GetGarageVehicles', function(source, garage)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local citizenId = Player.PlayerData.citizenid

    local vehicles
    local garageType = Config.Garages[garage].type

    if garageType == 'depot' then
        vehicles = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM player_vehicles WHERE citizenid = ? AND depotprice > 0', { citizenId })
    elseif Config.SharedGarages then
        vehicles = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM player_vehicles WHERE citizenid = ? AND depotprice <= 0', { citizenId })
    else
        vehicles = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM player_vehicles WHERE citizenid = ? AND garage = ? AND depotprice <= 0', { citizenId, garage })
    end

    if not vehicles or #vehicles == 0 then
        return
    end
    if Config.ClassSystem then
        local category = Config.Garages[garage].category
        local filteredVehicles = filterVehiclesByCategory(vehicles, category)
        return filteredVehicles
    else
        return vehicles
    end
end)

local function GetVehicleTypeByModel(model)
    local vehicleData = SharedVehicles[model]
    if not vehicleData then return 'automobile' end
    local category = vehicleData.category
    local vehicleType = vehicleTypes[category]
    return vehicleType or 'automobile'
end

-- Spawns a vehicle at the relevant garage, if a spot is free
RegisterServerEvent('qb-garages:server:SpawnVehicle', function(source, plate, index, vehicleName, fuel)
    if OutsideVehicles[plate] and OutsideVehicles[plate].entity:IsValid() then
        exports['qb-core']:Notify(source, Lang:t('error.not_depot'), 'error', 5000)
        return false
    end

    local SpawnPoint = GetSpawnPoint(index)
    if not SpawnPoint then
        exports['qb-core']:Notify(source, Lang:t('error.no_spawn'), 'error')
        return false
    end

    -- @TODO Amend to support vehicle mods
    local Player = exports['qb-core']:GetPlayer(source)
    local results = exports['qb-core']:DatabaseAction('Select', 
        'SELECT citizenid, fuel FROM player_vehicles WHERE plate = ? and citizenid = ? LIMIT 1', 
        { plate,  Player.PlayerData.citizenid}
    )
    if not results or #results <= 0 then return end

    -- @TODO Set Vehicle Mods, Plate
    local vehicle = HVehicle(SpawnPoint.coords, Rotator(0, SpawnPoint.heading, 0), SharedVehicles[vehicleName].asset_name)
    vehicle:SetPlate(plate)
    vehicle:SetFuel(tonumber(results[1].fuel) or 1.0)
    updateVehicleState(0, plate, Player.PlayerData.citizenid)
    OutsideVehicles[plate] = { entity = vehicle }

    if Config.Warp then
        -- @TODO Vehicle Warping
--[[         local Pawn = GetPlayerPawn(source)
        if Pawn then
            local AS = Pawn:GetLyraAbilitySystemComponent()

            local EventData = UE.FGameplayEventData()
            EventData.EventMagnitude = 0
            EventData.Instigator = Pawn
            EventData.Target = vehicle

            local Ability = UE.UClass.Load('/Game/SimpleVehicle/Blueprints/Abilities/GA_Vehicle_Enter.GA_Vehicle_Enter_C')
            local Spec = AS:K2_GiveAbility(Ability, nil, nil)
            AS:ServerTryActivateAbilityWithEventData(Spec, false, UE.FPredictionKey(), EventData)
        end ]]
    end

    if Config.VisuallyDamageCars then
        -- @TODO Visual Vehicle Damage
    end
    
    return true
end)

RegisterServerEvent('qb-garages:server:DepositVehicle', function(source, garage)
    local playerVehicle = GetVehiclePedIsIn(GetPlayerPawn(source))
    if not playerVehicle then return end

    local Player = exports['qb-core']:GetPlayer(source)
    local plate = playerVehicle:GetPlate()
    local results = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid, plate, state FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    if not results or #results <= 0 then return end

    local vehResult = results[1]
    if vehResult.citizenid ~= Player.PlayerData.citizenid then return end
    if state == 1 then return end

    if Config.Garages[garage].type == 'house' and not exports['qb-houses']:hasKey(Player.PlayerData.license, Player.PlayerData.citizenid, Config.Garages[garage].houseName) then
        return
    end

    -- @TODO Get Vehicle Mod Properties. Get Body Health
    local fuel = playerVehicle:GetFuelRatio() or 1.0
    local engine = playerVehicle:GetEngineHealth() or 1.0
    local body = 1.0

    local VehInteractionComp = playerVehicle.Door_FL:GetInteractionComponent()
    local Seats = playerVehicle:K2_GetComponentsByClass(UE.UClass.Load('/Game/SimpleVehicle/Blueprints/Components/SimpleVehicleSeat.SimpleVehicleSeat_C'))
    for k, v in pairs(Seats) do
        local Occupier = v:GetSeatOccupancy()
        if Occupier then
            local AS = Occupier:GetLyraAbilitySystemComponent()
            local Abilities = AS.ActivatableAbilities
            for k, v in pairs(Abilities.Items) do
                if v.Ability:GetName() == 'Default__GA_Vehicle_Exit_C' then
                    AS:ServerTryActivateAbilityWithEventData(v.Handle, true, UE.FPredictionKey(), UE.FGameplayEventData())
                    break
                end
            end
        end
    end

    local success = DeleteVehicle(playerVehicle)
    if not success then return end

    OutsideVehicles[plate] = nil
    exports['qb-core']:DatabaseAction('Execute', 
        'UPDATE player_vehicles SET fuel = ?, engine = ?, body = ?, state = ?, garage = ? WHERE plate = ? and citizenid = ?', 
        { fuel, engine, body, 1, garage, plate, Player.PlayerData.citizenid }
    )
end)

-- Events

--[[ RegisterNetEvent('qb-garages:server:updateVehicleStats', function(plate, fuel, engine, body)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    MySQL.update('UPDATE player_vehicles SET fuel = ?, engine = ?, body = ? WHERE plate = ? AND citizenid = ?', { fuel, engine, body, plate, Player.PlayerData.citizenid })
end)]]

RegisterServerEvent('qb-garages:server:updateVehicleState', function(source, state, plate)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    updateVehicleState(state, plate, Player.PlayerData.citizenid)
end)

--[[
RegisterNetEvent('qb-garages:server:trackVehicle', function(plate)
    local src = source
    local vehicleData = OutsideVehicles[plate]
    if vehicleData and DoesEntityExist(vehicleData.entity) then
        TriggerClientEvent('qb-garages:client:trackVehicle', src, GetEntityCoords(vehicleData.entity))
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.vehicle_tracked'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehicle_not_tracked'), 'error')
    end
end)]]

RegisterServerEvent('qb-garages:server:PayDepotPrice', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    local cashBalance = Player.PlayerData.money.cash
    local bankBalance = Player.PlayerData.money.bank
    local results = exports['qb-core']:DatabaseAction('Select', 'SELECT depotprice FROM player_vehicles WHERE plate = ?', { data.plate })
    
    if results[1] then
        local depotPrice = tonumber(results[1].depotprice)
        local moneyType = (cashBalance >= depotPrice and 'cash') or (bankBalance >= depotPrice and 'bank')
        if not moneyType then
            TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.not_enough'), 'error')
            return
        end

        local success = exports['qb-core']:Player(source, 'RemoveMoney', moneyType, depotPrice, 'paid-depot')
        if not success then return end
        TriggerLocalServerEvent('qb-garages:server:SpawnVehicle', source, data.plate, data.index, data.vehicle, data.stats.fuel)
    end
end)

-- House Garages

--[[ RegisterNetEvent('qb-garages:server:syncGarage', function(updatedGarages)
    Config.Garages = updatedGarages
end) ]]

--Call from qb-phone

RegisterCallback('GetPlayerVehicles', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local Vehicles = {}

    MySQL.rawExecute('SELECT * FROM player_vehicles WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(result)
        if result[1] then
            for _, v in pairs(result) do
                local VehicleData = SharedVehicles[v.vehicle]

                local VehicleGarage = Lang:t('error.no_garage')
                if v.garage ~= nil then
                    if Config.Garages[v.garage] ~= nil then
                        VehicleGarage = Config.Garages[v.garage].label
                    else
                        VehicleGarage = Lang:t('info.house')
                    end
                end

                local stateTranslation
                if v.state == 0 then
                    stateTranslation = Lang:t('status.out')
                elseif v.state == 1 then
                    stateTranslation = Lang:t('status.garaged')
                elseif v.state == 2 then
                    stateTranslation = Lang:t('status.impound')
                end

                local fullname
                if VehicleData and VehicleData['brand'] then
                    fullname = VehicleData['brand'] .. ' ' .. VehicleData['name']
                else
                    fullname = VehicleData and VehicleData['name'] or 'Unknown Vehicle'
                end

                Vehicles[#Vehicles + 1] = {
                    fullname = fullname,
                    brand = VehicleData and VehicleData['brand'] or '',
                    model = VehicleData and VehicleData['name'] or '',
                    plate = v.plate,
                    garage = VehicleGarage,
                    state = stateTranslation,
                    fuel = v.fuel,
                    engine = v.engine,
                    body = v.body
                }
            end
            return Vehicles
        else
            return
        end
    end)
end)

local function getAllGarages()
    local garages = {}
    for k, v in pairs(Config.Garages) do
        garages[#garages + 1] = {
            name = k,
            label = v.label,
            type = v.type,
            takeVehicle = v.takeVehicle,
            putVehicle = v.putVehicle,
            spawnPoint = v.spawnPoint,
            showBlip = v.showBlip,
            blipName = v.blipName,
            blipNumber = v.blipNumber,
            blipColor = v.blipColor,
            vehicle = v.vehicle
        }
    end
    return garages
end

exports('qb-garages', 'getAllGarages', getAllGarages)