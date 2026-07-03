local registeredZones = {}
local shopMarkers = {}

local function RegisterShopsAndMarkers()
    for shop, shopData in pairs(Config.Locations) do
        exports['qb-target']:AddSphereZone(shop, shopData.coords, 0, {
            useMesh = true,
            distance = 500,
        }, {
            {
                icon = shopData.targetIcon or Config.defaultTargetIcon,
                label = shopData.targetLabel or Config.defaultTargetLabel,
                event = 'qb-shops:client:openShop',
                shop = shop,
                item = shopData.requiredItem,
                job = shopData.requiredJob,
                gang = shopData.requiredGang,
            },
        })
        registeredZones[shop] = true

        if shopData.showblip then
            local markerId = exports['qb-hud']:AddMarker(shopData.coords, {
                title = shopData.label,
                description = shopData.description or '',
                icon = shopData.blipIcon or 'grocery',
                color = shopData.blipColor,
                markerType = 'Store',
            })
            if markerId then
                shopMarkers[#shopMarkers + 1] = markerId
            end
        end
    end
end

local function UnregisterShopsAndMarkers()
    for shop in pairs(registeredZones) do
        exports['qb-target']:RemoveZone(shop)
    end
    registeredZones = {}
    for _, id in ipairs(shopMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    shopMarkers = {}
end

-- Event Handlers

RegisterClientEvent('qb-shops:client:openShop', function(data)
    Timer.SetTimeout(function()
        TriggerServerEvent('qb-shops:server:openShop', { shop = data.shop })
    end, 600)
end)

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    RegisterShopsAndMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    UnregisterShopsAndMarkers()
end)
