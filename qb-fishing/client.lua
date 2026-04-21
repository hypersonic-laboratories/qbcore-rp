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
    if not fishing_ui then return end
    if not data or not data.entity then return end

    local mData = localMarkers[data.entity]
    if not mData then return end

    currentWaterType = mData.waterTypeId
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

    for _, data in pairs(localMarkers) do
        if data.actor and data.actor:IsValid() then
            DeleteEntity(data.actor)
        end
    end
    localMarkers = {}
end
