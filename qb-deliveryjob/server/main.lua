SharedVehicles = exports['qb-core']:GetShared('Vehicles')
local Peds = {}
local Initialised = false
local Lang = require('locales/en')

local function getDepots()
    return (Config.Locations and Config.Locations.Depots) or Config.Depots or {}
end

local function spawnJobPed(depot, depotIndex)
    local pedName = depot.pedName or depot.label or 'Delivery Depot'
    HPawn(depot.pedSpawn, Rotator(0, depot.pedHeading or 0, 0), function(npc)
        if not npc then
            return
        end

        Peds[#Peds + 1] = {
            npc = npc,
            depot = depotIndex,
        }
        npc:SetCharacterName(pedName)
        SetEntityInvincible(npc, true)
    end, { CharacterName = pedName, bShowNameplate = true })
end

local function isValidCourier(courier)
    return courier and (not courier.IsValid or courier:IsValid())
end

local function cleanupInvalidJobs()
    for k, v in pairs(Jobs) do
        if not isValidCourier(v.Courier) then
            v:Cleanup()
            Jobs[k] = nil
        end
    end
end

local function startDeliveryRoute(source, targetData)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.Job then
        print('qb-deliveryjob:server:takeVehicle - Player job is not delivery')
        return
    end

    local depotIndex = targetData and targetData.depot
    local depotInfo = getDepots()[depotIndex]
    if not depotInfo then
        return
    end

    cleanupInvalidJobs()

    local newJob = Job.new(source, depotInfo)
    if not newJob.Vehicle then
        Jobs[newJob.DeliveryId] = nil
        exports['qb-core']:NotifyPlayer(source, Lang.t('error.no_vehicle'), 'error')
        return
    end

    TriggerClientEvent(source, 'qb-deliveryjob:client:setCurrentLocation', newJob.Route[1], newJob.Vehicle.Object, newJob.CurrentStop, newJob.MaxStops)
end

-- Cleanup
function onShutdown()
    for i = 1, #Peds do
        local ped = Peds[i].npc
        if ped and ped:IsValid() then
            DeleteEntity(ped)
        end
    end

    for _, job in pairs(Jobs) do
        job:Cleanup()
    end
end

-- Workaround for late joins seeing invisible mesh
RegisterServerEvent('HEvent:PlayerPossessed', function()
    if Initialised then
        return
    end
    for index, depot in pairs(getDepots()) do
        spawnJobPed(depot, index)
    end
    Initialised = true
end)

RegisterServerEvent('HEvent:PlayerUnloaded', function(Player)
    -- Clear invalid jobs
    for k, v in pairs(Jobs) do
        if v.Courier == Player then
            v:Cleanup()
            Jobs[k] = nil
            break
        end
    end
end)

RegisterServerEvent('qb-deliveryjob:server:takeVehicle', function(source, targetData)
    startDeliveryRoute(source, targetData)
end)

RegisterServerEvent('qb-deliveryjob:server:startDelivering', function(source, targetData)
    startDeliveryRoute(source, targetData)
end)

RegisterCallback('getPeds', function()
    return Peds
end)

RegisterCallback('getJobPeds', function()
    return Peds
end)

RegisterCallback('server.pickupBox', function(source, jobId)
    local CurrentJob = Jobs[jobId]
    if not CurrentJob or CurrentJob.Courier ~= source then
        return
    end
    if CurrentJob.CurrentStop > CurrentJob.MaxStops then
        exports['qb-core']:NotifyPlayer(source, Lang.t('error.no_packages'), 'error')
        return
    end

    CurrentJob:CreateDeliveryProp()

    return true
end)

RegisterCallback('deliverPackage', function(source, jobId)
    local CurrentJob = Jobs[jobId]
    if not CurrentJob or CurrentJob.Courier ~= source then
        return
    end
    if IsPedInAnyVehicle(GetPlayerPawn(source)) then
        exports['qb-core']:NotifyPlayer(source, Lang.t('error.inside_vehicle'), 'error')
        return
    end

    local Delivered = CurrentJob:DeliverPackage()
    if not Delivered then
        return
    end
    -- Check if all stops completed
    if CurrentJob.CurrentStop > CurrentJob.MaxStops then
        exports['qb-core']:NotifyPlayer(source, 'That was your last stop. Return the truck for payment', 'success')
        TriggerClientEvent(source, 'qb-deliveryjob:client:setCurrentLocation', nil)
    else
        TriggerClientEvent(source, 'qb-deliveryjob:client:setCurrentLocation', CurrentJob.Route[CurrentJob.CurrentStop], CurrentJob.Vehicle.Object, CurrentJob.CurrentStop, CurrentJob.MaxStops)
    end

    return true
end)

RegisterCallback('finishDelivering', function(source, jobId)
    local CurrentJob = Jobs[jobId]
    if not CurrentJob or CurrentJob.Courier ~= source then
        return
    end

    local Paid = CurrentJob:Payout()
    if not Paid then
        return
    end

    CurrentJob:Cleanup()
    Jobs[CurrentJob.DeliveryId] = nil
    TriggerClientEvent(source, 'qb-deliveryjob:client:setCurrentLocation', nil)

    return true
end)
