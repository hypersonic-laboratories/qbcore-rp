local CurrentTime = Config.StartingTime
local CurrentWeather = Config.StartingWeather

-- Events

RegisterServerEvent('qb-weathersync:server:changeTime', function(_, hour)
    CurrentTime = hour
    BroadcastEvent('qb-weathersync:client:changeTime', hour)
end)

RegisterServerEvent('qb-weathersync:server:changeWeather', function(_, weatherType)
    CurrentWeather = weatherType
    BroadcastEvent('qb-weathersync:client:changeWeather', weatherType)
end)

-- Callbacks

RegisterCallback('syncRequest', function(source)
    return { time = CurrentTime, weather = CurrentWeather }
end)