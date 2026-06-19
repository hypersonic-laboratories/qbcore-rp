local Lang = require('locales/en')

local currentCameraIndex = 0

-- TODO(helix): Security cameras need a Helix camera/spectator API.

RegisterClientEvent('qb-policejob:client:ActiveCamera', function(cameraId)
    currentCameraIndex = tonumber(cameraId) or 0
    if currentCameraIndex == 0 then
        return
    end

    if not Config.SecurityCameras.cameras[currentCameraIndex] then
        exports['qb-core']:Notify(Lang.t('error.no_camera'), 'error')
        return
    end

    exports['qb-core']:Notify('TODO: Security cameras are not implemented in Helix yet.', 'primary')
end)

RegisterClientEvent('qb-policejob:client:DisableAllCameras', function()
    for k in pairs(Config.SecurityCameras.cameras) do
        Config.SecurityCameras.cameras[k].isOnline = false
    end
end)

RegisterClientEvent('qb-policejob:client:EnableAllCameras', function()
    for k in pairs(Config.SecurityCameras.cameras) do
        Config.SecurityCameras.cameras[k].isOnline = true
    end
end)

RegisterClientEvent('qb-policejob:client:SetCamera', function(key, isOnline)
    if type(key) == 'table' then
        for _, cameraId in pairs(key) do
            if Config.SecurityCameras.cameras[cameraId] then
                Config.SecurityCameras.cameras[cameraId].isOnline = isOnline
            end
        end
    elseif type(key) == 'number' and Config.SecurityCameras.cameras[key] then
        Config.SecurityCameras.cameras[key].isOnline = isOnline
    end
end)
