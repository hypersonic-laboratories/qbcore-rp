-- qb-mdt dispatch: calls, unit status, panic. Exposes CreateCall for other resources.

local function safeParse(text, fallback)
    if type(text) ~= 'string' or text == '' then return fallback end
    local ok, result = pcall(JSON.parse, text)
    if ok and result ~= nil then return result end
    return fallback
end

local function hydrateCall(row)
    row.units = safeParse(row.units, {})
    row.coords = safeParse(row.coords, nil)
    return row
end

local function closeStaleCalls()
    MDT.Execute(
        ("UPDATE mdt_calls SET status = 'closed', updated = CURRENT_TIMESTAMP WHERE status != 'closed' AND datetime(created) <= datetime('now', '-%d hours')"):format(Config.CallRetentionHours)
    )
end

-- ─────────────────────────── call creation ──────────────────────────────────

--- Create a dispatch call. data = { role='police'|'ems'|'all', code, title, details, coords={x,y,z}, priority, anonymous }
--- Exported so qb-phone (911), qb-policejob alerts, etc. can feed the MDT.
local function CreateCall(data)
    if type(data) ~= 'table' or type(data.title) ~= 'string' or data.title == '' then return nil end

    local role = data.role
    if role ~= 'police' and role ~= 'ems' and role ~= 'all' then role = 'police' end
    local priority = math.min(3, math.max(1, tonumber(data.priority) or 2))
    -- Param arrays must never contain nil: a hole truncates the Lua array, HELIX
    -- binds too few placeholders and the INSERT dies inside DatabaseAction's pcall
    -- with no error. Bind '' instead — hydrateCall's safeParse('') coerces it
    -- back to nil on every read.
    local coords = type(data.coords) == 'table' and JSON.stringify(data.coords) or ''

    MDT.Execute(
        'INSERT INTO mdt_calls (role, code, title, details, coords, priority, anonymous) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { role, tostring(data.code or ''), data.title, tostring(data.details or ''), coords, priority, data.anonymous and 1 or 0 }
    )

    -- Don't trust last_insert_rowid(): when an INSERT fails it returns the id of
    -- an EARLIER insert (stale rowid), so the caller can't tell success from
    -- failure. Re-read the row we just inserted by matching its columns — if the
    -- INSERT didn't land, this finds nothing and we correctly report failure.
    local rows = MDT.Select(
        'SELECT * FROM mdt_calls WHERE role = ? AND title = ? AND priority = ? ORDER BY id DESC LIMIT 1',
        { role, data.title, priority }
    )
    local call = rows and rows[1] and hydrateCall(rows[1]) or nil
    if not call then return nil end

    MDT.BroadcastRole(role, 'qb-mdt:client:newCall', call)
    return tonumber(call.id)
end
exports('qb-mdt', 'CreateCall', CreateCall)

-- 911 entry point for qb-phone or command bridges
RegisterServerEvent('qb-mdt:server:911', function(source, message, coords, anonymous)
    if type(message) ~= 'string' or message == '' then return end
    local caller = exports['qb-core']:GetPlayer(source)
    local callerName = 'Anonymous'
    if caller and not anonymous then
        local info = caller.PlayerData.charinfo or {}
        callerName = ((info.firstname or '') .. ' ' .. (info.lastname or ''))
    end
    CreateCall({
        role = 'police',
        code = '911',
        title = '911 Call - ' .. callerName,
        details = message,
        coords = coords and { x = coords.X or coords.x, y = coords.Y or coords.y, z = coords.Z or coords.z } or nil,
        priority = 1,
        anonymous = anonymous,
    })
end)

-- ─────────────────────────── call management ────────────────────────────────

MDT.RegisterRpc('getCalls', function(source)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    closeStaleCalls()
    local rows = MDT.Select(
        "SELECT * FROM mdt_calls WHERE status != 'closed' AND (role = ? OR role = 'all') ORDER BY priority ASC, created DESC LIMIT 50",
        { role }
    ) or {}
    for i = 1, #rows do hydrateCall(rows[i]) end
    return { ok = true, calls = rows, units = MDT.GetUnits(role) }
end)

MDT.RegisterRpc('createCall', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    if type(data) ~= 'table' then return { ok = false } end

    data.role = role -- manual dispatch entries stay within the caller's department
    local id = CreateCall(data)
    if not id then return { ok = false, message = 'Title is required' } end
    MDT.Log(role, Player, 'call:create', data.title)
    return { ok = true, id = id }
end)

local function updateCallUnits(callId, role, mutate)
    local rows = MDT.Select("SELECT * FROM mdt_calls WHERE id = ? AND (role = ? OR role = 'all')", { callId, role })
    local call = rows and rows[1]
    if not call then return nil end
    hydrateCall(call)

    mutate(call)

    MDT.Execute(
        'UPDATE mdt_calls SET units = ?, status = ?, updated = CURRENT_TIMESTAMP WHERE id = ?',
        { JSON.stringify(call.units), call.status, callId }
    )
    MDT.BroadcastRole(call.role, 'qb-mdt:client:callUpdated', call)
    return call
end

--- Everyone currently connected to the same unit slot as `unit` (including
--- itself). Officers without a unit operate alone.
local function unitCrew(unit, role)
    if not unit.callsign or unit.callsign == 'NO CALLSIGN' then return { unit } end
    local crew = {}
    for _, u in pairs(MDT.Units) do
        if u.role == role and u.callsign == unit.callsign then crew[#crew + 1] = u end
    end
    return crew
end

-- A unit rides together: attaching/detaching one member moves the whole crew.
MDT.RegisterRpc('attachToCall', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    local callId = tonumber(data and data.id)
    if not callId then return { ok = false } end

    local unit = MDT.RegisterUnit(source, Player, role)
    local crew = unitCrew(unit, role)
    local call = updateCallUnits(callId, role, function(call)
        for _, m in ipairs(crew) do
            local attached = false
            for _, u in ipairs(call.units) do
                if u.citizenid == m.citizenid then attached = true break end
            end
            if not attached then
                call.units[#call.units + 1] = { citizenid = m.citizenid, name = m.name, callsign = m.callsign }
            end
        end
        call.status = 'active'
    end)
    if not call then return { ok = false, message = 'Call not found' } end

    for _, m in ipairs(crew) do m.status = 'enroute' end
    MDT.BroadcastRole(role, 'qb-mdt:client:unitsUpdated', MDT.GetUnits(role))
    return { ok = true, call = call }
end)

MDT.RegisterRpc('detachFromCall', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    local callId = tonumber(data and data.id)
    if not callId then return { ok = false } end

    local unit = MDT.RegisterUnit(source, Player, role)
    local crew = unitCrew(unit, role)
    local crewIds = {}
    for _, m in ipairs(crew) do crewIds[m.citizenid] = true end

    local call = updateCallUnits(callId, role, function(call)
        for i = #call.units, 1, -1 do
            if crewIds[call.units[i].citizenid] then
                table.remove(call.units, i)
            end
        end
        if #call.units == 0 then call.status = 'pending' end
    end)
    if not call then return { ok = false, message = 'Call not found' } end

    for _, m in ipairs(crew) do m.status = 'available' end
    MDT.BroadcastRole(role, 'qb-mdt:client:unitsUpdated', MDT.GetUnits(role))
    return { ok = true, call = call }
end)

MDT.RegisterRpc('closeCall', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    local callId = tonumber(data and data.id)
    if not callId then return { ok = false } end

    local call = updateCallUnits(callId, role, function(call)
        call.status = 'closed'
    end)
    if not call then return { ok = false, message = 'Call not found' } end
    MDT.Log(role, Player, 'call:close', tostring(callId))
    return { ok = true }
end)

-- ─────────────────────────── units & panic ──────────────────────────────────

--- Config unit entry for a role by id, or nil.
local function findUnit(role, unitId)
    for _, u in ipairs(Config.Units[role] or {}) do
        if u.id == unitId then return u end
    end
    return nil
end

--- Unit slots for a role with current occupants (from live MDT.Units).
function MDT.UnitBoard(role)
    local occupants = {}
    for _, unit in pairs(MDT.Units) do
        if unit.role == role and unit.callsign and unit.callsign ~= 'NO CALLSIGN' then
            occupants[unit.callsign] = occupants[unit.callsign] or {}
            local list = occupants[unit.callsign]
            list[#list + 1] = { citizenid = unit.citizenid, name = unit.name }
        end
    end
    local board = {}
    for _, u in ipairs(Config.Units[role] or {}) do
        board[#board + 1] = { id = u.id, channel = u.channel, freq = u.freq, occupants = occupants[u.id] or {} }
    end
    return board
end

--- Join a unit slot: set callsign metadata + move to the unit's voice channel.
MDT.RegisterRpc('joinUnit', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local cfg = findUnit(role, data and data.unit)
    if not cfg then return { ok = false, message = 'Unknown unit' } end

    -- Switching units: tear down old channel + pair-mutes first
    local cid = Player.PlayerData.citizenid
    local prev = MDT.Units[cid]
    if prev and prev.channel and prev.channel ~= cfg.channel then
        MDT.ClearUnitVoice(prev)
    end
    if not source:IsInVoiceChannel(cfg.channel) then
        source:JoinVoiceChannel(cfg.channel)
    end

    Player:SetMetaData('callsign', cfg.id)
    local unit = MDT.RegisterUnit(source, Player, role)
    unit.callsign = cfg.id
    unit.channel = cfg.channel
    unit.freq = cfg.freq
    unit.pttHeld = false

    MDT.RefreshCrewMutes(role, cfg.id) -- new member changes everyone's mute matrix
    MDT.Log(role, Player, 'unit:join', cfg.id)
    MDT.BroadcastRole(role, 'qb-mdt:client:unitsUpdated', MDT.GetUnits(role))
    return { ok = true, unit = cfg.id, channel = cfg.channel, freq = cfg.freq, unitBoard = MDT.UnitBoard(role) }
end)

--- Leave the current unit: drop the voice channel, clear the callsign.
MDT.RegisterRpc('leaveUnit', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local cid = Player.PlayerData.citizenid
    local prev = MDT.Units[cid]
    if prev and prev.channel then
        MDT.ClearUnitVoice(prev) -- leaves the channel + clears pair-mutes both ways
    end

    Player:SetMetaData('callsign', 'NO CALLSIGN')
    local unit = MDT.RegisterUnit(source, Player, role)
    unit.callsign = 'NO CALLSIGN'
    unit.channel = nil
    unit.freq = nil
    unit.pttHeld = nil

    MDT.Log(role, Player, 'unit:leave', prev and prev.callsign or '')
    MDT.BroadcastRole(role, 'qb-mdt:client:unitsUpdated', MDT.GetUnits(role))
    return { ok = true, unitBoard = MDT.UnitBoard(role) }
end)

MDT.RegisterRpc('getUnitBoard', function(source)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    return { ok = true, unitBoard = MDT.UnitBoard(role) }
end)

MDT.RegisterRpc('setUnitStatus', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local status = data and data.status
    local valid = false
    for _, s in ipairs(Config.UnitStatuses) do
        if s == status then valid = true break end
    end
    if not valid then return { ok = false } end

    local unit = MDT.RegisterUnit(source, Player, role)
    unit.status = status
    unit.updated = true
    MDT.BroadcastRole(role, 'qb-mdt:client:unitsUpdated', MDT.GetUnits(role))
    return { ok = true }
end)

MDT.RegisterRpc('getUnits', function(source)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    return { ok = true, units = MDT.GetUnits(role) }
end)

-- PTT (CapsLock hold, see client). v1 is an INDICATOR layer: the unit channel
-- itself is open-mic while connected; this relays who is keying up so every
-- crew member's HUD shows the transmitting card. True voice gating needs a
-- HELIX self-mute-per-channel API — test in game, see HANDOFF.
-- ── voice gating ─────────────────────────────────────────────────────────────
-- Crew stay in the unit channel permanently (radio is ALWAYS audible). The
-- SPEAK side is gated per-listener with SetMutedForPlayerState (same API as
-- qb-apartments instancing): your voice is muted for crew members beyond
-- Config.UnitProxRangeCm unless you hold PTT. Result:
--   normal talk / V  -> proximity only (far crew can't hear you at all)
--   PTT (CapsLock)   -> unmuted for the whole crew -> proximity + radio
-- Near crew are never muted, so proximity always works between partners.

--- Re-apply my mute state toward every crew member. keyed = PTT held.
local function refreshSpeakerMutes(speaker, role, keyed)
    if not speaker.channel then return end
    local talker
    pcall(function() talker = speaker.source:GetVoiceTalker() end)
    if not talker then return end

    local sPos
    pcall(function()
        local pawn = GetPlayerPawn(speaker.source)
        if pawn then sPos = GetEntityCoords(pawn) end
    end)

    for _, m in pairs(MDT.Units) do
        if m.citizenid ~= speaker.citizenid and m.role == role and m.callsign == speaker.callsign then
            local mute = false
            if not keyed then
                local lPos
                pcall(function()
                    local pawn = GetPlayerPawn(m.source)
                    if pawn then lPos = GetEntityCoords(pawn) end
                end)
                if sPos and lPos then
                    local dx, dy, dz = sPos.X - lPos.X, sPos.Y - lPos.Y, sPos.Z - lPos.Z
                    mute = (dx * dx + dy * dy + dz * dz) > (Config.UnitProxRangeCm * Config.UnitProxRangeCm)
                else
                    mute = true -- unknown positions: fail toward radio silence
                end
            end
            pcall(function()
                local ps = m.source.PlayerState
                if ps then talker:SetMutedForPlayerState(mute, ps) end
            end)
        end
    end
end

--- Full voice teardown for a unit member: leave the channel and clear every
--- pair-mute in BOTH directions. Used by leaveUnit, unit switch, and the
--- off-duty prune in main.lua GetUnits.
function MDT.ClearUnitVoice(unit)
    pcall(function()
        if unit.channel and unit.source:IsInVoiceChannel(unit.channel) then
            unit.source:LeaveVoiceChannel(unit.channel)
        end
    end)
    local myTalker, myPS
    pcall(function() myTalker = unit.source:GetVoiceTalker() end)
    pcall(function() myPS = unit.source.PlayerState end)
    for _, o in pairs(MDT.Units) do
        if o.citizenid ~= unit.citizenid and o.role == unit.role and o.callsign == unit.callsign then
            pcall(function()
                if myTalker and o.source.PlayerState then myTalker:SetMutedForPlayerState(false, o.source.PlayerState) end
                local ot = o.source:GetVoiceTalker()
                if ot and myPS then ot:SetMutedForPlayerState(false, myPS) end
            end)
        end
    end
end

--- Refresh the whole crew's mute matrix (after join/leave membership changes).
--- On MDT (not a local) so joinUnit/leaveUnit above can call it at runtime.
function MDT.RefreshCrewMutes(role, callsign)
    for _, m in pairs(MDT.Units) do
        if m.role == role and m.callsign == callsign and m.channel then
            refreshSpeakerMutes(m, role, m.pttHeld and true or false)
        end
    end
end

-- Positions drift, so re-evaluate distances on a slow loop.
Timer.SetInterval(function()
    for _, unit in pairs(MDT.Units) do
        if unit.channel then
            refreshSpeakerMutes(unit, unit.role, unit.pttHeld and true or false)
        end
    end
end, 4000)

RegisterServerEvent('qb-mdt:server:ptt', function(source, talking, voice)
    local Player, role = MDT.GetContext(source)
    if not Player then return end

    local unit = MDT.Units[Player.PlayerData.citizenid]
    if not unit or not unit.channel then return end -- not connected to a unit

    unit.pttHeld = talking and true or false
    refreshSpeakerMutes(unit, role, unit.pttHeld)

    for _, m in pairs(MDT.Units) do
        if m.role == role and m.callsign == unit.callsign then
            local Target = exports['qb-core']:GetPlayer(m.source)
            if Target then
                TriggerClientEvent(Target.PlayerData.source, 'qb-mdt:client:ptt', {
                    talking = talking and true or false,
                    voice = voice and true or false, -- engine mic activity (animates waveform)
                    unit = unit.callsign,
                    freq = unit.freq,
                    name = unit.name,
                    grade = unit.grade,
                    self = m.citizenid == unit.citizenid,
                })
            end
        end
    end
end)

RegisterServerEvent('qb-mdt:server:panic', function(source, coords)
    local ok, err = pcall(function()
        local Player, role = MDT.GetContext(source)
        if not Player then return end

        local unit = MDT.RegisterUnit(source, Player, role)
        local payload = {
            citizenid = unit.citizenid,
            name = unit.name,
            callsign = unit.callsign,
            coords = coords and { x = coords.X or coords.x, y = coords.Y or coords.y, z = coords.Z or coords.z } or nil,
        }

        CreateCall({
            role = role,
            code = 'PANIC',
            title = ('PANIC - %s (%s)'):format(unit.callsign, unit.name),
            details = 'Officer needs immediate assistance',
            coords = payload.coords,
            priority = 1,
        })
        MDT.BroadcastRole(role, 'qb-mdt:client:panic', payload)
        MDT.Log(role, Player, 'panic', unit.callsign)
    end)
    if not ok then print('[qb-mdt] panic error -> ' .. tostring(err)) end
end)

