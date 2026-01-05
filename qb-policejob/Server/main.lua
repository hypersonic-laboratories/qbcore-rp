require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')
local FingerprintSessions = {}
local States = {
    Escorted = {}, -- <target_ped: AHCharacter, escorting_source: AHPlayerController>
    Cuffed = {} -- <target_citizenid: string, cuffing_source: AHPlayerController> ID used for persistence
}

-- Functions

local function GetClosestFingerprint(coords)
    local closestFingerprint
    for i = 1, #Config.Locations.fingerprint do
        local FingerprintCoords = Config.Locations.fingerprint[i].coords
        local distance = coords:Dist(FingerprintCoords)
        if distance <= 500 then
            closestFingerprint = i
            break
        end
    end
    return closestFingerprint
end

local function GetEscortedTarget(source)
    for k, v in pairs(States.Escorted) do
        if v == source then
            return k
        end
    end
    return nil
end

local function ToggleEscort(source, target_ped)
    local player_ped = GetPlayerPawn(source)
    if not player_ped then return end
    if not target_ped then return end
    if not target_ped:IsValid() then
        States.Escorted[target_ped] = nil
        return true
    end

    local target_coords = GetEntityCoords(target_ped)
    local player_coords = GetEntityCoords(player_ped)
    local distance = player_coords:Dist(target_coords)
    if distance > 500 then return end

    if not States.Escorted[target_ped] then
        target_ped:GetComponentByClass(UE.UCharacterMovementComponent):SetMovementMode(UE.EMovementMode.MOVE_None, nil)
        AttachActorToComponent(target_ped, player_ped:K2_GetRootComponent(), Vector(100, 50, 0), Rotator(), 'root')
        TriggerClientEvent(target_ped:GetController(), 'qb-policejob:client:setEscorted', player_ped, true)
        States.Escorted[target_ped] = source
        return true
    else
        DetachActor(target_ped)
        TriggerClientEvent(target_ped:GetController(), 'qb-policejob:client:setEscorted', player_ped, false)
        States.Escorted[target_ped] = nil
        local player_rotation = GetEntityRotation(player_ped)
        local placing_position = player_rotation:GetForwardVector() * 100
        SetEntityCoords(target_ped, player_coords + placing_position)
        local root = target_ped:K2_GetRootComponent()
        target_ped:GetComponentByClass(UE.UCharacterMovementComponent):SetMovementMode(UE.EMovementMode.MOVE_Walking, nil)
        root:SetCollisionProfileName('LyraPawnCapsule', true) -- reset pawn collision
        return true
    end
end

local function IsHandcuffed(CitizenId)
    return States.Cuffed[CitizenId] ~= nil
end

exports('qb-policejob', 'IsHandcuffed', IsHandcuffed)

-- Callbacks

RegisterCallback('escort', function(source, target_ped)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    target_ped = target_ped or GetEscortedTarget(source)

    local Success = ToggleEscort(source, target_ped)
    return Success
end)

RegisterCallback('GetCuffedState', function(source, PlayAnimation)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

    local Cuffed = IsHandcuffed(Player.PlayerData.citizenid)
    if Cuffed and PlayAnimation then
        local BaseAnimPath = '/Game/Characters/Heroes/Unified/Animations/HostageSet/'
        local AnimParams = UE.FHelixPlayAnimParams()
        AnimParams.AnimSlotName = 'UpperBody'
        AnimParams.LoopCount = -1
        Animation.Play(GetPlayerPawn(source), BaseAnimPath .. 'Paired_Handcuffs/Paired_HandcuffHostage_Loop_Vic.Paired_HandcuffHostage_Loop_Vic', AnimParams)
    end
    return Cuffed
end)

-- Events

RegisterServerEvent('qb-policejob:server:openStash', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local citizenId = Player.PlayerData.citizenid
    local stashName = 'policestash_' .. citizenId
    exports['qb-inventory']:OpenInventory(source, stashName)
end)

RegisterServerEvent('qb-policejob:server:retrieveVehicle', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end

    -- Check player grade and vehicle grade
    local PlayerGrade = Player.PlayerData.job.grade.level
    local VehicleName = data.vehicle
    local authorized = false
    for i = 0, PlayerGrade do
        if Config.AuthorizedVehicles[i] and Config.AuthorizedVehicles[i][VehicleName] then
            authorized = true
            break
        end
    end
    if not authorized then return end

    local VehicleData = Vehicles[VehicleName]
    if not VehicleData then return end

    -- Spawn Vehicle
    local SpawnLocation = Config.Locations.vehicle[data.locationIndex].spawn
    local Vehicle = HVehicle(SpawnLocation.coords, SpawnLocation.rotation, VehicleData.asset_name)
    Vehicle:SetPlate(Lang:t('info.police_plate') .. tostring(math.random(1000, 9999)))
end)

RegisterServerEvent('qb-policejob:server:evidence', function(source, drawer)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    exports['qb-inventory']:OpenInventory(source, 'evidence_' .. drawer, {
        maxweight = 4000000,
        slots = 500,
    })
end)

RegisterServerEvent('qb-policejob:server:openFingerprint', function(source)
    local PlayerPawn = GetPlayerPawn(source)
    if not PlayerPawn then return end
    local ClosestFingerprint = GetClosestFingerprint(GetEntityCoords(PlayerPawn))
    if not ClosestFingerprint then return end

    -- Add client to nearest fingerprint session
    FingerprintSessions[ClosestFingerprint] = FingerprintSessions[ClosestFingerprint] or {}
    FingerprintSessions[ClosestFingerprint][source] = true
    TriggerClientEvent(source, 'qb-policejob:client:openFingerprint')
end)

RegisterServerEvent('qb-policejob:server:closeFingerprint', function(source)
    local PlayerPawn = GetPlayerPawn(source)
    if not PlayerPawn then return end
    local ClosestFingerprint = GetClosestFingerprint(GetEntityCoords(PlayerPawn))
    if not ClosestFingerprint then return end

    -- Remove client from nearest fingerprint session
    if FingerprintSessions[ClosestFingerprint] then
        FingerprintSessions[ClosestFingerprint][source] = nil
    end
end)

RegisterServerEvent('qb-policejob:server:scanFinger', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

    local PlayerPawn = GetPlayerPawn(source)
    local PlayerCoords = GetEntityCoords(PlayerPawn)
    local FingerprintId = Player.PlayerData.metadata['fingerprint']

    local ClosestFingerprint = GetClosestFingerprint(PlayerCoords)
    if not ClosestFingerprint then return end

    -- Notify relevant clients to update fingerprint UI
    for target in pairs(FingerprintSessions[ClosestFingerprint] or {}) do
        TriggerClientEvent(target, 'qb-policejob:client:updateFingerprint', FingerprintId)
    end
end)


RegisterServerEvent('qb-policejob:server:search', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end

    local target_ped = data.entity
    if not target_ped then return end
    local target_coords = GetEntityCoords(target_ped)
    local player_coords = GetEntityCoords(GetPlayerPawn(source))
    local distance = player_coords:Dist(target_coords)
    if distance > 500 then return end
    local target_player = target_ped:GetController()
    exports['qb-inventory']:OpenInventoryById(source, target_player)
end)

RegisterServerEvent('qb-policejob:server:handcuff', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' and not Player.PlayerData.job.onduty then
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.on_duty_police_only'), 'error')
        return
    end
    local ped = GetPlayerPawn(source)
    local ped_coords = GetEntityCoords(ped)
    local target_ped = data.entity
    local target_coords = GetEntityCoords(target_ped)
    if ped_coords:Dist(target_coords) > 500 then return end

    -- Target
    local TargetAnimParams = UE.FHelixPlayAnimParams()
    TargetAnimParams.AnimSlotName = 'UpperBody'
    TargetAnimParams.LoopCount = -1

    -- Cuffer
    local AnimParams = UE.FHelixPlayAnimParams()
    AnimParams.bUseMotionWarping = true

    local FinalTransform = Transform()
    FinalTransform.Translation = GetEntityCoords(target_ped)
    FinalTransform.Rotation = GetEntityRotation(target_ped):ToQuat()
    AnimParams.WarpTargetTransform = FinalTransform

    local BaseAnimPath = '/Game/Characters/Heroes/Unified/Animations/HostageSet/'
    Animation.Play(ped, BaseAnimPath .. 'Paired_Handcuffs/Paired_HandcuffHostage_Start_Att.Paired_HandcuffHostage_Start_Att', AnimParams)
    Animation.Play(target_ped, BaseAnimPath .. 'Paired_Handcuffs/Paired_HandcuffHostage_Start_Vic.Paired_HandcuffHostage_Start_Vic', TargetAnimParams)

    Timer.SetTimeout(function()
        local Controller = target_ped:GetController()
        local TargetPlayer = exports['qb-core']:GetPlayer(Controller)
        if not TargetPlayer then return end
        local PlayerId = TargetPlayer.PlayerData.citizenid
        if IsHandcuffed(PlayerId) then
            Animation.Stop(target_ped)
            States.Cuffed[PlayerId] = nil
            TriggerClientEvent(Controller, 'qb-policejob:client:setCuffed', false)
        else
            Animation.Stop(target_ped)
            Animation.Play(target_ped, BaseAnimPath .. 'Paired_Handcuffs/Paired_HandcuffHostage_Loop_Vic.Paired_HandcuffHostage_Loop_Vic', TargetAnimParams)
            States.Cuffed[PlayerId] = source
            TriggerClientEvent(Controller, 'qb-policejob:client:setCuffed', true)
        end
    end, 5000)
end)

RegisterServerEvent('qb-policejob:server:putvehicle', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = data.entity
    if not target_ped then return end
    if not target_ped:GetController() then return end
    local closest_vehicle, distance = GetClosestVehicle(GetEntityCoords(target_ped))
    if not closest_vehicle or distance > 500 then return end
    local Seats = closest_vehicle:K2_GetComponentsByClass(UE.USeatComponent):ToTable()
    for i = 3, #Seats do
        local Seat = Seats[i]
        if not Seat:IsSeatOccupied() then
            if States.Escorted[target_ped] then ToggleEscort(States.Escorted[target_ped], target_ped) end -- stop escorting if being put in vehicle
            local VehicleParams = UE.FHEnterVehicleParams()
            VehicleParams.bSkipAnimations = true
            UE.UHGameplaySystemGlobals.SendEnterVehicleEventToActorBySeat(target_ped, closest_vehicle, Seat, VehicleParams)
            return
        end
    end
end)

local SEATS = {
    RR = 2,
    RL = 3,
}
RegisterServerEvent('qb-policejob:server:takevehicle', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end

    local SeatIndex = (data.door == 'RR' and SEATS.RR) or (data.door == 'RL' and SEATS.RL)
    local Vehicle = data.entity
    local Seat = Vehicle:GetSeatByIndex(SeatIndex)
    if not Seat then return end
    local Occupant = Seat:GetSeatOccupancy()
    if not Occupant then return end -- Notify no occupant

    local VehicleParams = UE.FHExitVehicleParams()
    VehicleParams.bSkipAnimations = true
    UE.UHGameplaySystemGlobals.SendExitVehicleEventToActor(Occupant, VehicleParams)
end)

RegisterServerEvent('qb-policejob:server:toggleTracker', function(source, args)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end

    local TargetPlayer = exports['qb-core']:GetPlayerByCitizenId(args.CitizenId)
    if not TargetPlayer then return end

    local TargetPed = GetPlayerPawn(TargetPlayer.PlayerData.source)
    if not TargetPed then return end

    local PlayerPawn = GetPlayerPawn(source)
    local PlayerCoords = GetEntityCoords(PlayerPawn)
    local TargetCoords = GetEntityCoords(TargetPed)
    local distance = PlayerCoords:Dist(TargetCoords)
    if distance > 500 then return end

    local NewTrackerState = not TargetPlayer.PlayerData.metadata.tracker
    exports['qb-core']:Player(TargetPlayer.PlayerData.source, 'SetMetaData', 'tracker', NewTrackerState)
    
    local FirstName = TargetPlayer.PlayerData.charinfo.firstname
    local LastName = TargetPlayer.PlayerData.charinfo.lastname
    local NameData = { firstname = FirstName, lastname = LastName }
    TriggerClientEvent(source, 'QBCore:Notify', NewTrackerState and Lang:t('success.put_anklet_on', NameData) or Lang:t('success.took_anklet_from', NameData), 'success')
    TriggerClientEvent(TargetPlayer.PlayerData.source, 'QBCore:Notify', NewTrackerState and Lang:t('success.put_anklet') or Lang:t('success.anklet_taken_off'), 'success')

    TargetPlayer.PlayerData.metadata.tracker = NewTrackerState -- transient, used for UI update
    TriggerClientEvent(source, 'qb-policejob:client:viewCriminalRecord', { PlayerData = TargetPlayer.PlayerData })
end)

RegisterServerEvent('qb-policejob:server:info', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = data.entity or GetPlayerPawn(source)
    if not target_ped then return end
    local OtherPlayer = exports['qb-core']:GetPlayer(target_ped:GetController())
    if not OtherPlayer then return end
    TriggerClientEvent(source, 'qb-policejob:client:checkCitizenInfo', OtherPlayer.PlayerData)
end)
--[[
Events.SubscribeRemote('qb-policejob:server:leaveCamera', function(source, coords)
    source:SetCameraLocation(coords)
    local newChar = HCharacter(coords, Rotator(), source)
    local player_dimension = source:GetDimension()
    newChar:SetDimension(player_dimension)
    source:Possess(newChar)
end)

Events.SubscribeRemote('qb-policejob:server:policeAlert', function(source, text)
    local ped = source:GetControlledCharacter()
    if not ped then return end
    local ped_coords = ped:GetLocation()
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            Events.CallRemote('qb-policejob:client:policeAlert', v.PlayerData.source, ped_coords, text)
        end
    end
end)

Events.SubscribeRemote('qb-policejob:server:panicButton', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' and not Player.PlayerData.job.onduty then
        Events.CallRemote('QBCore:Notify', source, Lang:t('error.on_duty_police_only'), 'error')
        return
    end
    local ped = source:GetControlledCharacter()
    local ped_coords = ped:GetLocation()
    local players = QBCore.Functions.GetQBPlayers()
    local text = Lang:t('info.officer_down', { lastname = Player.PlayerData.charinfo.lastname, callsign = Player.PlayerData.metadata.callsign })
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            Events.CallRemote('qb-policejob:client:policeAlert', v.PlayerData.source, ped_coords, text)
        end
    end
end)

-- Items

local function handcuff(source)
    local closest_player, distance = QBCore.Functions.GetClosestPlayer(source)
    if not closest_player or distance > 500 then return end
    local ped = source:GetControlledCharacter()
    local target_ped = closest_player:GetControlledCharacter()
    local target_coords = target_ped:GetLocation()
    ped:PlayAnimation('rp-anims-k::Paired_HandcuffHostage_Start_Att', AnimationSlotType.FullBody, false, 0.5, 0.5)
    target_ped:PlayAnimation('rp-anims-k::Paired_HandcuffHostage_Start_Vic', AnimationSlotType.FullBody, false, 0.5, 0.5)

    Timer.SetTimeout(function()
        if target_ped:GetValue('is_cuffed', false) then
            target_ped:GetValue('handcuffs'):Destroy()
            target_ped:StopAnimation('rp-anims-k::Paired_HandcuffHostage_Loop_Vic')
            target_ped:SetValue('is_cuffed', false, true)
        else
            local handcuffs = StaticMesh(target_coords, Rotator(), 'abcca-qbcore::SM_Handcuffs', CollisionType.NoCollision)
            handcuffs:AttachTo(target_ped, AttachmentRule.SnapToTarget, 'hand_r', 0, true)
            target_ped:PlayAnimation('rp-anims-k::Paired_HandcuffHostage_Loop_Vic', AnimationSlotType.UpperBody, true, 0.5, 0.5)
            target_ped:SetValue('is_cuffed', true, true)
            target_ped:SetValue('handcuffs', handcuffs, true)
        end
    end, 5000)
end

QBCore.Functions.CreateUseableItem('handcuffs', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' and not Player.PlayerData.job.onduty then
        Events.CallRemote('QBCore:Notify', source, Lang:t('error.on_duty_police_only'), 'error')
        return
    end
    handcuff(source)
end)
 ]]