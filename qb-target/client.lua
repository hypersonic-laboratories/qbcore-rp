local player_data = {}
local isLoggedIn = false
local playerController = nil
local target_active, target_entity, raycast_timer, target_component = false, nil, nil, nil
local nearby_scan_timer = nil
local nearby_components = {} -- Track components showing stencil 1
local nui_data, send_data, Entities, Types, Zones, Models = {}, {}, {}, {}, {}, {}
local my_webui = WebUI('qb-target', 'qb-target/html/index.html')
local subMenuOpen = false

-- UI

my_webui:RegisterEventHandler('selectTarget', function(option)
    option = tonumber(option) or option
    subMenuOpen = false
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

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    player_data = exports['qb-core']:GetPlayerData()
    if HPlayer then
        playerController = HPlayer
    elseif not HPlayer then
        playerController = UE.UGameplayStatics.GetPlayerController(HWorld, 0)
    end
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    player_data = {}
    isLoggedIn = false
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
local OutlinePPPath = '/Game/Effects/Materials/PostProcess/MPP_Outline_Inst.MPP_Outline_Inst'
local OutlinePPMaterial = UE.UObject.Load(OutlinePPPath)

-- Scalar Parameters
local scalarParams = OutlinePPMaterial.ScalarParameterValues
local InnerlineIntensity = scalarParams[1]
local OutlineIntensity = scalarParams[2]
InnerlineIntensity.ParameterValue = Config.InnerlineIntensity
OutlineIntensity.ParameterValue = Config.OutlineIntensity
scalarParams[1] = InnerlineIntensity
scalarParams[2] = OutlineIntensity
OutlinePPMaterial.ScalarParameterValues = scalarParams

-- Vector Parameters
local vectorParams = OutlinePPMaterial.VectorParameterValues
local highlight = vectorParams[1]
highlight.ParameterValue = UE.FLinearColor(Config.HighlightColor.R, Config.HighlightColor.G, Config.HighlightColor.B, Config.HighlightColor.A)
local select = vectorParams[2]
select.ParameterValue = UE.FLinearColor(Config.SelectColor.R, Config.SelectColor.G, Config.SelectColor.B, Config.SelectColor.A)
vectorParams[1] = highlight
vectorParams[2] = select
OutlinePPMaterial.VectorParameterValues = vectorParams

local OutlinePPIndex = nil
local function ToggleOutlinePP(enable)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local camera = pawn:GetComponentByClass(UE.UCameraComponent)
    if not camera then return end
    local settings = camera.PostProcessSettings
    local array = settings.WeightedBlendables.Array
    if not array then return end
    local newWeight = enable and 1.0 or 0.0
    if OutlinePPIndex ~= nil then
        local blend = array[OutlinePPIndex]
        if blend and blend.Object == OutlinePPMaterial then
            blend.Weight = newWeight
            return
        else
            OutlinePPIndex = nil
        end
    end
    local foundIndex = nil
    for i, blend in ipairs(array) do
        if blend.Object == OutlinePPMaterial then
            foundIndex = i
            break
        end
    end
    if not foundIndex then
        local newBlend = UE.FWeightedBlendable()
        newBlend.Object = OutlinePPMaterial
        newBlend.Weight = newWeight
        table.insert(array, newBlend)
        OutlinePPIndex = #array
        settings.WeightedBlendables.Array = array
        return
    end
    local blend = array[foundIndex]
    blend.Weight = newWeight
    array[foundIndex] = blend
    OutlinePPIndex = foundIndex
end

local function ShowPostProcessOnComponent(comp, stencilValue)
    if not comp then return end
    local enable = stencilValue > 0
    comp:SetRenderCustomDepth(enable)
    comp:SetCustomDepthStencilValue(stencilValue)
end

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
    for _, option in ipairs(options) do
        option.canInteract = function(entity)
            local controller = entity:GetController()
            if not controller then return false end
            local controllerClassName = controller:GetClass():GetName()
            if controllerClassName ~= "B_AI_Controller_C" then return false end
            return true
        end
    end
    SetOptions(Types[npcClassName], distance, options)
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
            if not controller then return false end
            local controllerClassName = controller:GetClass():GetName()
            if controllerClassName ~= "BP_HelixPlayerController_C" then return false end
            if controller == HPlayer then return false end
            return true
        end
    end
    SetOptions(Types[playerClassName], distance, options)
end
exports('qb-target', 'AddGlobalPlayer', AddGlobalPlayer)

local function GetPrimitiveComponents(actor)
    if not actor then return {} end
    local components = {}
    local allComps = actor:K2_GetComponentsByClass(UE.UPrimitiveComponent)
    if allComps then
        for _, comp in pairs(allComps) do
            table.insert(components, comp)
        end
    end
    return components
end

local function ClearAllNearbyHighlights()
    for comp, _ in pairs(nearby_components) do
        ShowPostProcessOnComponent(comp, 0)
    end
    nearby_components = {}
end

local function UpdateNearbyInteractables()
    if not target_active then return end

    local playerPos = GetEntityCoords(GetPlayerPawn())
    if not playerPos then return end
    local stillNearby = {}
    for entity, options in pairs(Entities) do
        if entity and entity:IsValid() then
            local entityPos = GetEntityCoords(entity)
            local distance = GetDistanceBetweenCoords(playerPos, entityPos)
            local hasValidOptions = false
            for _, data in pairs(options) do
                if checkOptions(data, entity, distance) then
                    hasValidOptions = true
                    break
                end
            end
            if hasValidOptions then
                local components = GetPrimitiveComponents(entity)
                for _, comp in ipairs(components) do
                    if comp and comp:IsValid() then
                        if comp ~= target_component then
                            if not nearby_components[comp] then
                                ShowPostProcessOnComponent(comp, 1)
                            end
                            stillNearby[comp] = true
                        end
                    end
                end
            end
        end
    end
    for comp, _ in pairs(nearby_components) do
        if not stillNearby[comp] and comp ~= target_component then
            ShowPostProcessOnComponent(comp, 0)
        end
    end
    nearby_components = stillNearby
end

local function clearTarget()
    if not target_entity then return end
    if target_component then
        local playerPos = GetEntityCoords(GetPlayerPawn())
        if playerPos and target_entity:IsValid() then
            local entityPos = GetEntityCoords(target_entity)
            local distance = GetDistanceBetweenCoords(playerPos, entityPos)
            local hasValidOptions = false
            local options = Entities[target_entity]
            if options then
                for _, data in pairs(options) do
                    if checkOptions(data, target_entity, distance) then
                        hasValidOptions = true
                        break
                    end
                end
            end
            if hasValidOptions then
                ShowPostProcessOnComponent(target_component, 1)
                nearby_components[target_component] = true
            else
                ShowPostProcessOnComponent(target_component, 0)
            end
        else
            ShowPostProcessOnComponent(target_component, 0)
        end
        target_component = nil
    end
    target_entity = nil
    nui_data = {}
    if my_webui then
        my_webui:SendEvent('leftTarget')
    end
end

local function setupOptions(datatable, entity, distance)
    if not datatable then return end
    for _, data in pairs(datatable) do
        if checkOptions(data, entity, distance) then
            local new_option = {
                icon = data.icon,
                targeticon = data.targetIcon,
                label = data.label,
            }
            local index = #nui_data + 1
            nui_data[index] = new_option
            send_data[index] = data
            send_data[index].entity = entity
        end
    end
end

local function handleEntity(trace_result)
    if not trace_result or not trace_result.Entity or not trace_result.Success then
        clearTarget()
        return
    end
    local entity_has_options = Entities[trace_result.Entity]
    local type_has_options = Types[trace_result.ClassName]
    local model_has_options = Models[tostring(trace_result.MeshName)]
    if not entity_has_options and not type_has_options and not model_has_options then
        clearTarget()
        return
    end
    if target_entity ~= trace_result.Entity then
        clearTarget()
        target_entity = trace_result.Entity
        target_component = trace_result.ComponentName
        nui_data = {}
        ShowPostProcessOnComponent(target_component, 2)
        nearby_components[target_component] = nil
        local distance = trace_result.Distance
        local entity_options = Entities[target_entity]
        local type_options = Types[trace_result.ClassName]
        local model_options = Models[tostring(trace_result.MeshName)]
        if entity_options then setupOptions(entity_options, target_entity, distance) end
        if type_options then setupOptions(type_options, target_entity, distance) end
        if model_options then setupOptions(model_options, target_entity, distance) end
        if #nui_data > 0 then
            local target_icon = nui_data[1] and nui_data[1].targeticon or ''
            if my_webui then
                my_webui:SendEvent('foundTarget', { icon = target_icon, options = nui_data })
            end
        end
    end
end

local function handleRaycast()
    if not target_active then return end
    if not playerController then return end
    local w, h = playerController:GetViewportSize()
    local sp = UE.FVector2D(w * 0.5, h * 0.5)
    local pos, dir = UE.FVector(), UE.FVector()
    if not UE.UGameplayStatics.DeprojectScreenToWorld(playerController, sp, pos, dir) then return end
    local startOffset = Config.RaycastStartOffset or 25.0
    local start = pos + dir * startOffset
    local stop = start + dir * Config.MaxDistance
    local hit = Trace:LineSingle(start, stop, UE.ETraceTypeQuery.Visibility, UE.EDrawDebugTrace.None)
    local trace_result = nil
    if hit then
        local bBlockingHit, bInitialOverlap, time, distance, location, impactPoint, normal, impactNormal, physMat, hitActor, hitComp, hitBoneName, boneName, hitItem, elementIndex, faceIndex, traceStart, traceEnd = UE.UGameplayStatics.BreakHitResult(hit)
        local actor = hitActor
        if not actor and hitComp then
            actor = hitComp:GetOwner()
        end
        if actor then
            trace_result = {}
            trace_result.Entity = hitActor
            trace_result.ComponentName = hitComp
            trace_result.Location = location
            trace_result.ImpactPoint = impactPoint
            trace_result.Normal = normal
            trace_result.ImpactNormal = impactNormal
            trace_result.Distance = distance
            trace_result.HitBoneName = hitBoneName
            trace_result.BoneName = boneName
            trace_result.PhysMat = physMat
            trace_result.BlockingHit = bBlockingHit
            trace_result.Success = true
            trace_result.ActorName = hitActor:GetName()
            trace_result.Mesh = hitComp.StaticMesh and hitComp.StaticMesh or nil
            trace_result.MeshName = hitComp.StaticMesh and hitComp.StaticMesh:GetName() or nil
            trace_result.Class = hitActor:GetClass()
            trace_result.ClassName = hitActor:GetClass():GetName()
        end
    end
    return trace_result
end

function enableTarget()
    if target_active then return end
    target_active = true
    ToggleOutlinePP(true)
    my_webui:SendEvent('openTarget')
    local raycastInterval = Config.RaycastInterval or 100
    raycast_timer = Timer.SetInterval(function()
        local trace_result = handleRaycast()
        handleEntity(trace_result)
    end, raycastInterval)
    local nearbyScanInterval = Config.NearbyScanInterval or 500
    nearby_scan_timer = Timer.SetInterval(function()
        UpdateNearbyInteractables()
    end, nearbyScanInterval)
end

function disableTarget()
    if not target_active then return end
    if target_component then
        ShowPostProcessOnComponent(target_component, 0)
        target_component = nil
    end
    ClearAllNearbyHighlights()
    ToggleOutlinePP(false)
    target_active, target_entity = false, nil
    nui_data, send_data = {}, {}
    if my_webui then
        my_webui:SendEvent('closeTarget')
        my_webui:SetInputMode(0)
    end
    if raycast_timer then
        Timer.ClearInterval(raycast_timer)
        raycast_timer = nil
    end
    if nearby_scan_timer then
        Timer.ClearInterval(nearby_scan_timer)
        nearby_scan_timer = nil
    end
end

-- Inputs

Input.BindKey(Config.OpenKey, function()
    if not isLoggedIn then return end
    if target_active then return end
    if HPlayer:GetInputMode() == 1 then return end
    enableTarget()
end, 'Pressed')

Input.BindKey(Config.OpenKey, function()
    if not isLoggedIn then return end
    if HPlayer:GetInputMode() == 1 then return end
    if target_active and not subMenuOpen then
        disableTarget()
        subMenuOpen = false
    end
end, 'Released')

Input.BindKey(Config.MenuControlKey, function()
    if not isLoggedIn then return end
    if target_active and target_entity and nui_data and nui_data[1] then
        subMenuOpen = true
        my_webui:BringToFront()
        my_webui:SetInputMode(1)
    end
end, 'Pressed')
