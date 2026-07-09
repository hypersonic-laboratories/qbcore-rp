-- qb-mdt database schema (runs against the shared qb-core SQLite database)

local function Execute(sql, params)
    return exports['qb-core']:DatabaseAction('Execute', sql, params)
end

-- Citizen profile extensions (notes, flags, custom image)
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) NOT NULL UNIQUE,
        notes TEXT DEFAULT '',
        flags TEXT DEFAULT '[]',
        image TEXT DEFAULT '',
        updated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_profiles_citizenid ON mdt_profiles(citizenid)]])

-- Incident reports
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_incidents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role VARCHAR(10) NOT NULL DEFAULT 'police',
        title VARCHAR(255) NOT NULL,
        details TEXT DEFAULT '',
        author_cid VARCHAR(11) NOT NULL,
        author_name VARCHAR(255) NOT NULL,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_incidents_role ON mdt_incidents(role)]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_incidents_author ON mdt_incidents(author_cid)]])

-- Links between incidents and citizens / vehicles / evidence / officers
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_incident_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        incident_id INTEGER NOT NULL,
        link_type VARCHAR(20) NOT NULL,
        identifier VARCHAR(64) NOT NULL,
        label VARCHAR(255) DEFAULT ''
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_links_incident ON mdt_incident_links(incident_id)]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_links_identifier ON mdt_incident_links(link_type, identifier)]])

-- Convictions (criminal record)
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_convictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) NOT NULL,
        incident_id INTEGER DEFAULT NULL,
        charges TEXT NOT NULL DEFAULT '[]',
        fine INTEGER NOT NULL DEFAULT 0,
        sentence INTEGER NOT NULL DEFAULT 0,
        officer_cid VARCHAR(11) NOT NULL,
        officer_name VARCHAR(255) NOT NULL,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_convictions_citizenid ON mdt_convictions(citizenid)]])

-- Warrants
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_warrants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) NOT NULL,
        incident_id INTEGER DEFAULT NULL,
        reason TEXT NOT NULL,
        status VARCHAR(10) NOT NULL DEFAULT 'active',
        author_cid VARCHAR(11) NOT NULL,
        author_name VARCHAR(255) NOT NULL,
        expires_at TEXT DEFAULT NULL,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_warrants_citizenid ON mdt_warrants(citizenid)]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_warrants_status ON mdt_warrants(status)]])

-- BOLOs (person or vehicle)
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_bolos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role VARCHAR(10) NOT NULL DEFAULT 'police',
        bolo_type VARCHAR(10) NOT NULL,
        identifier VARCHAR(64) DEFAULT '',
        title VARCHAR(255) NOT NULL,
        description TEXT DEFAULT '',
        priority INTEGER NOT NULL DEFAULT 2,
        image TEXT DEFAULT '',
        status VARCHAR(10) NOT NULL DEFAULT 'active',
        author_cid VARCHAR(11) NOT NULL,
        author_name VARCHAR(255) NOT NULL,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_bolos_status ON mdt_bolos(status)]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_bolos_identifier ON mdt_bolos(bolo_type, identifier)]])

-- Dispatch calls
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role VARCHAR(10) NOT NULL DEFAULT 'police',
        code VARCHAR(20) DEFAULT '',
        title VARCHAR(255) NOT NULL,
        details TEXT DEFAULT '',
        coords TEXT DEFAULT NULL,
        priority INTEGER NOT NULL DEFAULT 2,
        status VARCHAR(10) NOT NULL DEFAULT 'pending',
        units TEXT NOT NULL DEFAULT '[]',
        anonymous INTEGER NOT NULL DEFAULT 0,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_calls_status ON mdt_calls(status)]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_calls_role ON mdt_calls(role)]])

-- Medical records (EMS)
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_medical (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) NOT NULL,
        injuries TEXT DEFAULT '[]',
        treatment TEXT DEFAULT '',
        medications TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        flags TEXT DEFAULT '[]',
        author_cid VARCHAR(11) NOT NULL,
        author_name VARCHAR(255) NOT NULL,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_medical_citizenid ON mdt_medical(citizenid)]])

-- Department bulletins
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_bulletins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role VARCHAR(10) NOT NULL DEFAULT 'police',
        title VARCHAR(255) NOT NULL,
        content TEXT DEFAULT '',
        author_cid VARCHAR(11) NOT NULL,
        author_name VARCHAR(255) NOT NULL,
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_bulletins_role ON mdt_bulletins(role)]])

-- Action log (audit trail)
Execute([[
    CREATE TABLE IF NOT EXISTS mdt_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role VARCHAR(10) NOT NULL,
        actor_cid VARCHAR(11) NOT NULL,
        actor_name VARCHAR(255) NOT NULL,
        action VARCHAR(64) NOT NULL,
        details TEXT DEFAULT '',
        created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])
Execute([[CREATE INDEX IF NOT EXISTS idx_mdt_logs_actor ON mdt_logs(actor_cid)]])

