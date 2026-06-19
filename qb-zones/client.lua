local Zones = {}
local MonitorTimer = nil
local RemoveZone
local computeBounds
local Creator = {
    active = false,
    points = {},
    previewActors = {},
}

local function toNumber(value, default)
    local number = tonumber(value)
    if number == nil then
        return default or 0.0
    end
    return number
end

local function asPoint(value)
    if not value then
        return nil
    end

    local valueType = type(value)
    if valueType ~= 'table' and valueType ~= 'userdata' then
        return nil
    end

    local x = value.X or value.x or value[1]
    local y = value.Y or value.y or value[2]
    local z = value.Z or value.z or value[3] or 0.0

    if x == nil or y == nil then
        return nil
    end

    return {
        X = toNumber(x),
        Y = toNumber(y),
        Z = toNumber(z),
    }
end

local function toVector(point)
    return Vector(point.X, point.Y, point.Z)
end

local function pointPayload(point)
    if not point then
        return nil
    end

    return {
        X = point.X,
        Y = point.Y,
        Z = point.Z,
    }
end

local function getPlayerPoint()
    local pawn = GetPlayerPawn()
    if not pawn then
        return nil
    end

    return asPoint(GetEntityCoords(pawn))
end

local function formatCoord(value)
    return ('%.2f'):format(toNumber(value))
end

local function formatVectorLine(point, isLast)
    local suffix = isLast and '' or ','
    return ('    Vector(%s, %s, %s)%s'):format(formatCoord(point.X), formatCoord(point.Y), formatCoord(point.Z), suffix)
end

local function creatorPreviewEnabled()
    local creatorConfig = Config.Creator or {}
    return creatorConfig.Preview ~= false
end

local function creatorYawQuat(heading)
    if not UE or not UE.FQuat then
        return nil
    end

    local radians = math.rad(heading or 0.0) * 0.5
    return UE.FQuat(0.0, 0.0, math.sin(radians), math.cos(radians))
end

local function creatorHeadingFromDelta(dx, dy)
    if math.abs(dx) < 0.0001 then
        return dy >= 0.0 and 90.0 or -90.0
    end

    local heading = math.deg(math.atan(dy / dx))
    if dx < 0.0 then
        heading = heading + 180.0
    end

    return heading
end

local function tagCreatorPreviewActor(actor)
    if not actor or not actor.Tags then
        return
    end

    actor.Tags:Add('qb_zone_creator')
end

local function configureCreatorPreviewComponent(component)
    component:SetHiddenInGame(false, true)
    component:SetVisibility(true, true)
    component:SetCastShadow(false)
    component:SetMobility(UE.EComponentMobility.Stationary)
    component:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    component:SetCollisionObjectType(UE.ECollisionChannel.ECC_WorldDynamic)
    component:SetGenerateOverlapEvents(false)
    component:SetCollisionResponseToAllChannels(UE.ECollisionResponse.ECR_Ignore)
    component:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Visibility, UE.ECollisionResponse.ECR_Block)
end

local function spawnVisiblePreviewActor(center, heading)
    local transform = UE.FTransform()
    transform.Translation = UE.FVector(center.X, center.Y, center.Z)
    transform.Rotation = creatorYawQuat(heading or 0.0) or UE.FQuat(0.0, 0.0, 0.0, 1.0)

    local actor = HWorld:SpawnActor(UE.AActor, transform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if not actor then
        return nil, nil
    end

    pcall(function()
        actor:SetActorHiddenInGame(false)
    end)

    return actor, transform
end

local function spawnCreatorPreviewActor(center, heading)
    if not creatorPreviewEnabled() then
        return nil, nil
    end

    local actor, transform = spawnVisiblePreviewActor(center, heading)
    if not actor then
        return nil, nil
    end

    tagCreatorPreviewActor(actor)
    return actor, transform
end

local function storePreviewActor(actor, actorStore)
    local store = actorStore or Creator.previewActors
    store[#store + 1] = actor
end

local function tagZoneDebugActor(actor)
    if not actor or not actor.Tags then
        return
    end

    actor.Tags:Add('qb_zone_debug')
end

local function spawnCreatorPreviewSphere(center, radius, actorStore)
    local actor, transform
    if actorStore then
        actor, transform = spawnVisiblePreviewActor(center, 0.0)
        tagZoneDebugActor(actor)
    else
        actor, transform = spawnCreatorPreviewActor(center, 0.0)
    end

    if not actor then
        return nil
    end

    local sphere = actor:AddComponentByClass(UE.USphereComponent, false, transform, false)
    if not sphere then
        actor:K2_DestroyActor()
        return nil
    end

    sphere:SetSphereRadius(radius, true)
    configureCreatorPreviewComponent(sphere)

    storePreviewActor(actor, actorStore)
    return actor
end

local function spawnCreatorPreviewLine(center, extent, heading, actorStore)
    local actor, transform
    if actorStore then
        actor, transform = spawnVisiblePreviewActor(center, heading)
        tagZoneDebugActor(actor)
    else
        actor, transform = spawnCreatorPreviewActor(center, heading)
    end

    if not actor then
        return nil
    end

    local box = actor:AddComponentByClass(UE.UBoxComponent, false, transform, false)
    if not box then
        actor:K2_DestroyActor()
        return nil
    end

    box:SetBoxExtent(UE.FVector(extent.X, extent.Y, extent.Z), true)
    configureCreatorPreviewComponent(box)

    storePreviewActor(actor, actorStore)
    return actor
end

local function clearPreviewActors(actors)
    for _, actor in ipairs(actors or {}) do
        if actor then
            actor:K2_DestroyActor()
        end
    end
end

local function clearCreatorPreview()
    clearPreviewActors(Creator.previewActors)

    Creator.previewActors = {}
end

local function addPreviewEdge(point, previousPoint, actorStore, previewConfig)
    if not previousPoint then
        return
    end

    local creatorConfig = previewConfig or Config.Creator or {}
    local dx = point.X - previousPoint.X
    local dy = point.Y - previousPoint.Y
    local dz = point.Z - previousPoint.Z
    local length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.01 then
        return
    end

    local edgeThickness = toNumber(creatorConfig.EdgeThickness, 4.0)
    local edgeHeight = toNumber(creatorConfig.EdgeHeight, 4.0)
    local lineZ = creatorConfig.LineZ ~= nil and toNumber(creatorConfig.LineZ) or nil
    local center = {
        X = (point.X + previousPoint.X) * 0.5,
        Y = (point.Y + previousPoint.Y) * 0.5,
        Z = lineZ or ((point.Z + previousPoint.Z) * 0.5),
    }
    local extent = {
        X = length * 0.5,
        Y = edgeThickness * 0.5,
        Z = math.max(lineZ and 0.0 or math.abs(dz), edgeHeight) * 0.5,
    }
    local heading = creatorHeadingFromDelta(dx, dy)

    spawnCreatorPreviewLine(center, extent, heading, actorStore)
end

local function addCreatorEdgePreview(point, previousPoint)
    addPreviewEdge(point, previousPoint)
end

local function addCreatorPointPreview(point, previousPoint)
    local creatorConfig = Config.Creator or {}
    local pointRadius = toNumber(creatorConfig.PointRadius or creatorConfig.PointSize, 35.0)

    spawnCreatorPreviewSphere(point, pointRadius)
    addCreatorEdgePreview(point, previousPoint)
end

local function rebuildCreatorPreview()
    clearCreatorPreview()

    local points = Creator.points or {}
    for index, point in ipairs(points) do
        addCreatorPointPreview(point, points[index - 1])
    end

    if #points >= 3 then
        addCreatorEdgePreview(points[1], points[#points])
    end
end

local function clearZoneDebugActors(zone)
    if not zone then
        return
    end

    clearPreviewActors(zone.debugActors)
    zone.debugActors = {}
end

local function buildPointAtZ(point, z)
    return {
        X = point.X,
        Y = point.Y,
        Z = z,
    }
end

local function addPolyDebugRing(zone, z, previewConfig)
    local projectedPoints = {}

    for index, point in ipairs(zone.points) do
        local projectedPoint = buildPointAtZ(point, z)
        projectedPoints[index] = projectedPoint
        spawnCreatorPreviewSphere(projectedPoint, previewConfig.PointRadius, zone.debugActors)
        addPreviewEdge(projectedPoint, projectedPoints[index - 1], zone.debugActors, previewConfig)
    end

    if #projectedPoints >= 3 then
        addPreviewEdge(projectedPoints[1], projectedPoints[#projectedPoints], zone.debugActors, previewConfig)
    end
end

local function rebuildBoxZoneDebug(zone)
    clearZoneDebugActors(zone)

    if not zone or not zone.debug or zone.type ~= 'box' then
        return
    end

    zone.debugActors = {}
    spawnCreatorPreviewLine(zone.center, {
        X = zone.length * 0.5,
        Y = zone.width * 0.5,
        Z = zone.height * 0.5,
    }, zone.heading or 0.0, zone.debugActors)
end

local function rebuildSphereZoneDebug(zone)
    clearZoneDebugActors(zone)

    if not zone or not zone.debug or zone.type ~= 'sphere' then
        return
    end

    zone.debugActors = {}
    spawnCreatorPreviewSphere(zone.center, zone.radius, zone.debugActors)
end

local function rebuildCircleZoneDebug(zone)
    clearZoneDebugActors(zone)

    if not zone or not zone.debug or zone.type ~= 'circle' then
        return
    end

    zone.debugActors = {}

    local creatorConfig = Config.Creator or {}
    local minZ = zone.minZ
    local maxZ = zone.maxZ
    local lineZ = zone.center.Z
    local edgeHeight = toNumber(creatorConfig.EdgeHeight, 4.0)

    if minZ ~= nil and maxZ ~= nil then
        lineZ = (minZ + maxZ) * 0.5
        edgeHeight = math.abs(maxZ - minZ)
    end

    local previewConfig = {
        EdgeThickness = toNumber(creatorConfig.EdgeThickness, 4.0),
        EdgeHeight = edgeHeight,
        LineZ = lineZ,
    }
    local segmentCount = math.max(8, math.floor(toNumber(creatorConfig.CircleSegments, 32.0)))
    local firstPoint
    local previousPoint

    for index = 1, segmentCount do
        local angle = ((index - 1) / segmentCount) * math.pi * 2.0
        local point = {
            X = zone.center.X + (math.cos(angle) * zone.radius),
            Y = zone.center.Y + (math.sin(angle) * zone.radius),
            Z = lineZ,
        }

        firstPoint = firstPoint or point
        addPreviewEdge(point, previousPoint, zone.debugActors, previewConfig)
        previousPoint = point
    end

    if firstPoint and previousPoint then
        addPreviewEdge(firstPoint, previousPoint, zone.debugActors, previewConfig)
    end
end

local function rebuildPolyZoneDebug(zone)
    clearZoneDebugActors(zone)

    if not zone or not zone.debug or zone.type ~= 'poly' or not zone.points then
        return
    end

    zone.debugActors = {}

    local creatorConfig = Config.Creator or {}
    local zoneHeight = math.abs((zone.maxZ or zone.center.Z) - (zone.minZ or zone.center.Z))
    local previewConfig = {
        PointRadius = toNumber(creatorConfig.PointRadius or creatorConfig.PointSize, 35.0),
        EdgeThickness = toNumber(creatorConfig.EdgeThickness, 4.0),
        EdgeHeight = zoneHeight,
        LineZ = zone.center.Z,
    }

    addPolyDebugRing(zone, zone.center.Z, previewConfig)
end

local function rebuildZoneDebug(zone)
    if not zone then
        return
    end

    if not zone.debug then
        clearZoneDebugActors(zone)
        return
    end

    if zone.type == 'box' then
        rebuildBoxZoneDebug(zone)
    elseif zone.type == 'sphere' then
        rebuildSphereZoneDebug(zone)
    elseif zone.type == 'circle' then
        rebuildCircleZoneDebug(zone)
    elseif zone.type == 'poly' then
        rebuildPolyZoneDebug(zone)
    else
        clearZoneDebugActors(zone)
    end
end

local function printCreatorInstructions()
    local creatorConfig = Config.Creator or {}
    print(('[qb-zones] Creator keys: %s starts, %s adds a point, %s finishes and prints.'):format(creatorConfig.StartKey or 'F7', creatorConfig.AddPointKey or 'F8', creatorConfig.FinishKey or 'F9'))
end

local function printCreatorPoint(index, point)
    print(('[qb-zones] Point %d: Vector(%s, %s, %s)'):format(index, formatCoord(point.X), formatCoord(point.Y), formatCoord(point.Z)))
end

local function startZoneCreator()
    local point = getPlayerPoint()
    if not point then
        print('[qb-zones] Creator could not read player coords.')
        return
    end

    Creator.active = true
    Creator.points = { point }
    rebuildCreatorPreview()

    print('[qb-zones] Creator started.')
    printCreatorPoint(1, point)
    printCreatorInstructions()
end

local function addCreatorPoint()
    if not Creator.active then
        print('[qb-zones] Creator is not active. Start it first.')
        printCreatorInstructions()
        return
    end

    local point = getPlayerPoint()
    if not point then
        print('[qb-zones] Creator could not read player coords.')
        return
    end

    Creator.points[#Creator.points + 1] = point
    rebuildCreatorPreview()
    printCreatorPoint(#Creator.points, point)
end

local function printCreatorResult()
    local points = Creator.points
    local pointCount = #points

    if pointCount == 0 then
        print('[qb-zones] Creator has no points to print.')
        return
    end

    local bounds = computeBounds(points)
    local creatorConfig = Config.Creator or {}
    local zoneName = creatorConfig.PrintZoneName or 'new_zone'
    local verticalPadding = toNumber(creatorConfig.VerticalPadding, 100.0)

    print('[qb-zones] Zone creator result:')
    print(('exports[\'qb-zones\']:AddPolyZone(\'%s\', {'):format(zoneName))
    for index, point in ipairs(points) do
        print(formatVectorLine(point, index == pointCount))
    end
    print('}, {')
    print(('    minZ = %s,'):format(formatCoord(bounds.minZ - verticalPadding)))
    print(('    maxZ = %s,'):format(formatCoord(bounds.maxZ + verticalPadding)))
    print('})')

    if pointCount < 3 then
        print('[qb-zones] Add at least 3 points before using this as a polygon zone.')
    end
end

local function finishZoneCreator()
    if not Creator.active then
        print('[qb-zones] Creator is not active. Nothing to finish.')
        printCreatorInstructions()
        return
    end

    printCreatorResult()
    clearCreatorPreview()
    Creator.active = false
    Creator.points = {}
end

local function bindCreatorKeys()
    local creatorConfig = Config.Creator or {}
    if creatorConfig.Enabled == false then
        return
    end

    Input.BindKey(creatorConfig.StartKey or 'F7', function()
        if HPlayer and HPlayer.GetInputMode and HPlayer:GetInputMode() == 1 then
            return
        end
        startZoneCreator()
    end, 'Released')

    Input.BindKey(creatorConfig.AddPointKey or 'F8', function()
        if HPlayer and HPlayer.GetInputMode and HPlayer:GetInputMode() == 1 then
            return
        end
        addCreatorPoint()
    end, 'Released')

    Input.BindKey(creatorConfig.FinishKey or 'F9', function()
        if HPlayer and HPlayer.GetInputMode and HPlayer:GetInputMode() == 1 then
            return
        end
        finishZoneCreator()
    end, 'Released')
end

local function copyOptions(options)
    local copied = {}
    if type(options) ~= 'table' then
        return copied
    end

    for key, value in pairs(options) do
        copied[key] = value
    end

    return copied
end

computeBounds = function(points)
    local minX, minY, minZ
    local maxX, maxY, maxZ

    for _, point in ipairs(points) do
        minX = minX and math.min(minX, point.X) or point.X
        minY = minY and math.min(minY, point.Y) or point.Y
        minZ = minZ and math.min(minZ, point.Z) or point.Z
        maxX = maxX and math.max(maxX, point.X) or point.X
        maxY = maxY and math.max(maxY, point.Y) or point.Y
        maxZ = maxZ and math.max(maxZ, point.Z) or point.Z
    end

    return {
        minX = minX or 0.0,
        minY = minY or 0.0,
        minZ = minZ or 0.0,
        maxX = maxX or 0.0,
        maxY = maxY or 0.0,
        maxZ = maxZ or 0.0,
    }
end

local function centerFromBounds(bounds)
    return {
        X = (bounds.minX + bounds.maxX) * 0.5,
        Y = (bounds.minY + bounds.maxY) * 0.5,
        Z = (bounds.minZ + bounds.maxZ) * 0.5,
    }
end

local function isWithinZ(point, minZ, maxZ)
    if minZ ~= nil and point.Z < minZ then
        return false
    end
    if maxZ ~= nil and point.Z > maxZ then
        return false
    end
    return true
end

local function normalizeZRange(minZ, maxZ)
    if minZ ~= nil then
        minZ = toNumber(minZ)
    end
    if maxZ ~= nil then
        maxZ = toNumber(maxZ)
    end

    if minZ ~= nil and maxZ ~= nil and minZ > maxZ then
        minZ, maxZ = maxZ, minZ
    end

    return minZ, maxZ
end

local function pointOnSegment(point, a, b)
    local cross = (point.Y - a.Y) * (b.X - a.X) - (point.X - a.X) * (b.Y - a.Y)
    if math.abs(cross) > 0.0001 then
        return false
    end

    local dot = (point.X - a.X) * (b.X - a.X) + (point.Y - a.Y) * (b.Y - a.Y)
    if dot < 0.0 then
        return false
    end

    local lenSq = ((b.X - a.X) ^ 2) + ((b.Y - a.Y) ^ 2)
    return dot <= lenSq
end

local function pointInPolygon(point, points)
    local inside = false
    local count = #points

    if count < 3 then
        return false
    end

    local previous = points[count]
    for index = 1, count do
        local current = points[index]
        if pointOnSegment(point, previous, current) then
            return true
        end

        local crosses = ((current.Y > point.Y) ~= (previous.Y > point.Y))
        if crosses then
            local xAtY = (previous.X - current.X) * (point.Y - current.Y) / (previous.Y - current.Y) + current.X
            if point.X < xAtY then
                inside = not inside
            end
        end

        previous = current
    end

    return inside
end

local function containsBox(zone, point)
    if not isWithinZ(point, zone.minZ, zone.maxZ) then
        return false
    end

    local heading = math.rad(zone.heading or 0.0)
    local cosHeading = math.cos(heading)
    local sinHeading = math.sin(heading)
    local dx = point.X - zone.center.X
    local dy = point.Y - zone.center.Y
    local localX = (dx * cosHeading) + (dy * sinHeading)
    local localY = (-dx * sinHeading) + (dy * cosHeading)

    return math.abs(localX) <= zone.length * 0.5 and math.abs(localY) <= zone.width * 0.5
end

local function containsSphere(zone, point)
    if not isWithinZ(point, zone.minZ, zone.maxZ) then
        return false
    end

    local dx = point.X - zone.center.X
    local dy = point.Y - zone.center.Y
    local dz = zone.useZ and (point.Z - zone.center.Z) or 0.0
    local distanceSq = (dx * dx) + (dy * dy) + (dz * dz)

    return distanceSq <= zone.radius * zone.radius
end

local function containsPoly(zone, point)
    if not isWithinZ(point, zone.minZ, zone.maxZ) then
        return false
    end

    if point.X < zone.bounds.minX or point.X > zone.bounds.maxX then
        return false
    end
    if point.Y < zone.bounds.minY or point.Y > zone.bounds.maxY then
        return false
    end

    return pointInPolygon(point, zone.points)
end

local function containsCombo(zone, point)
    for _, child in ipairs(zone.children) do
        local childZone = child.refName and Zones[child.refName] or child
        if childZone and childZone.contains and childZone.contains(childZone, point) then
            return true
        end
    end

    return false
end

local function zoneContains(zone, point)
    if not zone or zone.active == false or not point then
        return false
    end

    return zone.contains(zone, point)
end

local function makeZone(name, zoneType, options)
    local zoneOptions = copyOptions(options)

    return {
        __qbZone = true,
        name = name,
        type = zoneType,
        active = zoneOptions.active ~= false,
        debug = zoneOptions.debug ~= nil and zoneOptions.debug or Config.Debug,
        data = zoneOptions.data,
        onEnter = zoneOptions.onEnter,
        onExit = zoneOptions.onExit,
        onInside = zoneOptions.onInside,
        onPointInOut = zoneOptions.onPointInOut,
        enterEvent = zoneOptions.enterEvent or zoneOptions.onEnterEvent,
        exitEvent = zoneOptions.exitEvent or zoneOptions.onExitEvent,
        insideEvent = zoneOptions.insideEvent or zoneOptions.onInsideEvent,
        serverEnterEvent = zoneOptions.serverEnterEvent,
        serverExitEvent = zoneOptions.serverExitEvent,
        serverInsideEvent = zoneOptions.serverInsideEvent,
        inside = false,
        actors = {},
    }
end

local function callSafely(zone, callback, ...)
    if type(callback) ~= 'function' then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        print(('[qb-zones] callback failed for %s: %s'):format(zone.name, tostring(err)))
    end
end

local function triggerConfiguredEvent(eventName, zone, point)
    if not eventName or eventName == '' then
        return
    end

    TriggerLocalClientEvent(eventName, {
        zone = zone.name,
        type = zone.type,
        data = zone.data,
        point = pointPayload(point),
    })
end

local function triggerConfiguredServerEvent(eventName, zone, point)
    if not eventName or eventName == '' then
        return
    end

    TriggerServerEvent(eventName, {
        zone = zone.name,
        type = zone.type,
        data = zone.data,
        point = pointPayload(point),
    })
end

local function fireTransition(zone, inside, point)
    callSafely(zone, zone.onPointInOut, inside, pointPayload(point), zone)

    if inside then
        callSafely(zone, zone.onEnter, zone, pointPayload(point))
        triggerConfiguredEvent(zone.enterEvent, zone, point)
        triggerConfiguredServerEvent(zone.serverEnterEvent, zone, point)
    else
        callSafely(zone, zone.onExit, zone, pointPayload(point))
        triggerConfiguredEvent(zone.exitEvent, zone, point)
        triggerConfiguredServerEvent(zone.serverExitEvent, zone, point)
    end
end

local function fireInside(zone, point)
    callSafely(zone, zone.onInside, zone, pointPayload(point))
    triggerConfiguredEvent(zone.insideEvent, zone, point)
    triggerConfiguredServerEvent(zone.serverInsideEvent, zone, point)
end

local function updateZoneStates()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end

    local point = asPoint(GetEntityCoords(pawn))
    if not point then
        return
    end

    for _, zone in pairs(Zones) do
        local inside = zoneContains(zone, point)
        if inside ~= zone.inside then
            zone.inside = inside
            fireTransition(zone, inside, point)
        elseif inside then
            fireInside(zone, point)
        end
    end
end

local function ensureMonitor()
    if MonitorTimer then
        return
    end

    MonitorTimer = Timer.SetInterval(updateZoneStates, Config.TickMs or 250)
end

local function stopMonitorIfIdle()
    if not MonitorTimer then
        return
    end

    if next(Zones) ~= nil then
        return
    end

    Timer.ClearInterval(MonitorTimer)
    MonitorTimer = nil
end

local function addActorTags(actor, zoneName)
    if not actor or not actor.Tags then
        return
    end

    actor.Tags:Add('qb_zone')
    actor.Tags:Add('qb_zone_' .. zoneName)
end

local function makeRotationQuat(heading)
    if not UE or not UE.FQuat then
        return nil
    end

    local radians = math.rad(heading or 0.0) * 0.5
    return UE.FQuat(0.0, 0.0, math.sin(radians), math.cos(radians))
end

local function spawnClusterActor(zone, center)
    if Config.CreateVolumeActors == false or zone.createVolumeActors == false then
        return nil
    end

    local transform = Transform()
    transform.Translation = toVector(center)

    local cluster = SpawnActor(Config.VolumeClusterClass, transform)
    if cluster then
        addActorTags(cluster, zone.name)
        pcall(function()
            cluster:SetActorHiddenInGame(not zone.debug)
        end)
    end

    return cluster
end

local function spawnBoxVolumeActor(zone, box)
    if Config.CreateVolumeActors == false or zone.createVolumeActors == false then
        return nil
    end

    local transform = Transform()
    transform.Translation = toVector(box.center)

    local quat = makeRotationQuat(box.heading or 0.0)
    if quat then
        transform.Rotation = quat
    end

    local actor = SpawnActor(Config.VolumeActorClass, transform)
    if not actor then
        return nil
    end

    addActorTags(actor, zone.name)
    pcall(function()
        actor:SetActorHiddenInGame(not zone.debug)
    end)

    pcall(function()
        actor:SetBoxExtent(Vector(box.length * 0.5, box.width * 0.5, box.height * 0.5))
    end)

    if zone.clusterActor then
        AttachActorToActor(actor, zone.clusterActor, nil, nil, '', {
            Location = AttachmentRule.KeepWorld,
            Rotation = AttachmentRule.KeepWorld,
            Scale = AttachmentRule.KeepWorld,
        }, false)
    end

    zone.actors[#zone.actors + 1] = actor

    return actor
end

local function destroyZoneActors(zone)
    if not zone then
        return
    end

    clearZoneDebugActors(zone)

    if zone.actors then
        for _, actor in ipairs(zone.actors) do
            if actor then
                actor:K2_DestroyActor()
            end
        end
    end

    if zone.clusterActor then
        zone.clusterActor:K2_DestroyActor()
    end

    zone.actors = {}
    zone.clusterActor = nil
end

local function applyZoneDebug(zone)
    if not zone then
        return
    end

    rebuildZoneDebug(zone)

    if zone.clusterActor then
        pcall(function()
            zone.clusterActor:SetActorHiddenInGame(not zone.debug)
        end)
    end

    if zone.actors then
        for _, actor in ipairs(zone.actors) do
            pcall(function()
                actor:SetActorHiddenInGame(not zone.debug)
            end)
        end
    end
end

local function attachMethods(zone)
    zone.isPointInside = function(self, point)
        return zoneContains(self, asPoint(point))
    end

    zone.onPlayerInOut = function(self, callback)
        self.onPointInOut = callback
        return self
    end

    zone.destroy = function(self)
        if RemoveZone then
            RemoveZone(self.name)
        end
    end

    zone.setActive = function(self, active)
        self.active = active ~= false
        return self
    end

    zone.setDebug = function(self, debug)
        self.debug = debug == true
        applyZoneDebug(self)
        return self
    end

    return zone
end

local function registerZone(zone)
    if not zone or not zone.name then
        return nil
    end

    if Zones[zone.name] then
        RemoveZone(zone.name)
    end

    Zones[zone.name] = attachMethods(zone)
    ensureMonitor()

    return Zones[zone.name]
end

local function normalizeBoxDefinition(center, length, width, options)
    local zoneOptions = copyOptions(options)
    local normalizedCenter = asPoint(center or zoneOptions.center or zoneOptions.coords)
    if not normalizedCenter then
        return nil
    end

    local minZ = zoneOptions.minZ
    local maxZ = zoneOptions.maxZ
    local height = toNumber(zoneOptions.height or zoneOptions.fullHeight, Config.DefaultBoxHeight or 200.0)

    if minZ ~= nil and maxZ ~= nil then
        minZ, maxZ = normalizeZRange(minZ, maxZ)
        height = math.abs(maxZ - minZ)
        normalizedCenter.Z = (minZ + maxZ) * 0.5
    else
        minZ = normalizedCenter.Z - (height * 0.5)
        maxZ = normalizedCenter.Z + (height * 0.5)
    end

    return {
        center = normalizedCenter,
        length = toNumber(length or zoneOptions.length or zoneOptions.sizeX or zoneOptions.x, 0.0),
        width = toNumber(width or zoneOptions.width or zoneOptions.sizeY or zoneOptions.y, 0.0),
        height = height,
        heading = toNumber(zoneOptions.heading or zoneOptions.yaw, 0.0),
        minZ = minZ,
        maxZ = maxZ,
    }
end

local function buildBoxZone(name, center, length, width, options)
    local box = normalizeBoxDefinition(center, length, width, options)
    if not box or box.length <= 0.0 or box.width <= 0.0 then
        return nil
    end

    local zone = makeZone(name, 'box', options)
    zone.center = box.center
    zone.length = box.length
    zone.width = box.width
    zone.height = box.height
    zone.heading = box.heading
    zone.minZ = box.minZ
    zone.maxZ = box.maxZ
    zone.createVolumeActors = options and options.createVolumeActors
    zone.contains = containsBox

    zone.clusterActor = spawnClusterActor(zone, zone.center)
    spawnBoxVolumeActor(zone, zone)
    rebuildZoneDebug(zone)

    return zone
end

local function normalizeSphereDefinition(center, radius, options, useZDefault)
    local zoneOptions = copyOptions(options)
    local normalizedCenter = asPoint(center or zoneOptions.center or zoneOptions.coords)
    if not normalizedCenter then
        return nil
    end

    return {
        center = normalizedCenter,
        radius = toNumber(radius or zoneOptions.radius, 0.0),
        minZ = select(1, normalizeZRange(zoneOptions.minZ, zoneOptions.maxZ)),
        maxZ = select(2, normalizeZRange(zoneOptions.minZ, zoneOptions.maxZ)),
        useZ = zoneOptions.useZ ~= nil and zoneOptions.useZ or useZDefault,
    }
end

local function buildSphereZone(name, center, radius, options, useZDefault, zoneType)
    local sphere = normalizeSphereDefinition(center, radius, options, useZDefault)
    if not sphere or sphere.radius <= 0.0 then
        return nil
    end

    local zone = makeZone(name, zoneType or 'sphere', options)
    zone.center = sphere.center
    zone.radius = sphere.radius
    zone.minZ = sphere.minZ
    zone.maxZ = sphere.maxZ
    zone.useZ = sphere.useZ
    zone.contains = containsSphere
    rebuildZoneDebug(zone)

    return zone
end

local function normalizePolyPoints(points)
    if type(points) ~= 'table' then
        return nil
    end

    local normalized = {}
    for _, point in ipairs(points) do
        local normalizedPoint = asPoint(point)
        if not normalizedPoint then
            return nil
        end
        normalized[#normalized + 1] = normalizedPoint
    end

    if #normalized < 3 then
        return nil
    end

    return normalized
end

local function buildPolyZone(name, points, options)
    local zoneOptions = copyOptions(options)
    local normalizedPoints = normalizePolyPoints(points or zoneOptions.points)
    if not normalizedPoints then
        return nil
    end

    local bounds = computeBounds(normalizedPoints)
    local minZ = zoneOptions.minZ
    local maxZ = zoneOptions.maxZ

    if minZ ~= nil and maxZ ~= nil then
        minZ, maxZ = normalizeZRange(minZ, maxZ)
    else
        local centerZ = zoneOptions.centerZ ~= nil and toNumber(zoneOptions.centerZ) or centerFromBounds(bounds).Z
        local height = toNumber(zoneOptions.height or zoneOptions.fullHeight, Config.DefaultPolyHeight or 200.0)
        minZ = centerZ - (height * 0.5)
        maxZ = centerZ + (height * 0.5)
    end

    local zone = makeZone(name, 'poly', options)
    zone.points = normalizedPoints
    zone.bounds = bounds
    zone.center = centerFromBounds(bounds)
    zone.center.Z = (minZ + maxZ) * 0.5
    zone.minZ = minZ
    zone.maxZ = maxZ
    zone.contains = containsPoly
    rebuildZoneDebug(zone)

    return zone
end

local function buildChildZone(definition, index)
    if type(definition) == 'string' then
        return { refName = definition }
    end

    if type(definition) ~= 'table' then
        return nil
    end

    if definition.__qbZone then
        return definition
    end

    local zoneType = definition.type or definition.shape or 'box'
    local childName = definition.name or ('child_' .. tostring(index))
    local childOptions = copyOptions(definition)
    childOptions.createVolumeActors = false

    if zoneType == 'box' then
        local child = buildBoxZone(childName, definition.center or definition.coords, definition.length, definition.width, childOptions)
        if child then
            child._ephemeral = true
        end
        return child
    elseif zoneType == 'sphere' then
        local child = buildSphereZone(childName, definition.center or definition.coords, definition.radius, childOptions, true, 'sphere')
        if child then
            child._ephemeral = true
        end
        return child
    elseif zoneType == 'circle' then
        local child = buildSphereZone(childName, definition.center or definition.coords, definition.radius, childOptions, false, 'circle')
        if child then
            child._ephemeral = true
        end
        return child
    elseif zoneType == 'poly' or zoneType == 'polygon' then
        local child = buildPolyZone(childName, definition.points, childOptions)
        if child then
            child._ephemeral = true
        end
        return child
    end

    return nil
end

local function buildComboZone(name, children, options, zoneType)
    if type(children) ~= 'table' or #children == 0 then
        return nil
    end

    local zone = makeZone(name, zoneType or 'combo', options)
    zone.children = {}
    zone.contains = containsCombo

    local centerPoints = {}
    for index, childDefinition in ipairs(children) do
        local child = buildChildZone(childDefinition, index)
        if child then
            zone.children[#zone.children + 1] = child
            local centerSource = child.refName and Zones[child.refName] or child
            if centerSource and centerSource.center then
                centerPoints[#centerPoints + 1] = centerSource.center
            end
        end
    end

    if #zone.children == 0 then
        return nil
    end

    if #centerPoints > 0 then
        zone.center = centerFromBounds(computeBounds(centerPoints))
    else
        zone.center = { X = 0.0, Y = 0.0, Z = 0.0 }
    end

    zone.createVolumeActors = options and options.createVolumeActors
    if zoneType ~= 'cluster' and zone.createVolumeActors == nil then
        zone.createVolumeActors = false
    end
    zone.clusterActor = spawnClusterActor(zone, zone.center)

    for _, child in ipairs(zone.children) do
        local volumeSource = child.refName and Zones[child.refName] or child
        if volumeSource and volumeSource.type == 'box' then
            spawnBoxVolumeActor(zone, volumeSource)
        end
        if child._ephemeral then
            destroyZoneActors(child)
        end
    end

    return zone
end

local function AddBoxZone(name, center, length, width, options)
    if not name then
        return nil
    end

    return registerZone(buildBoxZone(name, center, length, width, options or {}))
end
exports('qb-zones', 'AddBoxZone', AddBoxZone)

local function AddSphereZone(name, center, radius, options)
    if not name then
        return nil
    end

    return registerZone(buildSphereZone(name, center, radius, options or {}, true, 'sphere'))
end
exports('qb-zones', 'AddSphereZone', AddSphereZone)

local function AddCircleZone(name, center, radius, options)
    if not name then
        return nil
    end

    return registerZone(buildSphereZone(name, center, radius, options or {}, false, 'circle'))
end
exports('qb-zones', 'AddCircleZone', AddCircleZone)

local function AddPolyZone(name, points, options)
    if not name then
        return nil
    end

    return registerZone(buildPolyZone(name, points, options or {}))
end
exports('qb-zones', 'AddPolyZone', AddPolyZone)

local function AddComboZone(name, children, options)
    if not name then
        return nil
    end

    return registerZone(buildComboZone(name, children, options or {}, 'combo'))
end
exports('qb-zones', 'AddComboZone', AddComboZone)

local function AddClusterZone(name, volumes, options)
    if not name then
        return nil
    end

    return registerZone(buildComboZone(name, volumes, options or {}, 'cluster'))
end
exports('qb-zones', 'AddClusterZone', AddClusterZone)
exports('qb-zones', 'AddVolumeCluster', AddClusterZone)

RemoveZone = function(name)
    local zone = Zones[name]
    if not zone then
        return false
    end

    destroyZoneActors(zone)
    Zones[name] = nil
    stopMonitorIfIdle()

    return true
end
exports('qb-zones', 'RemoveZone', RemoveZone)

local function GetZone(name)
    return Zones[name]
end
exports('qb-zones', 'GetZone', GetZone)

local function DoesZoneExist(name)
    return Zones[name] ~= nil
end
exports('qb-zones', 'DoesZoneExist', DoesZoneExist)

local function IsPointInside(name, point)
    local zone = Zones[name]
    return zoneContains(zone, asPoint(point))
end
exports('qb-zones', 'IsPointInside', IsPointInside)

local function GetZonesContainingPoint(point)
    local normalizedPoint = asPoint(point)
    local results = {}

    if not normalizedPoint then
        return results
    end

    for name, zone in pairs(Zones) do
        if zoneContains(zone, normalizedPoint) then
            results[#results + 1] = name
        end
    end

    return results
end
exports('qb-zones', 'GetZonesContainingPoint', GetZonesContainingPoint)

local function GetPlayerZones()
    local pawn = GetPlayerPawn()
    if not pawn then
        return {}
    end

    return GetZonesContainingPoint(GetEntityCoords(pawn))
end
exports('qb-zones', 'GetPlayerZones', GetPlayerZones)

local function SetZoneActive(name, active)
    local zone = Zones[name]
    if not zone then
        return false
    end

    zone.active = active ~= false
    return true
end
exports('qb-zones', 'SetZoneActive', SetZoneActive)

local function SetZoneDebug(name, debug)
    local zone = Zones[name]
    if not zone then
        return false
    end

    zone.debug = debug == true
    applyZoneDebug(zone)
    return true
end
exports('qb-zones', 'SetZoneDebug', SetZoneDebug)

local function OnPlayerInOut(name, callback)
    local zone = Zones[name]
    if not zone then
        return false
    end

    zone.onPointInOut = callback
    return true
end
exports('qb-zones', 'OnPlayerInOut', OnPlayerInOut)

bindCreatorKeys()

-- AddPolyZone('new_zone', {
--     Vector(0.00, 0.00, 92.15),
--     Vector(579.87, 282.63, 91.81),
--     Vector(1075.89, 935.31, 91.81),
--     Vector(831.47, 1290.99, 91.81),
--     Vector(156.53, 1242.91, 91.81),
--     Vector(-451.09, 834.56, 91.81),
--     Vector(-830.57, 354.53, 91.81),
--     Vector(-837.34, -107.64, 91.81),
--     Vector(-632.10, -491.16, 91.81),
-- }, {
--     minZ = -8.19,
--     maxZ = 192.15,
--     debug = true,
--     onEnter = function(zone)
--         print('[qb-zones] entered ' .. zone.name)
--     end,
--     onExit = function(zone)
--         print('[qb-zones] exited ' .. zone.name)
--     end,
--     onPointInOut = function(isInside, _, zone)
--         print(('[qb-zones] %s in/out: %s'):format(zone.name, tostring(isInside)))
--     end,
-- })

-- AddBoxZone('example_box_zone', Vector(-1236.99, 1253.51, 91.85), 500.0, 300.0, {
--     heading = 0.0,
--     minZ = -8.19,
--     maxZ = 192.15,
--     debug = true,
--     onEnter = function(zone)
--         print('[qb-zones] entered ' .. zone.name)
--     end,
--     onExit = function(zone)
--         print('[qb-zones] exited ' .. zone.name)
--     end,
-- })

-- AddSphereZone('example_sphere_zone', Vector(-577.93, 2011.04, 91.85), 350.0, {
--     useZ = true,
--     debug = true,
--     onEnter = function(zone)
--         print('[qb-zones] entered ' .. zone.name)
--     end,
--     onExit = function(zone)
--         print('[qb-zones] exited ' .. zone.name)
--     end,
-- })

-- AddCircleZone('example_circle_zone', Vector(389.26, 2410.61, 91.85), 350.0, {
--     minZ = -8.19,
--     maxZ = 192.15,
--     debug = true,
--     onEnter = function(zone)
--         print('[qb-zones] entered ' .. zone.name)
--     end,
--     onExit = function(zone)
--         print('[qb-zones] exited ' .. zone.name)
--     end,
-- })

-- AddComboZone('example_combo_zone', {
--     {
--         type = 'box',
--         center = Vector(0.00, 0.00, 92.15),
--         length = 350.0,
--         width = 250.0,
--         minZ = -8.19,
--         maxZ = 192.15,
--     },
--     {
--         type = 'circle',
--         center = Vector(350.00, 0.00, 92.15),
--         radius = 200.0,
--         minZ = -8.19,
--         maxZ = 192.15,
--     },
-- }, {
--     onEnter = function(zone)
--         print('[qb-zones] entered ' .. zone.name)
--     end,
--     onExit = function(zone)
--         print('[qb-zones] exited ' .. zone.name)
--     end,
-- })

-- AddClusterZone('example_cluster_zone', {
--     {
--         type = 'box',
--         center = Vector(0.00, 0.00, 92.15),
--         length = 500.0,
--         width = 175.0,
--         minZ = -8.19,
--         maxZ = 192.15,
--     },
--     {
--         type = 'box',
--         center = Vector(250.00, 250.00, 92.15),
--         length = 175.0,
--         width = 500.0,
--         minZ = -8.19,
--         maxZ = 192.15,
--     },
-- }, {
--     debug = true,
--     onEnter = function(zone)
--         print('[qb-zones] entered ' .. zone.name)
--     end,
--     onExit = function(zone)
--         print('[qb-zones] exited ' .. zone.name)
--     end,
-- })

function onShutdown()
    clearCreatorPreview()

    if MonitorTimer then
        Timer.ClearInterval(MonitorTimer)
        MonitorTimer = nil
    end

    local zoneNames = {}
    for name in pairs(Zones) do
        zoneNames[#zoneNames + 1] = name
    end

    for _, name in ipairs(zoneNames) do
        RemoveZone(name)
    end
end
