local sky
local my_webui = WebUI('qb-weathersync', 'qb-weathersync/html/index.html')

-- Spawn Sky

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerCallback('syncRequest', function(skyInfo)
        sky = Sky()
        sky:SetTimeOfDay(skyInfo.time)
        sky:SetAnimateTimeOfDay(Config.AnimateTime)
        sky:ChangeWeather(Config.WeatherTypes[skyInfo.weather])
    end)
end)

-- Functions

local function RemoveAll(class)
    local actors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(HWorld, class, actors)
    for _, actor in pairs(actors) do
        actor:K2_DestroyActor()
    end
end

RemoveAll(UE.ADirectionalLight)     -- Sun light
RemoveAll(UE.ASkyLight)             -- Skylight
RemoveAll(UE.ASkyAtmosphere)        -- Atmosphere
RemoveAll(UE.AExponentialHeightFog) -- Fog
RemoveAll(UE.AVolumetricCloud)      -- Clouds

-- Events

RegisterClientEvent('qb-weathersync:client:changeTime', function(hour)
    if not sky then return end
    sky:SetTimeOfDay(hour)
end)

RegisterClientEvent('qb-weathersync:client:changeWeather', function(weatherType)
    if not sky then return end
    local enumWeather = Config.WeatherTypes[weatherType] or WeatherType.ClearSkies
    sky:ChangeWeather(enumWeather, Config.TransitionDelay)
end)

-- NUI Callbacks

my_webui:RegisterEventHandler('setTime', function(data)
    local hour = tonumber(data.hour)
    TriggerServerEvent('qb-weathersync:server:changeTime', hour)
end)

my_webui:RegisterEventHandler('setWeather', function(data)
    local weatherType = data.weather
    TriggerServerEvent('qb-weathersync:server:changeWeather', weatherType)
end)

-- Inputs

local ui_open = false
Input.BindKey(Config.Key, function()
    if not ui_open then
        ui_open = true
        my_webui:BringToFront()
        my_webui:SetInputMode(1)
        my_webui:SendEvent('toggle')
    else
        ui_open = false
        my_webui:SetInputMode(0)
        my_webui:SendEvent('toggle')
    end
end, 'Released')
