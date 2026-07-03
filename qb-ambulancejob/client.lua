local Lang = require('locales/en')
local checkedIn = false
local hospitalMarkers = {}

-- Functions

local function getAuthorizedVehicles(grade, authorizedVehicles)
    local accessibleVehicles = {}
    for availableGrade, vehicles in pairs(authorizedVehicles) do
        if grade >= availableGrade then
            for vehicleName, vehicleLabel in pairs(vehicles) do
                accessibleVehicles[vehicleName] = vehicleLabel
            end
        end
    end
    return accessibleVehicles
end

local function MenuGarage(locId)
    local loc = Config.Locations[locId]
    if not loc then
        return
    end
    local vehicleMenu = {
        {
            header = Lang.t('menu.amb_vehicles'),
            isMenuHeader = true,
        },
    }

    local authorizedVehicles = getAuthorizedVehicles(exports['qb-core']:GetPlayerData().job.grade.level, loc.authorizedVehicles)
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-ambulancejob:server:retrieveVehicle',
                args = {
                    vehicle = veh,
                    locId = locId,
                },
            },
        }
    end
    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang.t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        },
    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

local function getAuthorizedHelicopters(grade, authorizedHelicopters)
    local accessibleHelicopters = {}
    for availableGrade, helicopters in pairs(authorizedHelicopters) do
        if grade >= availableGrade then
            for helicopterName, helicopterLabel in pairs(helicopters) do
                accessibleHelicopters[helicopterName] = helicopterLabel
            end
        end
    end
    return accessibleHelicopters
end

local function MenuHelicopter(locId)
    local loc = Config.Locations[locId]
    if not loc then
        return
    end
    local helicopterMenu = {
        {
            header = Lang.t('menu.amb_helicopters'),
            isMenuHeader = true,
        },
    }

    local authorizedHelicopters = getAuthorizedHelicopters(exports['qb-core']:GetPlayerData().job.grade.level, loc.authorizedHelicopters)
    for heli, label in pairs(authorizedHelicopters) do
        helicopterMenu[#helicopterMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-ambulancejob:server:retrieveHelicopter',
                args = {
                    vehicle = heli,
                    locId = locId,
                },
            },
        }
    end
    helicopterMenu[#helicopterMenu + 1] = {
        header = Lang.t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        },
    }
    exports['qb-menu']:openMenu(helicopterMenu)
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function() end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    for _, id in ipairs(hospitalMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    hospitalMarkers = {}
end)

RegisterClientEvent('qb-ambulancejob:client:vehicleMenu', function(data)
    MenuGarage(data and data.locId)
end)

RegisterClientEvent('qb-ambulancejob:client:helicopterMenu', function(data)
    MenuHelicopter(data and data.locId)
end)

RegisterClientEvent('qb-ambulancejob:client:checkedIn', function()
    checkedIn = true
    exports['qb-core']:DrawText(Lang.t('text.bed_out'))
end)

RegisterClientEvent('qb-hospitaljob:client:openStatusMenu', function(limbData)
    local statusMenu = {
        {
            header = Lang.t('menu.status'),
            isMenuHeader = true,
        },
    }
    for _, limb in ipairs(limbData) do
        local healthPercent = math.floor((limb.currentHealth / limb.maxHealth) * 100)
        local limbName = limb.limbTag:gsub('GameplayEffect%.DamageArea%.', '')
        local damageText = ''
        if #limb.damageTypes > 0 then
            local cleanedDamageTypes = {}
            for _, damageType in ipairs(limb.damageTypes) do
                local cleanType = damageType:gsub('GameplayEffect%.DamageType%.', '')
                table.insert(cleanedDamageTypes, cleanType)
            end
            damageText = '<br>Damage Types: ' .. table.concat(cleanedDamageTypes, ', ')
        end
        local healthColor = '#00ff00'
        if healthPercent <= 0 then
            healthColor = '#ff0000'
        elseif healthPercent < 50 then
            healthColor = '#ffff00'
        end
        table.insert(statusMenu, {
            header = '<span style="color: ' .. healthColor .. ';">' .. limbName .. '</span>',
            txt = string.format('Health: %d%% (%d/%d)%s', healthPercent, limb.currentHealth, limb.maxHealth, damageText),
            params = {
                isServer = true,
                event = 'qb-hospitaljob:server:treatLimb',
                args = {
                    limb = limbName,
                    limbTag = limb.limbTag,
                    health = limb.currentHealth,
                    maxHealth = limb.maxHealth,
                    damageTypes = limb.damageTypes,
                    entity = limb.entity,
                },
            },
        })
    end
    table.insert(statusMenu, {
        header = Lang.t('menu.close'),
        params = {
            event = 'qb-menu:client:closeMenu',
        },
    })
    exports['qb-menu']:openMenu(statusMenu)
end)

-- Input

Input.BindKey('E', function()
    if checkedIn then
        TriggerServerEvent('qb-ambulancejob:server:checkOut')
        checkedIn = false
        exports['qb-core']:HideText()
    end
end)

-- Target

for locId, loc in pairs(Config.Locations) do
    for i, point in ipairs(loc.checking) do
        exports['qb-target']:AddSphereZone('ambchecking_' .. locId .. '_' .. i, point, 0, { distance = 1000, useMesh = true }, {
            {
                icon = 'clipboard-check',
                label = 'Check In',
                type = 'server',
                event = 'qb-ambulancejob:server:checkIn',
            },
        })
    end

    for i, point in ipairs(loc.duty) do
        exports['qb-target']:AddSphereZone('ambduty_' .. locId .. '_' .. i, point, 0, { distance = 1000, useMesh = true }, {
            {
                icon = 'clipboard',
                label = 'Toggle Duty',
                type = 'server',
                event = 'QBCore:ToggleDuty',
                job = 'ambulance',
            },
        })
    end

    for i, point in ipairs(loc.stash) do
        exports['qb-target']:AddSphereZone('ambstash_' .. locId .. '_' .. i, point, 0, { distance = 1000, useMesh = true }, {
            {
                icon = 'box',
                label = 'Open Stash',
                type = 'server',
                event = 'qb-ambulancejob:server:openStash',
                job = 'ambulance',
            },
        })
    end

    for i, point in ipairs(loc.vehicle) do
        exports['qb-target']:AddSphereZone('ambvehicle_' .. locId .. '_' .. i, point, 0, { distance = 1000, useMesh = true }, {
            {
                icon = 'car',
                label = 'Retrieve Vehicle',
                event = 'qb-ambulancejob:client:vehicleMenu',
                args = { locId = locId },
                job = 'ambulance',
            },
        })
    end

    for i, point in ipairs(loc.helicopter) do
        exports['qb-target']:AddSphereZone('ambhelicopter_' .. locId .. '_' .. i, point, 0, { distance = 1000, useMesh = true }, {
            {
                icon = 'helicopter',
                label = 'Retrieve Helicopter',
                event = 'qb-ambulancejob:client:helicopterMenu',
                args = { locId = locId },
                job = 'ambulance',
            },
        })
    end
end

-- Markers

for _, loc in pairs(Config.Locations) do
    local markerId = exports['qb-hud']:AddMarker(loc.checking[1], {
        title = loc.label,
        icon = 'hospital',
        markerType = 'Hospital',
    })
    if markerId then
        hospitalMarkers[#hospitalMarkers + 1] = markerId
    end
end

-- Global Player

exports['qb-target']:AddGlobalPlayer({
    distance = 1000,
    options = {
        {
            icon = 'heart-pulse',
            label = 'Check Health Status',
            type = 'server',
            event = 'qb-hospitaljob:server:status',
            -- job = 'ambulance'
        },
        {
            icon = 'user-doctor',
            label = 'Revive',
            type = 'server',
            event = 'qb-hospitaljob:server:revive',
            -- job = 'ambulance'
        },
        {
            icon = 'bandage',
            label = 'Bandage',
            type = 'server',
            event = 'qb-hospitaljob:server:bandage',
            -- job = 'ambulance'
        },
        {
            icon = 'user-group',
            label = 'Escort',
            type = 'server',
            event = 'qb-hospitaljob:server:escort',
            -- job = 'ambulance'
        },
    },
})
