local player_data = {}
local isLoggedIn = false
local target_active, target_entity = false, nil
local nui_data, send_data = {}, {}
local Entities, Types, TypeClasses, Zones, Models = {}, {}, {}, {}, {}
local my_webui = WebUI('qb-target', 'qb-target/html/index.html')
local scanTimerId = nil
local rescanQueued = false
local StaticMeshActorClass = nil
-- mesh names are cached per actor; actors that swap their static mesh at
-- runtime are not re-evaluated
local actorMeshNames = setmetatable({}, { __mode = 'k' })

-- Post Process Setup

Xray.SetOutlineIntensity(Config.InnerlineIntensity, Config.OutlineIntensity)
Xray.SetOutlineColors(Config.HighlightColor, Config.SelectColor)
Xray.SetSelectionMultiplier(1.0)
Xray.SetDetectionDistanceOverride(Config.DetectionDistance)
-- note: MinFocusDistance is a true minimum (focus requires being farther than
-- it, default 0) despite the API doc phrasing — do not use it as a range cap

-- Functions

local function isActorValid(actor)
    return actor ~= nil and (not actor.IsValid or actor:IsValid())
end

local function ensureXrayComponent(actor)
    if not isActorValid(actor) then
        return
    end
    local comps = actor:GetComponentsByClass(UE.UHXRayTargetActorComponent)
    local lcomps = comps and comps:ToTable() or {}
    if #lcomps == 0 then
        Xray.RegisterActor(actor)
        return
    end
    -- worlds that ran older builds have surplus Xray components stacked on
    -- actors, which emit conflicting focus events; keep one, destroy the rest
    for i = 2, #lcomps do
        local comp = lcomps[i]
        if comp:IsValid() then
            comp.OnXRayStateChangedEvent:Clear()
            comp:DestroyComponent(actor)
        end
    end
end

local function removeXrayComponent(actor)
    if not isActorValid(actor) then
        return
    end
    local comps = actor:GetComponentsByClass(UE.UHXRayTargetActorComponent)
    local lcomps = comps and comps:ToTable() or {}
    for i = 1, #lcomps do
        local comp = lcomps[i]
        if comp:IsValid() then
            comp.OnXRayStateChangedEvent:Clear()
            comp:DestroyComponent(actor)
        end
    end
end

local function GetModelKeyFromActor(actor)
    if not actor then
        return nil
    end
    local cached = actorMeshNames[actor]
    if cached ~= nil then
        return cached or nil
    end
    local meshName = nil
    local smc = actor:GetComponentByClass(UE.UStaticMeshComponent)
    if smc and smc.StaticMesh then
        local sm = smc.StaticMesh
        meshName = (sm.GetName and sm:GetName()) or nil
    end
    actorMeshNames[actor] = meshName or false
    return meshName
end

local function getStaticMeshActorClass()
    if not StaticMeshActorClass then
        StaticMeshActorClass = UE.UClass.Load('/Script/Engine.StaticMeshActor')
    end
    return StaticMeshActorClass
end

-- Types is keyed by class name; TypeClasses maps the same key to the loaded
-- UClass, or false when the key has no loadable path (blueprint short names
-- like BP_Character_NPC_Helix_Sandbox_C)
local function resolveTypeClass(classKey)
    local cached = TypeClasses[classKey]
    if cached ~= nil then
        return cached or nil
    end
    local ok, class = pcall(UE.UClass.Load, classKey)
    class = (ok and class) or nil
    TypeClasses[classKey] = class or false
    return class
end

local function getTypeOptionTables(target)
    local matches = {}
    local className = target:GetClass():GetName()
    for classKey, options in pairs(Types) do
        if classKey == className then
            matches[#matches + 1] = options
        else
            local class = TypeClasses[classKey]
            if class and target:IsA(class) then
                matches[#matches + 1] = options
            end
        end
    end
    return matches
end

local function actorHasOptions(actor)
    if Entities[actor] then
        return true
    end
    if #getTypeOptionTables(actor) > 0 then
        return true
    end
    local modelKey = GetModelKeyFromActor(actor)
    if modelKey and Models[modelKey] then
        return true
    end
    return false
end

local function registerModels()
    if not next(Models) then
        return
    end
    local class = getStaticMeshActorClass()
    if not class then
        return
    end
    local actors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(HWorld, class, actors)
    local lactors = actors:ToTable()
    for _, actor in ipairs(lactors) do
        local meshName = GetModelKeyFromActor(actor)
        if meshName and Models[meshName] then
            ensureXrayComponent(actor)
        end
    end
end

local function registerGlobalClasses()
    local unresolved = nil
    for classKey in pairs(Types) do
        local class = resolveTypeClass(classKey)
        if class then
            local actors = UE.TArray(UE.AActor)
            UE.UGameplayStatics.GetAllActorsOfClass(HWorld, class, actors)
            local lactors = actors:ToTable()
            for _, actor in ipairs(lactors) do
                ensureXrayComponent(actor)
            end
        else
            unresolved = unresolved or {}
            unresolved[classKey] = true
        end
    end
    -- classes without a loadable path can only be matched by name; scan live
    -- pawns since those keys are all character classes
    if unresolved then
        local actors = UE.TArray(UE.AActor)
        UE.UGameplayStatics.GetAllActorsOfClass(HWorld, UE.APawn, actors)
        local lactors = actors:ToTable()
        for _, actor in ipairs(lactors) do
            if unresolved[actor:GetClass():GetName()] then
                ensureXrayComponent(actor)
            end
        end
    end
end

-- batches bursts of Add* calls (resource startup) into a single world scan
local function queueRescan()
    if not isLoggedIn or rescanQueued then
        return
    end
    rescanQueued = true
    Timer.SetTimeout(function()
        rescanQueued = false
        if not isLoggedIn then
            return
        end
        registerModels()
        registerGlobalClasses()
    end, 100)
end

local function sweepInvalidTargets()
    for actor in pairs(Entities) do
        if not isActorValid(actor) then
            Entities[actor] = nil
        end
    end
    for name, actor in pairs(Zones) do
        if not isActorValid(actor) then
            Zones[name] = nil
        end
    end
    if target_entity and not isActorValid(target_entity) then
        disableTarget()
    end
end

local function startScanTimer()
    if scanTimerId then
        return
    end
    scanTimerId = Timer.SetInterval(function()
        if not isLoggedIn then
            return
        end
        registerModels()
        registerGlobalClasses()
        sweepInvalidTargets()
    end, Config.NearbyScanInterval)
end

local function stopScanTimer()
    if not scanTimerId then
        return
    end
    Timer.ClearTimeout(scanTimerId)
    scanTimerId = nil
end

local function JobCheck(job)
    if not player_data.job then
        return false
    end
    return player_data.job.name == job
end

local function JobTypeCheck(jobType)
    if not player_data.job then
        return false
    end
    return player_data.job.type == jobType
end

local function GangCheck(gang)
    if not player_data.gang then
        return false
    end
    return player_data.gang.name == gang
end

local function ItemCheck(item)
    return exports['qb-inventory']:HasItem(item)
end

local function CitizenCheck(citizenid)
    return player_data.citizenid == citizenid
end

local function checkOptions(data, entity, distance)
    return not (distance and data.distance and distance > data.distance) and (not data.job or JobCheck(data.job)) and (not data.jobType or JobTypeCheck(data.jobType)) and (not data.gang or GangCheck(data.gang)) and (not data.item or ItemCheck(data.item)) and (not data.citizenid or CitizenCheck(data.citizenid)) and (not data.canInteract or data.canInteract(entity, distance, data))
end

-- stores a copy of each option so registration never mutates caller tables
local function SetOptions(tbl, distance, options)
    for i = 1, #options do
        local option = {}
        for k, v in pairs(options[i]) do
            option[k] = v
        end
        if option.required_item then
            option.item = option.required_item
            option.required_item = nil
        end
        if not option.distance or option.distance > distance then
            option.distance = distance
        end
        tbl[option.label] = option
    end
end

local function setupOptions(datatable, entity, distance)
    if not datatable then
        return
    end
    for _, data in pairs(datatable) do
        if checkOptions(data, entity, distance) then
            local index = #nui_data + 1
            nui_data[index] = {
                icon = data.icon,
                targeticon = data.targetIcon,
                label = data.label,
                subLabel = data.subLabel,
            }
            local send = {}
            for k, v in pairs(data) do
                send[k] = v
            end
            send.entity = entity
            send_data[index] = send
        end
    end
end

local function enableTarget()
    if target_active then
        return
    end
    target_active = true
    --if my_webui then my_webui:SendEvent('openTarget') end
end

function disableTarget()
    if not target_active then
        return
    end
    target_active, target_entity = false, nil
    nui_data, send_data = {}, {}
    if my_webui then
        my_webui:SendEvent('closeTarget')
        my_webui:SetInputMode(0)
    end
end

local function clearTarget()
    if not target_entity and not next(nui_data) and not next(send_data) then
        return
    end
    target_entity = nil
    nui_data, send_data = {}, {}
    if my_webui then
        my_webui:SendEvent('leftTarget')
    end
end

local function focusTargetUi()
    if not my_webui then
        return
    end
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
end

-- UI

my_webui:RegisterEventHandler('selectTarget', function(option)
    option = tonumber(option) or option
    if not next(send_data) then
        return
    end
    local data = send_data[option]
    if not data then
        return
    end
    disableTarget()
    if not data.event then
        return
    end
    local entity = data.entity
    if entity and not isActorValid(entity) then
        return
    end
    -- requirements may have changed since the menu was built (player moved
    -- away, item consumed), so re-run the option checks before firing
    local distance = entity and GetDistanceBetweenActors(GetPlayerPawn(), entity) or nil
    if not checkOptions(data, entity, distance) then
        return
    end
    if data.type == 'server' then
        -- functions (canInteract) cannot cross the network boundary
        local payload = {}
        for k, v in pairs(data) do
            if type(v) ~= 'function' then
                payload[k] = v
            end
        end
        TriggerServerEvent(data.event, payload)
    else
        TriggerLocalClientEvent(data.event, data)
    end
end)

my_webui:RegisterEventHandler('leftTarget', function()
    target_entity = nil
end)

my_webui:RegisterEventHandler('closeTarget', function()
    disableTarget()
end)

function onShutdown()
    stopScanTimer()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

-- Exports

local function AddTargetEntity(entity, parameters)
    if not entity or not parameters then
        return
    end
    if type(parameters) ~= 'table' then
        return
    end
    if not parameters.options or type(parameters.options) ~= 'table' then
        return
    end
    local distance = parameters.distance or Config.MaxDistance
    local options = parameters.options
    if not options or #options == 0 then
        return
    end
    if not Entities[entity] then
        Entities[entity] = {}
    end
    SetOptions(Entities[entity], distance, options)
    ensureXrayComponent(entity)
end
exports('qb-target', 'AddTargetEntity', AddTargetEntity)

local function AddTargetModel(modelName, parameters)
    if not modelName or not parameters then
        return
    end
    if type(parameters) ~= 'table' then
        return
    end
    if not parameters.options or type(parameters.options) ~= 'table' then
        return
    end
    local distance = parameters.distance or Config.MaxDistance
    local options = parameters.options
    if not options or #options == 0 then
        return
    end
    if not Models[modelName] then
        Models[modelName] = {}
    end
    SetOptions(Models[modelName], distance, options)
    queueRescan()
end
exports('qb-target', 'AddTargetModel', AddTargetModel)

local function RemoveTargetEntity(entity)
    if not entity then
        return
    end
    Entities[entity] = nil
    if isActorValid(entity) and not actorHasOptions(entity) then
        removeXrayComponent(entity)
    end
end
exports('qb-target', 'RemoveTargetEntity', RemoveTargetEntity)

local function RemoveTargetModel(modelName)
    if not modelName then
        return
    end
    Models[modelName] = nil
    if not isLoggedIn then
        return
    end
    local class = getStaticMeshActorClass()
    if not class then
        return
    end
    local actors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(HWorld, class, actors)
    local lactors = actors:ToTable()
    for _, actor in ipairs(lactors) do
        if GetModelKeyFromActor(actor) == modelName and not actorHasOptions(actor) then
            removeXrayComponent(actor)
        end
    end
end
exports('qb-target', 'RemoveTargetModel', RemoveTargetModel)

local function RemoveZone(name)
    local actor = Zones[name]
    if not actor then
        return
    end
    if Entities[actor] then
        Entities[actor] = nil
    end
    DeleteEntity(actor)
    Zones[name] = nil
end
exports('qb-target', 'RemoveZone', RemoveZone)

local function AddBoxZone(name, center, length, width, zoneOptions, targetoptions)
    if not name or not center or not length or not width or not zoneOptions or not targetoptions then
        return
    end
    if Zones[name] then
        return
    end
    local yaw_degrees = zoneOptions.heading or zoneOptions.yaw or 0.0
    local minZ, maxZ = zoneOptions.minZ, zoneOptions.maxZ
    local height = (minZ and maxZ) and math.abs(maxZ - minZ) or (zoneOptions.height or zoneOptions.fullHeight or 200.0)
    local spawnCenter = UE.FVector(center.X, center.Y, center.Z)
    if minZ and maxZ then
        spawnCenter.Z = (minZ + maxZ) * 0.5
    end
    local xform = UE.FTransform()
    xform.Translation = spawnCenter
    xform.Rotation = UE.FQuat(0, 0, math.sin(math.rad(yaw_degrees) * 0.5), math.cos(math.rad(yaw_degrees) * 0.5))
    local actor = HWorld:SpawnActor(UE.AActor, xform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if not actor then
        return nil
    end
    local box = actor:AddComponentByClass(UE.UBoxComponent, false, xform, false)
    if not box then
        return nil
    end
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
        options = targetoptions,
    })
end
exports('qb-target', 'AddBoxZone', AddBoxZone)

local function AddSphereZone(name, center, radius, zoneOptions, targetoptions)
    if not name or not center or not radius or not zoneOptions or not targetoptions then
        return
    end
    if Zones[name] then
        return
    end
    local spawnCenter = UE.FVector(center.X, center.Y, center.Z)
    local xform = UE.FTransform()
    xform.Translation = spawnCenter
    xform.Rotation = UE.FQuat(0, 0, 0, 1)
    local actor = HWorld:SpawnActor(UE.AActor, xform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if not actor then
        return nil
    end
    local sphere = actor:AddComponentByClass(UE.USphereComponent, false, xform, false)
    if not sphere then
        return nil
    end
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
        options = targetoptions,
    })
end
exports('qb-target', 'AddSphereZone', AddSphereZone)

local function AddMeshTarget(name, location, rotation, meshPath, meshOptions, targetOptions)
    if not name or not location or not meshPath or not meshOptions or not targetOptions then
        print('AddStaticMeshTarget: Missing required parameters')
        return
    end
    if Zones[name] then
        return
    end
    local collisionType = meshOptions.collision or CollisionType.Auto
    local bStationary = meshOptions.stationary
    if bStationary == nil then
        bStationary = true
    end
    local distance = meshOptions.distance or Config.MaxDistance
    local meshWrapper = StaticMesh(location, rotation or UE.FRotator(0, 0, 0), meshPath, collisionType, bStationary)
    local actor = meshWrapper and meshWrapper.Object
    if not actor then
        print('AddMeshTarget: Failed to spawn static mesh for ' .. tostring(name))
        return
    end
    Zones[name] = actor
    AddTargetEntity(actor, {
        distance = distance,
        options = targetOptions,
    })
end
exports('qb-target', 'AddMeshTarget', AddMeshTarget)

local function AddGlobalClass(className, parameters)
    if not className or not parameters then
        return
    end
    if type(parameters) ~= 'table' then
        return
    end
    if not parameters.options or type(parameters.options) ~= 'table' then
        return
    end
    local classObj = nil
    if type(className) == 'userdata' then
        classObj = className
        className = className:GetName()
    end
    if type(className) ~= 'string' then
        return
    end
    local distance = parameters.distance or Config.MaxDistance
    local options = parameters.options
    if not options or #options == 0 then
        return
    end
    if not Types[className] then
        Types[className] = {}
    end
    if classObj and not TypeClasses[className] then
        TypeClasses[className] = classObj
    end
    SetOptions(Types[className], distance, options)
    queueRescan()
end
exports('qb-target', 'AddGlobalClass', AddGlobalClass)

local function AddGlobalNPC(parameters)
    if not parameters then
        return
    end
    if type(parameters) ~= 'table' then
        return
    end
    if not parameters.options or type(parameters.options) ~= 'table' then
        return
    end
    local distance = parameters.distance or Config.MaxDistance
    local options = parameters.options
    if not options or #options == 0 then
        return
    end
    local npcClassName = 'BP_Character_NPC_Helix_Sandbox_C'
    if not Types[npcClassName] then
        Types[npcClassName] = {}
    end
    SetOptions(Types[npcClassName], distance, options)
    -- wrap the stored copies so the built-in NPC check runs before any
    -- caller-supplied canInteract. Controllers (player or AI) don't exist on
    -- remote clients, so an NPC is identified by the absence of a replicated
    -- PlayerState on the pawn
    for i = 1, #options do
        local stored = Types[npcClassName][options[i].label]
        if stored then
            local customCheck = stored.canInteract
            stored.canInteract = function(entity, dist, data)
                if entity == GetPlayerPawn() then
                    return false
                end
                if entity.PlayerState then
                    return false
                end
                if customCheck then
                    return customCheck(entity, dist, data)
                end
                return true
            end
        end
    end
    queueRescan()
end
exports('qb-target', 'AddGlobalNPC', AddGlobalNPC)

local function AddGlobalPlayer(parameters)
    if not parameters then
        return
    end
    if type(parameters) ~= 'table' then
        return
    end
    if not parameters.options or type(parameters.options) ~= 'table' then
        return
    end
    local distance = parameters.distance or Config.MaxDistance
    local options = parameters.options
    if not options or #options == 0 then
        return
    end
    local playerClassName = 'BP_Character_Player_Helix_Sandbox_C'
    if not Types[playerClassName] then
        Types[playerClassName] = {}
    end
    SetOptions(Types[playerClassName], distance, options)
    -- wrap the stored copies so the built-in self/is-player check runs before
    -- any caller-supplied canInteract instead of replacing it. Remote player
    -- controllers don't exist on this client, so the checks go through the
    -- pawn: compare against the local pawn for self, and use the replicated
    -- PlayerState to tell a possessed player pawn from an NPC or empty body
    for i = 1, #options do
        local stored = Types[playerClassName][options[i].label]
        if stored then
            local customCheck = stored.canInteract
            stored.canInteract = function(entity, dist, data)
                if entity == GetPlayerPawn() then
                    return false
                end
                if not entity.PlayerState then
                    return false
                end
                if customCheck then
                    return customCheck(entity, dist, data)
                end
                return true
            end
        end
    end
    queueRescan()
end
exports('qb-target', 'AddGlobalPlayer', AddGlobalPlayer)

-- Xray Listener

local function debugLog(...)
    if Config.Debug then
        print('[qb-target]', ...)
    end
end

Xray.RegisterListener(function(controller, target, state)
    if not isLoggedIn then
        return
    end
    debugLog('xray event', tostring(state), target and target:GetName() or 'nil')
    if state == XrayState.BeginFocus then
        enableTarget()

        local entity_options = Entities[target]
        local type_option_tables = getTypeOptionTables(target)
        local modelKey = GetModelKeyFromActor(target)
        local model_options = modelKey and Models[modelKey] or nil

        if not entity_options and #type_option_tables == 0 and not model_options then
            debugLog('no registered options for', target:GetName())
            clearTarget()
            return
        end

        if target_entity ~= target then
            clearTarget()
        end

        target_entity = target
        nui_data, send_data = {}, {}

        local distance = GetDistanceBetweenActors(GetPlayerPawn(), target)

        setupOptions(entity_options, target, distance)
        for i = 1, #type_option_tables do
            setupOptions(type_option_tables[i], target, distance)
        end
        setupOptions(model_options, target, distance)

        debugLog('options built:', #nui_data, 'distance:', distance)
        if #nui_data > 0 and my_webui then
            local target_icon = nui_data[1].targeticon or ''
            my_webui:SendEvent('foundTarget', { icon = target_icon, options = nui_data })
        else
            clearTarget()
        end
    elseif state == XrayState.EndFocus then
        -- events can arrive out of order on a focus switch; a trailing
        -- EndFocus for a previous target must not wipe the current menu
        if target == target_entity then
            clearTarget()
        else
            debugLog('ignored stale endfocus for', target and target:GetName() or 'nil')
        end
    elseif state == XrayState.Reveal then
        if target_active and target_entity and nui_data and nui_data[1] then
            focusTargetUi()
        end
    elseif state == XrayState.Cancel then
        disableTarget()
    end
end)

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    player_data = exports['qb-core']:GetPlayerData() or {}
    registerModels()
    registerGlobalClasses()
    startScanTimer()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    player_data = {}
    stopScanTimer()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, value)
    if key == 'all' then
        player_data = value or {}
        return
    end
    if not key then
        return
    end
    if type(player_data) ~= 'table' then
        player_data = {}
    end
    player_data[key] = value
end)
