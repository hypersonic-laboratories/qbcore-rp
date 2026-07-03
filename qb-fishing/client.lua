local isFishing = false
local localMarkers = {}
local mapMarkers = {}
local currentWaterType = nil
local fishing_ui = WebUI('qb-fishing', 'qb-fishing/html/index.html')
if fishing_ui then
    fishing_ui:RegisterEventHandler('fishingDone', function(success)
        fishing_ui:SetInputMode(0)
        if success then
            TriggerServerEvent('qb-fishing:server:completeFishing', currentWaterType)
        else
            TriggerServerEvent('qb-fishing:server:completeFishing', nil)
        end
        isFishing = false
    end)
end

local function ClearFishingMarkers()
    for _, marker in ipairs(localMarkers) do
        if marker.actor and marker.actor:IsValid() then
            DeleteEntity(marker.actor)
        end
        exports['qb-target']:RemoveZone(marker.zoneName)
    end
    localMarkers = {}

    for _, markerId in ipairs(mapMarkers) do
        exports['qb-hud']:RemoveMarker(markerId)
    end
    mapMarkers = {}
end

local function SpawnFishingMarkers()
    ClearFishingMarkers()

    local zoneIndex = 0
    for _, waterType in pairs(Config.waterTypes) do
        local mapZone = waterType.zones and waterType.zones[1]
        if mapZone then
            local mapMarker = Config.mapMarker or {}
            local markerId = exports['qb-hud']:AddMarker(mapZone, {
                title = waterType.label,
                description = waterType.description or mapMarker.description or '',
                icon = waterType.blipIcon or mapMarker.icon or 'fish',
                color = waterType.blipColor or mapMarker.color,
                markerType = waterType.markerType or mapMarker.markerType or 'Store',
            })

            if markerId then
                mapMarkers[#mapMarkers + 1] = markerId
            end
        end

        for _, zone in ipairs(waterType.zones) do
            zoneIndex = zoneIndex + 1
            local zoneName = 'fishing_zone_' .. zoneIndex

            local mesh = StaticMesh(zone, Rotator(0, 0, 0), '/Game/HL_assets/InventoryItems/SM_MarkerCylinder.SM_MarkerCylinder')

            exports['qb-target']:AddSphereZone(zoneName, zone, 0, {
                distance = 400,
                useMesh = true,
            }, {
                {
                    icon = 'fish',
                    label = 'Start Fishing',
                    type = 'client',
                    event = 'qb-fishing:client:startFishing',
                    waterTypeId = waterType.id,
                },
            })

            localMarkers[#localMarkers + 1] = {
                actor = mesh and mesh.Object or nil,
                zoneName = zoneName,
            }
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    Timer.SetTimeout(function()
        SpawnFishingMarkers()
    end, 1000)
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isFishing = false
    currentWaterType = nil
    ClearFishingMarkers()
end)

RegisterClientEvent('qb-fishing:client:startFishing', function(data)
    if isFishing then
        return
    end
    if not fishing_ui then
        return
    end
    if not data or not data.waterTypeId then
        return
    end

    currentWaterType = data.waterTypeId
    isFishing = true

    TriggerServerEvent('qb-fishing:server:startFishingItem')

    fishing_ui:SendEvent('openUI')
    fishing_ui:BringToFront()
    fishing_ui:SetInputMode(1)
end)

function onShutdown()
    if fishing_ui then
        fishing_ui:Destroy()
        fishing_ui = nil
    end
    ClearFishingMarkers()
end
