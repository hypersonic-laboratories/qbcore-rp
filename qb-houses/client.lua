local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')
local isLoggedIn = false
local InProperty = false
local IsCurrentPropertyOwner = false
local propertyEntrance = nil
local propertyInstance
local propertyExterior = {}
local propertyInstanceLight
local garageInstance
local garageInstanceLight
local garageCenter
local propertyVolumeCluster
local Entrances = {} -- [entranceId] = { entranceId, label, entranceType, coords={x,y,z}, price, polyzoneBoxData={...} }
local ClosestEntranceId = nil
local CurrentProperty = nil -- propertyKey (unit) when inside
local EntranceTargets = {} -- [entranceId] = { created=true, interactionName=... }
local OwnedEntrances = {} -- [entranceId] = true/false
local InPropertyTargets = {} -- [targetKey] = { created=true, name=interactionName }
local sceneSpawner
local oldSceneData = nil
local intervalTimer
local vehicleTimer
local distanceInterval

-- Functions

local function RegisterInPropertyTarget(targetKey, coords, options)
    if not InProperty then
        return
    end
    if InPropertyTargets[targetKey] and InPropertyTargets[targetKey].created then
        return
    end
    local boxName = 'inPropertyTarget_' .. targetKey
    exports['qb-target']:AddBoxZone(boxName, coords, 100, 100, {
        name = boxName,
        heading = 0.0,
        distance = 500,
        debug = true,
    }, options)
    InPropertyTargets[targetKey] = InPropertyTargets[targetKey] or {}
    InPropertyTargets[targetKey].created = true
end

local function DeleteInPropertyTargets()
    if InPropertyTargets and next(InPropertyTargets) then
        for id in pairs(InPropertyTargets) do
            exports['qb-target']:RemoveZone('inPropertyTarget_' .. id)
        end
    end
    InPropertyTargets = {}
end

local function DeleteEntranceTargets()
    if EntranceTargets and next(EntranceTargets) then
        for entranceId, info in pairs(EntranceTargets) do
            exports['qb-target']:RemoveZone('entrance_' .. entranceId)
            if info.garage then
                exports['qb-target']:RemoveZone('garageEntrance_' .. entranceId)
            end
            EntranceTargets[entranceId] = nil
        end
    end
    for _, e in pairs(Entrances) do
        if e.polyzoneBoxData then
            e.polyzoneBoxData.created = false
        end
    end
end

local function RefreshEntrances()
    TriggerCallback('GetEntrances', function(result)
        if not result or next(result) == nil then
            Entrances = {}
            DeleteEntranceTargets()
            return
        end
        Entrances = {}
        for entranceId, e in pairs(result) do
            Entrances[entranceId] = {
                entranceId = e.entranceId or entranceId,
                label = e.label or entranceId,
                entranceType = e.entranceType or 'instanced',
                coords = e.coords,
                price = e.price or 0,
                polyzoneBoxData = {
                    distance = 1000,
                    created = false,
                },
                garageCoords = e.garageCoords,
            }
        end
        DeleteEntranceTargets()
    end)
end

local function SetClosestEntrance()
    if not isLoggedIn then
        return
    end
    if InProperty then
        return
    end
    local ped = GetPlayerPawn()
    if not ped then
        return
    end
    local pos = GetEntityCoords(ped)
    local current = nil
    local bestDist = 1000000
    for entranceId, e in pairs(Entrances) do
        if e and e.coords then
            local entrancePos = Vector(e.coords.x, e.coords.y, e.coords.z)
            local d = GetDistanceBetweenCoords(pos, entrancePos)
            if d < bestDist then
                bestDist = d
                current = entranceId
            end
        end
    end
    if current ~= ClosestEntranceId then
        ClosestEntranceId = current
        if ClosestEntranceId then
            TriggerCallback('IsOwnerAtEntrance', function(result)
                OwnedEntrances[ClosestEntranceId] = (result == true)
                DeleteEntranceTargets()
            end, ClosestEntranceId)
        else
            DeleteEntranceTargets()
        end
    end
end

local function RegisterEntranceTarget(entranceId, entranceData)
    if not entranceData or not entranceData.coords then
        return
    end
    local boxData = entranceData.polyzoneBoxData
    if boxData.created then
        return
    end
    local coords = Vector(entranceData.coords.x, entranceData.coords.y, entranceData.coords.z)
    local boxName = 'entrance_' .. entranceId
    local options = {}

    if entranceId == ClosestEntranceId and OwnedEntrances[ClosestEntranceId] then
        options[#options + 1] = {
            icon = 'door-open',
            label = Lang.t('text.enter'),
            type = 'client',
            event = 'qb-houses:client:EnterEntrance',
            entranceId = entranceId,
        }
    else
        if entranceData.entranceType == 'instanced' then
            options[#options + 1] = {
                icon = 'hotel',
                label = Lang.t('text.purchase'),
                type = 'client',
                event = 'qb-houses:client:PurchaseMenu',
                entranceId = entranceId,
            }
        else
            -- TO DO:
            options[#options + 1] = {
                icon = 'home',
                label = Lang.t('text.open_door') or 'Property',
                type = 'client',
                event = 'qb-houses:client:WorldPropertyMenu',
                entranceId = entranceId,
            }
        end
    end

    exports['qb-target']:AddBoxZone(boxName, coords, 100, 100, {
        name = boxName,
        heading = 0.0,
        distance = boxData.distance,
        debug = true,
    }, options)

    boxData.created = true
    EntranceTargets[entranceId] = { created = true }

    if entranceId == ClosestEntranceId and OwnedEntrances[ClosestEntranceId] then
        if entranceData.garageCoords then
            local rawGarageCoords = entranceData.garageCoords.coords
            local garageCoords = Vector(rawGarageCoords.X or rawGarageCoords.x, rawGarageCoords.Y or rawGarageCoords.y, rawGarageCoords.Z or rawGarageCoords.z)
            local garageBoxName = 'garageEntrance_' .. entranceId

            local garageOptions = {
                {
                    label = 'Return Vehicle',
                    icon = 'warehouse',
                    type = 'server',
                    event = 'qb-houses:server:StoreVehicle',
                    entranceId = entranceId,
                },
            }

            exports['qb-target']:AddBoxZone(garageBoxName, garageCoords, 100, 100, {
                name = garageBoxName,
                heading = entranceData.garageCoords.heading or 0.0,
                distance = 1000,
                debug = true,
            }, garageOptions)

            EntranceTargets[entranceId].garage = true
        end
    end
end

local function SetEntranceTargets()
    if not Entrances or next(Entrances) == nil then
        return
    end
    for entranceId, entranceData in pairs(Entrances) do
        RegisterEntranceTarget(entranceId, entranceData)
    end
end

local function SetInPropertyTargets(entrancePos, interiorRef)
    local options = {
        {
            icon = 'door-open',
            label = Lang.t('text.leave'),
            type = 'server',
            event = 'qb-houses:server:LeaveProperty',
            CurrentProperty = CurrentProperty,
        },
        {
            icon = 'car',
            label = Lang.t('text.go_to_garage'),
            type = 'server',
            event = 'qb-houses:server:GoToGarage',
            CurrentProperty = CurrentProperty,
        },
    }

    if IsCurrentPropertyOwner then
        options[#options + 1] = {
            icon = 'couch',
            label = Lang.t('text.furniture'),
            type = 'client',
            event = 'qb-houses:client:editFurniture',
            CurrentProperty = CurrentProperty,
        }

        options[#options + 1] = {
            icon = 'users',
            label = Lang.t('text.default_property'),
            type = 'server',
            event = 'qb-houses:server:setDefaultProperty',
            CurrentProperty = CurrentProperty,
        }
    end
    RegisterInPropertyTarget('entrancePos', entrancePos, options)

    local shellData = Config.Shells[interiorRef]
    if not shellData then
        return
    end

    if shellData.stashOffset then
        local stashPos = Vector(entrancePos.X - shellData.stashOffset.x, entrancePos.Y - shellData.stashOffset.y, entrancePos.Z + shellData.stashOffset.z)
        RegisterInPropertyTarget('stashPos', stashPos, {
            {
                icon = 'box-open',
                label = Lang.t('text.open_stash'),
                type = 'server',
                event = 'qb-houses:server:OpenStash',
                CurrentProperty = CurrentProperty,
            },
        })
    end

    if shellData.furnitureOffset then
        local furniturePos = Vector(entrancePos.X - shellData.furnitureOffset.x, entrancePos.Y - shellData.furnitureOffset.y, entrancePos.Z + shellData.furnitureOffset.z)
        RegisterInPropertyTarget('furniturePos', furniturePos, {
            {
                icon = 'box-open',
                label = Lang.t('text.open_furn_stash'),
                type = 'server',
                event = 'qb-houses:server:OpenFurnitureStash',
                CurrentProperty = CurrentProperty,
            },
        })
    end

    if shellData.outfitOffset then
        local outfitsPos = Vector(entrancePos.X - shellData.outfitOffset.x, entrancePos.Y - shellData.outfitOffset.y, entrancePos.Z + shellData.outfitOffset.z)
        RegisterInPropertyTarget('outfitsPos', outfitsPos, {
            {
                icon = 'tshirt',
                label = Lang.t('text.change_outfit'),
                type = 'client',
                event = 'qb-houses:client:ChangeOutfit',
            },
        })
    end

    if shellData.logoutOffset then
        local logoutPos = Vector(entrancePos.X - shellData.logoutOffset.x, entrancePos.Y - shellData.logoutOffset.y, entrancePos.Z + shellData.logoutOffset.z)
        RegisterInPropertyTarget('logoutPos', logoutPos, {
            {
                icon = 'sign-out-alt',
                label = Lang.t('text.logout'),
                type = 'server',
                event = 'qb-houses:server:LogoutProperty',
                CurrentProperty = CurrentProperty,
            },
        })
    end

    if shellData.kitchenOffset then
        local kitchenPos = Vector(entrancePos.X - shellData.kitchenOffset.x, entrancePos.Y - shellData.kitchenOffset.y, entrancePos.Z + shellData.kitchenOffset.z)
        RegisterInPropertyTarget('kitchenPos', kitchenPos, {
            {
                icon = 'utensils',
                label = Lang.t('text.use_kitchen'),
                type = 'client',
                event = 'qb-houses:client:UseKitchen',
            },
        })
    end

    if shellData.fridgeOffset then
        local fridgePos = Vector(entrancePos.X - shellData.fridgeOffset.x, entrancePos.Y - shellData.fridgeOffset.y, entrancePos.Z + shellData.fridgeOffset.z)
        RegisterInPropertyTarget('fridgePos', fridgePos, {
            {
                icon = 'ice-cream',
                label = Lang.t('text.open_fridge'),
                type = 'server',
                event = 'hl-fishing:server:OpenFridge',
                CurrentProperty = CurrentProperty,
            },
        })
    end

    if shellData.totemOffset then
        local totemPos = Vector(entrancePos.X - shellData.totemOffset.x, entrancePos.Y - shellData.totemOffset.y, entrancePos.Z + shellData.totemOffset.z)
        RegisterInPropertyTarget('totemPos', totemPos, {
            {
                icon = 'spa',
                label = Lang.t('text.open_totem'),
                type = 'server',
                event = 'hl-crafting:server:OpenTotem',
                CurrentProperty = CurrentProperty,
            },
        })
    end
end

local function CheckDistance()
    if not InProperty or not propertyEntrance then
        return
    end
    local ped = GetPlayerPawn()
    if not ped then
        return
    end
    local pos = GetEntityCoords(ped)
    local entrancePos = Vector(propertyEntrance.X, propertyEntrance.Y, propertyEntrance.Z)
    local d = GetDistanceBetweenCoords(pos, entrancePos)
    if d > 6000 then
        TriggerServerEvent('qb-houses:server:LeaveProperty', { CurrentProperty = CurrentProperty })
    end
end

local function GetPropertyEntrance()
    if not InProperty or not propertyEntrance then
        return nil
    end
    return propertyEntrance
end
exports('qb-houses', 'GetPropertyEntrance', GetPropertyEntrance)

local function IsInProperty()
    return InProperty
end
exports('qb-houses', 'IsInProperty', IsInProperty)

local function GetCurrentProperty()
    return CurrentProperty
end
exports('qb-houses', 'GetCurrentProperty', GetCurrentProperty)

-- Furniture

local function CreateMemoryDataSource(itemsWrapper)
    local BP_HelixMemoryDataSource = LoadClass('/HelixRemoteResourceModel/Persistence/BP_HelixMemoryDataSource.BP_HelixMemoryDataSource_C')
    local MemoryDataSource = NewObject(BP_HelixMemoryDataSource)
    MemoryDataSource:SetItems(itemsWrapper)
    return MemoryDataSource
end

local function CleanAssetPath(path)
    if not path or path == '' then
        return path
    end
    local dir, filename = path:match('^(.*/)(.*)')
    if not dir then
        return path
    end
    local base, ext = filename:match('^(.-)%.(.+)$')
    if not base then
        return path
    end
    if ext == base or ext == base .. '_C' then
        return dir .. base
    end
    return path
end

local function BuildLibraryFromScene(parsedScene)
    if not parsedScene or not parsedScene.actors then
        return nil
    end
    local libraryItems = {}
    local addedIds = {}
    for _, actorData in pairs(parsedScene.actors) do
        local sourceId = actorData.sourceId
        if sourceId and not addedIds[sourceId] then
            local itemData = sharedItems[sourceId]
            if itemData and itemData.furniturePath then
                libraryItems[#libraryItems + 1] = {
                    id = sourceId,
                    name = itemData.label,
                    asset = CleanAssetPath(itemData.furniturePath),
                    type = itemData.furnitureType == 'blueprint' and 'Blueprint' or 'Mesh',
                    tags = {},
                    preview = 'http://localhost:12890/qb-inventory/html/images/' .. itemData.image,
                    quantity = 0,
                }
                addedIds[sourceId] = true
            end
        end
    end
    if #libraryItems == 0 then
        return nil
    end
    local BP_JsonObjectWrapper = LoadClass('/HelixRemoteResourceModel/Utility/BP_JsonObjectWrapper.BP_JsonObjectWrapper_C')
    local libraryWrapper = NewObject(BP_JsonObjectWrapper)
    libraryWrapper:LoadFromString(JSON.stringify({ items = libraryItems }))
    local libraryDataSource = CreateMemoryDataSource(libraryWrapper)
    libraryDataSource:CreateIndex('id')
    libraryDataSource:CreateIndex('name')
    libraryDataSource:CreateIndex('type')
    libraryDataSource:CreateIndex('tags')
    return libraryDataSource
end

local function LoadFurniture(propertyId)
    if not propertyId then
        return
    end
    if sceneSpawner then
        return
    end
    TriggerCallback('getSceneData', function(sceneJson)
        if not sceneJson or sceneJson == '' then
            return
        end
        local parsedScene = JSON.parse(sceneJson)
        if not parsedScene or not parsedScene.actors then
            return
        end
        local dynamicLibrary = BuildLibraryFromScene(parsedScene)
        if not dynamicLibrary then
            return
        end
        local BP_JsonObjectWrapper = LoadClass('/HelixRemoteResourceModel/Utility/BP_JsonObjectWrapper.BP_JsonObjectWrapper_C')
        local sceneWrapper = NewObject(BP_JsonObjectWrapper)
        local loadSuccess = sceneWrapper:LoadFromString(sceneJson)
        if not loadSuccess then
            return
        end
        local Transform = Transform()
        Transform.Translation = Vector(propertyEntrance.X, propertyEntrance.Y, propertyEntrance.Z)
        sceneSpawner = SpawnActor('/QuietRuntimeEditor/Blueprints/BP_SceneSpawner.BP_SceneSpawner_C', Transform)
        if not sceneSpawner then
            return
        end
        sceneSpawner.OnSceneLoaded:Add(sceneSpawner, function(sceneSpawner)
            local dataComponentClass = LoadClass('/QuietRuntimeEditor/Outliner/Blueprints/BP_QuietOutlinerComponent.BP_QuietOutlinerComponent_C')
            for _, actor in pairs(sceneSpawner.Roots:ToTable()) do
                local actorDataComponent = actor:GetComponentByClass(dataComponentClass)
                if actorDataComponent then
                    local _, sourceId = actorDataComponent:GetSourceId(sourceId)
                    local itemInfo = sharedItems[sourceId]
                    local metadata = {
                        name = itemInfo.label or 'Unknown Item',
                        description = itemInfo.description or '',
                        itemName = sourceId,
                        tier = itemInfo.tier or 'standard',
                        supply = itemInfo.supply,
                        type = itemInfo.type,
                        weight = itemInfo.weight or 0,
                        canPickup = false,
                    }
                    exports['hl-xray']:RegisterEntity(actor, actorDataComponent.Guid, 'furniture', metadata)
                else
                    print('[qb-houses] Failed to register scene actor for Xray')
                end
            end
        end)
        sceneSpawner:SpawnScene(dynamicLibrary, sceneWrapper)
    end, propertyId)
end

local function UnloadFurniture()
    if sceneSpawner then
        sceneSpawner:DestroyScene()
        sceneSpawner:K2_DestroyActor()
        sceneSpawner = nil
    end
end

local BM = GetActorByTag('HBuildMode')

BM.OnSceneSaved:Add(BM, function(_, scene)
    if not CurrentProperty then
        return
    end
    local sceneJson = scene:SaveToString()
    if sceneJson and sceneJson ~= '' then
        local parsedScene = JSON.parse(sceneJson)
        if propertyEntrance and propertyEntrance.Z then
            parsedScene.entranceZ = propertyEntrance.Z
        end
        sceneJson = JSON.stringify(parsedScene)
        TriggerServerEvent('qb-houses:server:SaveSceneData', {
            CurrentProperty = CurrentProperty,
            sceneData = sceneJson,
            oldSceneData = oldSceneData,
        })
        oldSceneData = nil
    end
end)

BM.OnSceneDiscarded:Add(BM, function()
    oldSceneData = nil
    UnloadFurniture()
    LoadFurniture(CurrentProperty)
end)

local function OpenFurnitureEditor()
    if not CurrentProperty then
        return
    end
    UnloadFurniture()
    if not BM then
        print('Failed to spawn BM actor')
        return
    end

    TriggerCallback('getSceneData', function(sceneJson)
        if not sceneJson or sceneJson == '' then
            sceneJson = nil
        end

        local BP_JsonObjectWrapper = LoadClass('/HelixRemoteResourceModel/Utility/BP_JsonObjectWrapper.BP_JsonObjectWrapper_C')
        local furnitureItemsByName = {}

        if sceneJson then
            local sceneData = JSON.parse(sceneJson)
            if sceneData and sceneData.actors then
                for _, actor in pairs(sceneData.actors) do
                    if actor.sourceId and not furnitureItemsByName[actor.sourceId] then
                        local def = sharedItems[actor.sourceId]
                        if def and def.furniturePath then
                            furnitureItemsByName[actor.sourceId] = {
                                id = actor.sourceId,
                                name = def.label or actor.sourceId,
                                asset = CleanAssetPath(def.furniturePath),
                                type = (def.furnitureType == 'blueprint') and 'Blueprint' or 'Mesh',
                                tags = { 'Primitive' },
                                preview = 'http://localhost:12890/qb-inventory/html/images/' .. def.image,
                                quantity = 0,
                            }
                        end
                    end
                end
            end
        end

        TriggerCallback('getInventory', function(inventory)
            for _, invItem in pairs(inventory) do
                if invItem and invItem.name then
                    local def = sharedItems[invItem.name]
                    if def and def.furniturePath then
                        local entry = furnitureItemsByName[invItem.name]
                        if not entry then
                            entry = {
                                id = invItem.name,
                                name = def.label or invItem.name,
                                asset = CleanAssetPath(def.furniturePath),
                                type = (def.furnitureType == 'blueprint') and 'Blueprint' or 'Mesh',
                                tags = { 'Primitive' },
                                preview = 'http://localhost:12890/qb-inventory/html/images/' .. def.image,
                                quantity = invItem.amount or 1,
                            }
                            furnitureItemsByName[invItem.name] = entry
                        else
                            entry.quantity = invItem.amount or 1
                        end
                    end
                end
            end

            local furnitureItems = {}
            for _, entry in pairs(furnitureItemsByName) do
                furnitureItems[#furnitureItems + 1] = entry
            end
            local libraryWrapper = NewObject(BP_JsonObjectWrapper)
            local libraryJson = JSON.stringify({ items = furnitureItems })
            libraryWrapper:LoadFromString(libraryJson)
            local libraryDataSource = CreateMemoryDataSource(libraryWrapper)
            libraryDataSource:CreateIndex('id')
            libraryDataSource:CreateIndex('name')
            libraryDataSource:CreateIndex('type')
            libraryDataSource:CreateIndex('tags')
            local sceneToLoad
            if sceneJson then
                sceneToLoad = sceneJson
            else
                sceneToLoad = JSON.stringify({
                    entranceZ = propertyEntrance.Z,
                    actors = {},
                })
            end
            local existingScene = NewObject(BP_JsonObjectWrapper)
            local loadSuccess = existingScene:LoadFromString(sceneToLoad)
            if not loadSuccess then
                print('Failed to load scene into editor')
                return
            end
            local Transform = Transform()
            Transform.Translation = Vector(propertyEntrance.X, propertyEntrance.Y, propertyEntrance.Z)
            oldSceneData = sceneToLoad
            CreatePropertyBounds()
            -- BM:ActivateSceneEditor(Transform, libraryDataSource, existingScene, propertyVolumeCluster, 1.0)
            BM:ActivateSceneEditor(Transform, libraryDataSource, existingScene, nil, -1.0, true)
        end)
    end, CurrentProperty)
end

-- Cleanup

function onShutdown()
    if intervalTimer then
        Timer.ClearInterval(intervalTimer)
        intervalTimer = nil
    end
    DeleteEntranceTargets()
    DeleteInPropertyTargets()
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    RefreshEntrances()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    InProperty = false
    ClosestEntranceId = nil
    OwnedEntrances = {}
    CurrentProperty = nil
    DeleteEntranceTargets()
    DeleteInPropertyTargets()
end)

local function CreateVehicleTimer()
    if vehicleTimer then
        Timer.ClearInterval(vehicleTimer)
    end
    local playerPawn = GetPlayerPawn(HPlayer)
    local playerCameraManager = HPlayer.PlayerCameraManager
    vehicleTimer = Timer.SetInterval(function()
        local vehicle = GetVehiclePedIsIn(playerPawn)
        if not vehicle then
            return
        end
        local ratio = vehicle:GetRPMRatio() * 1000
        if ratio > 1 then
            playerCameraManager:StartCameraFade(0.0, 1.0, 0.5, LinearColor(0.0, 0.0, 0.0, 1.0), true, true) -- start Fade
            Timer.SetTimeout(function()
                TriggerCallback('WithdrawVehicle', function(success) -- request withdraw after 1s
                    Timer.SetTimeout(function()
                        playerCameraManager:StartCameraFade(1.0, 0.0, 0.5, LinearColor(0.0, 0.0, 0.0, 0.0), false, false) -- unfade 1s after return
                        playerCameraManager:StopCameraFade()
                    end, 1000)
                    if not success then
                        CreateVehicleTimer()
                    end -- if failed, restart timer
                end, CurrentProperty)
            end, 1000)
            Timer.ClearInterval(vehicleTimer)
        end
    end, 800)
end

RegisterClientEvent('qb-houses:client:GarageInteractions', function(garageCoords)
    local options = {
        {
            icon = 'door-open',
            label = Lang.t('text.return_to_apartment'),
            type = 'server',
            event = 'qb-houses:server:ReturnToProperty',
            CurrentProperty = CurrentProperty,
        },
        {
            icon = 'door-open',
            label = Lang.t('text.exit_garage'),
            type = 'server',
            event = 'qb-houses:server:LeaveProperty',
            CurrentProperty = CurrentProperty,
        },
    }
    RegisterInPropertyTarget('garageExit', { X = garageCoords.X, Y = garageCoords.Y, Z = garageCoords.Z }, options)
    CreateVehicleTimer()
end)

RegisterClientEvent('qb-houses:client:EnterEntrance', function(data)
    if InProperty then
        print('Client Enter Entrance - Already in Property')
        return
    end
    if CurrentProperty then
        print('Client Enter Entrance - Already in Property')
        return
    end

    local playerData = exports['qb-core']:GetPlayerData()
    local inside = playerData.metadata and playerData.metadata['inside']
    if inside and inside.property then
        print('Client Enter Entrance - Already in Property')
        return
    end
    local entranceId = data.entranceId
    TriggerServerEvent('qb-houses:server:EnterEntrance', { entranceId = entranceId })
end)

function CreatePropertyBounds()
    if propertyVolumeCluster then
        print('CreatePropertyBounds - propertyVolumeCluster already exists')
        return
    end
    if not propertyInstance then
        print('CreatePropertyBounds - propertyInstance is nil')
        return
    end
    if not CurrentProperty then
        print('CreatePropertyBounds - CurrentProperty is nil')
        return
    end

    local Center, Extent = UE.UKismetSystemLibrary.GetActorBounds(propertyInstance)

    if not Center or not Extent then
        print('CreatePropertyBounds - GetActorBounds failed')
        return
    end

    print('Actor Bounds Center:', Center.X, Center.Y, Center.Z)
    print('Actor Bounds Extent:', Extent.X, Extent.Y, Extent.Z)

    local volumeTransform = Transform()
    volumeTransform.Translation = Center

    local Volume = SpawnActor('/QuietRuntimeEditor/Common/Features/ScaleTool/BP_ShellVolume.BP_ShellVolume_C', volumeTransform)
    Volume:SetBoxExtent(Extent)

    propertyVolumeCluster = SpawnActor('/QuietRuntimeEditor/Common/Features/ScaleTool/BP_ShellVolumeCluster.BP_ShellVolumeCluster_C', volumeTransform)
    propertyVolumeCluster.Tags:Add('property_' .. CurrentProperty)

    AttachActorToActor(Volume, propertyVolumeCluster, nil, nil, '', {
        Location = AttachmentRule.SnapToTarget,
        Rotation = AttachmentRule.SnapToTarget,
        Scale = AttachmentRule.KeepWorld,
    }, false)

    print('Shell volume created for property:', CurrentProperty)
end

RegisterClientEvent('qb-houses:client:EnterProperty', function(propertyKey, interiorRef, shellSpawn, garageCoords, teleportCoords)
    local shellData = Config.Shells[interiorRef]
    local spawnTransform = Transform()
    spawnTransform.Translation = Vector(shellSpawn.X, shellSpawn.Y, shellSpawn.Z)
    propertyInstance = SpawnActor(shellData.shell, spawnTransform)

    if shellData.exterior then
        for _, exterior in pairs(shellData.exterior) do
            local exteriorTransform = Transform()
            exteriorTransform.Translation = Vector(shellSpawn.X, shellSpawn.Y, shellSpawn.Z)
            propertyExterior[#propertyExterior + 1] = SpawnActor(exterior, exteriorTransform)
        end
    end

    if shellData.light and shellData.light ~= '' then
        propertyInstanceLight = SpawnActor(shellData.light, spawnTransform)
    end
    if shellData.garage and shellData.garage ~= '' then
        garageCenter = Vector(garageCoords.X, garageCoords.Y, garageCoords.Z)
        local garageTransform = Transform()
        garageTransform.Translation = garageCenter
        garageInstance = SpawnActor(shellData.garage, garageTransform)
    end
    if shellData.garageLight and shellData.garageLight ~= '' then
        local garageLightTransform = Transform()
        garageLightTransform.Translation = Vector(garageCoords.X, garageCoords.Y, garageCoords.Z)
        garageInstanceLight = SpawnActor(shellData.garageLight, garageLightTransform)
    end
    InProperty = true
    CurrentProperty = propertyKey
    propertyEntrance = teleportCoords
    DeleteEntranceTargets()
    DeleteInPropertyTargets()
    IsCurrentPropertyOwner = false
    TriggerCallback('IsPropertyOwner', function(isOwner)
        IsCurrentPropertyOwner = (isOwner == true)
        DeleteInPropertyTargets()
        SetInPropertyTargets(teleportCoords, interiorRef)
    end, propertyKey)
    LoadFurniture(propertyKey)
    Timer.SetNextTick(function()
        TriggerServerEvent('qb-houses:server:teleportPlayer', teleportCoords)
        distanceInterval = Timer.SetInterval(function()
            CheckDistance()
        end, 1000)
    end)
end)

RegisterClientEvent('qb-houses:client:LeaveProperty', function()
    if distanceInterval then
        Timer.ClearInterval(distanceInterval)
        distanceInterval = nil
    end
    UnloadFurniture()
    if propertyInstance then
        propertyInstance:K2_DestroyActor()
        propertyInstance = nil
    end

    if propertyInstanceLight then
        propertyInstanceLight:K2_DestroyActor()
        propertyInstanceLight = nil
    end
    if garageInstance then
        garageInstance:K2_DestroyActor()
        garageInstance = nil
    end
    if garageInstanceLight then
        garageInstanceLight:K2_DestroyActor()
        garageInstanceLight = nil
    end
    if propertyVolumeCluster then
        propertyVolumeCluster:K2_DestroyActor()
        propertyVolumeCluster = nil
    end
    if propertyExterior then
        for _, exterior in pairs(propertyExterior) do
            if exterior then
                exterior:K2_DestroyActor()
            end
        end
        propertyExterior = {}
    end
    propertyEntrance = nil
    garageCenter = nil
    CurrentProperty = nil
    InProperty = false
    DeleteInPropertyTargets()
    RefreshEntrances()
    if vehicleTimer then
        Timer.ClearInterval(vehicleTimer)
    end
end)

RegisterClientEvent('qb-houses:client:ReloadFurniture', function(propertyKey)
    if propertyKey == CurrentProperty then
        UnloadFurniture()
        Timer.SetTimeout(function()
            LoadFurniture(propertyKey)
        end, 500)
    end
end)

RegisterClientEvent('qb-houses:client:PurchaseMenu', function(data)
    local entranceId = (data and data.entranceId) or ClosestEntranceId
    if not entranceId or not Entrances[entranceId] then
        return
    end
    local entrance = Entrances[entranceId]
    local price = tonumber(entrance.price) or 0
    local menu = {
        {
            header = entrance.label or entranceId,
            txt = ('Price: $%s'):format(price),
            isMenuHeader = true,
        },
        {
            header = 'Buy property',
            txt = 'Confirm purchase',
            params = {
                isServer = true,
                event = 'qb-houses:server:PurchaseProperty',
                args = { entranceId = entranceId },
            },
        },
        {
            header = 'Close',
            params = { event = 'qb-menu:client:closeMenu' },
        },
    }
    exports['qb-menu']:openMenu(menu)
end)

RegisterClientEvent('qb-houses:client:PurchaseProperty', function()
    if ClosestEntranceId then
        OwnedEntrances[ClosestEntranceId] = true
    end
    RefreshEntrances()
end)

RegisterClientEvent('qb-houses:client:ChangeOutfit', function()
    HPlayer:ClothingMenu()
end)

RegisterClientEvent('qb-houses:client:editFurniture', function(_)
    if not IsCurrentPropertyOwner then
        return
    end
    OpenFurnitureEditor()
end)

RegisterClientEvent('qb-houses:client:UseKitchen', function()
    exports['hl-fishing']:OpenKitchen({ station = 'stove' })
end)

-- Visibility & Voice

-- Hide Everyone
RegisterClientEvent('qb-houses:client:HideAllPlayers', function()
    local pawns = GetAllPawns()
    for _, pawn in pairs(pawns) do
        if not pawn:IsLocallyControlled() then
            pawn:SetActorHiddenInGame(true)
        end
    end
end)

-- Show Everyone
RegisterClientEvent('qb-houses:client:ShowAllPlayers', function()
    local pawns = GetAllPawns()
    for _, pawn in pairs(pawns) do
        if not pawn:IsLocallyControlled() then
            pawn:SetActorHiddenInGame(false)
        end
    end
end)

local function FindPawnByPlayerId(targetPlayerId)
    for _, pawn in pairs(GetAllPawns()) do
        local ps = pawn.PlayerState
        if ps and ps:GetPlayerId() == targetPlayerId then
            return pawn
        end
    end
    return nil
end

RegisterClientEvent('qb-houses:client:ShowPlayer', function(targetPlayerId)
    local pawn = FindPawnByPlayerId(targetPlayerId)
    if pawn and not pawn:IsLocallyControlled() then
        pawn:SetActorHiddenInGame(false)
    end
end)

RegisterClientEvent('qb-houses:client:HidePlayer', function(targetPlayerId)
    local pawn = FindPawnByPlayerId(targetPlayerId)
    if pawn and not pawn:IsLocallyControlled() then
        pawn:SetActorHiddenInGame(true)
    end
end)

-- TO DO:
RegisterClientEvent('qb-houses:client:WorldPropertyMenu', function(data)
    local entranceId = data and data.entranceId
    print('[qb-houses] WorldPropertyMenu not implemented yet. entranceId=' .. tostring(entranceId))
end)

-- Loop

intervalTimer = Timer.SetInterval(function()
    if isLoggedIn then
        if not InProperty then
            SetClosestEntrance()
            SetEntranceTargets()
        end
    end
end, 500)

-- Commands

local HConsole = GetActorByTag('HConsole')
HConsole:RegisterCommand('getoffset', 'Property Offset', nil, {
    HWorld,
    function()
        if not InProperty then
            return
        end
        if not CurrentProperty then
            return
        end
        if not propertyEntrance then
            return
        end
        local playerPawn = GetPlayerPawn()
        if not playerPawn then
            return
        end
        local pos = GetEntityCoords(playerPawn)
        local offset = ('{ x = %.2f, y = %.2f, z = %.2f }'):format(pos.X - propertyEntrance.X, pos.Y - propertyEntrance.Y, pos.Z - propertyEntrance.Z)
        CopyToClipboard(offset)
    end,
})

HConsole:RegisterCommand('getgarageoffset', 'Garage Offset', nil, {
    HWorld,
    function()
        if not InProperty then
            return
        end
        if not garageCenter then
            return
        end
        local playerPawn = GetPlayerPawn()
        if not playerPawn then
            return
        end
        local pos = GetEntityCoords(playerPawn)
        local offset = ('{ x = %.2f, y = %.2f, z = %.2f }'):format(garageCenter.X - pos.X, garageCenter.Y - pos.Y, pos.Z - garageCenter.Z)
        CopyToClipboard(offset)
    end,
})
