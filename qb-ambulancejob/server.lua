local Lang = require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')
local sharedItems = exports['qb-core']:GetShared('Items')

-- Functions

local function getAvailableBed()
    for _, loc in pairs(Config.Locations) do
        for i = 1, #loc.beds do
            if not loc.beds[i].taken then
                loc.beds[i].taken = true
                return loc.beds[i]
            end
        end
    end
end

-- Events

RegisterServerEvent('qb-ambulancejob:server:retrieveVehicle', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local loc = Config.Locations[data.locId]
    if not loc then
        return
    end
    local vehicleData = Vehicles[data.vehicle]
    local vehicleAsset = vehicleData and vehicleData.asset_name
    if not vehicleAsset then
        return
    end
    local vehicle = HVehicle(loc.vehicleSpawn.coords, Rotator(0, loc.vehicleSpawn.heading, 0), vehicleAsset)
    if not vehicle then
        return
    end
    local plate = Lang.t('info.amb_plate') .. tostring(math.random(1000, 9999))
    vehicle:SetPlate(plate)
end)

RegisterServerEvent('qb-ambulancejob:server:retrieveHelicopter', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local loc = Config.Locations[data.locId]
    if not loc then
        return
    end
    local vehicleData = Vehicles[data.vehicle]
    local vehicleAsset = vehicleData and vehicleData.asset_name
    if not vehicleAsset then
        return
    end
    local vehicle = HVehicle(loc.helicopterSpawn.coords, Rotator(0, loc.helicopterSpawn.heading, 0), vehicleAsset)
    if not vehicle then
        return
    end
    local plate = Lang.t('info.heli_plate') .. tostring(math.random(1000, 9999))
    vehicle:SetPlate(plate)
end)

RegisterServerEvent('qb-ambulancejob:server:openStash', function(source)
    print('qb-ambulancejob:server:openStash')
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
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
            local AnimParams = UE.FHPlayAnimParams()
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
    local _, loc = next(Config.Locations)
    if not loc then
        return
    end
    local c = loc.checking[1]
    SetEntityCoords(pawn, Vector(c.X, c.Y + 300, c.Z))
end)

RegisterServerEvent('qb-hospitaljob:server:status', function(source, data)
    local pawn = data.entity
    local ok, boneArray = UE.UHGameplaySystemGlobals.GetTargetActorAllLimbHealthStates(pawn)
    if not ok or not boneArray then
        return
    end
    local limbData = {}
    for i = 1, boneArray:Num() do
        local healthState = boneArray[i]
        local limbInfo = {
            limbTag = healthState.LimbTag.TagName,
            currentHealth = healthState.CurrentHealth,
            maxHealth = healthState.MaxHealth,
            entity = pawn,
            damageTypes = {},
        }
        local tagContainer = healthState.RecentDamageTypes
        for k, v in pairs(tagContainer.GameplayTags) do
            table.insert(limbInfo.damageTypes, v.TagName)
        end
        table.insert(limbData, limbInfo)
    end
    TriggerClientEvent(source, 'qb-hospitaljob:client:openStatusMenu', limbData)
end)

RegisterServerEvent('qb-hospitaljob:server:revive', function(source, data)
    local pawn = data.entity
    if not pawn then
        return
    end

    local healthComp = pawn:GetComponentByClass(UE.UHActorHealthComponent)
    if not healthComp then
        return
    end

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
    if not pawn then
        return
    end

    local healthComp = pawn:GetComponentByClass(UE.UHActorHealthComponent)
    if not healthComp then
        return
    end

    local currentHealth = healthComp:GetHealth()
    local maxHealth = healthComp:GetMaxHealth()
    local halfHealth = maxHealth * 0.5

    if currentHealth < halfHealth then
        local healAmount = halfHealth - currentHealth
        UE.UHGameplaySystemGlobals.HealTarget(pawn, healAmount)
    end
end)

RegisterServerEvent('qb-hospitaljob:server:treatLimb', function(source, data)
    local targetPawn = data.entity
    local limbTag = data.limbTag
    local limbName = data.limb
    local healAmount = data.maxHealth or 100.0
    local gameplayTag = UE.FGameplayTag()
    gameplayTag.TagName = limbTag
    local success = UE.UHGameplaySystemGlobals.HealTargetLimb(targetPawn, gameplayTag, healAmount)
    if success then
        TriggerClientEvent(source, 'QBCore:Notify', limbName .. ' healed', 'success')
        local ok, boneArray = UE.UHGameplaySystemGlobals.GetTargetActorAllLimbHealthStates(targetPawn)
        if not ok or not boneArray then
            return
        end
        local limbData = {}
        for i = 1, boneArray:Num() do
            local healthState = boneArray[i]
            local limbInfo = {
                limbTag = healthState.LimbTag.TagName,
                currentHealth = healthState.CurrentHealth,
                maxHealth = healthState.MaxHealth,
                entity = targetPawn,
                damageTypes = {},
            }
            local tagContainer = healthState.RecentDamageTypes
            for k, v in pairs(tagContainer.GameplayTags) do
                table.insert(limbInfo.damageTypes, v.TagName)
            end
            table.insert(limbData, limbInfo)
        end
        TriggerClientEvent(source, 'qb-hospitaljob:client:openStatusMenu', limbData)
    else
        TriggerClientEvent(source, 'QBCore:Notify', 'Failed to heal ' .. limbName, 'error')
    end
end)

-- Usable items

exports['qb-core']:CreateUseableItem('bandage', { event = 'qb-ambulancejob:server:useBandage' })
exports['qb-core']:CreateUseableItem('firstaid', { event = 'qb-ambulancejob:server:useFirstAid' })

RegisterServerEvent('qb-ambulancejob:server:useBandage', function(source, itemData)
    local Player = exports['qb-core']:GetPlayer(source)
    local pawn = GetPlayerPawn(source)
    if not Player or not pawn then
        return
    end
    if IsDowned(pawn) or IsDeadOrDying(pawn) then
        TriggerClientEvent(source, 'QBCore:Notify', 'You can\'t use a bandage right now', 'error')
        return
    end
    local currentHealth = GetHealth(pawn) or 0
    local maxHealth = GetMaxHealth(pawn) or 100
    if currentHealth >= maxHealth then
        TriggerClientEvent(source, 'QBCore:Notify', 'You are already at full health', 'error')
        return
    end
    if Player.RemoveItem('bandage', 1, itemData and itemData.slot) then
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['bandage'], 'remove')
        HealTarget(pawn, 30.0)
        TriggerClientEvent(source, 'QBCore:Notify', 'You applied a bandage', 'success')
    end
end)

RegisterServerEvent('qb-ambulancejob:server:useFirstAid', function(source, itemData)
    local Player = exports['qb-core']:GetPlayer(source)
    local pawn = GetPlayerPawn(source)
    if not Player or not pawn then
        return
    end
    local medicCoords = GetEntityCoords(pawn)
    local targetPawn, targetCtrl = nil, nil
    local closestDist = 500
    for _, otherCtrl in pairs(GetAllPlayers()) do
        if otherCtrl ~= source then
            local otherPawn = GetPlayerPawn(otherCtrl)
            if otherPawn and IsDowned(otherPawn) then
                local dist = medicCoords:Dist(GetEntityCoords(otherPawn))
                if dist < closestDist then
                    closestDist = dist
                    targetPawn = otherPawn
                    targetCtrl = otherCtrl
                end
            end
        end
    end
    if not targetPawn then
        TriggerClientEvent(source, 'QBCore:Notify', 'No downed player nearby', 'error')
        return
    end
    if Player.RemoveItem('firstaid', 1, itemData and itemData.slot) then
        TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['firstaid'], 'remove')
        Animation.Play(pawn, '/HelixAnimation/Unified/Animations/ReviveAnimationPack/Revive/A_Reviver_With_Medic_R2.A_Reviver_With_Medic_R2', nil, function() end)
        Timer.SetTimeout(function()
            if not IsDowned(targetPawn) then
                Animation.Stop(pawn)
                TriggerClientEvent(source, 'QBCore:Notify', 'The patient no longer needs reviving', 'error')
                return
            end
            ReviveFromDownedState(targetPawn)
            HealTarget(targetPawn, 100)
            Animation.Stop(pawn)
            Animation.Play(pawn, '/HelixAnimation/Unified/Animations/ReviveAnimationPack/Revive/A_Reviver_Without_Medic_L.A_Reviver_Without_Medic_L', nil, function() end)
            Animation.Play(targetPawn, '/HelixAnimation/Unified/Animations/ReviveAnimationPack/Revive/A_Revive_Without_Medic_R.A_Revive_Without_Medic_R', nil, function() end)
            TriggerClientEvent(source, 'QBCore:Notify', 'You revived the patient', 'success')
            TriggerClientEvent(targetCtrl, 'QBCore:Notify', 'You have been revived', 'success')
        end, 3000)
    end
end)

RegisterServerEvent('qb-hospitaljob:server:escort', function(source, data)
    local pawn = GetPlayerPawn(source)
    local target_pawn = data.entity
    if not target_pawn then
        return
    end
    local target_coords = GetEntityCoords(target_pawn)
    local player_coords = GetEntityCoords(pawn)
    local distance = player_coords:Dist(target_coords)
    if distance > 500 then
        return
    end
    if not target_pawn:GetAttachParentActor() then
        target_pawn:GetComponentByClass(UE.UCharacterMovementComponent):SetMovementMode(UE.EMovementMode.MOVE_None, nil)
        -- AttachActorToComponent(target_pawn, pawn:K2_GetRootComponent(), Vector(100, 50, 0), Rotator(), 'root')
        AttachActorToActor(target_pawn, pawn, Vector(100, 50, 0), Rotator(), 'root')
    else
        DetachActor(target_pawn)
        local player_rotation = GetEntityRotation(pawn)
        local placing_position = player_rotation:GetForwardVector() * 100
        SetEntityCoords(target_pawn, player_coords + placing_position)
        local root = target_pawn:K2_GetRootComponent()
        target_pawn:GetComponentByClass(UE.UCharacterMovementComponent):SetMovementMode(UE.EMovementMode.MOVE_Walking, nil)
        root:SetCollisionProfileName('LyraPawnCapsule', true) -- reset pawn collision
    end
end)
