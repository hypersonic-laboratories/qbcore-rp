-- qb-policejob mugshot station: tripod target -> live viewfinder (SceneCapture
-- feed + WebUI chrome) -> E captures -> upload -> server resolves the subject
-- (ray test) and stores the photo. Consumers read results via the server
-- export GetMugshot(citizenid); qb-mdt is notified through its
-- SetProfileImage export. Nothing here depends on the MDT.

local active = nil        -- station config while the viewfinder is open
local activeIndex = 0
local sceneCap, camRoot, camFeed = nil, nil, nil
local capComp = nil       -- USceneCaptureComponent2D (zoom = FOV change)
local zoom = 1.0
local probeTimer = nil    -- 1s subject probe while the viewfinder is open

-- Studio light, spawned per session and torn down with the viewfinder.
-- Intensity is clamped to 1000-30000: 30k already overexposes a subject at
-- tripod distance, and the 10k default reads as even studio lighting.
local light = {}          -- { actor, comp }
local lightState = { on = true, intensity = 10000, temp = 'neutral' }
local LIGHT_TEMPS = {
    cool = { 0.80, 0.90, 1.00 },
    neutral = { 1.00, 1.00, 1.00 },
    warm = { 1.00, 0.86, 0.70 },
}

-- Adjustable camera pose (position + aim), reset to the station calibration
local camPose = nil       -- { x, y, z, yaw, pitch }

local function notify(text, kind)
    TriggerLocalClientEvent('QBCore:Notify', text, kind or 'primary')
end

-- ─────────────────────────── WebUI bridge ───────────────────────────────────
-- The viewfinder chrome lives in qb-policejob/html (mugshot.js) on the shared
-- PoliceJobUI page (created in client/camera.lua, loads before this file).

local function sendUI(event, payload)
    if PoliceJobUI then PoliceJobUI:SendEvent(event, payload or {}) end
end

-- Focus = mouse on the HUD, player look parked. Action keybinds (E,
-- Backspace, arrows, R) still fire while a WebUI holds focus.
local function setFocus(focused)
    if not PoliceJobUI then return end
    if focused then
        PoliceJobUI:BringToFront()
        PoliceJobUI:SetInputMode(1)
    else
        PoliceJobUI:SetInputMode(0)
    end
end

-- Everything the HUD renders about the rig, pushed after every control op
local function pushState()
    sendUI('mugshot:state', {
        zoom = zoom,
        lightAvailable = light.comp ~= nil,
        lightOn = lightState.on,
        lightIntensity = lightState.intensity,
        lightTemp = lightState.temp,
    })
end

-- ─────────────────────────── viewfinder ─────────────────────────────────────

local function teardown()
    if probeTimer then Timer.ClearInterval(probeTimer) probeTimer = nil end
    if camRoot then camRoot:RemoveFromParent() end
    if sceneCap and sceneCap.Object then sceneCap.Object:K2_DestroyActor() end
    if light.actor then pcall(function() light.actor:K2_DestroyActor() end) end
    light = {}
    sceneCap, camRoot, camFeed, capComp = nil, nil, nil, nil
    active = nil
    activeIndex = 0
    zoom = 1.0
    camPose = nil
    setFocus(false) -- give look/keys back to the game
    sendUI('mugshot:close', {})
end

-- Called from client/evidence.lua's onShutdown (a second onShutdown global
-- here would overwrite it and leak the WebUI).
function PoliceMugshotTeardown()
    teardown()
end

-- Zoom = narrower capture FOV. Clamped 1.0x–2.5x in 0.25 steps.
local function applyZoom()
    if not active or not capComp then return end
    capComp.FOVAngle = (active.fov or 50) / zoom
    pushState()
end

-- ─────────────────────────── studio light ───────────────────────────────────
-- One spotlight at the lens aimed at the subject. Both spawns are pcall'd:
-- if neither light class is exposed by the runtime, the HUD reports lighting
-- as unavailable and everything else keeps working.

local function applyLight()
    if not light.comp then return end
    pcall(function()
        light.comp:SetVisibility(lightState.on, false)
        light.comp:SetIntensity(lightState.intensity)
        local t = LIGHT_TEMPS[lightState.temp] or LIGHT_TEMPS.neutral
        light.comp:SetLightColor(LinearColor(t[1], t[2], t[3], 1.0))
    end)
end

local function spawnLight(station)
    -- The light reuses the camera's calibrated transform (camPos + camRot):
    -- the SceneCapture faces the chart with it, so no aim math is needed.
    -- (Avoid computing rotations with two-arg math.atan here — this runtime
    -- ignores the second argument.)
    local pos = station.camPos
    -- Spotlight actors emit downward at identity rotation; +90 pitch tips the
    -- beam forward along the camera yaw for a level frontal light at face
    -- height.
    local rot = Rotator(station.camRot.Pitch + 90, station.camRot.Yaw, 0)
    local ok, actor = pcall(SpawnActor, UE.ASpotLight, pos, rot)
    local compClass = UE.USpotLightComponent
    if not ok or not actor then
        ok, actor = pcall(SpawnActor, UE.APointLight, pos, Rotator(0, 0, 0))
        compClass = UE.UPointLightComponent
    end
    if not ok or not actor then
        print('[qb-policejob] mugshot light spawn failed — LIGHTING controls disabled')
        return
    end

    light.actor = actor
    local okc, comp = pcall(function() return actor:GetComponentByClass(compClass.StaticClass()) end)
    light.comp = (okc and comp) or nil
    if not light.comp then return end
    pcall(function() light.comp:SetMobility(UE.EComponentMobility.Movable) end)
    pcall(function()
        light.comp:SetAttenuationRadius(1500)
        -- wide soft cone: cover head + shoulders with falloff, not a hard disc
        light.comp:SetOuterConeAngle(65) -- no-op on the point-light fallback
        light.comp:SetInnerConeAngle(25)
    end)
    applyLight()
end

-- ─────────────────────────── camera trim ────────────────────────────────────

local function applyCamPose()
    if not sceneCap or not sceneCap.Object or not camPose then return end
    pcall(function()
        sceneCap.Object:K2_SetActorLocation(Vector(camPose.x, camPose.y, camPose.z), false, nil, false)
        sceneCap.Object:K2_SetActorRotation(Rotator(camPose.pitch, camPose.yaw, 0), false)
    end)
end

local function resetCamPose(station)
    camPose = {
        x = station.camPos.X, y = station.camPos.Y, z = station.camPos.Z,
        yaw = station.camRot.Yaw, pitch = station.camRot.Pitch,
    }
end

-- Move sideways relative to where the camera currently looks (frame-space)
local function camStrafe(dist)
    local rad = math.rad(camPose.yaw + 90)
    camPose.x = camPose.x + math.cos(rad) * dist
    camPose.y = camPose.y + math.sin(rad) * dist
end

-- Ask the server whether someone is in front of the camera; the result feeds
-- the HUD's SUBJECT INFO panel + POSITION indicator.
local function probeSubject()
    if not active then return end
    local index = activeIndex
    TriggerCallback('policeMugshotProbe', function(result)
        if not active or activeIndex ~= index then return end -- stale reply
        sendUI('mugshot:subject', result or {})
    end, index)
end

local function openViewfinder(index)
    local station = Config.Mugshot.stations[index]
    if not station then return end
    if active then teardown() end

    -- Fixed lens at the tripod aimed at the height chart (see qb-phone for the
    -- SceneCapture/Widget pattern; portrait aspect suits a mugshot).
    sceneCap = SceneCapture(
        station.camPos, station.camRot,
        720, 900,
        SceneCaptureSource.FinalColorLDR,
        false
    )
    capComp = sceneCap.Object:GetComponentByClass(UE.USceneCaptureComponent2D.StaticClass())
    if capComp then capComp.FOVAngle = station.fov or 50 end

    local character = GetPlayerPawn()
    local vp = UE.UWidgetLayoutLibrary.GetViewportSize(character)
    local sx, sy = vp.X / 2560, vp.Y / 1440

    -- Centered preview panel — MUST stay in sync with the .mugHole rect in
    -- html/mugshot.css (760x950 at a 2560x1440 design space): the WebUI HUD
    -- draws the chrome, this UMG image is the feed inside its cutout.
    local w, h = math.floor(760 * sx), math.floor(950 * sy)
    camRoot = Widget(NativeWidget.CanvasPanel)
    camRoot:AddToViewport()
    camFeed = Widget(NativeWidget.Image)
    camRoot:AddChild(camFeed)
    -- SetCanvasLayout anchors the widget's center on the given position,
    -- not its top-left. The HTML hole is centered on the viewport, so the
    -- feed goes to the viewport center.
    camFeed:SetCanvasLayout(
        Vector2D(math.floor(vp.X / 2), math.floor(vp.Y / 2)),
        Vector2D(w, h)
    )
    camFeed.innerWidget:SetBrushResourceObject(sceneCap.RenderTarget)

    active = station
    activeIndex = index
    zoom = 1.0
    resetCamPose(station)
    spawnLight(station)

    sendUI('mugshot:open', { stationIndex = index })
    setFocus(true)
    pushState()
    probeSubject()
    probeTimer = Timer.SetInterval(probeSubject, 1000)
end

-- ─────────────────────────── capture + upload ───────────────────────────────

local function capture()
    if not active or not sceneCap or not sceneCap.RenderTarget then return end
    local stationIndex = activeIndex
    local character = GetPlayerPawn()
    if not character then teardown() return end

    -- Freeze the subject now: the upload takes seconds, and the photo shows
    -- whoever stood in frame at the shutter moment, not whoever happens to be
    -- there when the URL comes back.
    TriggerServerEvent('qb-policejob:server:mugshotBegin', stationIndex)

    local saveDir = UE.UKismetSystemLibrary.GetProjectSavedDirectory() .. 'MugShots/'
    local fileName = 'mug_' .. tostring(os.time()) .. '.png'
    UE.UKismetRenderingLibrary.ExportRenderTarget(character, sceneCap.RenderTarget, saveDir, fileName)
    teardown()
    notify('Processing mugshot…', 'primary')

    -- Detached curl upload: HTTP.Request corrupts binary PNGs, so the file
    -- goes out through a background curl and the response file is polled.
    local filePath = (saveDir .. fileName):gsub('\\', '/')
    local responsePath = filePath .. '.json'
    local winPath = filePath:gsub('/', '\\')
    local winResponsePath = responsePath:gsub('/', '\\')
    local cmd = 'start "" /b curl -s -X POST'
        .. ' -F "file=@' .. winPath .. '"'
        .. ' -H "Authorization: ' .. Config.Mugshot.imageApi.key .. '"'
        .. ' "' .. Config.Mugshot.imageApi.url .. '"'
        .. ' -o "' .. winResponsePath .. '"'
    os.execute(cmd)

    local attempts = 0
    local function pollResponse()
        attempts = attempts + 1
        local f = io.open(responsePath, 'r')
        if f then
            local result = f:read('*all')
            f:close()
            os.remove(responsePath)
            os.remove(filePath)
            local url = nil
            if result and result ~= '' then
                local ok, parsed = pcall(JSON.parse, result)
                url = ok and parsed and parsed.data and parsed.data.url
            end
            if url and url ~= '' then
                TriggerServerEvent('qb-policejob:server:mugshot', stationIndex, url)
            else
                notify('Mugshot upload failed — photo not saved', 'error')
            end
        elseif attempts < 120 then -- 60s cap; cold uploads can take a while
            Timer.SetTimeout(pollResponse, 500)
        else
            os.remove(filePath)
            print('[qb-policejob] mugshot upload timed out waiting for ' .. responsePath)
            notify('Mugshot upload timed out — photo not saved', 'error')
        end
    end
    Timer.SetTimeout(pollResponse, 500)
end

-- ─────────────────────────── HUD control ops ────────────────────────────────
-- Clicked buttons arrive as { op, value } from html/mugshot.js; the keyboard
-- shortcuts below route through the same ops.

local CAM_STEP, AIM_STEP = 8, 1.5 -- cm per nudge, degrees per aim tick

local function control(op, value)
    if not active then return end

    if op == 'capture' then capture() return end
    if op == 'cancel' then teardown() notify('Mugshot cancelled', 'error') return end

    if op == 'zoomIn' then zoom = math.min(2.5, zoom + 0.25) applyZoom() return end
    if op == 'zoomOut' then zoom = math.max(1.0, zoom - 0.25) applyZoom() return end
    if op == 'zoomReset' then zoom = 1.0 applyZoom() return end

    if op == 'lightToggle' then lightState.on = not lightState.on applyLight() pushState() return end
    if op == 'lightUp' then lightState.intensity = math.min(30000, lightState.intensity + 3000) applyLight() pushState() return end
    if op == 'lightDown' then lightState.intensity = math.max(1000, lightState.intensity - 3000) applyLight() pushState() return end
    if op == 'lightTemp' and LIGHT_TEMPS[value] then lightState.temp = value applyLight() pushState() return end

    if op == 'camLeft' then camStrafe(-CAM_STEP) applyCamPose() return end
    if op == 'camRight' then camStrafe(CAM_STEP) applyCamPose() return end
    if op == 'camUp' then camPose.z = camPose.z + CAM_STEP applyCamPose() return end
    if op == 'camDown' then camPose.z = camPose.z - CAM_STEP applyCamPose() return end
    if op == 'camYawL' then camPose.yaw = camPose.yaw - AIM_STEP applyCamPose() return end
    if op == 'camYawR' then camPose.yaw = camPose.yaw + AIM_STEP applyCamPose() return end
    if op == 'camPitchU' then camPose.pitch = math.min(25, camPose.pitch + AIM_STEP) applyCamPose() return end
    if op == 'camPitchD' then camPose.pitch = math.max(-25, camPose.pitch - AIM_STEP) applyCamPose() return end
    if op == 'camReset' then resetCamPose(active) applyCamPose() return end
end

if PoliceJobUI then
    PoliceJobUI:RegisterEventHandler('mugshot:op', function(data)
        if type(data) ~= 'table' or type(data.op) ~= 'string' then return end
        control(data.op, data.value)
    end)
end

-- ─────────────────────────── input ──────────────────────────────────────────
-- Keyboard shortcuts mirror the HUD buttons; keybinds fire even while the
-- WebUI holds focus.

Input.BindKey('E', function()
    if active then control('capture') end
end, 'Released')

Input.BindKey('Backspace', function()
    if active then control('cancel') end
end, 'Released')

Input.BindKey('Up', function()
    if active then control('zoomIn') end
end, 'Released')

Input.BindKey('Down', function()
    if active then control('zoomOut') end
end, 'Released')

Input.BindKey('R', function()
    if active then control('zoomReset') end
end, 'Released')

-- ─────────────────────────── manual-ID fallback ─────────────────────────────
-- Server found nobody in front of the camera: ask for the citizenid by hand
-- (also the solo-test path — type your own). The exported ShowInput can't
-- yield across the package boundary, so use qb-input's async event bridge:
-- the request carries replyEvent, the dialog result comes back on it.

local manualUrl = nil -- photo URL held while the citizenid dialog is open

RegisterClientEvent('qb-policejob:client:mugshotManualReply', function(dialog)
    local url = manualUrl
    manualUrl = nil
    if not url then return end
    if dialog and dialog.citizenid and dialog.citizenid ~= '' then
        TriggerServerEvent('qb-policejob:server:mugshotManual', dialog.citizenid, url)
    else
        notify('Mugshot discarded — no citizen ID given', 'error')
    end
end)

RegisterClientEvent('qb-policejob:client:mugshotManual', function(url)
    if type(url) ~= 'string' or url == '' then return end
    manualUrl = url
    TriggerLocalClientEvent('qb-input:client:ShowMenuAsync', {
        replyEvent = 'qb-policejob:client:mugshotManualReply',
        header = 'Mugshot — no subject in frame',
        submitText = 'Save',
        inputs = {
            {
                type = 'text',
                name = 'citizenid',
                label = 'Citizen ID',
                text = 'e.g. ABC12345',
                isRequired = true,
            },
        },
    })
end)

RegisterClientEvent('qb-policejob:client:mugshot', function(data)
    local index = tonumber(data and data.stationIndex) or 1
    openViewfinder(index)
end)

-- ─────────────────────────── target zones ───────────────────────────────────
-- Zones must be registered AFTER the player is loaded — XRay focus detection
-- doesn't pick up targets registered during package load.

local zonesRegistered = false

local function registerMugshotZones()
    if zonesRegistered then return end
    zonesRegistered = true
    for i, station in ipairs(Config.Mugshot.stations) do
        if station.interact.X ~= 0 or station.interact.Y ~= 0 then -- skip uncalibrated placeholders
            -- targetoptions must be an ARRAY of option tables (#options is
            -- checked in AddTargetEntity; a bare option map has length 0 and
            -- silently skips Xray registration)
            exports['qb-target']:AddSphereZone('PoliceMugshot_' .. i, station.interact, 0,
                { distance = 250, useMesh = true },
                { {
                    type = 'client',
                    event = 'qb-policejob:client:mugshot',
                    icon = 'camera',
                    label = 'Take Mugshot',
                    jobType = 'leo',
                    stationIndex = i,
                } })
        end
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    registerMugshotZones()
end)

-- Package reloads happen mid-session (no OnPlayerLoaded refire): register
-- after a short delay if a character is already active.
Timer.SetTimeout(function()
    local ok, pd = pcall(function() return exports['qb-core']:GetPlayerData() end)
    if ok and pd and pd.citizenid then registerMugshotZones() end
end, 2000)

-- ─────────────────────────── calibration helper ─────────────────────────────
-- /mugshotsetup — prints the current pawn position + rotation for pasting into
-- Config.Mugshot. Run once at the tripod facing the chart, once on the chart.

local setupTripod = nil -- step 1 result held until step 2

local HConsole = GetActorByTag('HConsole')
if HConsole then
    HConsole:RegisterCommand('mugshotsetup', 'Two-step Config.Mugshot calibration', nil, {
        HWorld,
        function()
            local pawn = GetPlayerPawn()
            if not pawn then return end
            local c = GetEntityCoords(pawn)
            local r = pawn:K2_GetActorRotation()

            if not setupTripod then
                -- STEP 1: standing AT the tripod, FACING the height chart
                setupTripod = { x = c.X, y = c.Y, z = c.Z, yaw = r.Yaw }
                print('[qb-policejob] mugshotsetup 1/2 — tripod saved.')
                print('[qb-policejob] Now STAND ON THE CHART MARK (where the suspect poses) and run /mugshotsetup again.')
                notify('Mugshot setup 1/2: tripod saved — stand on the chart mark, run again', 'primary')
            else
                -- STEP 2: standing ON the chart mark → print the finished block
                print('[qb-policejob] mugshotsetup 2/2 — paste this into Config.Mugshot.stations:')
                print(('        {'))
                print(('            interact = Vector(%.0f, %.0f, %.0f),'):format(setupTripod.x, setupTripod.y, setupTripod.z))
                -- camera: 25cm forward along facing (clears the tripod prop),
                -- +60 up = subject face height (camera looks level)
                local rad = math.rad(setupTripod.yaw)
                local camX = setupTripod.x + math.cos(rad) * 25
                local camY = setupTripod.y + math.sin(rad) * 25
                print(('            camPos = Vector(%.0f, %.0f, %.0f),'):format(camX, camY, setupTripod.z + 60))
                print(('            camRot = Rotator(0, %.1f, 0),'):format(setupTripod.yaw))
                print(('            stand = Vector(%.0f, %.0f, %.0f),'):format(c.X, c.Y, c.Z))
                print(('            corridorCm = 100,'))
                print(('            fov = 24,'))
                print(('        },'))
                notify('Mugshot setup 2/2: config printed to console — paste into config.lua', 'success')
                setupTripod = nil
            end
        end,
    })
end
