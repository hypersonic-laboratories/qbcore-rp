local Lang = require('locales/en')
local sharedVehicles = exports['qb-core']:GetShared('Vehicles')

local DisplayVehicles = {}

local function notify(source, message, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', message, notifyType or 'primary', length)
end

local function decodeJson(value, fallback)
    if type(value) ~= 'string' or value == '' then
        return fallback
    end

    local ok, decoded = pcall(JSON.parse, value)
    if ok and decoded ~= nil then
        return decoded
    end

    return fallback
end

local function encodeJson(value)
    return JSON.stringify(value or {})
end

local function getOccasionRows()
    return exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM occasion_vehicles ORDER BY id ASC', {}) or {}
end

local function getOccasionRow(plate, occasionId)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM occasion_vehicles WHERE plate = ? AND occasionid = ? LIMIT 1', { plate, occasionId }) or {}

    return rows[1]
end

local function getTotalVehicleSpots()
    local total = 0
    for _, zone in pairs(Config.Zones) do
        total = total + #(zone.VehicleSpots or {})
    end
    return total
end

local function getDisplaySlot(index)
    local cursor = 0
    for zoneName, zone in pairs(Config.Zones) do
        for _, spot in ipairs(zone.VehicleSpots or {}) do
            cursor = cursor + 1
            if cursor == index then
                return zoneName, spot
            end
        end
    end
end

local function getZone(zoneName)
    return Config.Zones[zoneName] or Config.Zones[Config.DefaultZone]
end

local function deleteVehicleSafe(vehicle)
    if not vehicle then
        return
    end

    local ok = pcall(function()
        DeleteVehicle(vehicle)
    end)

    if not ok and vehicle.Object then
        pcall(function()
            DeleteVehicle(vehicle.Object)
        end)
    end
end

local function clearDisplayVehicles()
    for _, display in pairs(DisplayVehicles) do
        deleteVehicleSafe(display.vehicle)
    end
    DisplayVehicles = {}
end

local function spawnHelixVehicle(model, spawn, plate, displayOnly)
    local vehicleInfo = sharedVehicles[model]
    if not vehicleInfo or not vehicleInfo.asset_name then
        print(('[qb-vehiclesales] Missing shared vehicle data for "%s"'):format(tostring(model)))
        return nil
    end

    local vehicle = HVehicle(spawn.coords, Rotator(0, spawn.heading or 0, 0), vehicleInfo.asset_name, vehicleInfo.collision_type, vehicleInfo.gravity_enabled)

    if not vehicle then
        return nil
    end

    if plate and vehicle.SetPlate then
        vehicle:SetPlate(plate)
    end
    if vehicle.SetFuel then
        vehicle:SetFuel(100.0)
    end
    if displayOnly and vehicle.SetInteractionEnabled then
        vehicle:SetInteractionEnabled(false)
    end

    return vehicle
end

local function buildDisplayPayload()
    local payload = {}

    for _, display in ipairs(DisplayVehicles) do
        local row = display.row
        payload[#payload + 1] = {
            actor = display.actor,
            zone = display.zone,
            price = tonumber(row.price) or 0,
            owner = row.seller,
            seller = row.seller,
            model = row.model,
            plate = row.plate,
            oid = row.occasionid,
            occasionid = row.occasionid,
            desc = row.description or '',
            description = row.description or '',
            mods = row.mods or '{}',
        }
    end

    return payload
end

local function spawnDisplayVehicles()
    clearDisplayVehicles()

    local rows = getOccasionRows()
    for index, row in ipairs(rows) do
        local zoneName, spot = getDisplaySlot(index)
        if not spot then
            break
        end

        local vehicle = spawnHelixVehicle(row.model, spot, row.occasionid or row.plate, true)
        if vehicle then
            DisplayVehicles[#DisplayVehicles + 1] = {
                vehicle = vehicle,
                actor = vehicle.Object or vehicle,
                zone = zoneName,
                row = row,
            }
        end
    end
end

local function syncDisplayVehicles()
    spawnDisplayVehicles()
    BroadcastEvent('qb-vehiclesales:client:setVehicles', buildDisplayPayload())
end

local function generateOID()
    for _ = 1, 20 do
        local oid = 'OC' .. tostring(math.random(1, 10)) .. tostring(math.random(111, 999))
        local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT occasionid FROM occasion_vehicles WHERE occasionid = ? LIMIT 1', { oid }) or {}
        if not rows[1] then
            return oid
        end
    end

    return 'OC' .. tostring(os.time())
end

local function getCurrentPlayerVehicle(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return nil
    end

    local vehicle = GetVehiclePedIsIn(pawn)
    if not vehicle and pawn.GetCurrentVehicle then
        local ok, currentVehicle = pcall(function()
            return pawn:GetCurrentVehicle()
        end)
        if ok then
            vehicle = currentVehicle
        end
    end

    return vehicle
end

local function getVehiclePlate(vehicle)
    if not vehicle then
        return nil
    end

    local plate
    if vehicle.GetPlate then
        local ok, result = pcall(function()
            return vehicle:GetPlate()
        end)
        if ok then
            plate = result
        end
    end

    plate = plate or vehicle.Plate
    if type(plate) ~= 'string' then
        return nil
    end

    return (plate:gsub('^%s*(.-)%s*$', '%1'))
end

local function getOwnedVehicle(source, plate)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not plate then
        return nil
    end

    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? LIMIT 1', { plate, Player.PlayerData.citizenid }) or {}

    return rows[1]
end

local function getCurrentOwnedVehicle(source)
    local currentVehicle = getCurrentPlayerVehicle(source)
    local plate = getVehiclePlate(currentVehicle)
    local ownedVehicle = getOwnedVehicle(source, plate)

    return ownedVehicle, currentVehicle, plate
end

local function canListCurrentVehicle(source)
    local ownedVehicle, currentVehicle, plate = getCurrentOwnedVehicle(source)
    if not currentVehicle or not plate then
        return { success = false, message = Lang.t('error.not_in_veh') }
    end

    if not ownedVehicle then
        return { success = false, message = Lang.t('error.not_your_vehicle') }
    end

    if tonumber(ownedVehicle.balance) and tonumber(ownedVehicle.balance) > 0 then
        return { success = false, message = Lang.t('error.finish_payments') }
    end

    local listedVehicles = getOccasionRows()
    if #listedVehicles >= getTotalVehicleSpots() then
        return { success = false, message = Lang.t('error.no_space_on_lot') }
    end

    return {
        success = true,
        ownedVehicle = ownedVehicle,
        currentVehicle = currentVehicle,
        plate = plate,
    }
end

local function spawnOwnedVehicleForPlayer(source, model, plate, zoneName)
    local zone = getZone(zoneName)
    if not zone or not zone.BuyVehicle then
        return
    end

    return spawnHelixVehicle(model, zone.BuyVehicle, plate, false)
end

local function sendSaleMail(citizenid, vehicleModel, payout)
    local vehicleInfo = sharedVehicles[vehicleModel] or {}
    local vehicleLabel = vehicleInfo.label or vehicleInfo.name or vehicleModel
    local message = Lang.t('mail.message', { value = payout, value2 = vehicleLabel })
    local mailId = tostring(math.random(100000, 999999))

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_mails (citizenid, sender, sender_number, subject, message, read, starred, mailid) VALUES (?, ?, ?, ?, ?, 0, 0, ?)', {
        citizenid,
        Lang.t('mail.sender'),
        'vehiclesales',
        Lang.t('mail.subject'),
        message,
        mailId,
    })

    local target = exports['qb-core']:GetPlayerByCitizenId(citizenid)
    if target and target.PlayerData and target.PlayerData.source then
        TriggerClientEvent(
            target.PlayerData.source,
            'qb-phone:client:emailReceived',
            JSON.stringify({
                id = tonumber(mailId),
                from = Lang.t('mail.sender'),
                fromNumber = 'vehiclesales',
                subject = Lang.t('mail.subject'),
                snippet = message,
                body = message,
                time = os.date('%H:%M'),
                read = false,
                starred = false,
            })
        )
    end
end

local function paySeller(citizenid, amount)
    local Seller = exports['qb-core']:GetPlayerByCitizenId(citizenid)
    if Seller then
        Seller.AddMoney('bank', amount, 'sold vehicle used lot')
        return true
    end

    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT money FROM players WHERE citizenid = ? LIMIT 1', { citizenid }) or {}
    if not rows[1] then
        return false
    end

    local money = decodeJson(rows[1].money, {})
    money.bank = (tonumber(money.bank) or 0) + amount

    return exports['qb-core']:DatabaseAction('Execute', 'UPDATE players SET money = ? WHERE citizenid = ?', { encodeJson(money), citizenid })
end

local function returnOccasionVehicle(source, vehicleData)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not vehicleData then
        return
    end

    local row = getOccasionRow(vehicleData.plate, vehicleData.oid or vehicleData.occasionid)
    if not row then
        notify(source, Lang.t('error.vehicle_does_not_exist'), 'error', 3500)
        return
    end

    if row.seller ~= Player.PlayerData.citizenid then
        notify(source, Lang.t('error.not_your_vehicle'), 'error', 3500)
        return
    end

    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_vehicles (license, citizenid, vehicle, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        row.model,
        row.mods or '{}',
        row.plate,
        0,
    })
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM occasion_vehicles WHERE plate = ? AND occasionid = ?', { row.plate, row.occasionid })

    spawnOwnedVehicleForPlayer(source, row.model, row.plate, vehicleData.zone)
    notify(source, Lang.t('info.vehicle_returned'), 'success', 3500)
    syncDisplayVehicles()
end

RegisterCallback('qb-occasions:server:getDisplayVehicles', function()
    return buildDisplayPayload()
end)

RegisterCallback('qb-occasions:server:getVehicles', function()
    local rows = getOccasionRows()
    if #rows == 0 then
        return nil
    end
    return rows
end)

RegisterCallback('qb-occasions:server:canListCurrentVehicle', function(source)
    local result = canListCurrentVehicle(source)
    return {
        success = result.success,
        message = result.message,
        plate = result.plate,
    }
end)

RegisterCallback('qb-occasions:server:checkVehicleOwner', function(source, plate)
    local row = getOwnedVehicle(source, plate)
    if row then
        return {
            owned = true,
            balance = tonumber(row.balance) or 0,
        }
    end

    return {
        owned = false,
        balance = 0,
    }
end)

RegisterCallback('qb-occasions:server:getSellerInformation', function(_, citizenid)
    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT citizenid, charinfo FROM players WHERE citizenid = ? LIMIT 1', { citizenid }) or {}
    local row = rows[1]
    if not row then
        return nil
    end

    row.charinfo = decodeJson(row.charinfo, {})
    return row
end)

RegisterCallback('qb-vehiclesales:server:CheckModelName', function(_, plate)
    if not plate then
        return nil
    end

    local rows = exports['qb-core']:DatabaseAction('Select', 'SELECT vehicle FROM player_vehicles WHERE plate = ? LIMIT 1', { plate }) or {}
    return rows[1] and rows[1].vehicle or nil
end)

RegisterServerEvent('qb-occasions:server:sellVehicle', function(source, vehiclePrice, vehicleDescription)
    local price = math.floor(tonumber(vehiclePrice) or 0)
    if price <= 0 then
        notify(source, Lang.t('error.not_enough_money'), 'error', 3500)
        return
    end

    local result = canListCurrentVehicle(source)
    if not result.success then
        notify(source, result.message, 'error', 3500)
        return
    end

    local Player = exports['qb-core']:GetPlayer(source)
    local ownedVehicle = result.ownedVehicle
    local description = tostring(vehicleDescription or ''):sub(1, 500)
    local occasionId = generateOID()

    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_vehicles WHERE plate = ? AND citizenid = ?', { result.plate, Player.PlayerData.citizenid })
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO occasion_vehicles (seller, price, description, plate, model, mods, occasionid) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        price,
        description,
        result.plate,
        ownedVehicle.vehicle,
        ownedVehicle.mods or '{}',
        occasionId,
    })

    deleteVehicleSafe(result.currentVehicle)
    notify(source, Lang.t('success.vehicle_listed'), 'success', 5500)
    syncDisplayVehicles()
end)

RegisterServerEvent('qb-occasions:server:sellVehicleBack', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local ownedVehicle, currentVehicle, plate = getCurrentOwnedVehicle(source)
    if not currentVehicle or not plate then
        notify(source, Lang.t('error.not_in_veh'), 'error', 4500)
        return
    end

    if not ownedVehicle then
        notify(source, Lang.t('error.not_your_vehicle'), 'error', 3500)
        return
    end

    if tonumber(ownedVehicle.balance) and tonumber(ownedVehicle.balance) > 0 then
        notify(source, Lang.t('error.finish_payments'), 'error', 3500)
        return
    end

    local vehicleInfo = sharedVehicles[ownedVehicle.vehicle] or {}
    local payout = math.floor((tonumber(vehicleInfo.price) or 0) * 0.5)

    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    deleteVehicleSafe(currentVehicle)
    Player.AddMoney('bank', payout, 'sold vehicle back')
    notify(source, Lang.t('success.sold_car_for_price', { value = payout }), 'success', 5500)
end)

RegisterServerEvent('qb-occasions:server:ReturnVehicle', function(source, vehicleData)
    returnOccasionVehicle(source, vehicleData)
end)

RegisterServerEvent('qb-occasions:server:buyVehicle', function(source, vehicleData)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not vehicleData then
        return
    end

    local row = getOccasionRow(vehicleData.plate, vehicleData.oid or vehicleData.occasionid)
    if not row then
        notify(source, Lang.t('error.vehicle_does_not_exist'), 'error', 3500)
        return
    end

    if row.seller == Player.PlayerData.citizenid then
        returnOccasionVehicle(source, vehicleData)
        return
    end

    local price = tonumber(row.price) or 0
    if (tonumber(Player.PlayerData.money.bank) or 0) < price then
        notify(source, Lang.t('error.not_enough_money'), 'error', 3500)
        return
    end

    local sellerPayout = math.ceil((price / 100) * 77)

    Player.RemoveMoney('bank', price, 'bought vehicle used lot')
    exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO player_vehicles (license, citizenid, vehicle, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        row.model,
        row.mods or '{}',
        row.plate,
        0,
    })
    exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM occasion_vehicles WHERE plate = ? AND occasionid = ?', { row.plate, row.occasionid })

    paySeller(row.seller, sellerPayout)
    sendSaleMail(row.seller, row.model, sellerPayout)
    spawnOwnedVehicleForPlayer(source, row.model, row.plate, vehicleData.zone)

    notify(source, Lang.t('success.vehicle_bought'), 'success', 3500)
    syncDisplayVehicles()
end)

RegisterServerEvent('QBCore:Server:PlayerLoaded', function(Player)
    if not Player or not Player.PlayerData then
        return
    end

    TriggerClientEvent(Player.PlayerData.source, 'qb-vehiclesales:client:setVehicles', buildDisplayPayload())
end)

function onShutdown()
    clearDisplayVehicles()
end

spawnDisplayVehicles()
