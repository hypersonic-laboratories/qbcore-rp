local my_webui = WebUI('Fingerprint', 'qb-policejob/html/index.html')
local Targets = {}
local IsEscorting = false
local IsCuffed = false
require('locales/en')

-- Functions

local function getAuthorizedVehicles(grade)
    local authorizedVehicles = {}
    for minimumGrade, vehicles in pairs(Config.AuthorizedVehicles) do
        if grade >= minimumGrade then
            for vehicleName, vehicleLabel in pairs(vehicles) do
                authorizedVehicles[vehicleName] = vehicleLabel
            end
        end
    end
    return authorizedVehicles
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
--[[
--@TODO Add handler for package restart when logged in
player_data = QBCore.Functions.GetPlayerData()
setupPeds()
]]

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    player_data = exports['qb-core']:GetPlayerData()
    TriggerCallback('GetCuffedState', function(CuffedState)
        IsCuffed = CuffedState
    end, true)
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    player_data = {}
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
    for i = 1, #Config.Locations.evidence do
        local coords = Config.Locations.evidence[i].coords
        local distance = player_coords:Dist(coords)
        if distance < 500 then
            TriggerServerEvent('qb-policejob:server:evidence', i)
        end
    end
end)

RegisterClientEvent('qb-policejob:client:vehicleMenu', function(data)
    local vehicleMenu = {
        {
            header = Lang:t('menu.garage_title')
        }
    }

    local AuthorizedVehicles = getAuthorizedVehicles(exports['qb-core']:GetPlayerData().job.grade.level)
    for vehicleName, label in pairs(AuthorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            txt = '',
            params = {
                isServer = true,
                event = 'qb-policejob:server:retrieveVehicle',
                args = {
                    vehicle = vehicleName,
                    locationIndex = data.locationIndex,
                }
            }
        }
    end

    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang:t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        }
    }
    exports['qb-menu']:openMenu(vehicleMenu)
end)

RegisterClientEvent('qb-policejob:client:escort', function(data)
    TriggerCallback('escort', function(success)
        if not success then return end

        exports['qb-core']:DrawText(Lang:t('info.escort_toggle'))
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

local police_alert = 0
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

--- Target Setup
--@TODO: Locales
local function AddTargetZone(type, name, ...)
    if type == 'Mesh' then
        exports['qb-target']:AddMeshTarget(name, ...)
    elseif type == 'Box' then
        exports['qb-target']:AddBoxZone(name, ...)
    end

    Targets[name] = true
end

-- Duty
for i = 1, #Config.Locations['duty'] do
    local pos = Config.Locations['duty'][i]
    AddTargetZone('Mesh',
        'polduty_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                type = 'server',
                event = 'QBCore:ToggleDuty',
                label = 'Toggle Duty',
                icon = 'fas fa-clipboard',
                --jobType = 'leo'
            },
        }
    )
end

-- Vehicle
for i = 1, #Config.Locations['vehicle'] do
    local pos = Config.Locations['vehicle'][i]
    AddTargetZone('Mesh',
        'polveh_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_BusStop.SM_BusStop', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                event = 'qb-policejob:client:vehicleMenu',
                label = Lang:t('menu.pol_garage'),
                icon = 'fas fa-car',
                locationIndex = i,
                --jobType = 'leo'
            },
        }
    )
end

-- Stash
for i = 1, #Config.Locations['stash'] do
    local pos = Config.Locations['stash'][i]
    AddTargetZone('Mesh',
        'polstash_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_DuffelBag.SM_DuffelBag', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                type = 'server',
                event = 'qb-policejob:server:openStash',
                label = Lang:t('target.open_personal_stash'),
                icon = 'fas fa-box',
                --jobType = 'leo'
            },
        }
    )
end

-- Evidence
for i = 1, #Config.Locations['evidence'] do
    local pos = Config.Locations['evidence'][i]
    AddTargetZone('Box', 'polevid_' .. i, pos.coords, 250.0, 100.0, { minZ = pos.coords.Z - 100, maxZ = pos.coords.Z + 100, heading = pos.heading or 0, debug = true },
        {
            {
                type = 'client',
                event = 'qb-policejob:client:evidence',
                label = Lang:t('target.open_evidence_stash'),
                icon = 'fas fa-box-open',
                --jobType = 'leo'
            },
        }
    )
end

-- Fingerprint
for i = 1, #Config.Locations['fingerprint'] do
    local pos = Config.Locations['fingerprint'][i]
    AddTargetZone('Mesh',
        'polfprint_' .. i,
        pos.coords,
        pos.rotation or Rotator(0, 0, 0),
        '/QBCoreAssets/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
        {
            {
                type = 'server',
                event = 'qb-policejob:server:openFingerprint',
                label = Lang:t('target.open_fingerprint'),
                icon = 'fas fa-fingerprint',
                --jobType = 'leo'
            },
        }
    )
end

exports['qb-target']:AddTargetModel('SM_Door_RR_PoliceCar', {
    options = {
        {
            label = 'Take Out Vehicle',
            icon = 'fas fa-person',
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
            icon = 'fas fa-person',
            type = 'server',
            event = 'qb-policejob:server:takevehicle',
            jobType = 'leo',
            door = 'RL',
        }
    },
    distance = 500,
})

exports['qb-target']:AddGlobalPlayer({
    options = {
        {
            type = 'client',
            event = 'qb-prison:client:jail',
            label = 'Jail',
            icon = 'fas fa-user-lock',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:info',
            label = 'View Info',
            icon = 'fas fa-question',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:search',
            label = 'Search',
            icon = 'fas fa-magnifying-glass',
            jobType = 'leo',
        },
        {
            type = 'client',
            event = 'qb-policejob:client:escort',
            label = 'Escort',
            icon = 'fas fa-user-group',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:handcuff',
            label = 'Handcuff',
            icon = 'fas fa-handcuffs',
            jobType = 'leo',
        },
        {
            type = 'server',
            event = 'qb-policejob:server:putvehicle',
            label = 'Put In Vehicle',
            icon = 'fas fa-car',
            jobType = 'leo',
        },
        {
            type = 'client',
            event = 'qb-policejob:client:checkStatus',
            label = 'Check Status',
            icon = 'fas fa-question',
            jobType = 'leo',
        }
    },
    distance = 500
})
