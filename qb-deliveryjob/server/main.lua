SharedVehicles = exports['qb-core']:GetShared('Vehicles')
local Peds = {}
local Initialised = false
require('locales/en')

-- Cleanup
function onShutdown()
    for i = 1, #Peds do
        local ped = Peds[i].Ped
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
    if Initialised then return end
    for index, depot in pairs(Config.Depots) do
        HPawn(depot.pedSpawn.coords, Rotator(0, depot.pedSpawn.heading, 0), function(Pawn)
            if not Pawn then return end
            Peds[#Peds + 1] = {
                Ped = Pawn,
                Index = index,
            }
        end)
    end
    Initialised = true
end)

RegisterServerEvent('HEvent:PlayerUnloaded', function(Player)
    -- Clear invalid jobs
    for k, v in pairs(Jobs) do
        if v.Courier == Player then
            job:Cleanup()
            Jobs[k] = nil
            break
        end
    end
end)

RegisterServerEvent('qb-deliveryjob:server:startDelivering', function(source, targetData)
    local depotIndex = targetData.depot
    local depotInfo = Config.Depots[depotIndex]
    if not depotInfo then return end

    -- Clear invalid jobs
    for k, v in pairs(Jobs) do
        if not v.Courier:IsValid() then
            job:Cleanup()
            Jobs[k] = nil
        end
    end

    local newJob = Job.new(source, depotInfo)
    TriggerClientEvent(source, 'qb-deliveryjob:client:setCurrentLocation', newJob.Route[1], newJob.Vehicle.Object, newJob.CurrentStop, newJob.MaxStops)
end)

RegisterCallback('getJobPeds', function(source)
    return Peds
end)

RegisterCallback('server.pickupBox', function(source, jobId)
    local CurrentJob = Jobs[jobId]
    if not CurrentJob or CurrentJob.Courier ~= source then return end
    if CurrentJob.CurrentStop > CurrentJob.MaxStops then
        exports['qb-core']:NotifyPlayer(source, Lang.t('error.no_packages'), 'error')
        return
    end

    CurrentJob:CreateDeliveryProp()

    return true
end)

RegisterCallback('deliverPackage', function(source, jobId)
    local CurrentJob = Jobs[jobId]
    if not CurrentJob or CurrentJob.Courier ~= source then return end
    if IsPedInAnyVehicle(GetPlayerPawn(source)) then
        exports['qb-core']:NotifyPlayer(source, Lang.t('error.inside_vehicle'), 'error')
        return
    end

    local Delivered = CurrentJob:DeliverPackage()
    if not Delivered then return end
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
    if not CurrentJob or CurrentJob.Courier ~= source then return end

    local Paid = CurrentJob:Payout()
    if not Paid then return end

    CurrentJob:Cleanup()
    Jobs[CurrentJob.DeliveryId] = nil
    TriggerClientEvent(source, 'qb-deliveryjob:client:setCurrentLocation', nil)

    return true
end)
