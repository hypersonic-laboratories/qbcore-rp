local Lang = require('locales/en')
local Houses = {}
local my_webui = WebUI('qb-spawn', 'qb-spawn/html/index.html')

-- Functions

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

local function SetDisplay(bool, cData, new, apps)
    local translations = {}
    for k in pairs(Lang.fallback and Lang.fallback.phrases or Lang.phrases) do
        if k:sub(0, #'ui.') then
            translations[k:sub(#'ui.' + 1)] = Lang.t(k)
        end
    end

    if not bool then
        my_webui:SetStackOrder(0)
        my_webui:SetInputMode(0)
        return
    end

    my_webui:SendEvent('showUi', bool, translations)
    if not new then
        --TriggerCallback('qb-houses:server:getOwnedHouses', function(houses)
        local myHouses = {}
        -- if houses then
        -- 	for i = 1, #houses do
        -- 		myHouses[#myHouses + 1] = {
        -- 			house = houses[i].house,
        -- 			label = houses[i].address,
        -- 		}
        -- 	end
        -- end
        my_webui:SendEvent('setupLocations', Config.Spawns, myHouses, new)
        --end, cData.citizenid)
    elseif new then
        my_webui:SendEvent('setupApartments', apps, new)
    end
    my_webui:SetStackOrder(1)
    my_webui:SetInputMode(1)
end

-- UI

my_webui:RegisterEventHandler('qb-spawn:setCam', function(data)
    -- local location = tostring(data.posname)
    -- local type = tostring(data.type)
    -- if type == 'current' then

    -- elseif type == 'house' then
    --     SetCam(Houses[location].coords.enter)
    -- elseif type == 'normal' then
    --     SetCam(Config.Spawns[location].coords)
    -- elseif type == 'appartment' then
    --     SetCam(Apartments.Locations[location].coords.enter)
    -- end
end)

my_webui:RegisterEventHandler('qb-spawn:chooseAppa', function(data)
    local appaYeet = data.appType
    SetDisplay(false)
    TriggerServerEvent('qb-apartments:server:CreateApartment', appaYeet)
end)

my_webui:RegisterEventHandler('qb-spawn:spawnplayer', function(data)
    local location = tostring(data.spawnloc)
    local type = tostring(data.typeLoc)
    local player_data = exports['qb-core']:GetPlayerData()
    local insideMeta = player_data.metadata['inside']
    if type == 'current' then
        if insideMeta.house ~= nil then
            local houseId = insideMeta.house
            TriggerLocalClientEvent('qb-houses:client:LastLocationHouse', houseId)
        elseif insideMeta.apartment.apartmentType ~= nil or insideMeta.apartment.apartmentId ~= nil then
            local apartmentType = insideMeta.apartment.apartmentType
            local apartmentId = insideMeta.apartment.apartmentId
            TriggerLocalClientEvent('qb-apartments:client:LastLocationHouse', apartmentType, apartmentId)
        end
        TriggerServerEvent('qb-spawn:server:spawnPlayer')
        SetDisplay(false)
    elseif type == 'house' then
        TriggerLocalClientEvent('qb-houses:client:enterOwnedHouse', location)
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        SetDisplay(false)
    elseif type == 'normal' then
        local pos = Config.Spawns[location].coords
        local coords = Vector(pos[1], pos[2], pos[3])
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        TriggerServerEvent('qb-spawn:server:spawnPlayer', coords)
        SetDisplay(false)
    end
end)

-- Events

RegisterClientEvent('qb-houses:client:setHouseConfig', function(houseConfig)
    Houses = houseConfig
end)

RegisterClientEvent('qb-spawn:client:openUI', function(value, cData, new, apps)
    SetDisplay(value, cData, new, apps)
end)
