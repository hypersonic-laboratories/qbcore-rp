local enumTable = {
    ['WeatherType.ClearSkies'] = WeatherType.ClearSkies,
    ['WeatherType.Cloudy'] = WeatherType.Cloudy,
    ['WeatherType.Foggy'] = WeatherType.Foggy,
    ['WeatherType.Overcast'] = WeatherType.Overcast,
    ['WeatherType.PartlyCloudy'] = WeatherType.PartlyCloudy,
    ['WeatherType.Rain'] = WeatherType.Rain,
    ['WeatherType.RainLight'] = WeatherType.RainLight,
    ['WeatherType.RainThunderstorm'] = WeatherType.RainThunderstorm,
    ['WeatherType.SandDustCalm'] = WeatherType.SandDustCalm,
    ['WeatherType.SandDustStorm'] = WeatherType.SandDustStorm,
    ['WeatherType.Snow'] = WeatherType.Snow,
    ['WeatherType.SnowBlizzard'] = WeatherType.SnowBlizzard,
    ['WeatherType.SnowLight'] = WeatherType.SnowLight,
}

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

local sky = Sky()
sky.SkyActor:SetReplicates(true)
sky.WeatherActor:SetReplicates(true)
sky:SetTimeOfDay(1200)
sky:ChangeWeather(WeatherType.ClearSkies)
sky:SetAnimateTimeOfDay(true)

RegisterServerEvent('qb-weathersync:server:changeTime', function(source, hour)
    local sky = Sky()
    sky:SetTimeOfDay(hour)
end)

RegisterServerEvent('qb-weathersync:server:changeWeather', function(source, weatherType)
    local sky = Sky()
    local enumWeather = enumTable[weatherType] or WeatherType.ClearSkies
    sky:ChangeWeather(enumWeather, 5)
end)

RegisterServerEvent('qb-weathersync:server:enableAurora', function(source, enable)
    local sky = Sky()
    sky:EnableAurora(enable)
end)
