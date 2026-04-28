---@diagnostic disable: undefined-global
local my_webui = WebUI('qb-phone', 'qb-phone/html/index.html')
local phoneOpen = false

-- ── Camera state ──────────────────────────────────────────────────────────────
local PHONE_ITEM = 'ID_Misc_Phone'
local HAND_SOCKET = 'hand_r'
local phoneEquipped = false
local cameraMode = nil -- nil | "front" | "back"
local sceneCap, camRoot, camFeed = nil, nil, nil
local camUpdateTimerId = nil
local localRotation = Rotator(0, 0, 0)
local sensitivity = 0.2

local offsets = {
    front = {
        location = Vector(-12, 4, 8),
        rotation = Rotator(0, 90, 0),
    },
    back = {
        location = Vector(-12, 0, 10),
        rotation = Rotator(0, -90, 0),
    },
}

local function getCharacter() return GetPlayerPawn() end

local function applyCameraTransform(mode)
    if not sceneCap or not sceneCap.Object then return end
    local cfg = offsets[mode]
    localRotation = Rotator(cfg.rotation.Pitch, cfg.rotation.Yaw, cfg.rotation.Roll)
    sceneCap.Object:K2_SetActorRelativeLocation(cfg.location, false, nil, false)
    sceneCap.Object:K2_SetActorRelativeRotation(localRotation, false, nil, false)
end

local function updateCameraRotation()
    if not sceneCap or not sceneCap.Object then return end
    local pc = UE.UGameplayStatics.GetPlayerController(sceneCap.Object, 0)
    local dx, dy = pc:GetInputMouseDelta()
    localRotation.Yaw = localRotation.Yaw + dx * sensitivity
    localRotation.Pitch = math.max(-45, math.min(45, localRotation.Pitch - dy * sensitivity))
    sceneCap.Object:K2_SetActorRelativeRotation(localRotation, false, nil, false)
end

local function buildCaptureAndUI(mode)
    local character = getCharacter()
    if not character then return end

    sceneCap = SceneCapture(
        Vector(0, 0, 0), Rotator(0, 0, 0),
        1280, 720,
        SceneCaptureSource.FinalColorLDR,
        false
    )

    local mesh = character:GetComponentByClass(UE.USkeletalMeshComponent.StaticClass())
    sceneCap.Object:K2_AttachToComponent(mesh, HAND_SOCKET, 0, 0, 0, true)
    applyCameraTransform(mode)

    camRoot = Widget(NativeWidget.CanvasPanel)
    camRoot:AddToViewport()
    camFeed = Widget(NativeWidget.Image)
    camRoot:AddChild(camFeed)
    camFeed:SetCanvasLayout(
        Vector2D(1920 - 400 - 50, 1080 - 225 - 50),
        Vector2D(400, 225)
    )
    camFeed.innerWidget:SetBrushResourceObject(sceneCap.RenderTarget)
end

local function destroyCaptureAndUI()
    if camUpdateTimerId then
        Timer.ClearInterval(camUpdateTimerId)
        camUpdateTimerId = nil
    end
    if camRoot then camRoot:RemoveFromParent() end
    if sceneCap and sceneCap.Object then sceneCap.Object:K2_DestroyActor() end
    sceneCap, camRoot, camFeed = nil, nil, nil
end

local function closeCamera()
    local character = getCharacter()
    if character and cameraMode then
        UE.UHRoleplaySystemGlobals.ClosePhoneCamera(character)
    end
    destroyCaptureAndUI()
    cameraMode = nil
end

local function setCameraMode(mode)
    local character = getCharacter()
    if not character then return end

    if cameraMode and cameraMode ~= mode then
        UE.UHRoleplaySystemGlobals.ClosePhoneCamera(character)
        cameraMode = nil
    end

    if cameraMode == mode then return end

    local ok
    if mode == 'front' then
        ok = UE.UHRoleplaySystemGlobals.OpenPhoneFrontCamera(character)
    elseif mode == 'back' then
        ok = UE.UHRoleplaySystemGlobals.OpenPhoneBackCamera(character)
    end

    if not ok then
        print('[PHONE] Failed to open ' .. mode .. ' camera')
        return
    end

    cameraMode = mode

    if not sceneCap then
        buildCaptureAndUI(mode)
        camUpdateTimerId = Timer.SetInterval(updateCameraRotation, 16)
    else
        applyCameraTransform(mode)
    end
end

-- ── Phone open/close ──────────────────────────────────────────────────────────

local function openPhone()
    phoneOpen = true
    TriggerServerEvent('qb-phone:server:givePhone')
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('open')
    TriggerServerEvent('qb-phone:server:loadPlayerData')
end

local function closePhone()
    phoneOpen = false
    TriggerServerEvent('qb-phone:server:takePhone')
    if cameraMode then closeCamera() end
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end

-- WebUI Events

my_webui:RegisterEventHandler('close', function()
    closePhone()
end)

my_webui:RegisterEventHandler('dial', function(data)
    TriggerServerEvent('qb-phone:server:dial', data.number)
end)

my_webui:RegisterEventHandler('acceptCall', function()
    TriggerServerEvent('qb-phone:server:accept')
end)

my_webui:RegisterEventHandler('hangup', function()
    TriggerServerEvent('qb-phone:server:hangup')
end)

-- Call Events

RegisterClientEvent('qb-phone:client:incomingCall', function(callerName, callerNumber)
    if not phoneOpen then openPhone() end
    my_webui:SendEvent('incomingCall', callerName, callerNumber)
end)

RegisterClientEvent('qb-phone:client:callRinging', function(targetName, targetNumber)
    my_webui:SendEvent('callRinging', targetName, targetNumber)
end)

RegisterClientEvent('qb-phone:client:callStarted', function(channel)
    my_webui:SendEvent('callStarted', channel)
end)

RegisterClientEvent('qb-phone:client:callEnded', function()
    my_webui:SendEvent('callEnded')
end)

RegisterClientEvent('qb-phone:client:callFailed', function(reason)
    my_webui:SendEvent('callFailed', reason)
end)

-- Messages

my_webui:RegisterEventHandler('sendMessage', function(data)
    TriggerServerEvent('qb-phone:server:sendMessage', data.number, data.text)
end)

RegisterClientEvent('qb-phone:client:messageReceived', function(senderName, senderNumber, text, time)
    my_webui:SendEvent('messageReceived', senderName, senderNumber, text, time)
end)

-- Contacts

my_webui:RegisterEventHandler('saveContact', function(data)
    TriggerServerEvent('qb-phone:server:saveContact', data.name, data.number, data.image)
end)

my_webui:RegisterEventHandler('deleteContact', function(data)
    TriggerServerEvent('qb-phone:server:deleteContact', data.number)
end)

RegisterClientEvent('qb-phone:client:contactsLoaded', function(contactsJson)
    my_webui:SendEvent('contactsLoaded', contactsJson)
end)

-- Call History

RegisterClientEvent('qb-phone:client:callLogged', function(name, number, callType, time, missed)
    my_webui:SendEvent('callLogged', name, number, callType, time, missed)
end)

-- H (Social Feed)

my_webui:RegisterEventHandler('createPost', function(data)
    TriggerServerEvent('qb-phone:server:createPost', data.content, data.image)
end)

my_webui:RegisterEventHandler('deletePost', function(data)
    TriggerServerEvent('qb-phone:server:deletePost', data.postId)
end)

my_webui:RegisterEventHandler('likePost', function(data)
    TriggerServerEvent('qb-phone:server:likePost', data.postId, data.liked)
end)

my_webui:RegisterEventHandler('repostPost', function(data)
    TriggerServerEvent('qb-phone:server:repostPost', data.postId, data.reposted)
end)

my_webui:RegisterEventHandler('followUser', function(data)
    TriggerServerEvent('qb-phone:server:followUser', data.handle, data.following)
end)

my_webui:RegisterEventHandler('addComment', function(data)
    TriggerServerEvent('qb-phone:server:addComment', data.postId, data.text)
end)

RegisterClientEvent('qb-phone:client:feedLoaded', function(postsJson)
    my_webui:SendEvent('feedLoaded', postsJson)
end)

RegisterClientEvent('qb-phone:client:postReceived', function(postJson)
    my_webui:SendEvent('postReceived', postJson)
end)

RegisterClientEvent('qb-phone:client:postDeleted', function(postId)
    my_webui:SendEvent('postDeleted', postId)
end)

RegisterClientEvent('qb-phone:client:postLikeUpdated', function(postId, likeCount)
    my_webui:SendEvent('postLikeUpdated', postId, likeCount)
end)

RegisterClientEvent('qb-phone:client:postRepostUpdated', function(postId, repostCount)
    my_webui:SendEvent('postRepostUpdated', postId, repostCount)
end)

RegisterClientEvent('qb-phone:client:commentAdded', function(postId, commentJson)
    my_webui:SendEvent('commentAdded', postId, commentJson)
end)

RegisterClientEvent('qb-phone:client:newFollower', function(followerName, followerNumber)
    my_webui:SendEvent('newFollower', followerName, followerNumber)
end)

-- Calendar

my_webui:RegisterEventHandler('saveCalendarEvent', function(data)
    TriggerServerEvent('qb-phone:server:saveCalendarEvent', data.month, data.day, data.title, data.time, data.detail)
end)

RegisterClientEvent('qb-phone:client:calendarEventsLoaded', function(eventsJson)
    my_webui:SendEvent('calendarEventsLoaded', eventsJson)
end)

-- Photos

my_webui:RegisterEventHandler('deletePhoto', function(data)
    TriggerServerEvent('qb-phone:server:deletePhoto', data.photoId)
end)

RegisterClientEvent('qb-phone:client:photosLoaded', function(photosJson)
    my_webui:SendEvent('photosLoaded', photosJson)
end)

-- ── Camera events from JS ─────────────────────────────────────────────────────

my_webui:RegisterEventHandler('cameraOpened', function(data)
    -- JS defaults to rear on open
    local facing = (data and data.facing) or 'rear'
    setCameraMode(facing == 'front' and 'front' or 'back')
end)

my_webui:RegisterEventHandler('cameraFlipped', function(data)
    local facing = (data and data.facing) or 'rear'
    setCameraMode(facing == 'front' and 'front' or 'back')
end)

my_webui:RegisterEventHandler('cameraClosed', function()
    if cameraMode then closeCamera() end
end)

my_webui:RegisterEventHandler('takePhoto', function(_)
    -- TODO: capture screenshot and upload
    -- JS expects: hideForCapture → showAfterCapture + photoTaken(url) or photoFailed
end)

RegisterClientEvent('qb-phone:client:photoUploaded', function(url)
    my_webui:SendEvent('showAfterCapture')
    my_webui:SendEvent(url and 'photoTaken' or 'photoFailed', url)
end)

-- Lifecycle

function onShutdown()
    if cameraMode then closeCamera() end
    local character = getCharacter()
    if character and phoneEquipped then
        HInventory.RemoveItemByName(character, PHONE_ITEM, 1)
    end
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

-- Input

Input.BindKey('O', function()
    if HPlayer:GetInputMode() == 1 and not phoneOpen then return end
    if phoneOpen then closePhone() else openPhone() end
end, 'Pressed')
