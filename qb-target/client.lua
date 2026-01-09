local player_data = {}
local isLoggedIn = false
local target_active, target_entity = false, nil
local nui_data, send_data, Entities, Types, Zones, Models = {}, {}, {}, {}, {}, {}
local my_webui = WebUI('qb-target', 'qb-target/html/index.html')

-- UI

my_webui:RegisterEventHandler('selectTarget', function(option)
    option = tonumber(option) or option
    if not next(send_data) then return end
    local data = send_data[option]
    if not data then return end
    disableTarget()
    send_data = {}
    if data.event then
        if data.type == 'server' then
            TriggerServerEvent(data.event, data)
        else
            TriggerLocalClientEvent(data.event, data)
        end
    end
end)

my_webui:RegisterEventHandler('leftTarget', function()
    target_entity = nil
end)

my_webui:RegisterEventHandler('closeTarget', function()
    disableTarget()
end)

-- Handlers

local function registerModels()
    local actors = UE.TArray(UE.AActor)
    local class = UE.UClass.Load("/Script/Engine.StaticMeshActor")
    UE.UGameplayStatics.GetAllActorsOfClass(HWorld, class, actors)
    local lactors = actors:ToTable()
    for _,v in ipairs(lactors) do
        local mesh = v:GetComponentByClass(UE.UStaticMeshComponent)
        if mesh then
            local smesh = mesh.StaticMesh
            if smesh then
                local meshName = smesh:GetName()
                if Models[meshName] then
                    Xray.RegisterActor(v)
                end
            end
        end
    end
end

local function registerGlobalClasses()
    for className in pairs(Types) do
        local actors = UE.TArray(UE.AActor)
        local class = UE.UClass.Load(className)
        if class then
            UE.UGameplayStatics.GetAllActorsOfClass(HWorld, class, actors)
            local lactors = actors:ToTable()
            for k, v in ipairs(lactors) do
                Xray.RegisterActor(v, function() end)
            end
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    player_data = exports['qb-core']:GetPlayerData()
    registerModels()
    registerGlobalClasses()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    player_data = {}
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    player_data.job = JobInfo
end)

RegisterClientEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
    player_data.gang = GangInfo
end)

RegisterClientEvent('QBCore:Player:SetPlayerData', function(val)
    player_data = val
end)

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

-- Functions

local function JobCheck(job)
    if not player_data.job then return false end
    return player_data.job.name == job
end

local function JobTypeCheck(jobType)
    if not player_data.job then return false end
    return player_data.job.type == jobType
end

local function GangCheck(gang)
    if not player_data.gang then return false end
    return player_data.gang.name == gang
end

local function ItemCheck(item)
    return exports['qb-inventory']:HasItem(item)
end

local function CitizenCheck(citizenid)
    return player_data.citizenid == citizenid
end

local function checkOptions(data, entity, distance)
    return not (distance and data.distance and distance > data.distance)
        and (not data.job or JobCheck(data.job))
        and (not data.jobType or JobTypeCheck(data.jobType))
        and (not data.gang or GangCheck(data.gang))
        and (not data.item or ItemCheck(data.item))
        and (not data.citizenid or CitizenCheck(data.citizenid))
        and (not data.canInteract or data.canInteract(entity, distance, data))
end

local function SetOptions(tbl, distance, options)
    for i = 1, #options do
        local v = options[i]
        if v.required_item then
            v.item = v.required_item
            v.required_item = nil
        end
        if not v.distance or v.distance > distance then
            v.distance = distance
        end
        tbl[v.label] = v
    end
end

-- Post Process Setup

Xray.SetOutlineIntensity(Config.InnerlineIntensity, Config.OutlineIntensity)
Xray.SetOutlineColors(Config.HighlightColor, Config.SelectColor)
Xray.SetSelectionMultiplier(1.0)
Xray.SetDetectionDistanceOverride(Config.MaxDistance)

-- Exports

local function AddTargetEntity(entity, parameters)
    if not entity or not parameters then return end
    if type(parameters) ~= 'table' then return end
    if not parameters.options or type(parameters.options) ~= 'table' then return end
    local distance = parameters.distance or Config.MaxDistance
    local options  = parameters.options
    if not options or #options == 0 then return end
    if not Entities[entity] then Entities[entity] = {} end
    SetOptions(Entities[entity], distance, options)
    Xray.RegisterActor(entity)
end
exports('qb-target', 'AddTargetEntity', AddTargetEntity)

local function AddTargetModel(modelName, parameters)
    if not modelName or not parameters then return end
    if type(parameters) ~= 'table' then return end
    if not parameters.options or type(parameters.options) ~= 'table' then return end
    local distance = parameters.distance or Config.MaxDistance
    local options  = parameters.options
    if not options or #options == 0 then return end
    if not Models[modelName] then Models[modelName] = {} end
    SetOptions(Models[modelName], distance, options)
    if isLoggedIn then registerModels() end
end
exports('qb-target', 'AddTargetModel', AddTargetModel)

local function RemoveTargetEntity(entity)
    if not entity then return end
    Entities[entity] = nil
end
exports('qb-target', 'RemoveTargetEntity', RemoveTargetEntity)

local function RemoveTargetModel(modelName)
    if not modelName then return end
    Models[modelName] = nil
end
exports('qb-target', 'RemoveTargetModel', RemoveTargetModel)

local function RemoveZone(name)
    local actor = Zones[name]
    if not actor then return end
    if Entities[actor] then Entities[actor] = nil end
    DeleteEntity(actor)
    Zones[name] = nil
end
exports('qb-target', 'RemoveZone', RemoveZone)

local function AddBoxZone(name, center, length, width, zoneOptions, targetoptions)
    if not name or not center or not length or not width or not zoneOptions or not targetoptions then return end
    if Zones[name] then return end
    local yaw_degrees = zoneOptions.heading or zoneOptions.yaw or 0.0
    local minZ, maxZ = zoneOptions.minZ, zoneOptions.maxZ
    local height = (minZ and maxZ) and math.abs(maxZ - minZ) or (zoneOptions.height or zoneOptions.fullHeight or 200.0)
    local spawnCenter = UE.FVector(center.X, center.Y, center.Z)
    if minZ and maxZ then spawnCenter.Z = (minZ + maxZ) * 0.5 end
    local xform       = UE.FTransform()
    xform.Translation = spawnCenter
    xform.Rotation    = UE.FQuat(0, 0, math.sin(math.rad(yaw_degrees) * 0.5), math.cos(math.rad(yaw_degrees) * 0.5))
    local actor       = HWorld:SpawnActor(UE.AActor, xform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if not actor then return nil end
    local box = actor:AddComponentByClass(UE.UBoxComponent, false, xform, false)
    if not box then return nil end
    local full = UE.FVector(length, width, height)
    local half = UE.FVector(full.X * 0.5, full.Y * 0.5, full.Z * 0.5)
    box:SetBoxExtent(half, true)
    local debug = (zoneOptions.debug ~= nil) and zoneOptions.debug or false
    box:SetHiddenInGame(not debug, true)
    box:SetVisibility(debug, true)
    box:SetCastShadow(false)
    box:SetMobility(UE.EComponentMobility.Stationary)
    box:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    box:SetCollisionObjectType(UE.ECollisionChannel.ECC_WorldDynamic)
    box:SetGenerateOverlapEvents(false)
    box:SetCollisionResponseToAllChannels(UE.ECollisionResponse.ECR_Ignore)
    box:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Visibility, UE.ECollisionResponse.ECR_Block)
    Zones[name] = actor
    AddTargetEntity(actor, {
        distance = zoneOptions.distance or Config.MaxDistance,
        options  = targetoptions
    })
end
exports('qb-target', 'AddBoxZone', AddBoxZone)

local function AddSphereZone(name, center, radius, zoneOptions, targetoptions)
    if not name or not center or not radius or not zoneOptions or not targetoptions then return end
    if Zones[name] then return end
    local spawnCenter = UE.FVector(center.X, center.Y, center.Z)
    local xform       = UE.FTransform()
    xform.Translation = spawnCenter
    xform.Rotation    = UE.FQuat(0, 0, 0, 1)
    local actor       = HWorld:SpawnActor(UE.AActor, xform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if not actor then return nil end
    local sphere = actor:AddComponentByClass(UE.USphereComponent, false, xform, false)
    if not sphere then return nil end
    sphere:SetSphereRadius(radius, true)
    local debug = (zoneOptions.debug ~= nil) and zoneOptions.debug or false
    sphere:SetHiddenInGame(not debug, true)
    sphere:SetVisibility(debug, true)
    sphere:SetCastShadow(false)
    sphere:SetMobility(UE.EComponentMobility.Stationary)
    sphere:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    sphere:SetCollisionObjectType(UE.ECollisionChannel.ECC_WorldDynamic)
    sphere:SetGenerateOverlapEvents(false)
    sphere:SetCollisionResponseToAllChannels(UE.ECollisionResponse.ECR_Ignore)
    sphere:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Visibility, UE.ECollisionResponse.ECR_Block)
    Zones[name] = actor
    AddTargetEntity(actor, {
        distance = zoneOptions.distance or Config.MaxDistance,
        options  = targetoptions
    })
end
exports('qb-target', 'AddSphereZone', AddSphereZone)

local function AddMeshTarget(name, location, rotation, meshPath, meshOptions, targetOptions)
    if not name or not location or not meshPath or not meshOptions or not targetOptions then
        print('AddStaticMeshTarget: Missing required parameters')
        return
    end
    if Zones[name] then return end
    local collisionType = meshOptions.collision or CollisionType.Auto
    local bStationary = meshOptions.stationary
    if bStationary == nil then bStationary = true end
    local distance = meshOptions.distance or Config.MaxDistance
    local meshWrapper = StaticMesh(
        location,
        rotation or UE.FRotator(0, 0, 0),
        meshPath,
        collisionType,
        bStationary
    )
    local actor = meshWrapper.Object
    Zones[name] = actor
    AddTargetEntity(actor, {
        distance = distance,
        options = targetOptions
    })
end
exports('qb-target', 'AddMeshTarget', AddMeshTarget)

local function AddGlobalClass(className, parameters)
    if not className or not parameters then return end
    if type(parameters) ~= 'table' then return end
    if not parameters.options or type(parameters.options) ~= 'table' then return end
    if type(className) == 'userdata' then className = className:GetName() end
    if type(className) ~= 'string' then return end
    local distance = parameters.distance or Config.MaxDistance
    local options  = parameters.options
    if not options or #options == 0 then return end
    if not Types[className] then Types[className] = {} end
    SetOptions(Types[className], distance, options)
    if isLoggedIn then registerGlobalClasses() end
end
exports('qb-target', 'AddGlobalClass', AddGlobalClass)

local function AddGlobalNPC(parameters)
    if not parameters then return end
    if type(parameters) ~= 'table' then return end
    if not parameters.options or type(parameters.options) ~= 'table' then return end
    local distance = parameters.distance or Config.MaxDistance
    local options  = parameters.options
    if not options or #options == 0 then return end
    local npcClassName = "BP_Character_NPC_Helix_Sandbox_C"
    if not Types[npcClassName] then Types[npcClassName] = {} end
    -- for _, option in ipairs(options) do
    --     option.canInteract = function(entity)
    --         local controller = entity:GetController()
    --         if not controller then return false end
    --         if not controller:IsA(UE.AHAIController) then return false end
    --         return true
    --     end
    -- end
    SetOptions(Types[npcClassName], distance, options)
    if isLoggedIn then registerGlobalClasses() end
end
exports('qb-target', 'AddGlobalNPC', AddGlobalNPC)

local function AddGlobalPlayer(parameters)
    if not parameters then return end
    if type(parameters) ~= 'table' then return end
    if not parameters.options or type(parameters.options) ~= 'table' then return end
    local distance = parameters.distance or Config.MaxDistance
    local options  = parameters.options
    if not options or #options == 0 then return end
    local playerClassName = "BP_Character_Player_Helix_Sandbox_C"
    if not Types[playerClassName] then Types[playerClassName] = {} end
    for _, option in ipairs(options) do
        option.canInteract = function(entity)
            local controller = entity:GetController()
            if controller == HPlayer then return false end
            if not entity:IsPlayerControlled() then return false end
            return true
        end
    end
    SetOptions(Types[playerClassName], distance, options)
    if isLoggedIn then registerGlobalClasses() end
end
exports('qb-target', 'AddGlobalPlayer', AddGlobalPlayer)

local function setupOptions(datatable, entity, distance)
    if not datatable then return end
    for _, data in pairs(datatable) do
        if checkOptions(data, entity, distance) then
            local new_option = {
                icon = data.icon,
                targeticon = data.targetIcon,
                label = data.label,
                subLabel = data.subLabel,
            }
            local index = #nui_data + 1
            nui_data[index] = new_option
            send_data[index] = data
            send_data[index].entity = entity
        end
    end
end

local function enableTarget()
    if target_active then return end
    target_active = true
    --if my_webui then my_webui:SendEvent('openTarget') end
end

function disableTarget()
    if not target_active then return end
    target_active, target_entity = false, nil
    nui_data, send_data = {}, {}
    if my_webui then
        my_webui:SendEvent('closeTarget')
        my_webui:SetInputMode(0)
    end
end

local function clearTarget()
    if not target_entity then return end
    target_entity = nil
    nui_data = {}
    if my_webui then my_webui:SendEvent('leftTarget') end
end

local function GetModelKeyFromActor(actor)
    if not actor then return nil end
    local smc = actor:GetComponentByClass(UE.UStaticMeshComponent)
    if not smc or not smc.StaticMesh then return nil end
    local sm = smc.StaticMesh
    return (sm.GetName and sm:GetName()) or nil
end

Xray.RegisterListener(function(controller, target, state)
    if not isLoggedIn then return end
    if state == XrayState.BeginFocus then
        enableTarget()

        local entity_has_options = Entities[target]
        local className          = target:GetClass():GetName()
        local type_has_options   = Types[className]
        local modelKey           = GetModelKeyFromActor(target)
        local model_has_options  = Models[modelKey]

        if not entity_has_options and not type_has_options and not model_has_options then
            clearTarget()
            return
        end

        if target_entity ~= target then
            clearTarget()
            target_entity = target
            nui_data = {}

            local distance = GetDistanceBetweenActors(GetPlayerPawn(), target)

            if entity_has_options then setupOptions(entity_has_options, target, distance) end
            if type_has_options   then setupOptions(type_has_options,   target, distance) end
            if model_has_options  then setupOptions(model_has_options,  target, distance) end

            if #nui_data > 0 and my_webui then
                local target_icon = nui_data[1].targeticon or ''
                my_webui:SendEvent('foundTarget', { icon = target_icon, options = nui_data })
            end
        end
    elseif state == XrayState.EndFocus then
        clearTarget()
    elseif state == XrayState.Reveal then
        if target_active and target_entity and nui_data and nui_data[1] then
            my_webui:BringToFront()
            my_webui:SetInputMode(1)
        end
    elseif state == XrayState.Cancel then
        disableTarget()
    end
end)