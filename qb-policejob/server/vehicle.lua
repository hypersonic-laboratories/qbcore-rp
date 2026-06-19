local Lang = require('locales/en')
local sharedVehicles = exports['qb-core']:GetShared('Vehicles') or {}

local Plates = {}

local function notify(source, text, notifyType)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType)
end

local function isLeoOnDuty(Player)
    return Player and Player.PlayerData.job and Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty
end

local function IsVehicleOwned(plate)
    local result = exports['qb-core']:DatabaseAction('Select', 'SELECT plate FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    return result and result[1]
end

local function getStation(stationKey)
    if stationKey and Config.Locations[stationKey] then
        return stationKey, Config.Locations[stationKey]
    end
    for key, station in pairs(Config.Locations) do
        return key, station
    end
    return nil, nil
end

local function isAuthorizedInGroup(Player, station, groupName, vehicleName)
    local playerGrade = Player.PlayerData.job and Player.PlayerData.job.grade and Player.PlayerData.job.grade.level or 0
    for grade = 0, playerGrade do
        if station and station[groupName] and station[groupName][grade] and station[groupName][grade][vehicleName] then
            return true
        end
    end
    return false
end

local function isAuthorizedVehicle(Player, station, vehicleName)
    return isAuthorizedInGroup(Player, station, 'authorizedVehicles', vehicleName) or isAuthorizedInGroup(Player, station, 'authorizedHelicopters', vehicleName)
end

local function isAuthorizedHelicopter(Player, station, vehicleName)
    return isAuthorizedInGroup(Player, station, 'authorizedHelicopters', vehicleName)
end

local function getSpawnPoint(station, spawnKey, fallbackListKey)
    local spawn = station and station[spawnKey]
    if spawn and spawn.coords then
        return spawn
    end

    local fallbackList = station and station[fallbackListKey]
    if fallbackList and fallbackList[1] then
        return {
            coords = fallbackList[1],
            rotation = Rotator(0, fallbackList[1].W or fallbackList[1].w or 0, 0),
        }
    end

    return nil
end

local function spawnPoliceVehicle(source, vehicleName, station, spawnKey, fallbackListKey, plate, fuel)
    if not sharedVehicles[vehicleName] then
        notify(source, ('Unknown Helix vehicle "%s"'):format(tostring(vehicleName)), 'error')
        return nil
    end

    local spawn = getSpawnPoint(station, spawnKey, fallbackListKey)
    if not spawn then
        notify(source, 'No spawn point configured for this vehicle.', 'error')
        return nil
    end

    local coords = spawn.coords or spawn
    local rotation = spawn.rotation or Rotator(0, coords.W or coords.w or 0, 0)
    local vehicle = exports['qb-core']:CreateVehicle(vehicleName, coords, rotation, plate, fuel or 100.0)
    if not vehicle then
        notify(source, 'Unable to spawn vehicle.', 'error')
        return nil
    end

    if plate and vehicle.SetPlate then
        vehicle:SetPlate(plate)
    end

    return vehicle
end

RegisterCallback('qb-policejob:GetImpoundedVehicles', function(_)
    local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM player_vehicles WHERE state = ?', { 2 })
    return result or {}
end)

RegisterCallback('qb-policejob:server:IsPlateFlagged', function(_, plate)
    return Plates and Plates[plate] and Plates[plate].isflagged or false
end)

RegisterServerEvent('qb-policejob:server:spotlight', function(source, _)
    -- TODO(helix): Helicopter spotlight sync needs Helix vehicle support.
    notify(source, 'TODO: Helicopter spotlight is not implemented in Helix yet.', 'primary')
end)

RegisterServerEvent('qb-policejob:server:Impound', function(source, plate, fullImpound, price, body, engine, fuel)
    -- TODO(helix): Vehicle impound needs Helix vehicle support. The DB update is kept
    -- for future vehicle integration when a plate is supplied by another system.
    price = price or 0
    if not plate or not IsVehicleOwned(plate) then
        notify(source, 'TODO: Vehicle impound is not implemented in Helix yet.', 'primary')
        return
    end

    if not fullImpound then
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE player_vehicles SET state = ?, depotprice = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?', { 0, price, body, engine, fuel, plate })
        notify(source, Lang.t('info.vehicle_taken_depot', { price = price }))
    else
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE player_vehicles SET state = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?', { 2, body, engine, fuel, plate })
        notify(source, Lang.t('info.vehicle_seized'))
    end
end)

RegisterServerEvent('qb-policejob:server:TakeOutVehicle', function(source, vehicleName, stationKey)
    local Player = exports['qb-core']:GetPlayer(source)
    local _, station = getStation(stationKey)
    if not isLeoOnDuty(Player) or not station or not isAuthorizedVehicle(Player, station, vehicleName) then
        return
    end

    local plate = exports['qb-core']:GeneratePlate()
    local isHelicopter = isAuthorizedHelicopter(Player, station, vehicleName)
    local vehicle = spawnPoliceVehicle(source, vehicleName, station, isHelicopter and 'helicopterSpawn' or 'vehicleSpawn', isHelicopter and 'helicopter' or 'vehicle', plate, 100.0)
    if vehicle then
        notify(source, 'Vehicle spawned', 'success')
    end
end)

RegisterServerEvent('qb-policejob:server:TakeOutImpound', function(source, plate, vehicleName, stationKey)
    local Player = exports['qb-core']:GetPlayer(source)
    local _, station = getStation(stationKey)
    if not isLeoOnDuty(Player) or not station then
        return
    end
    if not plate then
        return
    end

    local results = exports['qb-core']:DatabaseAction('Select', 'SELECT vehicle, fuel FROM player_vehicles WHERE plate = ? AND state = ? LIMIT 1', { plate, 2 })
    local vehicleData = results and results[1]
    if not vehicleData then
        notify(source, Lang.t('error.no_impound'), 'error')
        return
    end

    local vehicle = spawnPoliceVehicle(source, vehicleName or vehicleData.vehicle, station, 'vehicleSpawn', 'impound', plate, tonumber(vehicleData.fuel) or 100.0)
    if vehicle then
        exports['qb-core']:DatabaseAction('Execute', 'UPDATE player_vehicles SET state = ? WHERE plate = ?', { 0, plate })
        notify(source, Lang.t('success.impound_vehicle_removed'), 'success')
    end
end)

RegisterServerEvent('qb-policejob:server:FlaggedPlateTriggered', function(_, coords, plate)
    for _, Player in pairs(exports['qb-core']:GetQBPlayers()) do
        if isLeoOnDuty(Player) then
            local vehPlate = tostring(plate or ''):upper()
            local message = Lang.t('info.flagged_vehicle_radar', { plate = vehPlate })
            TriggerClientEvent(Player.PlayerData.source, 'qb-policejob:client:policeAlert', coords, message)
        end
    end
end)

RegisterServerEvent('qb-policejob:server:FlagPlate', function(source, plate, reason)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeoOnDuty(Player) then
        notify(source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end

    plate = tostring(plate or ''):upper()
    if plate == '' then
        return
    end

    Plates[plate] = {
        isflagged = true,
        reason = tostring(reason or ''),
    }
    notify(source, Lang.t('info.vehicle_flagged', { vehicle = plate, reason = Plates[plate].reason }))
end)

RegisterServerEvent('qb-policejob:server:UnflagPlate', function(source, plate)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeoOnDuty(Player) then
        notify(source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end

    plate = tostring(plate or ''):upper()
    if Plates and Plates[plate] and Plates[plate].isflagged then
        Plates[plate].isflagged = false
        notify(source, Lang.t('info.unflag_vehicle', { vehicle = plate }))
    else
        notify(source, Lang.t('error.vehicle_not_flag'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:PlateInfo', function(source, plate)
    local Player = exports['qb-core']:GetPlayer(source)
    if not isLeoOnDuty(Player) then
        notify(source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end

    plate = tostring(plate or ''):upper()
    if Plates and Plates[plate] and Plates[plate].isflagged then
        notify(source, Lang.t('success.vehicle_flagged', { plate = plate, reason = Plates[plate].reason }), 'success')
    else
        notify(source, Lang.t('error.vehicle_not_flag'), 'error')
    end
end)

-- TODO(helix): Original flagplate/unflagplate/plateinfo commands are intentionally
-- not registered because commands are not available in Helix.
