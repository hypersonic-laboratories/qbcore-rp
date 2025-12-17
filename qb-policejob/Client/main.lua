local my_webui = WebUI('Fingerprint', 'qb-policejob/html/index.html')
local Targets = {}
local IsEscorting = false
local IsCuffed = false
require('locales/en')

-- Functions

-- Cleanup
function onShutdown()
    for name, _ in pairs(Targets) do
        exports['qb-target']:RemoveZone(name)
    end
end

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
    },
    distance = 500
})

-- Handlers
--[[ 
--@TODO Add handler for package restart when logged in
player_data = QBCore.Functions.GetPlayerData()
setupPeds()
]]

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    player_data = exports['qb-core']:GetPlayerData()
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
end)

Events.SubscribeRemote('qb-policejob:client:info', function(data)
    local char_info = data.charinfo
    local job_info = data.job
    local char_metadata = data.metadata
    local info_menu = ContextMenu.new()

    -- Character Information
    local citizen_id = data.citizenid
    local birthdate = char_info.birthdate
    local nationality = char_info.nationality
    local phone_number = char_info.phone
    local gender = char_info.gender == 0 and 'Male' or 'Female'
    info_menu:addDropdown('char-info', 'Documentation', {
        { id = '1', label = 'Citizen ID: ' .. citizen_id,     type = 'button', callback = function() end },
        { id = '2', label = 'Birthdate: ' .. birthdate,       type = 'button', callback = function() end },
        { id = '3', label = 'Gender: ' .. gender,             type = 'button', callback = function() end },
        { id = '4', label = 'Nationality: ' .. nationality,   type = 'button', callback = function() end },
        { id = '5', label = 'Phone Number: ' .. phone_number, type = 'button', callback = function() end },
    })

    -- Job Information
    local job = job_info.label
    local rank = job_info.grade.name
    info_menu:addDropdown('job', 'Job Information', {
        { id = '1', label = 'Job: ' .. job,   type = 'button', callback = function() end },
        { id = '2', label = 'Rank: ' .. rank, type = 'button', callback = function() end }
    })

    -- Licenses
    local licenses = char_metadata.licences
    local license_table = {}
    for license, obtained in pairs(licenses) do
        license_table[#license_table + 1] = { id = tostring(license), label = license:gsub('^%l', string.upper), type = 'checkbox', checked = obtained, callback = function() end }
    end
    info_menu:addDropdown('licenses', 'Licenses', license_table)

    -- Criminal
    local criminal_record = char_metadata.criminalrecord.hasRecord
    local has_tracker = char_metadata.tracker
    info_menu:addDropdown('criminal', 'Criminal Record', {
        { id = '1', label = 'Criminal Record', type = 'checkbox', checked = criminal_record, callback = function() end },
        {
            id = '2',
            label = 'Manage Tracker',
            type = 'checkbox',
            checked = has_tracker,
            callback = function()
                Events.CallRemote('qb-policejob:server:tracker', data.source)
            end
        }
    })

    info_menu:SetHeader(char_info.firstname .. ' ' .. char_info.lastname)
    info_menu:setMenuInfo('Citizen Information')
    info_menu:Open(false, true)
end)
 ]]

--- Target Setup
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
        '/Game/QBCore/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
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
        '/Game/QBCore/Meshes/SM_BusStop.SM_BusStop', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
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
        '/Game/QBCore/Meshes/SM_DuffelBag.SM_DuffelBag', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
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
    AddTargetZone('Box', 'polevid_' .. i, pos.coords, 250.0, 100.0, { minZ = pos.coords.Z - 100, maxZ = pos.coords.Z + 100, heading = pos.heading or 0, debug = true},
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
        '/Game/QBCore/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
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