local Lang = require('locales/en')
local my_webui = WebUI('qb-multicharacter', 'qb-multicharacter/html/index.html')

-- Cosmetics state
local pendingGender = nil -- 0 = male, 1 = female
local pendingIsNew  = false

local function applyInitialCosmetics()
    if pendingGender == nil then return end
    local pawn = GetPlayerPawn()
    if not pawn then return end

    local gender = pendingGender == 1
        and UE.EHCharacterCosmeticsGender.Female
        or UE.EHCharacterCosmeticsGender.Male
    local isNew = pendingIsNew
    pendingGender = nil
    pendingIsNew  = false

    local checkId
    checkId = Timer.SetInterval(function()
        if not pawn:IsInitialCosmeticsLoadDone() then return end
        Timer.ClearInterval(checkId)
        local System = pawn:GetCosmeticsSystem()
        if not System then return end
        if isNew then
            System:ResetCosmeticsToDefaults(gender, UE.EHCosmeticBodyType.Average)
        else
            System:SetCosmeticGender(gender)
        end
    end, 500)
end

-- UI

my_webui:RegisterEventHandler('selectCharacter', function(data)
    local cData = data.cData
    pendingGender = cData.charinfo and cData.charinfo.gender or 0
    pendingIsNew  = false
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
    if cData.gender == Lang.t('ui.male') then
        cData.gender = 0
    elseif cData.gender == Lang.t('ui.female') then
        cData.gender = 1
    end
    pendingGender = cData.gender or 0
    pendingIsNew  = true
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
        local translations = {}
        for k in pairs(Lang.fallback and Lang.fallback.phrases or Lang.phrases) do
            if k:sub(0, ('ui.'):len()) then
                translations[k:sub(('ui.'):len() + 1)] = Lang.t(k)
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
            })
        end
    end)
end

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    applyInitialCosmetics()
end)

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
    openCharMenu()
end)

RegisterClientEvent('qb-multicharacter:client:closeNUIdefault', function()
    if my_webui then
        my_webui:SetInputMode(0)
        my_webui:SetStackOrder(0)
    end
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
end)

-- Hot Reload Support
local CurrentInputMode = HPlayer:GetInputMode()
if CurrentInputMode == 2 then
    -- Check for when UI is closed
    local InputCheck
    InputCheck = Timer.SetInterval(function()
        if HPlayer:GetInputMode() ~= 2 then
            TriggerServerEvent('qb-multicharacter:server:chooseChar')
            Timer.ClearInterval(InputCheck)
        end
    end, 1000)
else
    -- No UI open
    TriggerServerEvent('qb-multicharacter:server:chooseChar')
end
