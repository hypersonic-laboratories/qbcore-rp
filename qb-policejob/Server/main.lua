require('locales/en')
local Vehicles = exports['qb-core']:GetShared('Vehicles')

--[[

for i = 1, #Config.Locations['evidence'] do
    local location_info = Config.Locations['evidence'][i]
    local coords = location_info.coords
    local heading = location_info.heading
    local ped = HCharacter(coords, Rotator(0, heading, 0), '/CharacterCreator/CharacterAssets/Avatar_FBX/Body/Male/Mesh/Male_Full_Body')
    ped:AddSkeletalMeshAttached('head', 'helix::SK_Male_Head')
    ped:AddSkeletalMeshAttached('chest', 'helix::SK_Police_Top')
    ped:AddSkeletalMeshAttached('legs', 'helix::SK_Police_Lower')
    ped:AddSkeletalMeshAttached('feet', 'helix::SK_Police_Shoes')
    ped:AddSkeletalMeshAttached('hat', 'helix::SK_Police_Hat')

    peds[ped] = {
        options = {
            {
                type = 'client',
                event = 'qb-policejob:client:evidence',
                label = 'Evidence Locker',
                icon = 'fas fa-dungeon',
                jobType = 'leo'
            },
        },
        distance = 400,
    }
end

for i = 1, #Config.Locations['fingerprint'] do
    local location_info = Config.Locations['fingerprint'][i]
    local coords = location_info.coords
    local heading = location_info.heading
    local ped = HCharacter(coords, Rotator(0, heading, 0), '/CharacterCreator/CharacterAssets/Avatar_FBX/Body/Male/Mesh/Male_Full_Body')
    ped:AddSkeletalMeshAttached('head', 'helix::SK_Male_Head')
    ped:AddSkeletalMeshAttached('chest', 'helix::SK_Police_Top')
    ped:AddSkeletalMeshAttached('legs', 'helix::SK_Police_Lower')
    ped:AddSkeletalMeshAttached('feet', 'helix::SK_Police_Shoes')
    ped:AddSkeletalMeshAttached('hat', 'helix::SK_Police_Hat')

    peds[ped] = {
        options = {
            {
                type = 'server',
                event = 'qb-policejob:server:fingerprint',
                label = 'Fingerprint',
                icon = 'fas fa-fingerprint',
                jobType = 'leo'
            },
        },
        distance = 400,
    }
end
]]
-- Callbacks

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
    print('Spawning Vehicle at:', SpawnLocation.coords, SpawnLocation.rotation, VehicleData.asset_name)
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
    local target_coords = target_ped:GetLocation()
    local player_coords = source:GetControlledCharacter():GetLocation()
    local distance = player_coords:Distance(target_coords)
    if distance > 500 then return end
    local target_player = target_ped:GetPlayer()
    OpenInventoryById(source, target_player)
end)

Events.SubscribeRemote('qb-policejob:server:escort', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = data.entity
    if not target_ped then return end
    local target_coords = target_ped:GetLocation()
    local player_ped = source:GetControlledCharacter()
    local player_coords = player_ped:GetLocation()
    local distance = player_coords:Distance(target_coords)
    if distance > 500 then return end
    local player_rotation = player_ped:GetRotation()
    local placing_position = player_rotation:GetForwardVector() * 100
    if not target_ped:GetValue('escorted', false) then
        target_ped:SetInputEnabled(false)
        target_ped:SetGravityEnabled(false)
        target_ped:AttachTo(player_ped)
        target_ped:SetRelativeLocation(Vector(99, 9, 0))
        target_ped:SetCollision(CollisionType.Auto)
        target_ped:SetValue('escorted', true, true)
    else
        target_ped:Detach()
        target_ped:SetInputEnabled(true)
        target_ped:SetLocation(placing_position + player_coords)
        target_ped:SetCollision(CollisionType.Normal)
        target_ped:SetGravityEnabled(true)
        target_ped:SetValue('escorted', false, true)
    end
end)

Events.SubscribeRemote('qb-policejob:server:handcuff', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' and not Player.PlayerData.job.onduty then
        Events.CallRemote('QBCore:Notify', source, Lang:t('error.on_duty_police_only'), 'error')
        return
    end
    local ped = source:GetControlledCharacter()
    local ped_coords = ped:GetLocation()
    local target_ped = data.entity
    local target_coords = target_ped:GetLocation()
    if ped_coords:Distance(target_coords) > 500 then return end

    ped:PlayAnimation('rp-anims-k::Paired_HandcuffHostage_Start_Att', AnimationSlotType.FullBody, false, 0.5, 0.5)
    target_ped:PlayAnimation('rp-anims-k::Paired_HandcuffHostage_Start_Vic', AnimationSlotType.FullBody, false, 0.5, 0.5)

    Timer.SetTimeout(function()
        if targetPed:GetValue('is_cuffed', false) then
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
end)

Events.SubscribeRemote('qb-policejob:server:putvehicle', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = data.entity
    if not target_ped then return end
    local target_player = target_ped:GetPlayer()
    if not target_player then return end
    local closest_vehicle, distance = QBCore.Functions.GetClosestHVehicle(source)
    if not closest_vehicle or distance > 500 then return end
    local allowed_passengers = closest_vehicle:NumOfAllowedPassanger()
    local current_passengers = closest_vehicle:NumOfCurrentPassanger()
    if current_passengers >= allowed_passengers then return end
    target_ped:EnterVehicle(closest_vehicle)
end)

Events.SubscribeRemote('qb-policejob:server:takevehicle', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = data.entity
    if not target_ped then return end
    local target_player = target_ped:GetPlayer()
    if not target_player then return end
    local closest_vehicle, distance = QBCore.Functions.GetClosestHVehicle(source)
    if not closest_vehicle or distance > 500 then return end
    print(closest_vehicle, distance)
end)

Events.SubscribeRemote('qb-policejob:server:tracker', function(source, player_id)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = player_id:GetControlledCharacter()
    if not target_ped then return end
    local target_coords = target_ped:GetLocation()
    local player_ped = source:GetControlledCharacter()
    local player_coords = player_ped:GetLocation()
    local distance = player_coords:Distance(target_coords)
    if distance > 500 then return end
    local OtherPlayer = QBCore.Functions.GetPlayer(player_id)
    if not OtherPlayer then return end
    local tracker_active = OtherPlayer.PlayerData.metadata.tracker
    if tracker_active then
        OtherPlayer.Functions.SetMetaData('tracker', false)
        Events.CallRemote('QBCore:Notify', player_id, Lang:t('success.anklet_taken_off'), 'success')
        Events.CallRemote('QBCore:Notify', source, Lang:t('success.took_anklet_from', { firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname }), 'success')
    else
        OtherPlayer.Functions.SetMetaData('tracker', true)
        Events.CallRemote('QBCore:Notify', player_id, Lang:t('success.put_anklet'), 'success')
        Events.CallRemote('QBCore:Notify', source, Lang:t('success.put_anklet_on', { firstname = Target.PlayerData.charinfo.firstname, lastname = Target.PlayerData.charinfo.lastname }), 'success')
    end
end)

Events.SubscribeRemote('qb-policejob:server:leaveCamera', function(source, coords)
    source:SetCameraLocation(coords)
    local newChar = HCharacter(coords, Rotator(), source)
    local player_dimension = source:GetDimension()
    newChar:SetDimension(player_dimension)
    source:Possess(newChar)
end)

Events.SubscribeRemote('qb-policejob:server:info', function(source, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' then return end
    local target_ped = data.entity
    if not target_ped then return end
    local target_player = target_ped:GetPlayer()
    if not target_player then return end
    local OtherPlayer = QBCore.Functions.GetPlayer(target_player)
    if not OtherPlayer then return end
    Events.CallRemote('qb-policejob:client:info', source, OtherPlayer.PlayerData)
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