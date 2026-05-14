local Lang = require('locales/en')
local sharedJobs = exports['qb-core']:GetShared('Jobs')

-- Functions

local function getHighestRank(jobName)
    local highestRank = 0
    local job = sharedJobs[jobName]
    if not job then return nil end
    local jobGrades = job.grades
    for i = 1, #jobGrades do
        if jobGrades[i].isboss then
            highestRank = i
            break
        end
    end
    return highestRank
end

-- Events

RegisterServerEvent('qb-cityhall:server:ApplyJob', function(source, job)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local ped = GetPlayerPawn(source)
    if not ped then return end
    local pedCoords = GetEntityCoords(ped)
    local coords = Config.Cityhalls[1].coords
    if GetDistanceBetweenCoords(pedCoords, coords) > 1500 then return end

    local JobInfo = sharedJobs[job]
    Player.SetJob(job, getHighestRank(job))
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.new_job', { job = JobInfo.label }))
end)

RegisterServerEvent('qb-cityhall:server:requestId', function(source, item)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local ped = GetPlayerPawn(source)
    if not ped then return end
    local pedCoords = GetEntityCoords(ped)
    local coords = Config.Cityhalls[1].coords
    if GetDistanceBetweenCoords(pedCoords, coords) > 1500 then return end

    local itemInfo = Config.Cityhalls[1].licenses[item]
    if not Player.RemoveMoney('cash', itemInfo.cost) then
        return TriggerClientEvent(source, 'QBCore:Notify', ('You don\'t have enough money on you, you need %s cash'):format(itemInfo.cost), 'error')
    end

    local info = {}
    if item == 'id_card' then
        info.citizenid = Player.PlayerData.citizenid
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.birthdate = Player.PlayerData.charinfo.birthdate
        info.gender = Player.PlayerData.charinfo.gender
        info.nationality = Player.PlayerData.charinfo.nationality
    elseif item == 'driver_license' then
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.birthdate = Player.PlayerData.charinfo.birthdate
        info.type = 'Class C Driver License'
    elseif item == 'weaponlicense' then
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.birthdate = Player.PlayerData.charinfo.birthdate
    end

    if not exports['qb-inventory']:AddItem(source, item, 1, false, info, 'qb-cityhall:server:requestId') then return end
end)

-- Callbacks

RegisterCallback('getIdentityData', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return {} end

    local licensesMeta = Player.PlayerData.metadata['licences']
    local availableLicenses = {}

    for license, data in pairs(Config.Cityhalls[1].licenses) do
        if not data.metadata or licensesMeta[data.metadata] then
            availableLicenses[license] = data
        end
    end

    return availableLicenses
end)
