local isFishing = false
local localMarkers = {}
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

local function SpawnFishingMarkers()
    local zoneIndex = 0
    for _, waterType in pairs(Config.waterTypes) do
        for _, zone in ipairs(waterType.zones) do
            zoneIndex = zoneIndex + 1
            local zoneName = 'fishing_zone_' .. zoneIndex

            local mesh = StaticMesh(
                zone.coords,
                Rotator(0, 0, 0),
                '/Game/HL_assets/InventoryItems/SM_MarkerCylinder.SM_MarkerCylinder'
            )

            exports['qb-target']:AddSphereZone(zoneName, zone.coords, 100, { distance = 400, debug = true }, {
                {
                    icon = 'fish',
                    label = 'Start Fishing',
                    type = 'client',
                    event = 'qb-fishing:client:startFishing',
                    waterTypeId = waterType.id,
                }
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

RegisterClientEvent('qb-fishing:client:startFishing', function(data)
    if isFishing then return end
    if not fishing_ui then return end
    if not data or not data.waterTypeId then return end

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

    for _, marker in ipairs(localMarkers) do
        if marker.actor and marker.actor:IsValid() then
            DeleteEntity(marker.actor)
        end
        exports['qb-target']:RemoveZone(marker.zoneName)
    end
    localMarkers = {}
end
