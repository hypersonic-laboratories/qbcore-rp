local my_webui = WebUI('qb-weathersync', 'qb-weathersync/html/index.html')

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
    local sky = Sky()
    sky:SetTimeOfDay(hour)
end)

RegisterClientEvent('qb-weathersync:client:changeWeather', function(weatherType)
    local sky = Sky()
    local enumWeather = Config.weatherTypes[weatherType] or WeatherType.ClearSkies
    sky:ChangeWeather(enumWeather, 5)
end)

RegisterClientEvent('qb-weathersync:client:enableAurora', function(enable)
    local sky = Sky()
    sky:EnableAurora(enable)
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

my_webui:RegisterEventHandler('toggleAurora', function(data)
    local enable = data.enabled
    TriggerServerEvent('qb-weathersync:server:enableAurora', enable)
end)

-- Inputs

local ui_open = false
Input.BindKey('F7', function()
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
