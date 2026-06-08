local Lang = require('locales/en')
local sharedJobs = exports['qb-core']:GetShared('Jobs')

-- Blip markers

local markerIds = {}

local function addCityhallMarkers()
    for i = 1, #Config.Cityhalls do
        local m = Config.Cityhalls[i].marker
        if m then
            local d = m.blipData
            local markerId = exports['qb-hud']:AddMarker(m.coords, {
                title       = d.title or '',
                description = d.description or '',
                markerType  = d.markerType or 'Store',
                icon        = d.icon or 'city',
                color       = d.color,
            })
            if markerId then markerIds[#markerIds + 1] = markerId end
        end
    end
end

local function removeCityhallMarkers()
    for _, id in ipairs(markerIds) do
        exports['qb-hud']:RemoveMarker(id)
    end
    markerIds = {}
end

-- Functions

local function openCityhallMenu()
    local mainMenu = {
        {
            header = 'City Hall',
            isMenuHeader = true
        },
        {
            header = 'ID Card',
            txt = 'Get your ID Card',
            params = {
                event = 'qb-cityhall:client:openIdentityMenu'
            }
        },
        {
            header = 'Job Center',
            txt = 'Available Jobs',
            params = {
                event = 'qb-cityhall:client:openJobMenu'
            }
        },
        {
            header = 'Close Menu',
            txt = '',
            params = {
                event = 'qb-menu:client:closeMenu'
            }
        }
    }
    exports['qb-menu']:openMenu(mainMenu)
end

local function openIdentityMenu()
    TriggerCallback('getIdentityData', function(licenses)
        local identityMenu = {
            {
                header = 'Identity',
                isMenuHeader = true
            },
            {
                header = '← Go Back',
                params = {
                    event = 'qb-cityhall:client:openCityhallMenu'
                }
            }
        }
        for license, data in pairs(licenses) do
            identityMenu[#identityMenu + 1] = {
                header = data.label,
                txt = 'Cost: $' .. data.cost,
                params = {
                    event = 'qb-cityhall:client:requestId',
                    args = {
                        type = license,
                        cost = data.cost
                    }
                }
            }
        end
        exports['qb-menu']:openMenu(identityMenu)
    end)
end

local function openJobMenu()
    local jobMenu = {
        {
            header = 'Job Center',
            isMenuHeader = true
        },
        {
            header = '← Go Back',
            params = {
                event = 'qb-cityhall:client:openCityhallMenu'
            }
        }
    }

    for i = 1, #Config.AvailableJobs do
        local jobName = Config.AvailableJobs[i]
        jobMenu[#jobMenu + 1] = {
            header = sharedJobs[jobName] and sharedJobs[jobName].label or jobName,
            txt = 'Apply for this job',
            params = {
                event = 'qb-cityhall:client:applyJob',
                args = {
                    job = jobName
                }
            }
        }
    end

    exports['qb-menu']:openMenu(jobMenu)
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    addCityhallMarkers()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    removeCityhallMarkers()
end)

RegisterClientEvent('qb-cityhall:client:openCityhallMenu', function()
    Timer.SetTimeout(function()
        openCityhallMenu()
    end, 500)
end)

RegisterClientEvent('qb-cityhall:client:openIdentityMenu', function()
    openIdentityMenu()
end)

RegisterClientEvent('qb-cityhall:client:openJobMenu', function()
    openJobMenu()
end)

RegisterClientEvent('qb-cityhall:client:applyJob', function(data)
    TriggerServerEvent('qb-cityhall:server:ApplyJob', data.job)
end)

RegisterClientEvent('qb-cityhall:client:requestId', function(data)
    local license = Config.Cityhalls[1].licenses[data.type]
    if license and data.cost == license.cost then
        TriggerServerEvent('qb-cityhall:server:requestId', data.type)
        exports['qb-core']:Notify(('You have received your %s for $%s'):format(license.label, data.cost), 'success', 3500)
    else
        exports['qb-core']:Notify(Lang.t('error.not_in_range'), 'error')
    end
end)

-- Markers

function onShutdown()
    removeCityhallMarkers()
end

-- Targets

for i = 1, #Config.Cityhalls do
    local spots = Config.Cityhalls[i].spots
    for j = 1, #spots do
        local spot = spots[j]
        exports['qb-target']:AddMeshTarget(
            'cityhall_' .. i .. '_' .. j,
            spot.coords,
            Rotator(0, spot.heading, 0),
            '/QBCoreAssets/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
            {
                {
                    icon = 'landmark',
                    label = 'Open City Hall',
                    event = 'qb-cityhall:client:openCityhallMenu',
                }
            }
        )
    end
end
