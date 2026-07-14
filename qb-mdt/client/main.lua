-- qb-mdt client: WebUI shell, open/close, RPC bridge, dispatch push events

local my_webui = WebUI('qb-mdt', 'qb-mdt/html/index.html')
local isOpen = false

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

-- ─────────────────────────── access ─────────────────────────────────────────

local function HasAccess()
    local playerData = exports['qb-core']:GetPlayerData()
    local job = playerData and playerData.job
    if not job or not job.type or not Config.Roles[job.type] then return false end
    if Config.RequireOnDuty and not job.onduty then return false end
    return true
end

-- ─────────────────────────── RPC ────────────────────────────────────────────
-- Request/response via the engine callback system ('mdtRpc' server-side; the
-- name must be a plain identifier — colon names are silently dropped).
-- payload stays a JSON string from the WebUI; the server dispatcher parses it.
local function Rpc(name, payload, cb)
    TriggerCallback('mdtRpc', cb or function() end, { action = name, payload = payload })
end

-- ─────────────────────────── open / close ───────────────────────────────────

local function CloseMDT()
    if not isOpen then return end
    isOpen = false
    my_webui:SendEvent('mdt:close', {})
    my_webui:SetInputMode(0)
end

local function OpenMDT()
    if isOpen then return end
    if not HasAccess() then
        TriggerLocalClientEvent('QBCore:Notify', 'You are not on duty with an authorized department', 'error')
        return
    end
    Rpc('open', nil, function(data)
        if not data or not data.ok then
            TriggerLocalClientEvent('QBCore:Notify', 'MDT access denied', 'error')
            return
        end
        isOpen = true
        -- CCTV list comes from qb-policejob (single source of truth); pcall in
        -- case that resource isn't running.
        if data.role == 'police' then
            local ok, cams = pcall(function() return exports['qb-policejob']:GetCameraList() end)
            data.cameras = (ok and cams) or {}
        end
        my_webui:BringToFront()
        my_webui:SetInputMode(1)
        my_webui:SendEvent('mdt:open', data)
    end)
end

local function ToggleMDT()
    if isOpen then
        CloseMDT()
    else
        -- Don't open over another focused UI (input mode 1 = a WebUI has focus).
        if HPlayer:GetInputMode() == 1 then return end
        OpenMDT()
    end
end

Input.BindKey(Config.OpenKey, function()
    ToggleMDT()
end, 'Released')

-- ─────────────────────────── unit radio PTT ─────────────────────────────────
-- Hold to transmit on the unit channel. Server validates unit membership and
-- relays the speaking state to the whole crew (qb-mdt:client:ptt below).
local pttHeld = false

Input.BindKey(Config.PttKey, function()
    if pttHeld then return end
    -- Don't key up while typing in a WebUI (CapsLock is a text key too).
    if HPlayer:GetInputMode() == 1 then return end
    if not HasAccess() then return end
    pttHeld = true
    TriggerServerEvent('qb-mdt:server:ptt', true, false)
end, 'Pressed')

Input.BindKey(Config.PttKey, function()
    if not pttHeld then return end
    pttHeld = false
    TriggerServerEvent('qb-mdt:server:ptt', false, false)
end, 'Released')

-- Real mic activity (engine voice detection) animates the HUD waveform while
-- keyed up — crew sees who is actually speaking, not just who holds the key.
RegisterClientEvent('HEvent:VoiceStateChanged', function(isTalking)
    if not pttHeld then return end
    TriggerServerEvent('qb-mdt:server:ptt', true, isTalking and true or false)
end)

-- No proximity key needed: normal talk (V / voice-activated) reaches only
-- players nearby — far crew members have this player muted server-side unless
-- PTT is held (see dispatch.lua voice gating). Radio stays audible always.

RegisterClientEvent('qb-mdt:client:ptt', function(payload)
    my_webui:SendEvent('mdt:ptt', payload or {})
end)

-- ─────────────────────────── UI -> server RPC bridge ────────────────────────

-- Single RPC channel: UI sends { action, payload, reqId }, gets mdt:response back.
-- Every action maps to a server callback named 'qb-mdt:<action>'.
local AllowedActions = {
    search = true,
    getProfile = true,
    saveProfile = true,
    getVehicle = true,
    getIncidents = true,
    getIncident = true,
    saveIncident = true,
    deleteIncident = true,
    processArrest = true,
    getWarrants = true,
    createWarrant = true,
    updateWarrant = true,
    getBolos = true,
    createBolo = true,
    resolveBolo = true,
    getCalls = true,
    createCall = true,
    attachToCall = true,
    detachFromCall = true,
    closeCall = true,
    setUnitStatus = true,
    getUnits = true,
    joinUnit = true,
    leaveUnit = true,
    getUnitBoard = true,
    getMedicalRecords = true,
    saveMedicalRecord = true,
    addBulletin = true,
    deleteBulletin = true,
    getLogs = true,
}

my_webui:RegisterEventHandler('mdt:request', function(data)
    if type(data) ~= 'table' or not AllowedActions[data.action] then return end
    local reqId = data.reqId
    Rpc(data.action, data.payload, function(result)
        my_webui:SendEvent('mdt:response', { reqId = reqId, action = data.action, data = result })
    end)
end)

my_webui:RegisterEventHandler('mdt:close', function()
    CloseMDT()
end)

my_webui:RegisterEventHandler('mdt:viewCamera', function(data)
    -- JSON-string payload (nested objects don't survive hEvent JS->Lua).
    if type(data) ~= 'table' or type(data.payload) ~= 'string' then return end
    local ok, parsed = pcall(JSON.parse, data.payload)
    local camId = ok and type(parsed) == 'table' and tonumber(parsed.id) or nil
    if not camId then return end
    -- The CCTV view is a full-screen takeover (view-target blend); close the
    -- tablet first. Backspace exits the camera (qb-policejob behavior).
    CloseMDT()
    TriggerLocalClientEvent('qb-policejob:client:ActiveCamera', camId)
end)

my_webui:RegisterEventHandler('mdt:panic', function()
    local pawn = GetPlayerPawn()
    local coords = pawn and GetEntityCoords(pawn) or nil
    TriggerServerEvent('qb-mdt:server:panic', coords)
end)

my_webui:RegisterEventHandler('mdt:setWaypoint', function(data)
    -- Payload arrives JSON-stringified: nested JS objects don't survive hEvent
    -- JS->Lua (coords came through as nil), same workaround as the rpc bridge.
    if type(data) ~= 'table' or type(data.payload) ~= 'string' then return end
    local ok, parsed = pcall(JSON.parse, data.payload)
    if not ok or type(parsed) ~= 'table' or type(parsed.coords) ~= 'table' then return end
    -- Waypoint support: route through qb-hud marker until a native waypoint API is wired
    exports['qb-hud']:AddMarker(Vector(parsed.coords.x, parsed.coords.y, parsed.coords.z), {
        title = parsed.title or 'Dispatch Call',
        icon = 'police',
        markerType = 'Alert', -- 'Dispatch' is not a known HMap marker type
    })
end)

-- ─────────────────────────── server -> UI push events ───────────────────────

local function forward(event, uiEvent, notifyText, notifyType)
    RegisterClientEvent(event, function(payload)
        my_webui:SendEvent(uiEvent, payload or {})
        if notifyText and not isOpen then
            TriggerLocalClientEvent('QBCore:Notify', notifyText, notifyType or 'primary')
        end
    end)
end

forward('qb-mdt:client:newCall', 'mdt:newCall', 'New dispatch call received', 'primary')
forward('qb-mdt:client:callUpdated', 'mdt:callUpdated')
forward('qb-mdt:client:unitsUpdated', 'mdt:unitsUpdated')
forward('qb-mdt:client:warrantIssued', 'mdt:warrantIssued', 'New warrant issued', 'primary')
forward('qb-mdt:client:boloIssued', 'mdt:boloIssued', 'New BOLO issued', 'primary')
forward('qb-mdt:client:panic', 'mdt:panic', 'PANIC BUTTON ACTIVATED', 'error')
forward('qb-mdt:client:refresh', 'mdt:refresh')

-- ─────────────────────────── lifecycle ──────────────────────────────────────

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    CloseMDT()
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function()
    if isOpen and not HasAccess() then
        CloseMDT()
    end
end)
