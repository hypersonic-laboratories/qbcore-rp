---@diagnostic disable: undefined-global
local my_webui = WebUI('qb-phone', 'qb-phone/html/index.html')
local phoneOpen = false

local PHONE_ITEM = 'ID_Misc_Phone'
local HAND_SOCKET = 'hand_r'
local phoneEquipped = false
local cameraMode = nil
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

local zoomFov = { [0.6] = 90, [1] = 60, [2] = 30, [5] = 12 }

local function getCharacter() return GetPlayerPawn() end

local function nonEmpty(value)
    if value == nil then return nil end
    local text = tostring(value)
    return text ~= '' and text or nil
end

local function getLocalProfile()
    local ok, data = pcall(function()
        return exports['qb-core']:GetPlayerData()
    end)
    if not ok or type(data) ~= 'table' then return nil end

    local charinfo = data.charinfo or {}
    local firstName = nonEmpty(charinfo.firstname) or ''
    local lastName = nonEmpty(charinfo.lastname) or ''
    local name = nonEmpty((firstName .. ' ' .. lastName):match('^%s*(.-)%s*$')) or nonEmpty(data.name)

    return {
        name = name,
        phone = nonEmpty(charinfo.phone),
        citizenid = nonEmpty(data.citizenid) or nonEmpty(charinfo.citizenid),
        account = nonEmpty(charinfo.account),
    }
end

local function hasProfileData(profile)
    return profile and (profile.name or profile.phone or profile.citizenid or profile.account)
end

local function sendProfile(profile)
    if hasProfileData(profile) then
        my_webui:SendEvent('profileLoaded', profile)
    end
end

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
        720, 1280,
        SceneCaptureSource.FinalColorLDR,
        false
    )

    local mesh = character:GetComponentByClass(UE.USkeletalMeshComponent.StaticClass())
    sceneCap.Object:K2_AttachToComponent(mesh, HAND_SOCKET, 0, 0, 0, true)
    applyCameraTransform(mode)

    local capComp = sceneCap.Object:GetComponentByClass(UE.USceneCaptureComponent2D.StaticClass())
    if capComp then capComp.FOVAngle = 60 end

    local vp = UE.UWidgetLayoutLibrary.GetViewportSize(character)
    local sx, sy = vp.X / 2560, vp.Y / 1440

    camRoot = Widget(NativeWidget.CanvasPanel)
    camRoot:AddToViewport()
    camFeed = Widget(NativeWidget.Image)
    camRoot:AddChild(camFeed)
    camFeed:SetCanvasLayout(
        Vector2D(math.floor(1761 * sx), math.floor(739 * sy)),
        Vector2D(math.floor(254 * sx), math.floor(402 * sy))
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

    if mode == 'front' then
        UE.UHRoleplaySystemGlobals.OpenPhoneFrontCamera(character)
    elseif mode == 'back' then
        UE.UHRoleplaySystemGlobals.OpenPhoneBackCamera(character)
    end

    cameraMode = mode

    if not sceneCap then
        buildCaptureAndUI(mode)
        camUpdateTimerId = Timer.SetInterval(updateCameraRotation, 16)
    else
        applyCameraTransform(mode)
    end
end

local function openPhone()
    phoneOpen = true
    TriggerServerEvent('qb-phone:server:givePhone')
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('open')
    sendProfile(getLocalProfile())
    TriggerCallback('qb-phone:loadCoreData', function(data)
        if not data then return end
        my_webui:SendEvent('contactsLoaded', data.contacts)
        my_webui:SendEvent('conversationsLoaded', data.conversations)
        my_webui:SendEvent('callHistoryLoaded', data.callHistory)
        sendProfile({
            name = data.playerName,
            phone = data.phoneNumber,
            citizenid = data.citizenid,
            account = data.accountNumber,
        })
        TriggerServerEvent('qb-phone:server:loadCalendar')
    end)

    TriggerServerEvent('qb-phone:server:requestPhotos')
end

local function closePhone()
    phoneOpen = false
    TriggerServerEvent('qb-phone:server:takePhone')
    if cameraMode then closeCamera() end
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end

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

my_webui:RegisterEventHandler('sendMessage', function(data)
    TriggerServerEvent('qb-phone:server:sendMessage', data.number, data.text)
end)

my_webui:RegisterEventHandler('deleteConversation', function(data)
    TriggerServerEvent('qb-phone:server:deleteConversation', data.number)
end)

RegisterClientEvent('qb-phone:client:messageReceived', function(senderName, senderNumber, text, time)
    my_webui:SendEvent('messageReceived', senderName, senderNumber, text, time)
end)

my_webui:RegisterEventHandler('saveContact', function(data)
    TriggerServerEvent('qb-phone:server:saveContact', data.name, data.number, data.image)
end)

my_webui:RegisterEventHandler('deleteContact', function(data)
    TriggerServerEvent('qb-phone:server:deleteContact', data.number)
end)

RegisterClientEvent('qb-phone:client:callLogged', function(name, number, callType, time, missed)
    my_webui:SendEvent('callLogged', name, number, callType, time, missed)
end)

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
    TriggerServerEvent('qb-phone:server:followUser', data.handle, data.following, data.targetPhone)
end)

my_webui:RegisterEventHandler('addComment', function(data)
    TriggerServerEvent('qb-phone:server:addComment', data.postId, data.text)
end)

my_webui:RegisterEventHandler('loadFeed', function()
    TriggerCallback('qb-phone:loadFeed', function(data)
        if not data then return end
        my_webui:SendEvent('feedLoaded', data.feed)
        my_webui:SendEvent('usersLoaded', data.users)
    end)
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

my_webui:RegisterEventHandler('loadEmails', function()
    TriggerCallback('qb-phone:loadEmails', function(data)
        if not data then return end
        my_webui:SendEvent('emailsLoaded', data.emails)
    end)
end)

my_webui:RegisterEventHandler('sendEmail', function(data)
    TriggerServerEvent('qb-phone:server:sendEmail', data.toNumber, data.subject, data.body)
end)

my_webui:RegisterEventHandler('deleteEmail', function(data)
    TriggerServerEvent('qb-phone:server:deleteEmail', data.emailId)
end)

RegisterClientEvent('qb-phone:client:emailReceived', function(emailJson)
    my_webui:SendEvent('emailReceived', emailJson)
end)

my_webui:RegisterEventHandler('loadProfile', function(_, cb)
    if type(_) == 'function' and cb == nil then cb = _ end

    local responded = false
    local fallback = getLocalProfile()
    if hasProfileData(fallback) then
        sendProfile(fallback)
        if type(cb) == 'function' then
            cb(fallback)
            responded = true
        end
    end

    TriggerCallback('qb-phone:loadProfile', function(data)
        if not data then return end
        local profile = {
            name = data.name,
            phone = data.phone,
            citizenid = data.citizenid,
            account = data.account,
        }
        sendProfile(profile)
        if type(cb) == 'function' and not responded then cb(profile) end
    end)
end)

my_webui:RegisterEventHandler('copyToClipboard', function(data)
    local text = data
    if type(data) == 'table' then
        text = data.text or data.value or data.phone
    end

    text = nonEmpty(text)
    if not text then return end
    CopyToClipboard(text)
end)

my_webui:RegisterEventHandler('loadCalendar', function()
    TriggerServerEvent('qb-phone:server:loadCalendar')
end)

RegisterClientEvent('qb-phone:client:calendarEventsLoaded', function(eventsJson)
    my_webui:SendEvent('calendarEventsLoaded', eventsJson or '{}')
end)

my_webui:RegisterEventHandler('saveCalendarEvent', function(data)
    TriggerServerEvent('qb-phone:server:saveCalendarEvent', data.year, data.month, data.day, data.title, data.time, data.detail)
end)

my_webui:RegisterEventHandler('deleteCalendarEvent', function(data)
    TriggerServerEvent('qb-phone:server:deleteCalendarEvent', data.eventId)
end)

my_webui:RegisterEventHandler('loadPhotos', function()
    TriggerServerEvent('qb-phone:server:requestPhotos')
end)

RegisterClientEvent('qb-phone:client:photosLoaded', function(photosJson)
    my_webui:SendEvent('photosLoaded', photosJson or '[]')
end)

my_webui:RegisterEventHandler('deletePhoto', function(data)
    TriggerServerEvent('qb-phone:server:deletePhoto', data.photoId)
end)

my_webui:RegisterEventHandler('cameraOpened', function(data)
    local facing = (data and data.facing) or 'rear'
    setCameraMode(facing == 'front' and 'front' or 'back')
end)

my_webui:RegisterEventHandler('cameraFlipped', function(data)
    local facing = (data and data.facing) or 'rear'
    setCameraMode(facing == 'front' and 'front' or 'back')
end)

my_webui:RegisterEventHandler('cameraZoom', function(data)
    if not sceneCap or not sceneCap.Object then return end
    local fov = zoomFov[data and data.zoom] or 60
    local capComp = sceneCap.Object:GetComponentByClass(UE.USceneCaptureComponent2D.StaticClass())
    if capComp then capComp.FOVAngle = fov end
end)

my_webui:RegisterEventHandler('cameraClosed', function()
    if cameraMode then closeCamera() end
end)

local FIVEMANAGE_IMAGE_KEY = 'Py4jfdWgiRLzTTboAofHBC2aoiCSfrar'
local FIVEMANAGE_URL = 'https://api.fivemanage.com/api/v3/file'

my_webui:RegisterEventHandler('takePhoto', function(_)
    if not sceneCap or not sceneCap.RenderTarget then
        my_webui:SendEvent('showAfterCapture')
        my_webui:SendEvent('photoFailed')
        return
    end

    local character = getCharacter()
    if not character then
        my_webui:SendEvent('showAfterCapture')
        my_webui:SendEvent('photoFailed')
        return
    end

    my_webui:SendEvent('hideForCapture')

    local saveDir = UE.UKismetSystemLibrary.GetProjectSavedDirectory() .. 'PhonePhotos/'
    local fileName = 'photo_' .. tostring(os.time()) .. '.png'
    UE.UKismetRenderingLibrary.ExportRenderTarget(character, sceneCap.RenderTarget, saveDir, fileName)

    local filePath = (saveDir .. fileName):gsub('\\', '/')
    -- local responsePath = filePath .. '.json'
    -- os.execute('start "" /b curl -s -X POST -F "file=@' .. filePath .. '" -H "Authorization: ' .. FIVEMANAGE_IMAGE_KEY .. '" "https://api.fivemanage.com/api/v3/file" -o "' .. responsePath .. '"')

    my_webui:SendEvent('showAfterCapture')

    Timer.SetTimeout(function()
        local f = io.open(filePath, 'rb')
        if not f then
            my_webui:SendEvent('photoFailed')
            return
        end
        local fileData = f:read('*all')
        f:close()
        os.remove(filePath)

        local boundary = 'HELIXphoto' .. tostring(os.time())
        local body = '--' .. boundary .. '\r\n'
            .. 'Content-Disposition: form-data; name="file"; filename="' .. fileName .. '"\r\n'
            .. 'Content-Type: image/png\r\n\r\n'
            .. fileData .. '\r\n--' .. boundary .. '--\r\n'

        HTTP.Request(FIVEMANAGE_URL, {
            Method = 'POST',
            Headers = {
                Authorization = FIVEMANAGE_IMAGE_KEY,
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
            },
            Body = body,
        }, function(response)
            local url = nil
            if response.Ok and response.Body then
                local ok, parsed = pcall(JSON.parse, response.Body)
                url = ok and parsed and parsed.data and parsed.data.url
            end
            if url and url ~= '' then
                TriggerServerEvent('qb-phone:server:savePhoto', url)
            end
            my_webui:SendEvent(url and url ~= '' and 'photoTaken' or 'photoFailed', url)
        end)
    end, 500)
end)

function handlePhotoUploaded(url)
    if url and url ~= '' then
        TriggerServerEvent('qb-phone:server:savePhoto', url)
    end
    my_webui:SendEvent('showAfterCapture')
    my_webui:SendEvent((url and url ~= '') and 'photoTaken' or 'photoFailed', url)
end

my_webui:RegisterEventHandler('gallerySavePhoto', function(data)
    local url = type(data) == 'table' and (data.url or data.image) or data
    if url and url ~= '' then
        TriggerServerEvent('qb-phone:server:savePhoto', url)
    end
end)

my_webui:RegisterEventHandler('photoUploaded', function(data)
    local url = data
    if type(data) == 'table' then
        url = data.url or data.image
    end
    handlePhotoUploaded(url)
end)

RegisterClientEvent('qb-phone:client:photoUploaded', function(url)
    handlePhotoUploaded(url)
end)

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

Input.BindKey(Config.OpenKey, function()
    if HPlayer:GetInputMode() == 1 and not phoneOpen then return end
    if phoneOpen then closePhone() else openPhone() end
end, 'Pressed')

my_webui:RegisterEventHandler('rightMouseDown', function()
    if not phoneOpen then return end
    my_webui:SetInputMode(0)
end)

Input.BindKey('RightMouseButton', function()
    if not phoneOpen then return end
    my_webui:SetInputMode(1)
end, 'Released')
