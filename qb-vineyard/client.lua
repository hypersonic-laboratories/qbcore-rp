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

local function AddActiveGrapeZone()
    RemoveActiveGrapeZone()
    local loc = Config.grapeLocations[random]
    exports['qb-target']:AddBoxZone('vineyard_grape_active', loc, 4.0, 4.0, {
        name = 'vineyard_grape_active',
        heading = 0,
        debugPoly = false,
        minZ = loc.Z - 1.0,
        maxZ = loc.Z + 1.0,
    }, {
        options = {
            {
                label = Lang.t('task.pick_grapes'),
                icon = 'fa-solid fa-hand',
                action = function()
                    pickProcess()
                end,
            },
        },
        distance = 2.0,
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

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshJob()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'job' then
        PlayerJob = val
    elseif key == 'all' then
        PlayerJob = val.job
    end
end)

-- Zone: Start shift

exports['qb-target']:AddBoxZone('vineyard_start_zone', Config.Vineyard.start.coords, 6.0, 5.0, {
    name = 'vineyard_start_zone',
    heading = 0,
    debugPoly = false,
    minZ = Config.Vineyard.start.coords.Z - 1.0,
    maxZ = Config.Vineyard.start.coords.Z + 1.0,
}, {
    options = {
        {
            label = Lang.t('task.start_shift'),
            icon = 'fa-solid fa-play',
            action = function()
                if not PlayerJob or PlayerJob.name ~= 'vineyard' then
                    Notify(Lang.t('error.invalid_job'), 'error')
                    return
                end
                if startVineyard then
                    return
                end
                startVinyard()
            end,
        },
    },
    distance = 2.5,
})

-- Zone: Wine making (3 sequential options, each checks its own preconditions)

exports['qb-target']:AddBoxZone('vineyard_wine_zone', Config.Vineyard.wine.coords, 10.0, 6.0, {
    name = 'vineyard_wine_zone',
    heading = 0,
    debugPoly = false,
    minZ = Config.Vineyard.wine.coords.Z - 1.0,
    maxZ = Config.Vineyard.wine.coords.Z + 1.0,
}, {
    options = {
        {
            label = Lang.t('task.load_ingrediants'),
            icon = 'fa-solid fa-wine-bottle',
            action = function()
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
            end,
        },
        {
            label = Lang.t('task.wine_process'),
            icon = 'fa-solid fa-flask',
            action = function()
                if not PlayerJob or PlayerJob.name ~= 'vineyard' then
                    return
                end
                if startVineyard or not loadIngredients or wineStarted or finishedWine then
                    return
                end
                StartWineProcess()
            end,
        },
        {
            label = Lang.t('task.get_wine'),
            icon = 'fa-solid fa-bottle-droplet',
            action = function()
                if not PlayerJob or PlayerJob.name ~= 'vineyard' then
                    return
                end
                if startVineyard or not finishedWine then
                    return
                end
                TriggerServerEvent('qb-vineyard:server:receiveWine')
                finishedWine = false
                loadIngredients = false
            end,
        },
    },
    distance = 2.5,
})

-- Zone: Grape juice processing

exports['qb-target']:AddBoxZone('vineyard_grapejuice_zone', Config.Vineyard.grapejuice.coords, 7.0, 8.0, {
    name = 'vineyard_grapejuice_zone',
    heading = 0,
    debugPoly = false,
    minZ = Config.Vineyard.grapejuice.coords.Z - 1.0,
    maxZ = Config.Vineyard.grapejuice.coords.Z + 1.0,
}, {
    options = {
        {
            label = Lang.t('task.make_grape_juice'),
            icon = 'fa-solid fa-blender',
            action = function()
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
            end,
        },
    },
    distance = 2.5,
})

function onShutdown()
    DeleteMarker()
    RemoveActiveGrapeZone()
    if wineIntervalId then
        Timer.ClearInterval(wineIntervalId)
        wineIntervalId = nil
    end
end
