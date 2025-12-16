local Lang = require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')

-- Functions

local function getAvailableBed()
    for i = 1, #Config.Locations['hospital'][1].beds do
        local bedInfo = Config.Locations['hospital'][1].beds[i]
        if not bedInfo.taken then
            bedInfo.taken = true
            return bedInfo
        end
    end
end

-- Events

RegisterServerEvent('qb-ambulancejob:server:retrieveVehicle', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local vehicleName = data.vehicle
    local vehicleData = Vehicles[vehicleName]
    local vehicleAsset = vehicleData and vehicleData.asset_name or nil
    local vehicle = HVehicle(Config.VehicleSpawn.coords, Rotator(0, Config.VehicleSpawn.heading, 0), vehicleAsset)
    local plate = Lang:t('info.amb_plate') .. tostring(math.random(1000, 9999))
    vehicle:SetPlate(plate)
end)

RegisterServerEvent('qb-ambulancejob:server:retrieveHelicopter', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local vehicleName = data.vehicle
    local vehicleData = Vehicles[vehicleName]
    local vehicleAsset = vehicleData and vehicleData.asset_name or nil
    local vehicle = HVehicle(Config.HelicopterSpawn.coords, Rotator(0, Config.HelicopterSpawn.heading, 0), vehicleAsset)
    local plate = Lang:t('info.heli_plate') .. tostring(math.random(1000, 9999))
    vehicle:SetPlate(plate)
end)

RegisterServerEvent('qb-ambulancejob:server:openStash', function(source)
    print('qb-ambulancejob:server:openStash')
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    print('Opening ambulance stash for citizen ID:', citizenid)
    exports['qb-inventory']:OpenInventory(source, citizenid)
end)

RegisterServerEvent('qb-ambulancejob:server:checkIn', function(source)
    local bedInfo = getAvailableBed()
    if bedInfo then
        local pawn = GetPlayerPawn(source)
        SetEntityCoords(pawn, bedInfo.coords)
        SetEntityHeading(pawn, bedInfo.heading)
        -- AttachActorToActor(pawn, bed, nil, Rotator(0, 90, 0), nil, {
        --     Location = AttachmentRule.SnapToTarget,
        --     Rotation = AttachmentRule.KeepWorld,
        --     Scale = AttachmentRule.SnapToTarget
        -- })
        Timer.SetTimeout(function()
            local AnimParams = UE.FHelixPlayAnimParams()
            AnimParams.LoopCount = -1
            local result = Animation.Play(pawn, '/Game/Characters/Heroes/Unified/Animations/SleepAnimPack/Sleep_Bed/A_Sleep_Bed_RightSide_SleepLoop.A_Sleep_Bed_RightSide_SleepLoop', AnimParams, function() end)
        end, 2000)
    end
    TriggerClientEvent(source, 'qb-ambulancejob:client:checkedIn')
end)

RegisterServerEvent('qb-ambulancejob:server:checkOut', function(source)
    local pawn = GetPlayerPawn(source)
    --DetachActor(pawn)
    Animation.Stop(pawn)
    SetEntityCoords(pawn, Vector(Config.Locations['checking'][1].coords.X, Config.Locations['checking'][1].coords.Y + 300, Config.Locations['checking'][1].coords.Z))
end)

RegisterServerEvent('qb-hospitaljob:server:status', function(source, data)
    local pawn = data.entity
    local boneArray = UE.TArray(UE.FHLimbHealthState)
    UE.UHGameplaySystemGlobals.GetTargetActorAllLimbHealthStates(pawn, boneArray)
    for i = 1, boneArray:Num() do
        local healthState = boneArray[i]
        print(healthState.LimbTag.TagName)
        print(healthState.CurrentHealth)
        print(healthState.MaxHealth)
        local tagContainer = healthState.RecentDamageTypes
        for k,v in pairs(tagContainer.GameplayTags) do
            print(v.TagName)
        end
    end
end)

RegisterServerEvent('qb-hospitaljob:server:revive', function(source, data)
    local pawn = data.entity
    if not pawn then return end

    local healthComp = pawn:GetComponentByClass(UE.UHActorHealthComponent)
    if not healthComp then return end

    local isDead = healthComp:IsDeadOrDying()
    local currentHealth = healthComp:GetHealth()
    local maxHealth = healthComp:GetMaxHealth()

    if isDead then
        local coords = GetEntityCoords(pawn)
        local SpawnTransform = Transform()
        SpawnTransform.Translation = Vector(coords.X, coords.Y, coords.Z)
        UE.UHGameplaySystemGlobals.RespawnPlayerByCharacterAtTransform(pawn, SpawnTransform)
        return
    end

    local healAmount = maxHealth - currentHealth
    if healAmount > 0 then
        UE.UHGameplaySystemGlobals.HealTarget(pawn, healAmount)
    end
end)

RegisterServerEvent('qb-hospitaljob:server:bandage', function(source, data)
    local pawn = data.entity
    if not pawn then return end

    local healthComp = pawn:GetComponentByClass(UE.UHActorHealthComponent)
    if not healthComp then return end

    local currentHealth = healthComp:GetHealth()
    local maxHealth = healthComp:GetMaxHealth()
    local halfHealth = maxHealth * 0.5

    if currentHealth < halfHealth then
        local healAmount = halfHealth - currentHealth
        UE.UHGameplaySystemGlobals.HealTarget(pawn, healAmount)
    end
end)

RegisterServerEvent('qb-hospitaljob:server:escort', function(source)
end)