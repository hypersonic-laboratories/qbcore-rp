-- qb-mdt search: global search, citizen profiles, vehicle lookup

local function safeParse(text, fallback)
    if type(text) ~= 'string' or text == '' then return fallback end
    local ok, result = pcall(JSON.parse, text)
    if ok and result ~= nil then return result end
    return fallback
end

local function citizenSummary(row)
    local charinfo = safeParse(row.charinfo, {})
    local job = safeParse(row.job, {})
    return {
        citizenid = row.citizenid,
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
        name = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):gsub('^%s+', ''):gsub('%s+$', ''),
        dob = charinfo.birthdate or '',
        phone = charinfo.phone or '',
        job = job.label or '',
    }
end

-- ─────────────────────────── global search ──────────────────────────────────

MDT.RegisterRpc('search', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local query = type(data) == 'table' and tostring(data.query or '') or ''
    query = query:gsub('^%s+', ''):gsub('%s+$', '')
    if #query < 2 then return { ok = true, citizens = {}, vehicles = {} } end

    local like = '%' .. query .. '%'
    local limit = Config.MaxSearchResults

    local citizenRows = MDT.Select(
        'SELECT citizenid, name, charinfo, job FROM players WHERE citizenid LIKE ? OR name LIKE ? OR charinfo LIKE ? LIMIT ?',
        { like, like, like, limit }
    ) or {}

    local citizens = {}
    for i = 1, #citizenRows do
        citizens[#citizens + 1] = citizenSummary(citizenRows[i])
    end

    local vehicles = {}
    if role == 'police' then
        local vehicleRows = MDT.Select(
            'SELECT plate, fakeplate, vehicle, citizenid FROM player_vehicles WHERE plate LIKE ? OR fakeplate LIKE ? LIMIT ?',
            { like, like, limit }
        ) or {}
        for i = 1, #vehicleRows do
            local v = vehicleRows[i]
            vehicles[#vehicles + 1] = {
                plate = v.plate,
                model = v.vehicle,
                owner_cid = v.citizenid,
            }
        end
    end

    return { ok = true, citizens = citizens, vehicles = vehicles }
end)

-- ─────────────────────────── citizen profile ────────────────────────────────

MDT.RegisterRpc('getProfile', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end

    local citizenid = type(data) == 'table' and tostring(data.citizenid or '') or ''
    if citizenid == '' then return { ok = false } end

    local rows = MDT.Select('SELECT * FROM players WHERE citizenid = ?', { citizenid })
    local row = rows and rows[1]
    if not row then return { ok = false, message = 'Citizen not found' } end

    local charinfo = safeParse(row.charinfo, {})
    local job = safeParse(row.job, {})
    local gang = safeParse(row.gang, {})
    local metadata = safeParse(row.metadata, {})

    local profileRows = MDT.Select('SELECT notes, flags, image FROM mdt_profiles WHERE citizenid = ?', { citizenid })
    local extra = profileRows and profileRows[1] or {}

    local profile = {
        citizenid = citizenid,
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
        dob = charinfo.birthdate or '',
        gender = charinfo.gender,
        nationality = charinfo.nationality or '',
        phone = charinfo.phone or '',
        job = { name = job.name, label = job.label or '', grade = job.grade and job.grade.name or '' },
        gang = { name = gang.name, label = gang.label or '' },
        bloodtype = metadata.bloodtype or '',
        fingerprint = metadata.fingerprint or '',
        licences = metadata.licences or metadata.licenses or {},
        callsign = metadata.callsign,
        notes = extra.notes or '',
        flags = safeParse(extra.flags, {}),
        image = extra.image or '',
        online = MDT.GetOnlineByCitizenId(citizenid) ~= nil,
    }

    profile.vehicles = MDT.Select(
        'SELECT plate, fakeplate, vehicle, garage, state FROM player_vehicles WHERE citizenid = ?',
        { citizenid }
    ) or {}

    if role == 'police' then
        local convictions = MDT.Select(
            'SELECT * FROM mdt_convictions WHERE citizenid = ? ORDER BY created DESC LIMIT 50',
            { citizenid }
        ) or {}
        for i = 1, #convictions do
            convictions[i].charges = safeParse(convictions[i].charges, {})
        end
        profile.convictions = convictions

        MDT.ExpireWarrants()
        profile.warrants = MDT.Select(
            'SELECT * FROM mdt_warrants WHERE citizenid = ? ORDER BY created DESC LIMIT 25',
            { citizenid }
        ) or {}

        profile.incidents = MDT.Select(
            [[SELECT i.id, i.title, i.author_name, i.created FROM mdt_incidents i
              JOIN mdt_incident_links l ON l.incident_id = i.id
              WHERE l.link_type = 'citizen' AND l.identifier = ?
              ORDER BY i.created DESC LIMIT 25]],
            { citizenid }
        ) or {}
    end

    if role == 'ems' then
        local medical = MDT.Select(
            'SELECT * FROM mdt_medical WHERE citizenid = ? ORDER BY created DESC LIMIT 50',
            { citizenid }
        ) or {}
        for i = 1, #medical do
            medical[i].injuries = safeParse(medical[i].injuries, {})
            medical[i].flags = safeParse(medical[i].flags, {})
        end
        profile.medical = medical
    end

    return { ok = true, profile = profile }
end)

MDT.RegisterRpc('saveProfile', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player then return { ok = false } end
    if type(data) ~= 'table' or type(data.citizenid) ~= 'string' or data.citizenid == '' then return { ok = false } end

    local notes = tostring(data.notes or '')
    local flags = JSON.stringify(type(data.flags) == 'table' and data.flags or {})
    local image = tostring(data.image or '')

    MDT.Execute(
        [[INSERT INTO mdt_profiles (citizenid, notes, flags, image) VALUES (?, ?, ?, ?)
          ON CONFLICT(citizenid) DO UPDATE SET notes = excluded.notes, flags = excluded.flags,
          image = excluded.image, updated = CURRENT_TIMESTAMP]],
        { data.citizenid, notes, flags, image }
    )
    MDT.Log(role, Player, 'profile:save', data.citizenid)
    return { ok = true }
end)

-- ─────────────────────────── vehicle lookup ─────────────────────────────────

MDT.RegisterRpc('getVehicle', function(source, data)
    local Player, role = MDT.GetContext(source)
    if not Player or role ~= 'police' then return { ok = false } end

    local plate = type(data) == 'table' and tostring(data.plate or ''):upper() or ''
    if plate == '' then return { ok = false } end

    local rows = MDT.Select(
        'SELECT * FROM player_vehicles WHERE UPPER(plate) = ? OR UPPER(fakeplate) = ? LIMIT 1',
        { plate, plate }
    )
    local vehicle = rows and rows[1]
    if not vehicle then return { ok = false, message = 'No registered vehicle with that plate' } end

    local owner = nil
    if vehicle.citizenid then
        local ownerRows = MDT.Select('SELECT citizenid, charinfo, job, name FROM players WHERE citizenid = ?', { vehicle.citizenid })
        if ownerRows and ownerRows[1] then
            owner = citizenSummary(ownerRows[1])
        end
    end

    local bolos = MDT.Select(
        "SELECT * FROM mdt_bolos WHERE status = 'active' AND bolo_type = 'vehicle' AND UPPER(identifier) = ?",
        { plate }
    ) or {}

    return {
        ok = true,
        vehicle = {
            plate = vehicle.plate,
            fakeplate = vehicle.fakeplate,
            model = vehicle.vehicle,
            garage = vehicle.garage,
            state = vehicle.state,
            fuel = vehicle.fuel,
        },
        owner = owner,
        bolos = bolos,
    }
end)

