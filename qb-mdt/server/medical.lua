-- qb-mdt medical records (EMS only)

local function safeParse(text, fallback)
    if type(text) ~= 'string' or text == '' then return fallback end
    local ok, result = pcall(JSON.parse, text)
    if ok and result ~= nil then return result end
    return fallback
end

MDT.RegisterRpc('getMedicalRecords', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'ems' then return { ok = false } end

    local citizenid = type(data) == 'table' and tostring(data.citizenid or '') or ''
    if citizenid == '' then return { ok = false } end

    local rows = MDT.Select(
        'SELECT * FROM mdt_medical WHERE citizenid = ? ORDER BY created DESC LIMIT 50',
        { citizenid }
    ) or {}
    for i = 1, #rows do
        rows[i].injuries = safeParse(rows[i].injuries, {})
        rows[i].flags = safeParse(rows[i].flags, {})
    end
    return { ok = true, records = rows }
end)

MDT.RegisterRpc('saveMedicalRecord', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'ems' then return { ok = false } end
    if type(data) ~= 'table' or type(data.citizenid) ~= 'string' or data.citizenid == '' then return { ok = false } end

    local injuries = JSON.stringify(type(data.injuries) == 'table' and data.injuries or {})
    local flags = JSON.stringify(type(data.flags) == 'table' and data.flags or {})
    local treatment = tostring(data.treatment or '')
    local medications = tostring(data.medications or '')
    local notes = tostring(data.notes or '')

    local id = tonumber(data.id)
    if id then
        MDT.Execute(
            'UPDATE mdt_medical SET injuries = ?, treatment = ?, medications = ?, notes = ?, flags = ? WHERE id = ?',
            { injuries, treatment, medications, notes, flags, id }
        )
        MDT.Log(role, Player, 'medical:update', tostring(id))
    else
        MDT.Execute(
            'INSERT INTO mdt_medical (citizenid, injuries, treatment, medications, notes, flags, author_cid, author_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            { data.citizenid, injuries, treatment, medications, notes, flags, Player.PlayerData.citizenid, MDT.CharName(Player) }
        )
        id = MDT.LastInsertId()
        MDT.Log(role, Player, 'medical:create', data.citizenid)
    end
    return { ok = true, id = id }
end)

--- Bridge: other resources (e.g. qb-ambulancejob on revive) can file a record.
local function AddMedicalRecord(data)
    if type(data) ~= 'table' or type(data.citizenid) ~= 'string' or data.citizenid == '' then return nil end
    MDT.Execute(
        'INSERT INTO mdt_medical (citizenid, injuries, treatment, medications, notes, flags, author_cid, author_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            data.citizenid,
            JSON.stringify(type(data.injuries) == 'table' and data.injuries or {}),
            tostring(data.treatment or ''),
            tostring(data.medications or ''),
            tostring(data.notes or ''),
            JSON.stringify(type(data.flags) == 'table' and data.flags or {}),
            tostring(data.author_cid or 'system'),
            tostring(data.author_name or 'System'),
        }
    )
    return MDT.LastInsertId()
end
exports('qb-mdt', 'AddMedicalRecord', AddMedicalRecord)

