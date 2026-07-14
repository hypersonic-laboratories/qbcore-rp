-- qb-policejob mugshot server: subject resolution (ray test), photo storage,
-- and the result contract for other resources:
--   exports['qb-policejob']:GetMugshot(citizenid) -> { url, taken } | nil
-- On every saved photo the MDT (if running) is updated through its
-- exports['qb-mdt']:SetProfileImage — pcall'd, so servers without the MDT
-- still keep full mugshot history here.

local function DbExecute(sql, params)
    return exports['qb-core']:DatabaseAction('Execute', sql, params)
end

local function DbSelect(sql, params)
    return exports['qb-core']:DatabaseAction('Select', sql, params)
end

DbExecute([[
    CREATE TABLE IF NOT EXISTS police_mugshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT NOT NULL,
        url TEXT NOT NULL,
        officer_cid TEXT,
        officer_name TEXT,
        created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
]])
DbExecute('CREATE INDEX IF NOT EXISTS idx_police_mugshots_cid ON police_mugshots (citizenid, id)')

--- Validates the caller is a LEO. Duty is not required: the tripod target
--- already gates who can open the station.
--- @return Player|nil
local function GetOfficer(source)
    local Player = exports['qb-core']:GetPlayer(source)
    local job = Player and Player.PlayerData.job
    if not job or job.type ~= 'leo' then return nil end
    return Player
end

-- ─────────────────────────── result contract ────────────────────────────────

--- Latest mugshot for a citizen (any resource: ID cards, MDT, prison intake).
exports('qb-policejob', 'GetMugshot', function(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then return nil end
    local rows = DbSelect(
        'SELECT url, created FROM police_mugshots WHERE citizenid = ? ORDER BY id DESC LIMIT 1',
        { citizenid }
    )
    local row = rows and rows[1]
    if not row then return nil end
    return { url = row.url, taken = row.created }
end)

local function saveMugshot(Player, citizenid, url, name)
    local oinfo = Player.PlayerData.charinfo or {}
    DbExecute(
        'INSERT INTO police_mugshots (citizenid, url, officer_cid, officer_name) VALUES (?, ?, ?, ?)',
        { citizenid, url, Player.PlayerData.citizenid, ((oinfo.firstname or '') .. ' ' .. (oinfo.lastname or '')) }
    )
    -- Notify the MDT so the citizen profile photo updates immediately;
    -- pcall'd because the MDT is optional.
    pcall(function() exports['qb-mdt']:SetProfileImage(citizenid, url) end)
    TriggerClientEvent(Player.PlayerData.source, 'QBCore:Notify',
        ('Mugshot saved — %s (%s)'):format(name, citizenid), 'success')
end

-- ─────────────────────────── subject resolution ─────────────────────────────
-- Who is in front of the camera? Ray test along the camera's line of sight
-- (camPos -> stand: the lens aims at the chart mark by construction, so no
-- rotator math needed). Each candidate is projected onto that axis; accept
-- players inside the view corridor — forward of the lens, not past the wall
-- behind the chart, within `corridorCm` laterally — and take the one CLOSEST
-- to the lens, like a real raycast's first hit.
-- The photographing officer is NOT excluded: at the tripod they sit behind
-- the lens (fwd < 30) and never match, but an officer stepping in front of
-- the camera is a valid subject — that's also the solo-test path.
local function findMugshotSubject(station)
    -- unit forward vector, camera -> chart (2D: booking rooms are flat)
    local fx, fy = station.stand.X - station.camPos.X, station.stand.Y - station.camPos.Y
    local standDist = math.sqrt(fx * fx + fy * fy)
    if standDist < 1 then return nil end -- degenerate calibration
    fx, fy = fx / standDist, fy / standDist

    local maxFwd = standDist + 200            -- small margin past the mark
    local maxLat = station.corridorCm or 100  -- half-width of the sight line
    local best, bestFwd = nil, maxFwd
    for _, p in pairs(GetAllPlayers()) do
        local Subject = exports['qb-core']:GetPlayer(p)
        if Subject then
            local pawn = GetPlayerPawn(p)
            local c = pawn and GetEntityCoords(pawn) or nil
            if c then
                local dx, dy = c.X - station.camPos.X, c.Y - station.camPos.Y
                local fwd = dx * fx + dy * fy               -- distance along the ray
                local lat = math.abs(dx * fy - dy * fx)     -- perpendicular offset
                if fwd > 30 and fwd < bestFwd and lat <= maxLat then
                    best, bestFwd = Subject, fwd
                end
            end
        end
    end
    return best
end

-- Live viewfinder probe: is someone in front of the camera right now? Polled
-- ~1/s by client/mugshot.lua while the viewfinder is open; feeds the HUD's
-- subject panel + POSITION indicator. The callback name must be a plain
-- identifier: the engine silently drops callback names containing a colon.
RegisterCallback('policeMugshotProbe', function(source, stationIndex)
    if not GetOfficer(source) then return { ok = false } end
    local station = Config.Mugshot.stations[tonumber(stationIndex) or 0]
    if not station then return { ok = false } end

    local best = findMugshotSubject(station)
    if not best then return { ok = true } end -- no subject in frame

    local info = best.PlayerData.charinfo or {}
    return {
        ok = true,
        subject = {
            citizenid = best.PlayerData.citizenid,
            name = ((info.firstname or '') .. ' ' .. (info.lastname or '')),
            dob = info.birthdate or '',
            gender = tonumber(info.gender) or 0,
        },
    }
end)

-- The shutter moment: snapshot who is in frame right now. The upload takes
-- seconds and the subject may leave the corridor before the URL comes back;
-- the photo shows whoever stood there when E was pressed, so that's who it
-- saves to. Snapshots expire after 120s (the upload poll gives up at 60s).
local pendingSubjects = {} -- [officer source] = { citizenid, name, t }

RegisterServerEvent('qb-policejob:server:mugshotBegin', function(source, stationIndex)
    local Player = GetOfficer(source)
    if not Player then return end
    local station = Config.Mugshot.stations[tonumber(stationIndex) or 0]
    if not station then return end

    local best = findMugshotSubject(station)
    if not best then
        pendingSubjects[source] = nil
        return
    end
    local info = best.PlayerData.charinfo or {}
    pendingSubjects[source] = {
        citizenid = best.PlayerData.citizenid,
        name = ((info.firstname or '') .. ' ' .. (info.lastname or '')),
        t = os.time(),
    }
end)

-- Upload finished (client/mugshot.lua); save the photo to the subject frozen
-- at shutter time, falling back to a live re-scan, then to the manual prompt.
RegisterServerEvent('qb-policejob:server:mugshot', function(source, stationIndex, url)
    local Player = GetOfficer(source)
    if not Player then return end
    if type(url) ~= 'string' or url == '' then return end

    local station = Config.Mugshot.stations[tonumber(stationIndex) or 0]
    if not station then return end

    local pending = pendingSubjects[source]
    pendingSubjects[source] = nil
    if pending and os.time() - pending.t <= 120 then
        saveMugshot(Player, pending.citizenid, url, pending.name)
        return
    end

    local best = findMugshotSubject(station)

    -- Nobody in frame: hand the URL back to the officer's client, which
    -- prompts for a citizenid (qb-input) and replies via mugshotManual below.
    if not best then
        TriggerClientEvent(Player.PlayerData.source, 'qb-policejob:client:mugshotManual', url)
        return
    end

    local info = best.PlayerData.charinfo or {}
    local name = ((info.firstname or '') .. ' ' .. (info.lastname or ''))
    saveMugshot(Player, best.PlayerData.citizenid, url, name)
end)

-- Officer typed a citizenid after no subject was found in frame.
RegisterServerEvent('qb-policejob:server:mugshotManual', function(source, citizenid, url)
    local Player = GetOfficer(source)
    if not Player then return end
    if type(url) ~= 'string' or url == '' then return end
    citizenid = type(citizenid) == 'string' and citizenid:gsub('%s', ''):upper() or ''
    if citizenid == '' then return end

    local rows = DbSelect('SELECT citizenid, charinfo FROM players WHERE citizenid = ?', { citizenid })
    local row = rows and rows[1]
    if not row then
        TriggerClientEvent(Player.PlayerData.source, 'QBCore:Notify', 'Unknown citizen ID: ' .. citizenid, 'error')
        return
    end

    local info = {}
    if type(row.charinfo) == 'string' and row.charinfo ~= '' then
        local ok, parsed = pcall(JSON.parse, row.charinfo)
        if ok and type(parsed) == 'table' then info = parsed end
    end
    local name = ((info.firstname or '') .. ' ' .. (info.lastname or ''))
    saveMugshot(Player, row.citizenid, url, name)
end)
