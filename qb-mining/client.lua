local isMining = false
local localRocks = {}
local currentTargetEntity = nil
local currentRockItem = nil

local mining_ui = WebUI('qb-mining', 'qb-mining/html/index.html')
if mining_ui then
    mining_ui:SetVisibility(UI_HIDDEN)

    mining_ui:RegisterEventHandler('miningDone', function(success)
        mining_ui:SetVisibility(UI_HIDDEN)
        mining_ui:SetInputMode(0)

        if success then
            if Config.NetworkedRocks then
                TriggerServerEvent('qb-mining:server:completeMine', { entity = currentTargetEntity })
            else
                TriggerServerEvent('qb-mining:server:completeMine', { entity = currentTargetEntity, item = currentRockItem })
                if currentTargetEntity and currentTargetEntity:IsValid() then
                    DeleteEntity(currentTargetEntity)
                end
                localRocks[currentTargetEntity] = nil
            end
        else
            TriggerServerEvent('qb-mining:server:completeMine', nil)
        end
        isMining = false
    end)
end

local TargetOptions = {
    options = {
        {
            icon = 'fas fa-hammer',
            label = 'Mine Rock',
            type = 'client',
            event = 'qb-mining:client:startMining'
        }
    },
    distance = 400
}

local function SpawnLocalRocks()
    if Config.NetworkedRocks then return end

    for i = 1, #Config.miningZones do
        local zone = Config.miningZones[i]
        local spawnedPts = {}

        for j = 1, zone.maxRocks do
            local tries = 0
            local isValid = false
            local pos = nil

            while not isValid and tries < 50 do
                local angle = math.random() * math.pi * 2
                local rDist = math.random() * zone.radius
                pos = Vector(
                    zone.center.X + math.cos(angle) * rDist,
                    zone.center.Y + math.sin(angle) * rDist,
                    zone.center.Z
                )

                isValid = true
                for _, pt in ipairs(spawnedPts) do
                    local dx = pos.X - pt.X
                    local dy = pos.Y - pt.Y
                    local dist = math.sqrt(dx ^ 2 + dy ^ 2)
                    if dist < zone.minDistanceBetweenRocks then
                        isValid = false
                        break
                    end
                end
                tries = tries + 1
            end

            if isValid and pos then
                table.insert(spawnedPts, pos)

                local totalWt = 0
                for _, rt in ipairs(zone.rockTypes) do
                    totalWt = totalWt + rt.weight
                end

                local rand = math.random() * totalWt
                local currWt = 0
                local rockType = zone.rockTypes[1]
                for _, rt in ipairs(zone.rockTypes) do
                    currWt = currWt + rt.weight
                    if rand <= currWt then
                        rockType = rt
                        break
                    end
                end

                local mesh = StaticMesh(pos, Rotator(0, math.random() * 360, 0), rockType.mesh)

                if mesh and mesh.Object then
                    if rockType.scale then
                        mesh.Object:SetActorScale3D(rockType.scale)
                    end
                    localRocks[mesh.Object] = { item = rockType.item, zoneId = i, actor = mesh.Object }
                    exports['qb-target']:AddTargetEntity(mesh.Object, TargetOptions)
                end
            end
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    if Config.NetworkedRocks then
        TriggerCallback('getRocks', function(rocks)
            if rocks and type(rocks) == 'table' then
                for i = 1, #rocks do
                    exports['qb-target']:AddTargetEntity(rocks[i], TargetOptions)
                end
            end
        end)
    else
        SpawnLocalRocks()
    end
end)

RegisterClientEvent('qb-mining:client:startMining', function(data)
    if isMining then return end
    if not data or not data.entity then return end

    if not Config.NetworkedRocks then
        if not localRocks[data.entity] then return end
    end

    currentTargetEntity = data.entity
    if not Config.NetworkedRocks then
        currentRockItem = localRocks[data.entity].item
    end

    isMining = true
    TriggerServerEvent('qb-mining:server:startMiningItem')

    if mining_ui then
        mining_ui:SendEvent('openUI')
        mining_ui:SetVisibility(UI_VISIBLE)
        mining_ui:BringToFront()
        mining_ui:SetInputMode(1)
    end
end)

function onShutdown()
    if mining_ui then
        mining_ui:Destroy()
        mining_ui = nil
    end

    if not Config.NetworkedRocks then
        for _, data in pairs(localRocks) do
            if data.actor and data.actor:IsValid() then
                DeleteEntity(data.actor)
            end
        end
        localRocks = {}
    end
end
