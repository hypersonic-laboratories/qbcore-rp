-- qb-mdt incidents: report CRUD, links, arrest processing (charges -> conviction)

local ChargesByCode = {}
for _, category in ipairs(Config.PenalCode) do
    for _, charge in ipairs(category.charges) do
        ChargesByCode[charge.code] = charge
    end
end

local LinkTypes = { citizen = true, vehicle = true, evidence = true, officer = true }

local function safeParse(text, fallback)
    if type(text) ~= 'string' or text == '' then return fallback end
    local ok, result = pcall(JSON.parse, text)
    if ok and result ~= nil then return result end
    return fallback
end

-- ─────────────────────────── incident CRUD ──────────────────────────────────

MDT.RegisterRpc('getIncidents', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local page = math.max(1, tonumber(data and data.page) or 1)
    local offset = (page - 1) * Config.PageSize
    local query = type(data) == 'table' and tostring(data.query or '') or ''

    local rows
    if query ~= '' then
        rows = MDT.Select(
            'SELECT id, title, author_name, created, updated FROM mdt_incidents WHERE role = ? AND title LIKE ? ORDER BY created DESC LIMIT ? OFFSET ?',
            { role, '%' .. query .. '%', Config.PageSize, offset }
        )
    else
        rows = MDT.Select(
            'SELECT id, title, author_name, created, updated FROM mdt_incidents WHERE role = ? ORDER BY created DESC LIMIT ? OFFSET ?',
            { role, Config.PageSize, offset }
        )
    end

    return { ok = true, incidents = rows or {}, page = page }
end)

MDT.RegisterRpc('getIncident', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local id = tonumber(data and data.id)
    if not id then return { ok = false } end

    local rows = MDT.Select('SELECT * FROM mdt_incidents WHERE id = ? AND role = ?', { id, role })
    local incident = rows and rows[1]
    if not incident then return { ok = false, message = 'Incident not found' } end

    incident.links = MDT.Select('SELECT link_type, identifier, label FROM mdt_incident_links WHERE incident_id = ?', { id }) or {}

    local convictions = MDT.Select('SELECT * FROM mdt_convictions WHERE incident_id = ? ORDER BY created DESC', { id }) or {}
    for i = 1, #convictions do
        convictions[i].charges = safeParse(convictions[i].charges, {})
    end
    incident.convictions = convictions

    return { ok = true, incident = incident }
end)

MDT.RegisterRpc('saveIncident', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    if type(data) ~= 'table' or type(data.title) ~= 'string' or data.title == '' then
        return { ok = false, message = 'Title is required' }
    end

    local id = tonumber(data.id)
    local details = tostring(data.details or '')

    if id then
        local rows = MDT.Select('SELECT author_cid FROM mdt_incidents WHERE id = ? AND role = ?', { id, role })
        local incident = rows and rows[1]
        if not incident then return { ok = false, message = 'Incident not found' } end
        if incident.author_cid ~= Player.PlayerData.citizenid and not MDT.IsSupervisor(Player) then
            return { ok = false, message = 'Only the author or a supervisor can edit this report' }
        end
        MDT.Execute(
            'UPDATE mdt_incidents SET title = ?, details = ?, updated = CURRENT_TIMESTAMP WHERE id = ?',
            { data.title, details, id }
        )
        MDT.Log(role, Player, 'incident:update', tostring(id))
    else
        MDT.Execute(
            'INSERT INTO mdt_incidents (role, title, details, author_cid, author_name) VALUES (?, ?, ?, ?, ?)',
            { role, data.title, details, Player.PlayerData.citizenid, MDT.CharName(Player) }
        )
        -- last_insert_rowid() (via MDT.LastInsertId) is unreliable in HELIX: Select
        -- can run on a different handle than Execute, so it returns nil/0 in game.
        -- The links below and the returned id both depend on this, so re-read the
        -- inserted row by newest match instead of trusting the rowid.
        local newRows = MDT.Select(
            'SELECT id FROM mdt_incidents WHERE role = ? AND title = ? AND author_cid = ? ORDER BY id DESC LIMIT 1',
            { role, data.title, Player.PlayerData.citizenid }
        )
        id = newRows and newRows[1] and tonumber(newRows[1].id) or nil
        if not id then return { ok = false, message = 'Failed to save report' } end
        MDT.Log(role, Player, 'incident:create', tostring(id))
    end

    -- Replace links with the submitted set
    if type(data.links) == 'table' then
        MDT.Execute('DELETE FROM mdt_incident_links WHERE incident_id = ?', { id })
        for _, link in ipairs(data.links) do
            if type(link) == 'table' and LinkTypes[link.link_type] and type(link.identifier) == 'string' and link.identifier ~= '' then
                MDT.Execute(
                    'INSERT INTO mdt_incident_links (incident_id, link_type, identifier, label) VALUES (?, ?, ?, ?)',
                    { id, link.link_type, link.identifier, tostring(link.label or '') }
                )
            end
        end
    end

    return { ok = true, id = id }
end)

MDT.RegisterRpc('deleteIncident', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or not MDT.IsSupervisor(Player) then
        return { ok = false, message = 'Supervisor access required' }
    end

    local id = tonumber(data and data.id)
    if not id then return { ok = false } end

    MDT.Execute('DELETE FROM mdt_incident_links WHERE incident_id = ?', { id })
    MDT.Execute('DELETE FROM mdt_incidents WHERE id = ? AND role = ?', { id, role })
    MDT.Log(role, Player, 'incident:delete', tostring(id))
    return { ok = true }
end)

-- ─────────────────────────── arrest processing ──────────────────────────────

MDT.RegisterRpc('processArrest', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'police' then return { ok = false } end
    if type(data) ~= 'table' or type(data.citizenid) ~= 'string' or data.citizenid == '' then return { ok = false } end
    if type(data.charges) ~= 'table' or #data.charges == 0 then
        return { ok = false, message = 'At least one charge is required' }
    end

    -- Resolve charges against the penal code (server-side truth)
    local charges, totalFine, totalSentence = {}, 0, 0
    for _, code in ipairs(data.charges) do
        local charge = ChargesByCode[code]
        if not charge then
            return { ok = false, message = 'Unknown charge code: ' .. tostring(code) }
        end
        charges[#charges + 1] = { code = charge.code, label = charge.label, class = charge.class, fine = charge.fine, sentence = charge.sentence }
        totalFine = totalFine + charge.fine
        totalSentence = totalSentence + charge.sentence
    end

    local citizenid = data.citizenid
    local incidentId = tonumber(data.incidentId)

    MDT.Execute(
        'INSERT INTO mdt_convictions (citizenid, incident_id, charges, fine, sentence, officer_cid, officer_name) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { citizenid, incidentId, JSON.stringify(charges), totalFine, totalSentence, Player.PlayerData.citizenid, MDT.CharName(Player) }
    )
    -- last_insert_rowid() is unreliable in HELIX (see saveIncident). The jail
    -- bridge below carries convictionId, so re-read the newest matching row.
    local convRows = MDT.Select(
        'SELECT id FROM mdt_convictions WHERE citizenid = ? AND officer_cid = ? ORDER BY id DESC LIMIT 1',
        { citizenid, Player.PlayerData.citizenid }
    )
    local convictionId = convRows and convRows[1] and tonumber(convRows[1].id) or nil

    -- Collect the fine: online player straight from bank, offline via stored money JSON
    local Target = MDT.GetOnlineByCitizenId(citizenid)
    if Target then
        if totalFine > 0 then
            Target.RemoveMoney('bank', totalFine, 'mdt-fine')
        end
        TriggerClientEvent(Target.PlayerData.source, 'QBCore:Notify',
            ('You were convicted: $%s fine, %s months'):format(totalFine, totalSentence), 'error')
    elseif totalFine > 0 then
        local rows = MDT.Select('SELECT money FROM players WHERE citizenid = ?', { citizenid })
        local money = rows and rows[1] and safeParse(rows[1].money, nil)
        if money and money.bank then
            money.bank = (tonumber(money.bank) or 0) - totalFine
            MDT.Execute('UPDATE players SET money = ? WHERE citizenid = ?', { JSON.stringify(money), citizenid })
        end
    end

    -- Serve any active warrants for this citizen
    MDT.Execute("UPDATE mdt_warrants SET status = 'served' WHERE citizenid = ? AND status = 'active'", { citizenid })

    -- Bridge for other resources (e.g. qb-policejob jail). Guarded: the Events bus
    -- is unused elsewhere in this codebase, so a missing API must not kill the arrest.
    pcall(function()
        Events.Call('qb-mdt:server:convictionProcessed', {
            convictionId = convictionId,
            citizenid = citizenid,
            source = Target and Target.PlayerData.source or nil,
            fine = totalFine,
            sentence = totalSentence,
            charges = charges,
            officer = MDT.CharName(Player),
        })
    end)

    MDT.Log(role, Player, 'arrest:process', ('%s fine=%s sentence=%s'):format(citizenid, totalFine, totalSentence))
    return { ok = true, convictionId = convictionId, fine = totalFine, sentence = totalSentence }
end)

