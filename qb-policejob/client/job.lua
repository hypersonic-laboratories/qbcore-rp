local Lang = require('locales/en')
local sharedVehicles = exports['qb-core']:GetShared('Vehicles') or {}
local currentStation = nil
local FingerPrintSessionId = nil
local jobTargetsRegistered = false

local function getPlayerIdFromEntity(entity)
    if not entity or not entity.PlayerState then
        return nil
    end
    return entity.PlayerState:GetPlayerId()
end

local function getClosestPlayerId(maxDistance)
    local pawn = GetPlayerPawn()
    if not pawn then
        return nil, -1
    end

    local closestPawn, distance = GetClosestPawn(GetEntityCoords(pawn), maxDistance or 250.0, pawn)
    if closestPawn and closestPawn.PlayerState then
        return closestPawn.PlayerState:GetPlayerId(), distance
    end

    return nil, -1
end

local function openFingerprintUI()
    if not PoliceJobUI then
        return
    end
    PoliceJobUI:BringToFront()
    PoliceJobUI:SetInputMode(1)
    PoliceJobUI:SendEvent('fingerprintOpen')
end

local function closeFingerprintUI()
    if not PoliceJobUI then
        return
    end
    PoliceJobUI:SetInputMode(0)
    PoliceJobUI:SendEvent('fingerprintClose')
end

local function notifyVehicleTodo()
    exports['qb-core']:Notify('TODO: This vehicle interaction is not implemented in Helix yet.', 'primary')
end

local function addTargetSphere(name, coords, radius, option)
    exports['qb-target']:AddSphereZone(name, coords, radius, { distance = 250, useMesh = true }, { option })
end

local function getStationKey(stationKey)
    if stationKey and Config.Locations[stationKey] then
        return stationKey
    end
    for key in pairs(Config.Locations) do
        return key
    end
    return nil
end

local function getStation(stationKey)
    stationKey = getStationKey(stationKey)
    return stationKey, stationKey and Config.Locations[stationKey] or nil
end

local function getAuthorizedVehicles(station, groupName)
    local playerData = exports['qb-core']:GetPlayerData()
    local playerGrade = playerData.job and playerData.job.grade and playerData.job.grade.level or 0
    local authorized = {}

    for grade = 0, playerGrade do
        local gradeVehicles = station and station[groupName] and station[groupName][grade]
        if gradeVehicles then
            for vehicle, label in pairs(gradeVehicles) do
                authorized[vehicle] = label
            end
        end
    end

    return authorized
end

local function getFirstAuthorizedVehicle(station, groupName)
    local authorized = getAuthorizedVehicles(station, groupName)
    for vehicle in pairs(authorized) do
        return vehicle
    end
    return nil
end

function TakeOutImpound(data)
    local vehicle = data and data.vehicle or data
    local stationKey = data and data.stationKey or currentStation
    if not vehicle then
        return
    end

    TriggerServerEvent('qb-policejob:server:TakeOutImpound', vehicle.plate, vehicle.vehicle, stationKey)
end

function TakeOutVehicle(data)
    local vehicle = data and data.vehicle or data
    local stationKey = data and data.stationKey or currentStation
    if not vehicle then
        return
    end

    TriggerServerEvent('qb-policejob:server:TakeOutVehicle', vehicle, stationKey)
end

function MenuGarage(stationKey)
    stationKey = getStationKey(stationKey)
    currentStation = stationKey or currentStation
    local _, station = getStation(stationKey)
    local vehicleMenu = {
        {
            header = Lang.t('menu.garage_title'),
            isMenuHeader = true,
        },
    }

    local authorizedVehicles = getAuthorizedVehicles(station, 'authorizedVehicles')
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            txt = station and station.label or '',
            params = {
                event = 'qb-policejob:client:TakeOutVehicle',
                args = {
                    vehicle = veh,
                    stationKey = stationKey,
                },
            },
        }
    end

    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang.t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        },
    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

function MenuImpound(stationKey)
    stationKey = getStationKey(stationKey)
    currentStation = stationKey or currentStation
    local impoundMenu = {
        {
            header = Lang.t('menu.impound'),
            isMenuHeader = true,
        },
    }

    TriggerCallback('qb-policejob:GetImpoundedVehicles', function(result)
        if not result or #result == 0 then
            exports['qb-core']:Notify(Lang.t('error.no_impound'), 'error', 5000)
            return
        end

        for _, v in pairs(result) do
            local vehicleData = sharedVehicles[v.vehicle] or {}
            impoundMenu[#impoundMenu + 1] = {
                header = (vehicleData.name or vehicleData.label or v.vehicle) .. ' [' .. v.plate .. ']',
                txt = '',
                params = {
                    event = 'qb-policejob:client:TakeOutImpound',
                    args = {
                        vehicle = v,
                        stationKey = stationKey,
                    },
                },
            }
        end

        impoundMenu[#impoundMenu + 1] = {
            header = Lang.t('menu.close'),
            txt = '',
            params = {
                event = 'qb-menu:client:closeMenu',
            },
        }
        exports['qb-menu']:openMenu(impoundMenu)
    end)
end

if PoliceJobUI then
    PoliceJobUI:RegisterEventHandler('closeFingerprint', function(_, cb)
        closeFingerprintUI()
        if cb then
            cb('ok')
        end
    end)

    PoliceJobUI:RegisterEventHandler('doFingerScan', function(_, cb)
        TriggerServerEvent('qb-policejob:server:showFingerprintId', FingerPrintSessionId)
        if cb then
            cb('ok')
        end
    end)
end

RegisterClientEvent('qb-policejob:client:showFingerprint', function(playerId)
    openFingerprintUI()
    FingerPrintSessionId = playerId
end)

RegisterClientEvent('qb-policejob:client:showFingerprintId', function(fid)
    if PoliceJobUI then
        PoliceJobUI:SendEvent('updateFingerprintId', {
            fingerprintId = fid,
        })
    end
end)

RegisterClientEvent('qb-policejob:client:SendEmergencyMessage', function(coords, message)
    TriggerServerEvent('qb-policejob:server:SendEmergencyMessage', coords, message)
    TriggerLocalClientEvent('qb-policejob:client:CallAnim')
end)

RegisterClientEvent('qb-policejob:client:EmergencySound', function()
    -- TODO(helix): Add an equivalent alert sound when an audio API is available.
end)

RegisterClientEvent('qb-policejob:client:CallAnim', function()
    -- TODO(helix): Phone call animation needs Helix animation support.
end)

RegisterClientEvent('qb-policejob:client:ImpoundVehicle', function(_, _)
    -- Progressbar is intentionally instant; selecting and impounding an existing vehicle still needs a Helix vehicle-target flow.
    notifyVehicleTodo()
end)

RegisterClientEvent('qb-policejob:client:CheckStatus', function(data)
    local playerId = getPlayerIdFromEntity(data and data.entity) or getClosestPlayerId(500.0)
    if not playerId then
        exports['qb-core']:Notify(Lang.t('error.none_nearby'), 'error')
        return
    end

    TriggerCallback('qb-policejob:GetPlayerStatus', function(result)
        if result then
            for _, v in pairs(result) do
                exports['qb-core']:Notify(tostring(v))
            end
        end
    end, playerId)
end)

RegisterClientEvent('qb-policejob:client:VehicleMenuHeader', function(data)
    MenuGarage(data and data.stationKey)
end)

RegisterClientEvent('qb-policejob:client:ImpoundMenuHeader', function(data)
    MenuImpound(data and data.stationKey)
end)

RegisterClientEvent('qb-policejob:client:TakeOutImpound', function(data)
    TakeOutImpound(data)
end)

RegisterClientEvent('qb-policejob:client:TakeOutVehicle', function(data)
    TakeOutVehicle(data)
end)

RegisterClientEvent('qb-policejob:client:EvidenceStashDrawer', function(data)
    local currentEvidence = data and data.currentEvidence
    if not currentEvidence then
        return
    end

    local drawer = exports['qb-input']:ShowInput({
        header = Lang.t('info.evidence_stash', { value = currentEvidence }),
        submitText = 'open',
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'slot',
                text = Lang.t('info.slot'),
            },
        },
    })
    if drawer and drawer.slot then
        TriggerServerEvent('qb-policejob:server:evidence', Lang.t('info.current_evidence', { value = currentEvidence, value2 = drawer.slot }))
    end
end)

RegisterClientEvent('qb-policejob:client:ToggleDuty', function()
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('qb-policejob:server:UpdateCurrentCops')
    TriggerServerEvent('qb-policejob:server:UpdateBlips')
end)

RegisterClientEvent('qb-policejob:client:scanFingerPrint', function(data)
    local playerId = getPlayerIdFromEntity(data and data.entity) or getClosestPlayerId(250.0)
    if playerId then
        TriggerServerEvent('qb-policejob:server:showFingerprint', playerId)
    else
        exports['qb-core']:Notify(Lang.t('error.none_nearby'), 'error')
    end
end)

RegisterClientEvent('qb-policejob:client:spawnHelicopter', function(data)
    local stationKey, station = getStation(data and data.stationKey or currentStation)
    local helicopter = getFirstAuthorizedVehicle(station, 'authorizedHelicopters')
    if helicopter then
        TriggerServerEvent('qb-policejob:server:TakeOutVehicle', helicopter, stationKey)
    else
        exports['qb-core']:Notify('No authorized police helicopter configured.', 'error')
    end
end)

RegisterClientEvent('qb-policejob:client:OpenClothing', function()
    exports['qb-clothing']:OpenClothing('clothing')
end)

local function registerPoliceTargets()
    if jobTargetsRegistered then
        return
    end
    jobTargetsRegistered = true

    for stationKey, station in pairs(Config.Locations) do
        for i, coords in ipairs(station.duty or {}) do
            addTargetSphere('PoliceDuty_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:ToggleDuty',
                icon = 'log-in',
                label = Lang.t('target.sign_in'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.stash or {}) do
            addTargetSphere('PoliceStash_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'server',
                event = 'qb-policejob:server:stash',
                icon = 'archive',
                label = Lang.t('target.open_personal_stash'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.clothing or {}) do
            addTargetSphere('PoliceClothing_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:OpenClothing',
                icon = 'shirt',
                label = Lang.t('target.open_clothing'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.trash or {}) do
            addTargetSphere('PoliceTrash_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'server',
                event = 'qb-policejob:server:trash',
                icon = 'trash',
                label = Lang.t('target.open_trash'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.fingerprint or {}) do
            addTargetSphere('PoliceFingerprint_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:scanFingerPrint',
                icon = 'fingerprint',
                label = Lang.t('target.open_fingerprint'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.camera or {}) do
            addTargetSphere('PoliceCamera_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:CameraMenu',
                icon = 'camera',
                label = Lang.t('target.open_security_cameras'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.evidence or {}) do
            addTargetSphere('PoliceEvidence_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:EvidenceStashDrawer',
                icon = 'archive',
                label = Lang.t('target.open_evidence_stash'),
                currentEvidence = stationKey .. '_' .. i,
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.vehicle or {}) do
            addTargetSphere('PoliceGarage_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:VehicleMenuHeader',
                icon = 'car',
                label = Lang.t('menu.pol_garage'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.impound or {}) do
            addTargetSphere('PoliceImpound_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:ImpoundMenuHeader',
                icon = 'warehouse',
                label = Lang.t('menu.pol_impound'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end

        for i, coords in ipairs(station.helicopter or {}) do
            addTargetSphere('PoliceHelicopter_' .. stationKey .. '_' .. i, coords, 0, {
                type = 'client',
                event = 'qb-policejob:client:spawnHelicopter',
                icon = 'helicopter',
                label = Lang.t('info.take_heli'),
                stationKey = stationKey,
                jobType = 'leo',
            })
        end
    end
end

PoliceLoadedHandlers[#PoliceLoadedHandlers + 1] = function()
    registerPoliceTargets()
end
