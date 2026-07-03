local Lang = require('locales/en')

-- State
local PlayerJob = {}
local tasking = false
local startVineyard = false
local shiftAmount = 0
local pickedGrapes = 0
local blipId = nil
local winetimer = Config.wineTimer
local loadIngredients = false
local wineStarted = false
local finishedWine = false
local wineIntervalId = nil
local random = 0

-- Helpers

local function Notify(text, ntype)
    exports['qb-core']:Notify(text, ntype or 'primary')
end

-- Marker

local function CreateMarker()
    if random == 0 then
        return
    end
    blipId = exports['qb-hud']:AddMarker(Config.grapeLocations[random], {
        title = Lang.t('text.pick_grapes'),
        markerType = 'Job',
    })
end

local function DeleteMarker()
    if blipId then
        exports['qb-hud']:RemoveMarker(blipId)
        blipId = nil
    end
end

-- Grape picking

local function RemoveActiveGrapeZone()
    exports['qb-target']:RemoveZone('vineyard_grape_active')
end

local function onTaskComplete()
    tasking = false
    RemoveActiveGrapeZone()
    DeleteMarker()
    TriggerServerEvent('qb-vineyard:server:getGrapes')

    pickedGrapes = pickedGrapes + 1
    if pickedGrapes >= shiftAmount then
        Timer.SetTimeout(function()
            startVineyard = false
            pickedGrapes = 0
            Notify(Lang.t('text.end_shift'), 'success')
        end, 20000)
    else
        Timer.SetTimeout(function()
            if startVineyard then
                nextTask()
            end
        end, 5000)
    end
end

local function pickProcess()
    onTaskComplete()
end

RegisterClientEvent('qb-vineyard:client:pickGrapes', function()
    if not startVineyard or not tasking then
        return
    end
    pickProcess()
end)

local function AddActiveGrapeZone()
    RemoveActiveGrapeZone()
    exports['qb-target']:AddSphereZone('vineyard_grape_active', Config.grapeLocations[random], 0, {
        distance = 400,
        useMesh = true,
    }, {
        {
            icon = 'hand',
            label = Lang.t('task.pick_grapes'),
            type = 'client',
            event = 'qb-vineyard:client:pickGrapes',
            job = 'vineyard',
        },
    })
end

function nextTask()
    if tasking then
        return
    end
    random = math.random(#Config.grapeLocations)
    tasking = true
    CreateMarker()
    AddActiveGrapeZone()
end

-- Shift

local function startVinyard()
    if startVineyard then
        return
    end
    shiftAmount = math.random(Config.PickAmount.min, Config.PickAmount.max)
    startVineyard = true
    pickedGrapes = 0
    Notify(Lang.t('text.start_shift'), 'success')
    nextTask()
end

-- Wine process

local function StartWineProcess()
    if wineStarted then
        return
    end
    wineStarted = true
    winetimer = Config.wineTimer
    wineIntervalId = Timer.SetInterval(function()
        winetimer = winetimer - 1
        if winetimer <= 0 then
            Timer.ClearInterval(wineIntervalId)
            wineIntervalId = nil
            wineStarted = false
            finishedWine = true
            Notify(Lang.t('task.get_wine') .. '!', 'success')
        end
    end, 1000)
end

-- Grape juice

local function grapeJuiceProcess()
    TriggerServerEvent('qb-vineyard:server:receiveGrapeJuice')
end

-- Player data

local function refreshJob()
    TriggerCallback('qb-vineyard:server:getPlayerJob', function(job)
        if job then
            PlayerJob = job
        end
    end)
end

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'job' then
        PlayerJob = val
    elseif key == 'all' then
        PlayerJob = val.job
    end
end)

-- Ped: Start shift

local vineyardPeds = {}
local pedsRegistered = false

RegisterClientEvent('qb-vineyard:client:startShift', function()
    if not PlayerJob or PlayerJob.name ~= 'vineyard' then
        Notify(Lang.t('error.invalid_job'), 'error')
        return
    end
    if startVineyard then
        return
    end
    startVinyard()
end)

local function SetupPeds()
    if pedsRegistered then
        return
    end
    pedsRegistered = true
    TriggerCallback('getPeds', function(jobPeds)
        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc
            vineyardPeds[#vineyardPeds + 1] = ped
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        type = 'client',
                        event = 'qb-vineyard:client:startShift',
                        icon = 'play',
                        label = Lang.t('task.start_shift'),
                    },
                },
                distance = Config.Vineyard.start.distance or 500,
            })
        end
    end)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshJob()
    SetupPeds()
end)

-- Zone: Wine making (3 sequential options, each checks its own preconditions)

RegisterClientEvent('qb-vineyard:client:loadIngredients', function()
    if not PlayerJob or PlayerJob.name ~= 'vineyard' then
        return
    end
    if startVineyard or loadIngredients or wineStarted then
        return
    end
    TriggerCallback('qb-vineyard:server:loadIngredients', function(result)
        if result then
            loadIngredients = true
        end
    end)
end)

RegisterClientEvent('qb-vineyard:client:wineProcess', function()
    if not PlayerJob or PlayerJob.name ~= 'vineyard' then
        return
    end
    if startVineyard or not loadIngredients or wineStarted or finishedWine then
        return
    end
    StartWineProcess()
end)

RegisterClientEvent('qb-vineyard:client:getWine', function()
    if not PlayerJob or PlayerJob.name ~= 'vineyard' then
        return
    end
    if startVineyard or not finishedWine then
        return
    end
    TriggerServerEvent('qb-vineyard:server:receiveWine')
    finishedWine = false
    loadIngredients = false
end)

exports['qb-target']:AddSphereZone('vineyard_wine_zone', Config.Vineyard.wine.coords, 0, {
    distance = 400,
    useMesh = true,
}, {
    {
        icon = 'wine-bottle',
        label = Lang.t('task.load_ingrediants'),
        type = 'client',
        event = 'qb-vineyard:client:loadIngredients',
        job = 'vineyard',
    },
    {
        icon = 'flask',
        label = Lang.t('task.wine_process'),
        type = 'client',
        event = 'qb-vineyard:client:wineProcess',
        job = 'vineyard',
    },
    {
        icon = 'bottle-droplet',
        label = Lang.t('task.get_wine'),
        type = 'client',
        event = 'qb-vineyard:client:getWine',
        job = 'vineyard',
    },
})

-- Zone: Grape juice processing

RegisterClientEvent('qb-vineyard:client:makeGrapeJuice', function()
    if not PlayerJob or PlayerJob.name ~= 'vineyard' then
        return
    end
    if startVineyard then
        return
    end
    TriggerCallback('qb-vineyard:server:grapeJuice', function(result)
        if result then
            grapeJuiceProcess()
        end
    end)
end)

exports['qb-target']:AddSphereZone('vineyard_grapejuice_zone', Config.Vineyard.grapejuice.coords, 0, {
    distance = 400,
    useMesh = true,
}, {
    {
        icon = 'blender',
        label = Lang.t('task.make_grape_juice'),
        type = 'client',
        event = 'qb-vineyard:client:makeGrapeJuice',
        job = 'vineyard',
    },
})

function onShutdown()
    DeleteMarker()
    RemoveActiveGrapeZone()
    for _, ped in ipairs(vineyardPeds) do
        exports['qb-target']:RemoveTargetEntity(ped)
    end
    vineyardPeds = {}
    if wineIntervalId then
        Timer.ClearInterval(wineIntervalId)
        wineIntervalId = nil
    end
end
