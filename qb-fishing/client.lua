local isFishing = false
local localMarkers = {}

local TargetOptions = {
    options = {
        {
            icon = 'fas fa-fish',
            label = 'Start Fishing',
            type = 'client',
            event = 'qb-fishing:client:startFishing'
        }
    },
    distance = 400
}

local function SpawnFishingMarkers()
    for _, waterType in pairs(Config.waterTypes) do
        for _, zone in ipairs(waterType.zones) do
            local mesh = StaticMesh(
                zone.coords,
                Rotator(0, 0, 0),
                '/Game/HL_assets/InventoryItems/SM_MarkerCylinder.SM_MarkerCylinder'
            )

            if mesh and mesh.Object then
                localMarkers[mesh.Object] = {
                    waterTypeId = waterType.id,
                    actor = mesh.Object
                }
                exports['qb-target']:AddTargetEntity(mesh.Object, TargetOptions)
            end
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    SpawnFishingMarkers()
end)

RegisterClientEvent('qb-fishing:client:startFishing', function(data)
    if isFishing then return end
    if not data or not data.entity then return end

    local mData = localMarkers[data.entity]
    if not mData then return end

    isFishing = true
    TriggerServerEvent('qb-fishing:server:startFishingItem')
    TriggerLocalClientEvent('QBCore:Notify', 'You cast your line...', 'primary')

    Timer.SetTimeout(function()
        TriggerServerEvent('qb-fishing:server:completeFishing', mData.waterTypeId)
        isFishing = false
    end, Config.fishingTime)
end)

function onShutdown()
    for _, data in pairs(localMarkers) do
        if data.actor and data.actor:IsValid() then
            DeleteEntity(data.actor)
        end
    end
    localMarkers = {}
end
