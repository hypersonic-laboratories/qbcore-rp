local IsWorking = false
local HoldingPackage = false
local CurrentLocation = {
    TimerId = nil,
    Cone = nil,
    Coords = nil,
}
require('locales/en')

function onShutdown()
    if CurrentLocation.TimerId then
        Timer.ClearInterval(CurrentLocation.TimerId)
    end
end

local function setupPeds(peds)
    for i = 1, #peds do
        exports['qb-target']:AddTargetEntity(peds[i].Ped, {
            distance = 1500,
            options = {
                {
                    label = Lang.t('info.start_delivering'),
                    icon = 'boxes-stacked',
                    job = Config.Job,
                    type = 'server',
                    event = 'qb-deliveryjob:server:startDelivering',
                    depot = peds[i].Index,
                },
                {
                    label = Lang.t('info.finish_delivering'),
                    icon = 'boxes-stacked',
                    job = Config.Job,
                    type = 'client',
                    event = 'qb-deliveryjob:client:finishDelivering',
                }
            }
        })
    end
end

local function deliverPackage()
    local Pawn = GetPlayerPawn(HPlayer)
    local PawnCoords = GetEntityCoords(Pawn)
    if PawnCoords and PawnCoords:Dist(CurrentLocation.Coords) > 1000 then
        exports['qb-core']:Notify(Lang.t('error.too_far'), 'error')
        return
    end
    TriggerCallback('deliverPackage', function(success)
        if not success then return end
        HoldingPackage = false
    end, CurrentLocation.jobId)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    --@TODO Revert to one time registration
    TriggerCallback('getJobPeds', function(peds)
        setupPeds(peds)
    end)
end)

RegisterClientEvent('qb-deliveryjob:client:pickupBox', function(targetData)
    CurrentLocation.jobId = targetData.jobId
    TriggerCallback('server.pickupBox', function(success)
        if not success then return end
        exports['qb-core']:DrawText(Lang.t('info.deliver_package'))
        HoldingPackage = true
    end, targetData.jobId)
end)

RegisterClientEvent('qb-deliveryjob:client:setupVehicleTarget', function(Vehicle, Job)
    exports['qb-target']:AddTargetEntity(Vehicle.Object, {
        distance = 4000,
        options = {
            {
                label = Lang.t('info.pickup_box'),
                icon = 'boxes-stacked',
                job = Config.Job,
                type = 'client',
                event = 'qb-deliveryjob:client:pickupBox',
                jobId = Job
            }
        }
    })
end)

RegisterClientEvent('qb-deliveryjob:client:setCurrentLocation', function(Location, Vehicle, CurrentStop, MaxStops)
    -- Reset states
    if CurrentLocation.TimerId then Timer.ClearInterval(CurrentLocation.TimerId) end
    if CurrentLocation.Cone and CurrentLocation.Cone:IsValid() then DeleteEntity(CurrentLocation.Cone) end
    if not Location then
        exports['qb-core']:HideText()
        if CurrentLocation.TimerId then Timer.ClearInterval(CurrentLocation.TimerId) end
        CurrentLocation.TimerId = nil
        CurrentLocation.Cone = nil
        CurrentLocation.Coords = nil
        exports['qb-target']:RemoveTargetEntity(Vehicle)
        return
    end

    -- Create cone, attach, calculate rotation
    local FindRotation = UE.UKismetMathLibrary.FindLookAtRotation
    local Pawn = GetPlayerPawn(HPlayer)
    local Cone = StaticMesh(GetEntityCoords(Pawn), Rotator(), '/QuietRuntimeEditor/UserContent/StaticMeshes/Primitives/SM_Cone.SM_Cone')
    CurrentLocation.Cone = Cone
    AttachActorToActor(Cone.Object, Pawn, Vector(0, 0, 0), nil, '', {
        Location = AttachmentRule.KeepWorld,
        Rotation = AttachmentRule.KeepRelative
    }, true)
    Cone:SetActorScale3D(Vector(0.2, 0.2, 0.2))
    CurrentLocation.TimerId = Timer.SetInterval(function()
        local targetRotation = FindRotation(GetEntityCoords(Pawn), Location)
        targetRotation.Roll = 0
        targetRotation.Pitch = 90
        targetRotation.Yaw = targetRotation.Yaw + 180
        SetEntityRotation(Cone, targetRotation)
    end, 50)
    CurrentLocation.Coords = Location

    -- Update UI
    exports['qb-core']:DrawText(Lang.t('status.location_info', { Current = CurrentStop, Max = MaxStops }))
end)

RegisterClientEvent('qb-deliveryjob:client:finishDelivering', function()
    TriggerCallback('finishDelivering', function(success)
        if not success then return end
        HoldingPackage = false
        CurrentLocation = {}
    end, CurrentLocation.jobId)
end)

Input.BindKey('E', function()
    if HoldingPackage then
        deliverPackage()
        return
    end
end)
