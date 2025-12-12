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
sky:SetTimeOfDay(Config.StartingTime)
sky:ChangeWeather(Config.StartingWeather)
sky:SetAnimateTimeOfDay(Config.AnimateTime)

RegisterServerEvent('qb-weathersync:server:changeTime', function(_, hour)
    BroadcastEvent('qb-weathersync:client:changeTime', hour)
end)

RegisterServerEvent('qb-weathersync:server:changeWeather', function(_, weatherType)
    BroadcastEvent('qb-weathersync:client:changeWeather', weatherType)
end)

RegisterServerEvent('qb-weathersync:server:enableAurora', function(_, enable)
    BroadcastEvent('qb-weathersync:client:enableAurora', enable)
end)
