local Lang = require('locales/en')
local my_webui = WebUI('qb-multicharacter', 'qb-multicharacter/html/index.html')

-- UI

my_webui:RegisterEventHandler('selectCharacter', function(data)
    local cData = data.cData
    TriggerServerEvent('qb-multicharacter:server:loadUserData', cData)
    my_webui:SendEvent('ui', Config.customNationality, false, 0, false, translations)
end)

my_webui:RegisterEventHandler('setupCharacters', function()
    TriggerCallback('setupCharacters', function(characters)
        my_webui:SendEvent('setupCharacters', characters)
    end)
end)

my_webui:RegisterEventHandler('createNewCharacter', function(data)
    local cData = data
    if cData.gender == Lang:t('ui.male') then
        cData.gender = 0
    elseif cData.gender == Lang:t('ui.female') then
        cData.gender = 1
    end
    TriggerServerEvent('qb-multicharacter:server:createCharacter', cData)
end)

my_webui:RegisterEventHandler('removeCharacter', function(data)
    TriggerServerEvent('qb-multicharacter:server:deleteCharacter', data.citizenid)
end)

-- Functions

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

local function openCharMenu()
    TriggerCallback('GetNumberOfCharacters', function(data)
        local charCount = data.charCount
        local countries = data.countries
        local translations = {}
        for k in pairs(Lang.fallback and Lang.fallback.phrases or Lang.phrases) do
            if k:sub(0, ('ui.'):len()) then
                translations[k:sub(('ui.'):len() + 1)] = Lang:t(k)
            end
        end
        if my_webui then
            my_webui:SetInputMode(1)
            my_webui:SetStackOrder(1)
            my_webui:SendEvent('ui', {
                customNationality = Config.customNationality,
                toggle = true,
                nChar = charCount,
                enableDeleteButton = Config.EnableDeleteButton,
                translations = translations,
                countries = countries,
            })
        end
    end)
end

-- Events

RegisterClientEvent('HEvent:PlayerReady', function()
    TriggerServerEvent('qb-multicharacter:server:chooseChar')
end)

RegisterClientEvent('qb-multicharacter:client:closeNUI', function()
    if my_webui then
        my_webui:SetInputMode(0)
        my_webui:SetStackOrder(0)
    end
end)

RegisterClientEvent('qb-multicharacter:client:chooseChar', function()
    openCharMenu(true)
end)

RegisterClientEvent('qb-multicharacter:client:closeNUIdefault', function()
    if my_webui then
        my_webui:SetInputMode(0)
        my_webui:SetStackOrder(0)
    end
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
end)
