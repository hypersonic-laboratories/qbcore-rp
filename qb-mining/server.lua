local netRocks = {}
local activeMiners = {}
local TOOL_ID = 'ID_Misc_Jackhammer'

local function SpawnNetRocks()
    if not Config.NetworkedRocks then
        return
    end

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
                pos = Vector(zone.center.X + math.cos(angle) * rDist, zone.center.Y + math.sin(angle) * rDist, zone.center.Z)

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
                    netRocks[mesh.Object] = { item = rockType.item, zoneId = i, actor = mesh.Object }
                end
            end
        end
    end
end

SpawnNetRocks()

RegisterCallback('getRocks', function()
    local rocks = {}
    for actor, _ in pairs(netRocks) do
        table.insert(rocks, actor)
    end
    return rocks
end)

function onShutdown()
    for _, data in pairs(netRocks) do
        if data.actor and data.actor:IsValid() then
            DeleteEntity(data.actor)
        end
    end
    for src in pairs(activeMiners) do
        local pawn = GetPlayerPawn(src)
        if pawn then
            HInventory.RemoveItemByName(pawn, TOOL_ID, 1)
        end
    end
    activeMiners = {}
    netRocks = {}
end

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    if activeMiners[source] then
        HInventory.RemoveItemByName(source, TOOL_ID, 1)
        activeMiners[source] = nil
    end
end)

RegisterServerEvent('qb-mining:server:startMiningItem', function(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end
    HInventory.GiveAndEquipItemByName(pawn, TOOL_ID)
    activeMiners[source] = true
end)

RegisterServerEvent('qb-mining:server:completeMine', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end
    if activeMiners[source] then
        HInventory.RemoveItemByName(pawn, TOOL_ID, 1)
        activeMiners[source] = nil
    end
    if not data then
        return
    end
    if Config.NetworkedRocks then
        if not data.entity then
            return
        end
        local rData = netRocks[data.entity]
        if rData then
            Player.AddItem(rData.item, 1)
            TriggerClientEvent(source, 'QBCore:Notify', 'You successfully mined ' .. rData.item .. '!', 'success')

            if data.entity:IsValid() then
                DeleteEntity(data.entity)
            end
            netRocks[data.entity] = nil
        end
    else
        -- Local rocks event
        if not data.item then
            return
        end
        Player.AddItem(data.item, 1)
        TriggerClientEvent(source, 'QBCore:Notify', 'You successfully mined ' .. data.item .. '!', 'success')
    end
end)
