-- qb-mdt records: warrants + BOLOs

-- ─────────────────────────── warrants ───────────────────────────────────────

function MDT.ExpireWarrants()
    MDT.Execute(
        "UPDATE mdt_warrants SET status = 'expired' WHERE status = 'active' AND expires_at IS NOT NULL AND datetime(expires_at) <= datetime('now')"
    )
end

MDT.RegisterRpc('getWarrants', function(source)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'police' then return { ok = false } end

    MDT.ExpireWarrants()
    local rows = MDT.Select(
        "SELECT * FROM mdt_warrants WHERE status = 'active' ORDER BY created DESC LIMIT 100"
    )
    return { ok = true, warrants = rows or {} }
end)

MDT.RegisterRpc('createWarrant', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'police' then return { ok = false } end
    if type(data) ~= 'table' or type(data.citizenid) ~= 'string' or data.citizenid == ''
        or type(data.reason) ~= 'string' or data.reason == '' then
        return { ok = false, message = 'Citizen and reason are required' }
    end

    local days = tonumber(data.expiresDays)
    if days and days > 0 then
        MDT.Execute(
            "INSERT INTO mdt_warrants (citizenid, incident_id, reason, author_cid, author_name, expires_at) VALUES (?, ?, ?, ?, ?, datetime('now', '+' || ? || ' days'))",
            { data.citizenid, tonumber(data.incidentId), data.reason, Player.PlayerData.citizenid, MDT.CharName(Player), math.floor(days) }
        )
    else
        MDT.Execute(
            'INSERT INTO mdt_warrants (citizenid, incident_id, reason, author_cid, author_name) VALUES (?, ?, ?, ?, ?)',
            { data.citizenid, tonumber(data.incidentId), data.reason, Player.PlayerData.citizenid, MDT.CharName(Player) }
        )
    end

    local id = MDT.LastInsertId()
    MDT.Log(role, Player, 'warrant:create', ('%s (%s)'):format(data.citizenid, data.reason))
    MDT.BroadcastRole('police', 'qb-mdt:client:warrantIssued', { id = id, citizenid = data.citizenid, reason = data.reason })
    return { ok = true, id = id }
end)

MDT.RegisterRpc('updateWarrant', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'police' then return { ok = false } end

    local id = tonumber(data and data.id)
    local status = data and data.status
    if not id or (status ~= 'served' and status ~= 'cancelled') then return { ok = false } end

    if status == 'cancelled' and not MDT.IsSupervisor(Player) then
        return { ok = false, message = 'Supervisor access required to cancel a warrant' }
    end

    MDT.Execute("UPDATE mdt_warrants SET status = ? WHERE id = ? AND status = 'active'", { status, id })
    MDT.Log(role, Player, 'warrant:' .. status, tostring(id))
    return { ok = true }
end)

--- True when the citizen has an active warrant. Usable from other resources.
local function IsWarranted(citizenid)
    MDT.ExpireWarrants()
    local rows = MDT.Select(
        "SELECT id FROM mdt_warrants WHERE citizenid = ? AND status = 'active' LIMIT 1",
        { citizenid }
    )
    return rows ~= nil and rows[1] ~= nil
end
exports('qb-mdt', 'IsWarranted', IsWarranted)

-- ─────────────────────────── BOLOs ──────────────────────────────────────────

MDT.RegisterRpc('getBolos', function(source)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local rows = MDT.Select(
        "SELECT * FROM mdt_bolos WHERE role = ? AND status = 'active' ORDER BY priority ASC, created DESC LIMIT 100",
        { role }
    )
    return { ok = true, bolos = rows or {} }
end)

MDT.RegisterRpc('createBolo', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    if type(data) ~= 'table' or type(data.title) ~= 'string' or data.title == '' then
        return { ok = false, message = 'Title is required' }
    end
    local boloType = data.bolo_type
    if boloType ~= 'person' and boloType ~= 'vehicle' then
        return { ok = false, message = 'Invalid BOLO type' }
    end

    local identifier = tostring(data.identifier or '')
    if boloType == 'vehicle' then identifier = identifier:upper() end
    local priority = math.min(3, math.max(1, tonumber(data.priority) or 2))

    MDT.Execute(
        'INSERT INTO mdt_bolos (role, bolo_type, identifier, title, description, priority, image, author_cid, author_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { role, boloType, identifier, data.title, tostring(data.description or ''), priority, tostring(data.image or ''), Player.PlayerData.citizenid, MDT.CharName(Player) }
    )
    local id = MDT.LastInsertId()

    MDT.Log(role, Player, 'bolo:create', data.title)
    MDT.BroadcastRole(role, 'qb-mdt:client:boloIssued', { id = id, title = data.title, priority = priority })
    return { ok = true, id = id }
end)

MDT.RegisterRpc('resolveBolo', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local id = tonumber(data and data.id)
    if not id then return { ok = false } end

    MDT.Execute("UPDATE mdt_bolos SET status = 'resolved' WHERE id = ? AND role = ?", { id, role })
    MDT.Log(role, Player, 'bolo:resolve', tostring(id))
    MDT.BroadcastRole(role, 'qb-mdt:client:refresh', { view = 'bolos' })
    return { ok = true }
end)

--- Active vehicle BOLO for a plate (e.g. for ANPR integration). Returns row or nil.
local function GetVehicleBolo(plate)
    if type(plate) ~= 'string' or plate == '' then return nil end
    local rows = MDT.Select(
        "SELECT * FROM mdt_bolos WHERE status = 'active' AND bolo_type = 'vehicle' AND UPPER(identifier) = ? LIMIT 1",
        { plate:upper() }
    )
    return rows and rows[1] or nil
end
exports('qb-mdt', 'GetVehicleBolo', GetVehicleBolo)

