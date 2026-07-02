local Lang = require('locales/en')
-- global: job.lua (fingerprint UI) and evidence.lua (shutdown) use this too
PoliceJobUI = WebUI('qb-policejob', 'qb-policejob/html/index.html')
local currentCameraIndex = 0
local currentCameraActor = nil
local cameraTimeTimer = nil

local function getCamera(cameraId)
    cameraId = tonumber(cameraId) or 0
    if cameraId == 0 then
        return nil, cameraId
    end
    return Config.SecurityCameras.cameras[cameraId], cameraId
end

local function stopCameraTime()
    if cameraTimeTimer then
        Timer.ClearInterval(cameraTimeTimer)
        cameraTimeTimer = nil
    end
end

local function sendCameraUI(eventName, payload, focus)
    if not PoliceJobUI then
        print(('[qb-policejob] Camera UI event %s skipped because PoliceJobUI is not ready'):format(eventName))
        return
    end

    if focus then
        PoliceJobUI:BringToFront()
        PoliceJobUI:SetInputMode(0)
    end
    PoliceJobUI:SendEvent(eventName, payload)
end

local function destroyCameraActor()
    if currentCameraActor then
        DestroyActor(currentCameraActor.Object)
        currentCameraActor = nil
    end
end

local function restorePlayerView()
    local controller = HPlayer
    if not controller then
        return
    end

    local pawn = GetPlayerPawn()
    if pawn then
        controller:SetViewTargetWithBlend(pawn, 0.0, 0, 0.0, false)
    end
end

local function closeCamera()
    restorePlayerView()
    destroyCameraActor()
    stopCameraTime()
    currentCameraIndex = 0
    sendCameraUI('disablecam', nil, true)
end

local function getCameraTime()
    return os.date('%S')
end

local function startCameraTime()
    stopCameraTime()
    cameraTimeTimer = Timer.SetInterval(function()
        if currentCameraIndex ~= 0 then
            sendCameraUI('updatecamtime', {
                time = getCameraTime(),
            })
        end
    end, 1000)
end

local function openCameraUI(cameraId, camera, connected)
    sendCameraUI('enablecam', {
        id = cameraId,
        label = camera.label or ('Camera ' .. cameraId),
        connected = connected,
        time = getCameraTime(),
    }, true)
end

local function openCameraMenu()
    local cameraMenu = {
        {
            header = Lang.t('menu.security_cameras'),
            isMenuHeader = true,
        },
    }

    for cameraId, camera in ipairs(Config.SecurityCameras.cameras or {}) do
        local isOnline = camera.isOnline ~= false
        cameraMenu[#cameraMenu + 1] = {
            header = camera.label or ('Camera ' .. cameraId),
            txt = isOnline and 'Online' or 'Offline',
            params = {
                event = 'qb-policejob:client:ActiveCamera',
                args = cameraId,
            },
        }
    end

    if currentCameraIndex ~= 0 then
        cameraMenu[#cameraMenu + 1] = {
            header = Lang.t('info.close_camera'),
            txt = '',
            params = {
                event = 'qb-policejob:client:CloseCamera',
            },
        }
    end

    cameraMenu[#cameraMenu + 1] = {
        header = Lang.t('menu.close'),
        txt = '',
        params = {
            event = 'qb-menu:client:closeMenu',
        },
    }

    exports['qb-menu']:openMenu(cameraMenu)
end

local function spawnCamera(camera)
    local controller = HPlayer
    if not controller then
        return nil
    end

    local camLocation = camera.coords
    local camRotation = camera.rotation or Rotator(0, 0, 0)
    local cctvCam = SpawnActor(UE.ACameraActor, camLocation, camRotation)
    if not cctvCam then
        return nil
    end

    controller:SetViewTargetWithBlend(cctvCam, 0.0, 0, 0.0, false)
    return cctvCam
end

RegisterClientEvent('qb-policejob:client:ActiveCamera', function(cameraId)
    local camera, requestedCameraIndex = getCamera(cameraId)
    if requestedCameraIndex == 0 then
        closeCamera()
        return
    end

    if not camera then
        exports['qb-core']:Notify(Lang.t('error.no_camera'), 'error')
        return
    end

    closeCamera()
    currentCameraIndex = requestedCameraIndex

    if camera.isOnline == false then
        openCameraUI(requestedCameraIndex, camera, false)
        return
    end

    currentCameraActor = spawnCamera(camera)
    if not currentCameraActor then
        exports['qb-core']:Notify(Lang.t('error.no_camera'), 'error')
        currentCameraIndex = 0
        openCameraUI(requestedCameraIndex, camera, false)
        return
    end

    openCameraUI(requestedCameraIndex, camera, true)
    startCameraTime()
end)

RegisterClientEvent('qb-policejob:client:CameraMenu', function()
    if not Config.SecurityCameras.cameras or #Config.SecurityCameras.cameras == 0 then
        exports['qb-core']:Notify(Lang.t('error.no_camera'), 'error')
        return
    end

    openCameraMenu()
end)

RegisterClientEvent('qb-policejob:client:CloseCamera', function()
    closeCamera()
end)

RegisterClientEvent('qb-policejob:client:DisableAllCameras', function()
    for k in pairs(Config.SecurityCameras.cameras) do
        Config.SecurityCameras.cameras[k].isOnline = false
    end
    closeCamera()
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

    if not isOnline then
        if type(key) == 'table' then
            for _, cameraId in pairs(key) do
                if currentCameraIndex == cameraId then
                    closeCamera()
                    return
                end
            end
        elseif currentCameraIndex == key then
            closeCamera()
        end
    end
end)

PoliceUnloadHandlers[#PoliceUnloadHandlers + 1] = function()
    closeCamera()
end

Input.BindKey('Backspace', function()
    if currentCameraIndex ~= 0 then
        closeCamera()
    end
end, 'Released')
