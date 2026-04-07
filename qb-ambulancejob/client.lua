local Lang = require('locales/en')
local checkedIn = false

-- Functions

local function getAuthorizedVehicles(grade)
    local accessibleVehicles = {}
    for availableGrade, vehicles in pairs(Config.AuthorizedVehicles) do
        if grade >= availableGrade then
            for vehicleName, vehicleLabel in pairs(vehicles) do
                accessibleVehicles[vehicleName] = vehicleLabel
            end
        end
    end
    return accessibleVehicles
end

local function MenuGarage()
    local vehicleMenu = {
        {
            header = Lang:t('menu.amb_vehicles'),
            isMenuHeader = true
        }
    }

    local authorizedVehicles = getAuthorizedVehicles(exports['qb-core']:GetPlayerData().job.grade.level)
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-ambulancejob:server:retrieveVehicle',
                args = {
                    vehicle = veh
                }
            }
        }
    end
    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang:t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu'
        }

    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

local function getAuthorizedHelicopters(grade)
    local accessibleHelicopters = {}
    for availableGrade, helicopters in pairs(Config.AuthorizedHelicopters) do
        if grade >= availableGrade then
            for helicopterName, helicopterLabel in pairs(helicopters) do
                accessibleHelicopters[helicopterName] = helicopterLabel
            end
        end
    end
    return accessibleHelicopters
end

local function MenuHelicopter()
    local helicopterMenu = {
        {
            header = Lang:t('menu.amb_helicopters'),
            isMenuHeader = true
        }
    }

    local authorizedHelicopters = getAuthorizedHelicopters(exports['qb-core']:GetPlayerData().job.grade.level)
    for heli, label in pairs(authorizedHelicopters) do
        helicopterMenu[#helicopterMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-ambulancejob:server:retrieveHelicopter',
                args = {
                    vehicle = heli
                }
            }
        }
    end
    helicopterMenu[#helicopterMenu + 1] = {
        header = Lang:t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu'
        }

    }
    exports['qb-menu']:openMenu(helicopterMenu)
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()

end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()

end)

RegisterClientEvent('qb-ambulancejob:client:vehicleMenu', function()
    MenuGarage()
end)

RegisterClientEvent('qb-ambulancejob:client:helicopterMenu', function()
    MenuHelicopter()
end)

RegisterClientEvent('qb-ambulancejob:client:checkedIn', function()
    checkedIn = true
    exports['qb-core']:DrawText(Lang:t('text.bed_out'))
end)

RegisterClientEvent('qb-hospitaljob:client:openStatusMenu', function(limbData)
    local statusMenu = {
        {
            header = Lang:t('menu.status'),
            isMenuHeader = true
        }
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
            txt = string.format('Health: %d%% (%d/%d)%s',
                healthPercent,
                limb.currentHealth,
                limb.maxHealth,
                damageText
            ),
            params = {
                isServer = true,
                event = 'qb-hospitaljob:server:treatLimb',
                args = {
                    limb = limbName,
                    limbTag = limb.limbTag,
                    health = limb.currentHealth,
                    maxHealth = limb.maxHealth,
                    damageTypes = limb.damageTypes,
                    entity = limb.entity
                }
            }
        })
    end
    table.insert(statusMenu, {
        header = Lang:t('menu.close'),
        params = {
            event = 'qb-menu:client:closeMenu'
        }
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

-- Checking
for i = 1, #Config.Locations['checking'] do
    local pos = Config.Locations['checking'][i]
    exports['qb-target']:AddMeshTarget(
        'ambchecking_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                icon = 'fas fa-clipboard-check',
                label = 'Check In',
                type = 'server',
                event = 'qb-ambulancejob:server:checkIn',
                -- job = 'ambulance'
            }
        }
    )
end

-- Duty
for i = 1, #Config.Locations['duty'] do
    local pos = Config.Locations['duty'][i]
    exports['qb-target']:AddMeshTarget(
        'ambduty_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                icon = 'fas fa-clipboard',
                label = 'Toggle Duty',
                type = 'server',
                event = 'QBCore:ToggleDuty',
                -- job = 'ambulance'
            }
        }
    )
end

-- Stash
for i = 1, #Config.Locations['stash'] do
    local pos = Config.Locations['stash'][i]
    exports['qb-target']:AddMeshTarget(
        'ambstash_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_MedicalBag.SM_MedicalBag', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                icon = 'fas fa-box',
                label = 'Open Stash',
                type = 'server',
                event = 'qb-ambulancejob:server:openStash',
                -- job = 'ambulance'
            }
        }
    )
end

--Vehicle
for i = 1, #Config.Locations['vehicle'] do
    local pos = Config.Locations['vehicle'][i]
    exports['qb-target']:AddMeshTarget(
        'ambvehicle_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_BusStop.SM_BusStop', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                icon = 'fas fa-car',
                label = 'Retrieve Vehicle',
                event = 'qb-ambulancejob:client:vehicleMenu',
                -- job = 'ambulance'
            }
        }
    )
end

-- Helicopter
for i = 1, #Config.Locations['helicopter'] do
    local pos = Config.Locations['helicopter'][i]
    exports['qb-target']:AddMeshTarget(
        'ambhelicopter_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_BusStop.SM_BusStop', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                icon = 'fas fa-helicopter',
                label = 'Retrieve Helicopter',
                event = 'qb-ambulancejob:client:helicopterMenu',
                -- job = 'ambulance'
            }
        }
    )
end

-- Global Player

exports['qb-target']:AddGlobalPlayer({
    distance = 1000,
    options = {
        {
            icon = 'fas fa-heart-pulse',
            label = 'Check Health Status',
            type = 'server',
            event = 'qb-hospitaljob:server:status',
            -- job = 'ambulance'
        },
        {
            icon = 'fas fa-user-doctor',
            label = 'Revive',
            type = 'server',
            event = 'qb-hospitaljob:server:revive',
            -- job = 'ambulance'
        },
        {
            icon = 'fas fa-bandage',
            label = 'Bandage',
            type = 'server',
            event = 'qb-hospitaljob:server:bandage',
            -- job = 'ambulance'
        },
        {
            icon = 'fas fa-user-group',
            label = 'Escort',
            type = 'server',
            event = 'qb-hospitaljob:server:escort',
            -- job = 'ambulance'
        }
    }
})
