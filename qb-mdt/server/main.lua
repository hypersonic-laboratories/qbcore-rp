-- qb-mdt server core: auth, helpers, shell data (dashboard / bulletins / logs)

MDT = {}
MDT.Units = {} -- [citizenid] = { source, citizenid, name, callsign, role, status, updated }

-- ─────────────────────────── RPC dispatcher ─────────────────────────────────
-- All request/response rides the engine callback system through ONE callback.
-- The name must be a plain identifier: the engine silently drops callbacks
-- whose name contains a colon (server handler never runs, no error).
local RpcHandlers = {}

--- Register an RPC handler. name is the short action ('open','search',...).
--- fn(source, payload) -> result table (returned to the caller).
function MDT.RegisterRpc(name, fn)
    RpcHandlers[name] = fn
end

RegisterCallback('mdtRpc', function(source, data)
    local name = type(data) == 'table' and data.action or nil
    local fn = name and RpcHandlers[name]
    if not fn then
        return { ok = false, error = 'no handler: ' .. tostring(name) }
    end
    -- Payload arrives JSON-stringified from the WebUI (see qb-mdt/html/app.js rpc()).
    local payload = data.payload
    if type(payload) == 'string' and payload ~= '' then
        local okParse, decoded = pcall(JSON.parse, payload)
        payload = (okParse and decoded) or {}
    elseif type(payload) ~= 'table' then
        payload = {}
    end
    local ok, result = pcall(fn, source, payload)
    if not ok then
        print('[qb-mdt] RPC handler error [' .. tostring(name) .. '] -> ' .. tostring(result))
        return { ok = false, error = tostring(result) }
    end
    return result or { ok = false }
end)

-- ─────────────────────────── helpers ────────────────────────────────────────

function MDT.Select(sql, params)
    return exports['qb-core']:DatabaseAction('Select', sql, params)
end

function MDT.Execute(sql, params)
    return exports['qb-core']:DatabaseAction('Execute', sql, params)
end

function MDT.LastInsertId()
    local rows = MDT.Select('SELECT last_insert_rowid() AS id')
    return rows and rows[1] and tonumber(rows[1].id) or nil
end

--- Validates the caller and resolves their MDT role.
--- @return table|nil Player, string|nil role
function MDT.GetContext(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return nil, nil end

    local job = Player.PlayerData.job
    local role = job and job.type and Config.Roles[job.type] or nil
    if not role then return nil, nil end
    if Config.RequireOnDuty and not job.onduty then return nil, nil end

    return Player, role
end

function MDT.IsSupervisor(Player)
    local job = Player.PlayerData.job
    if not job then return false end
    if job.isboss then return true end
    local level = job.grade and job.grade.level or 0
    return level >= Config.SupervisorGrade
end

function MDT.CharName(Player)
    local info = Player.PlayerData.charinfo or {}
    local first = info.firstname or ''
    local last = info.lastname or ''
    local name = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
    return name ~= '' and name or Player.PlayerData.name
end

function MDT.Log(role, Player, action, details)
    MDT.Execute(
        'INSERT INTO mdt_logs (role, actor_cid, actor_name, action, details) VALUES (?, ?, ?, ?, ?)',
        { role, Player.PlayerData.citizenid, MDT.CharName(Player), action, details or '' }
    )
end

--- Broadcast an event to every on-duty player of a role ('all' hits every role).
function MDT.BroadcastRole(role, event, payload)
    local players = exports['qb-core']:GetQBPlayers()
    for _, p in pairs(players) do
        local job = p.PlayerData.job
        local pRole = job and job.type and Config.Roles[job.type] or nil
        if pRole and job.onduty and (role == 'all' or pRole == role) then
            TriggerClientEvent(p.PlayerData.source, event, payload)
        end
    end
end

function MDT.GetOnlineByCitizenId(citizenid)
    local players = exports['qb-core']:GetQBPlayers()
    for _, p in pairs(players) do
        if p.PlayerData.citizenid == citizenid then
            -- GetQBPlayers entries lack the money methods; refetch the full player.
            return exports['qb-core']:GetPlayer(p.PlayerData.source) or p
        end
    end
    return nil
end

-- Officer/unit descriptor for the caller
local function unitDescriptor(Player, role)
    local job = Player.PlayerData.job
    local metadata = Player.PlayerData.metadata or {}
    return {
        citizenid = Player.PlayerData.citizenid,
        name = MDT.CharName(Player),
        callsign = metadata.callsign or 'NO CALLSIGN',
        role = role,
        job = job.label,
        grade = job.grade and job.grade.name or '',
        gradeLevel = job.grade and job.grade.level or 0,
        supervisor = MDT.IsSupervisor(Player),
    }
end

function MDT.RegisterUnit(source, Player, role)
    local unit = unitDescriptor(Player, role)
    local prev = MDT.Units[unit.citizenid]
    unit.source = source
    unit.status = prev and prev.status or 'available'
    unit.channel = prev and prev.channel or nil -- unit voice channel (see dispatch.lua joinUnit)
    unit.freq = prev and prev.freq or nil
    unit.pttHeld = prev and prev.pttHeld or nil
    -- MDT.Units is authoritative for the callsign: the SetMetaData write in
    -- joinUnit doesn't survive the qb-core export boundary in game, so a fresh
    -- descriptor (built from metadata) would silently revert to NO CALLSIGN.
    if prev and prev.callsign then unit.callsign = prev.callsign end
    MDT.Units[unit.citizenid] = unit
    return unit
end

--- Prune units whose player is gone or off duty, return role-filtered list.
function MDT.GetUnits(role)
    local out = {}
    for cid, unit in pairs(MDT.Units) do
        local Player = exports['qb-core']:GetPlayer(unit.source)
        if not Player or Player.PlayerData.citizenid ~= cid or not Player.PlayerData.job.onduty then
            -- Off duty / character switch: drop the unit voice channel AND the
            -- pair-mutes, or the player keeps hearing unit radio / stays muted
            -- for ex-crew. (ClearUnitVoice pcalls around stale sources.)
            if unit.channel and MDT.ClearUnitVoice then
                MDT.ClearUnitVoice(unit)
            end
            MDT.Units[cid] = nil
        elseif role == 'all' or unit.role == role then
            out[#out + 1] = {
                citizenid = unit.citizenid,
                name = unit.name,
                callsign = unit.callsign,
                role = unit.role,
                grade = unit.grade,
                status = unit.status,
            }
        end
    end
    return out
end

-- ─────────────────────────── shell callbacks ────────────────────────────────

MDT.RegisterRpc('open', function(source)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local me = MDT.RegisterUnit(source, Player, role)

    local bulletins = MDT.Select(
        'SELECT * FROM mdt_bulletins WHERE role = ? ORDER BY created DESC LIMIT 20',
        { role }
    )

    return {
        ok = true,
        role = role,
        -- Copy from the registered unit (authoritative callsign), not a fresh
        -- descriptor; strip .source — the HELIX player object won't serialize.
        officer = {
            citizenid = me.citizenid, name = me.name, callsign = me.callsign,
            role = me.role, job = me.job, grade = me.grade,
            gradeLevel = me.gradeLevel, supervisor = me.supervisor,
        },
        bulletins = bulletins or {},
        units = MDT.GetUnits(role),
        unitBoard = MDT.UnitBoard(role),
        penalCode = role == 'police' and Config.PenalCode or nil,
        priorities = Config.CallPriorities,
        statuses = Config.UnitStatuses,
    }
end)

MDT.RegisterRpc('addBulletin', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    if type(data) ~= 'table' or type(data.title) ~= 'string' or data.title == '' then return { ok = false } end

    MDT.Execute(
        'INSERT INTO mdt_bulletins (role, title, content, author_cid, author_name) VALUES (?, ?, ?, ?, ?)',
        { role, data.title, data.content or '', Player.PlayerData.citizenid, MDT.CharName(Player) }
    )
    MDT.Log(role, Player, 'bulletin:add', data.title)
    MDT.BroadcastRole(role, 'qb-mdt:client:refresh', { view = 'bulletins' })
    return { ok = true, id = MDT.LastInsertId() }
end)

MDT.RegisterRpc('deleteBulletin', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    local id = tonumber(data and data.id)
    if not id then return { ok = false } end

    local rows = MDT.Select('SELECT author_cid FROM mdt_bulletins WHERE id = ?', { id })
    local bulletin = rows and rows[1]
    if not bulletin then return { ok = false } end
    if bulletin.author_cid ~= Player.PlayerData.citizenid and not MDT.IsSupervisor(Player) then
        return { ok = false, message = 'Insufficient permissions' }
    end

    MDT.Execute('DELETE FROM mdt_bulletins WHERE id = ?', { id })
    MDT.Log(role, Player, 'bulletin:delete', tostring(id))
    MDT.BroadcastRole(role, 'qb-mdt:client:refresh', { view = 'bulletins' })
    return { ok = true }
end)

MDT.RegisterRpc('getLogs', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or not MDT.IsSupervisor(Player) then return { ok = false } end

    local page = math.max(1, tonumber(data and data.page) or 1)
    local offset = (page - 1) * Config.PageSize
    local rows = MDT.Select(
        'SELECT * FROM mdt_logs WHERE role = ? ORDER BY created DESC LIMIT ? OFFSET ?',
        { role, Config.PageSize, offset }
    )
    return { ok = true, logs = rows or {}, page = page }
end)

