local my_webui = WebUI('Fingerprint', 'qb-policejob/html/index.html')
local Targets = {}
local IsEscorting = false
local IsCuffed = false
local policeMarkers = {}
local Lang = require('locales/en')

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

local function MenuVehicle(locId)
    local loc = Config.Locations[locId]
    if not loc then return end
    local vehicleMenu = {
        {
            header = Lang.t('menu.garage_title'),
            isMenuHeader = true,
        }
    }

    local authorizedVehicles = getAuthorizedVehicles(exports['qb-core']:GetPlayerData().job.grade.level, loc.authorizedVehicles)
    for vehicleName, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-policejob:server:retrieveVehicle',
                args = {
                    vehicle = vehicleName,
                    locId = locId,
                }
            }
        }
    end

    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang.t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
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
    if not loc then return end
    local helicopterMenu = {
        {
            header = Lang.t('menu.pol_helicopters'),
            isMenuHeader = true,
        }
    }

    local authorizedHelicopters = getAuthorizedHelicopters(exports['qb-core']:GetPlayerData().job.grade.level, loc.authorizedHelicopters)
    for heliName, label in pairs(authorizedHelicopters) do
        helicopterMenu[#helicopterMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-policejob:server:retrieveHelicopter',
                args = {
                    vehicle = heliName,
                    locId = locId,
                }
            }
        }
    end

    helicopterMenu[#helicopterMenu + 1] = {
        header = Lang.t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
    }
    exports['qb-menu']:openMenu(helicopterMenu)
end

local fingerprint = false
local function closeFingerprint()
    my_webui:SetInputMode(0)
    fingerprint = false
    TriggerServerEvent('qb-policejob:server:closeFingerprint')
end

exports('qb-policejob', 'IsHandcuffed', function()
    return IsCuffed
end)

-- Cleanup
function onShutdown()
    for name, _ in pairs(Targets) do
        exports['qb-target']:RemoveZone(name)
    end
end

-- Handlers

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    player_data = exports['qb-core']:GetPlayerData()
    TriggerCallback('GetCuffedState', function(CuffedState)
        IsCuffed = CuffedState
    end, true)
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    player_data = {}
    for _, id in ipairs(policeMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    policeMarkers = {}
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    player_data.job = JobInfo
end)

-- Events

Input.BindKey('BackSpace', function()
    if not fingerprint then return end
    my_webui:SendEvent('closeFingerprint')
    closeFingerprint()
end)

Input.BindKey('E', function()
    if not IsEscorting then return end
    TriggerCallback('escort', function(success)
        if not success then return end

        exports['qb-core']:HideText()
        IsEscorting = false
    end)
end)

my_webui:RegisterEventHandler('closeFingerprint', function()
    closeFingerprint()
end)

my_webui:RegisterEventHandler('scanFinger', function()
    TriggerServerEvent('qb-policejob:server:scanFinger')
end)

RegisterClientEvent('qb-policejob:client:openFingerprint', function()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('openFingerprint')
    fingerprint = true
end)

RegisterClientEvent('qb-policejob:client:updateFingerprint', function(fingerprintId)
    my_webui:SendEvent('updateFingerprint', { fingerprintId = fingerprintId })
end)

RegisterClientEvent('qb-policejob:client:evidence', function()
    local player_ped = GetPlayerPawn(HPlayer)
    if not player_ped then return end
    local player_coords = GetEntityCoords(player_ped)
    for locId, loc in pairs(Config.Locations) do
        for i, point in ipairs(loc.evidence) do
            if player_coords:Dist(point) < 500 then
                TriggerServerEvent('qb-policejob:server:evidence', locId .. '_' .. i)
            end
        end
    end
end)

RegisterClientEvent('qb-policejob:client:vehicleMenu', function(data)
    MenuVehicle(data and data.locId)
end)

RegisterClientEvent('qb-policejob:client:helicopterMenu', function(data)
    MenuHelicopter(data and data.locId)
end)

RegisterClientEvent('qb-policejob:client:escort', function(data)
    TriggerCallback('escort', function(success)
        if not success then return end

        exports['qb-core']:DrawText(Lang.t('info.escort_toggle'))
        IsEscorting = true
    end, data.entity)
end)

RegisterClientEvent('qb-policejob:client:setEscorted', function(Escorter, IsEscorted)
    local PlayerPed = GetPlayerPawn(HPlayer)
    if IsEscorted then
        AttachActorToComponent(PlayerPed, Escorter:K2_GetRootComponent(), Vector(100, 50, 0), Rotator(), 'root')
    else
        DetachActor(PlayerPed)
        PlayerPed:GetComponentByClass(UE.UCharacterMovementComponent):SetMovementMode(UE.EMovementMode.MOVE_Walking, nil)
    end
end)

RegisterClientEvent('qb-policejob:client:setCuffed', function(NewIsCuffed)
    IsCuffed = NewIsCuffed
end)

--[[ Events.SubscribeRemote('qb-policejob:client:policeAlert', function(coords, text)
    police_alert = police_alert + 1
    QBCore.Functions.Notify('Police Alert: ' .. text)
    Events.Call('Map:AddBlip', {
        id = 'police_alert_' .. police_alert,
        name = 'Police Alert',
        coords = { x = coords.X, y = coords.Y, z = coords.Z },
        imgUrl = './media/map-icons/Police-icon.svg',
        group = 'dispatch'
    })
    Timer.SetTimeout(function()
        Events.Call('Map:RemoveBlip', 'police_alert_' .. police_alert)
    end, 30000)
end)

Events.SubscribeRemote('qb-policejob:client:tracker', function(coords, citizenid)
    QBCore.Functions.Notify('Tracker location shown for 30 seconds')
    Events.Call('Map:AddBlip', {
        id = 'tracker_' .. citizenid,
        name = 'Anklet Tracker',
        coords = { x = coords.X, y = coords.Y, z = coords.Z },
        imgUrl = './media/map-icons/Police-icon.svg',
        group = 'anklet'
    })
    Timer.SetTimeout(function()
        Events.Call('Map:RemoveBlip', 'tracker_' .. citizenid)
    end, 30000)
end)]]

RegisterClientEvent('qb-policejob:client:checkCitizenInfo', function(args)
    local PlayerData = args.PlayerData or args
    -- Character Info
    local CharInfo = PlayerData.charinfo
    local CitizenId = PlayerData.citizenid
    local Gender = CharInfo.gender == 0 and 'Male' or 'Female'

    -- Job Info
    local JobData = PlayerData.job

    local menuItems = {
        {
            header = 'Citizen Info',
            isMenuHeader = true,
        },
        {
            header = 'Name',
            txt = CharInfo.firstname .. ' ' .. CharInfo.lastname,
        },
        {
            header = 'Gender',
            txt = Gender,
        },
        {
            header = 'Nationality',
            txt = CharInfo.nationality,
        },
        {
            header = 'Phone Number',
            txt = CharInfo.phone,
        },
        {
            header = 'Citizen ID',
            txt = CitizenId,
        },
        {
            header = 'Date of Birth',
            txt = CharInfo.birthdate,
        },
        {
            header = 'Job',
            txt = JobData.label .. ' | ' .. JobData.grade.name,
        },
        {
            header = 'View Licenses',
            txt = '',
            params = {
                event = 'qb-policejob:client:viewLicenses',
                args = {
                    PlayerData = PlayerData,
                }
            }
        },
        {
            header = 'View Criminal Record',
            txt = '',
            params = {
                event = 'qb-policejob:client:viewCriminalRecord',
                args = {
                    PlayerData = PlayerData,
                }
            }
        },
    }

    exports['qb-menu']:openMenu(menuItems)
end)

RegisterClientEvent('qb-policejob:client:viewLicenses', function(args)
    local licenseMenu = {
        {
            header = 'Licenses',
            isMenuHeader = true,
        },
        {
            header = '← Go Back',
            params = {
                event = 'qb-policejob:client:checkCitizenInfo',
                args = {
                    PlayerData = args.PlayerData,
                }
            }
        },
    }
    for license, obtained in pairs(args.PlayerData.metadata.licences) do
        licenseMenu[#licenseMenu + 1] = {
            header = string.format('%s | %s%s', obtained and '✅' or '❌', license:sub(1, 1):upper(), license:sub(2))
        }
    end
    licenseMenu[#licenseMenu + 1] = {
        header = 'Close Menu',
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
    }

    exports['qb-menu']:openMenu(licenseMenu)
end)

RegisterClientEvent('qb-policejob:client:viewCriminalRecord', function(args)
    local criminalRecordMenu = {
        {
            header = 'Criminal Record',
            isMenuHeader = true,
        },
        {
            header = '← Go Back',
            params = {
                event = 'qb-policejob:client:checkCitizenInfo',
                args = {
                    PlayerData = args.PlayerData,
                }
            }
        },
        {
            header = 'Has Criminal Record',
            txt = args.PlayerData.metadata.criminalrecord.hasRecord and 'Yes' or 'No',
        },
        {
            header = 'Toggle Tracker',
            txt = args.PlayerData.metadata.tracker and '✅ Active' or '❌ Inactive',
            params = {
                isServer = true,
                event = 'qb-policejob:server:toggleTracker',
                args = {
                    CitizenId = args.PlayerData.citizenid,
                }
            }
        }
    }
    criminalRecordMenu[#criminalRecordMenu + 1] = {
        header = 'Close Menu',
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
    }

    exports['qb-menu']:openMenu(criminalRecordMenu)
end)

-- Target Setup

for locId, loc in pairs(Config.Locations) do
    for i, point in ipairs(loc.duty) do
        local name = 'polduty_' .. locId .. '_' .. i
        exports['qb-target']:AddSphereZone(name, point, 75, { distance = 1000 },
            {
                {
                    type = 'server',
                    event = 'QBCore:ToggleDuty',
                    label = 'Toggle Duty',
                    icon = 'clipboard',
                    --jobType = 'leo'
                },
            }
        )
        Targets[name] = true
    end

    for i, point in ipairs(loc.vehicle) do
        local name = 'polveh_' .. locId .. '_' .. i
        exports['qb-target']:AddSphereZone(name, point, 75, { distance = 1000 },
            {
                {
                    event = 'qb-policejob:client:vehicleMenu',
                    label = Lang.t('menu.pol_garage'),
                    icon = 'car',
                    args = { locId = locId },
                    --jobType = 'leo'
                },
            }
        )
        Targets[name] = true
    end

    for i, point in ipairs(loc.stash) do
        local name = 'polstash_' .. locId .. '_' .. i
        exports['qb-target']:AddSphereZone(name, point, 75, { distance = 1000 },
            {
                {
                    type = 'server',
                    event = 'qb-policejob:server:openStash',
                    label = Lang.t('target.open_personal_stash'),
                    icon = 'box',
                    --jobType = 'leo'
                },
            }
        )
        Targets[name] = true
    end

    for i, point in ipairs(loc.fingerprint) do
        local name = 'polfprint_' .. locId .. '_' .. i
        exports['qb-target']:AddSphereZone(name, point, 75, { distance = 1000 },
            {
                {
                    type = 'server',
                    event = 'qb-policejob:server:openFingerprint',
                    label = Lang.t('target.open_fingerprint'),
                    icon = 'fingerprint',
                    --jobType = 'leo'
                },
            }
        )
        Targets[name] = true
    end

    for i, point in ipairs(loc.evidence) do
        local name = 'polevid_' .. locId .. '_' .. i
        exports['qb-target']:AddSphereZone(name, point, 75, { distance = 1000 },
            {
                {
                    type = 'client',
                    event = 'qb-policejob:client:evidence',
                    label = Lang.t('target.open_evidence_stash'),
                    icon = 'box-open',
                    --jobType = 'leo'
                },
            }
        )
        Targets[name] = true
    end

    for i, point in ipairs(loc.helicopter) do
        local name = 'polheli_' .. locId .. '_' .. i
        exports['qb-target']:AddSphereZone(name, point, 75, { distance = 1000 },
            {
                {
                    event = 'qb-policejob:client:helicopterMenu',
                    label = Lang.t('menu.pol_helicopters'),
                    icon = 'helicopter',
                    args = { locId = locId },
                    --jobType = 'leo'
                },
            }
        )
        Targets[name] = true
    end
end

-- Markers

for _, loc in pairs(Config.Locations) do
    local markerId = exports['qb-hud']:AddMarker(loc.duty[1], {
        title      = loc.label,
        icon       = 'shield',
        markerType = 'Police',
    })
    if markerId then policeMarkers[#policeMarkers + 1] = markerId end
end

-- Vehicle Doors

exports['qb-target']:AddTargetModel('SM_Door_RR_PoliceCar', {
    options = {
        {
            label = 'Take Out Vehicle',
            icon = 'person',
            type = 'server',
            event = 'qb-policejob:server:takevehicle',
            jobType = 'leo',
            door = 'RR',
        }
    },
    distance = 500,
})

exports['qb-target']:AddTargetModel('SM_Door_RL_PoliceCar', {
    options = {
        {
            label = 'Take Out Vehicle',
            icon = 'person',
            type = 'server',
            event = 'qb-policejob:server:takevehicle',
            jobType = 'leo',
            door = 'RL',
        }
    },
    distance = 500,
})

-- Global Player

exports['qb-target']:AddGlobalPlayer({
    options = {
        {
            type = 'client',
            event = 'qb-prison:client:jail',
            label = 'Jail',
            icon = 'user-lock',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:info',
            label = 'View Info',
            icon = 'question',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:search',
            label = 'Search',
            icon = 'magnifying-glass',
            jobType = 'leo',
        },
        {
            type = 'client',
            event = 'qb-policejob:client:escort',
            label = 'Escort',
            icon = 'user-group',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:handcuff',
            label = 'Handcuff',
            icon = 'handcuffs',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:putvehicle',
            label = 'Put In Vehicle',
            icon = 'car',
            jobType = 'leo',
        },
        {
            type = 'client',
            event = 'qb-policejob:client:checkStatus',
            label = 'Check Status',
            icon = 'question',
            jobType = 'leo',
        }
    },
    distance = 500
})
