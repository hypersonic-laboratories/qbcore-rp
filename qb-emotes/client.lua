local activeEmote = nil -- '<category>:<id>' for solo emotes, 'paired:<id>' for paired emotes

local function notify(text, notifyType)
    exports['qb-core']:Notify(text, notifyType)
end

local function getClosestPlayerId(maxDistance)
    local pawn = GetPlayerPawn()
    if not pawn then
        return nil
    end

    local closestPawn = GetClosestPawn(GetEntityCoords(pawn), maxDistance or 250.0, pawn)
    if closestPawn and closestPawn.PlayerState then
        return closestPawn.PlayerState:GetPlayerId()
    end

    return nil
end

local function findCategory(name)
    for i = 1, #Config.Categories do
        if Config.Categories[i].name == name then
            return Config.Categories[i]
        end
    end
    return nil
end

-- Menus

local function openMainMenu()
    local menu = {
        {
            header = 'Emotes',
            icon = 'drama',
            isMenuHeader = true,
        },
    }

    if activeEmote then
        menu[#menu + 1] = {
            header = 'Stop Emote',
            txt = 'Stop the emote you are currently playing',
            icon = 'square',
            params = { event = 'qb-emotes:client:stopEmote' },
        }
    end

    for i = 1, #Config.Categories do
        local category = Config.Categories[i]
        menu[#menu + 1] = {
            header = category.label,
            txt = #category.emotes .. ' emotes',
            icon = category.icon,
            params = {
                event = 'qb-emotes:client:openCategory',
                args = { category = category.name },
            },
        }
    end

    menu[#menu + 1] = {
        header = 'Paired Emotes',
        txt = 'Emotes played together with the nearest player',
        icon = 'users',
        params = { event = 'qb-emotes:client:openPaired' },
    }

    menu[#menu + 1] = {
        header = 'Close Menu',
        icon = 'x',
        params = { event = 'qb-menu:client:closeMenu' },
    }

    exports['qb-menu']:openMenu(menu)
end

local function openCategoryMenu(categoryName)
    local category = findCategory(categoryName)
    if not category then
        return
    end

    local menu = {
        {
            header = category.label,
            icon = category.icon,
            isMenuHeader = true,
        },
        {
            header = '← Go Back',
            params = { event = 'qb-emotes:client:openMain' },
        },
    }

    for i = 1, #category.emotes do
        local emote = category.emotes[i]
        local isPlaying = activeEmote == (category.name .. ':' .. emote.id)
        menu[#menu + 1] = {
            header = emote.label,
            txt = isPlaying and 'Playing — click to stop' or (emote.upperBody and 'Upper body — you can walk around' or ''),
            icon = isPlaying and 'square' or 'play',
            params = {
                event = 'qb-emotes:client:selectEmote',
                args = { category = category.name, id = emote.id },
            },
        }
    end

    exports['qb-menu']:openMenu(menu)
end

local function openPairedMenu()
    local menu = {
        {
            header = 'Paired Emotes',
            txt = 'Sends a request to the nearest player',
            icon = 'users',
            isMenuHeader = true,
        },
        {
            header = '← Go Back',
            params = { event = 'qb-emotes:client:openMain' },
        },
    }

    for i = 1, #Config.PairedEmotes do
        local emote = Config.PairedEmotes[i]
        local isPlaying = activeEmote == ('paired:' .. emote.id)
        menu[#menu + 1] = {
            header = emote.label,
            txt = isPlaying and 'Playing — click to stop' or 'Request to play with the nearest player',
            icon = isPlaying and 'square' or emote.icon,
            params = {
                event = 'qb-emotes:client:selectPaired',
                args = { id = emote.id },
            },
        }
    end

    exports['qb-menu']:openMenu(menu)
end

-- Events

RegisterClientEvent('qb-emotes:client:openMain', function()
    openMainMenu()
end)

RegisterClientEvent('qb-emotes:client:openCategory', function(data)
    openCategoryMenu(data.category)
end)

RegisterClientEvent('qb-emotes:client:openPaired', function()
    openPairedMenu()
end)

RegisterClientEvent('qb-emotes:client:stopEmote', function()
    activeEmote = nil
    TriggerServerEvent('qb-emotes:server:stop')
end)

RegisterClientEvent('qb-emotes:client:selectEmote', function(data)
    local key = data.category .. ':' .. data.id
    if activeEmote == key then
        activeEmote = nil
        TriggerServerEvent('qb-emotes:server:stop')
        return
    end
    activeEmote = key
    TriggerServerEvent('qb-emotes:server:play', data.category, data.id)
end)

RegisterClientEvent('qb-emotes:client:selectPaired', function(data)
    if activeEmote == ('paired:' .. data.id) then
        activeEmote = nil
        TriggerServerEvent('qb-emotes:server:stop')
        return
    end

    local targetId = getClosestPlayerId(Config.PairedRequestDistance)
    if not targetId then
        notify('Nobody nearby to emote with', 'error')
        return
    end
    TriggerServerEvent('qb-emotes:server:pairedRequest', targetId, data.id)
end)

RegisterClientEvent('qb-emotes:client:respondPaired', function(data)
    TriggerServerEvent('qb-emotes:server:pairedResponse', data.requester, data.emote, data.accept == true)
end)

-- Server tells us someone nearby wants to play a paired emote with us
RegisterClientEvent('qb-emotes:client:pairedRequest', function(requesterId, requesterName, emoteId, emoteLabel)
    local menu = {
        {
            header = 'Paired Emote Request',
            txt = requesterName .. ' wants to play "' .. emoteLabel .. '" with you',
            icon = 'users',
            isMenuHeader = true,
        },
        {
            header = 'Accept',
            icon = 'check',
            params = {
                event = 'qb-emotes:client:respondPaired',
                args = { requester = requesterId, emote = emoteId, accept = true },
            },
        },
        {
            header = 'Decline',
            icon = 'x',
            params = {
                event = 'qb-emotes:client:respondPaired',
                args = { requester = requesterId, emote = emoteId, accept = false },
            },
        },
    }
    exports['qb-menu']:openMenu(menu)
end)

RegisterClientEvent('qb-emotes:client:pairedStarted', function(emoteId)
    activeEmote = 'paired:' .. emoteId
end)

-- Sent by the server when a paired emote ends (partner stopped, one-shot
-- finished, etc). Solo emotes are cleared locally, so only paired state is
-- reset here.
RegisterClientEvent('qb-emotes:client:emoteCleared', function()
    if activeEmote and activeEmote:sub(1, 7) == 'paired:' then
        activeEmote = nil
    end
end)

Input.BindKey(Config.OpenKey, function()
    openMainMenu()
end)
