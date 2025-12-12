-- Events

RegisterServerEvent('qb-weathersync:server:changeTime', function(_, hour)
    BroadcastEvent('qb-weathersync:client:changeTime', hour)
end)

RegisterServerEvent('qb-weathersync:server:changeWeather', function(_, weatherType)
    BroadcastEvent('qb-weathersync:client:changeWeather', weatherType)
end)

RegisterServerEvent('qb-weathersync:server:enableAurora', function(_, enable)
    BroadcastEvent('qb-weathersync:client:enableAurora', enable)
end)
