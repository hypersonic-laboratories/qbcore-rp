Database.Initialize('qbcore.db')

local success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) NOT NULL UNIQUE,
        cid INTEGER DEFAULT NULL,
        license VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        money TEXT NOT NULL,
        charinfo TEXT DEFAULT NULL,
        job TEXT NOT NULL,
        gang TEXT DEFAULT NULL,
        position TEXT NOT NULL,
        metadata TEXT NOT NULL,
        inventory TEXT DEFAULT NULL,
        last_updated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_players_last_updated ON players(last_updated)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_players_license ON players(license)]])

    Database.Execute([[
        CREATE TRIGGER IF NOT EXISTS trigger_players_last_updated
        AFTER UPDATE ON players
        FOR EACH ROW
        BEGIN
            UPDATE players SET last_updated = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END
    ]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS apartments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(255) DEFAULT NULL,
        type VARCHAR(255) DEFAULT NULL,
        label VARCHAR(255) DEFAULT NULL,
        citizenid VARCHAR(11) DEFAULT NULL
    )
]])
if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_apartments_citizenid ON apartments(citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_apartments_name ON apartments(name)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS bank_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) DEFAULT NULL,
        account_name VARCHAR(50) DEFAULT NULL,
        account_balance INTEGER NOT NULL DEFAULT 0,
        account_type VARCHAR(10) NOT NULL CHECK (account_type IN ('shared','job','gang')),
        users TEXT DEFAULT '[]',
        UNIQUE (account_name)
    )
]])

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS bank_statements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) DEFAULT NULL,
        account_name VARCHAR(50) DEFAULT 'checking',
        amount INTEGER DEFAULT NULL,
        reason VARCHAR(50) DEFAULT NULL,
        statement_type VARCHAR(10) DEFAULT NULL CHECK (statement_type IN ('deposit','withdraw')),
        date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_bank_statements_citizenid ON bank_statements(citizenid)]])

    Database.Execute([[
        CREATE TRIGGER IF NOT EXISTS trigger_bank_statements_date_updated
        AFTER UPDATE ON bank_statements
        FOR EACH ROW
        BEGIN
            UPDATE bank_statements SET date = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END
    ]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS bans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) DEFAULT NULL,
        license VARCHAR(50) DEFAULT NULL,
        discord VARCHAR(50) DEFAULT NULL,
        ip VARCHAR(50) DEFAULT NULL,
        reason TEXT DEFAULT NULL,
        expire INTEGER DEFAULT NULL,
        bannedby VARCHAR(255) NOT NULL DEFAULT 'LeBanhammer'
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_bans_license ON bans(license)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_bans_discord ON bans(discord)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_bans_ip ON bans(ip)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS crypto (
        crypto VARCHAR(50) NOT NULL DEFAULT 'qbit',
        worth INTEGER NOT NULL DEFAULT 0,
        history TEXT DEFAULT NULL,
        PRIMARY KEY (crypto)
    )
]])

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS crypto_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) DEFAULT NULL,
        title VARCHAR(50) DEFAULT NULL,
        message VARCHAR(50) DEFAULT NULL,
        date TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_crypto_transactions_citizenid ON crypto_transactions(citizenid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS dealers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL DEFAULT '0',
        coords TEXT DEFAULT NULL,
        time TEXT DEFAULT NULL,
        createdby VARCHAR(50) NOT NULL DEFAULT '0'
    )
]])

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS house_plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building VARCHAR(50) DEFAULT NULL,
        stage INTEGER DEFAULT 1,
        sort VARCHAR(50) DEFAULT NULL,
        gender VARCHAR(50) DEFAULT NULL,
        food INTEGER DEFAULT 100,
        health INTEGER DEFAULT 100,
        progress INTEGER DEFAULT 0,
        coords TEXT DEFAULT NULL,
        plantid VARCHAR(50) DEFAULT NULL
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_house_plants_building ON house_plants(building)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_house_plants_plantid ON house_plants(plantid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS lapraces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) DEFAULT NULL,
        checkpoints TEXT DEFAULT NULL,
        records TEXT DEFAULT NULL,
        creator VARCHAR(50) DEFAULT NULL,
        distance INTEGER DEFAULT NULL,
        raceid VARCHAR(50) DEFAULT NULL
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_lapraces_raceid ON lapraces(raceid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_key TEXT NOT NULL UNIQUE,
        entrance_id TEXT NOT NULL,
        owner_citizenid TEXT NOT NULL,
        owned INTEGER NOT NULL DEFAULT 1 CHECK (owned IN (0,1)),
        interior_type TEXT NOT NULL CHECK (interior_type IN ('instanced', 'world')),
        interior_ref TEXT DEFAULT NULL,
        keyholders TEXT DEFAULT NULL,
        scene_data TEXT DEFAULT NULL,
        stash TEXT DEFAULT NULL,
        outfit TEXT DEFAULT NULL,
        logout TEXT DEFAULT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(owner_citizenid, entrance_id)
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_properties_owner ON properties(owner_citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_properties_entrance ON properties(entrance_id)]])
    Database.Execute([[CREATE UNIQUE INDEX IF NOT EXISTS idx_properties_key ON properties(property_key)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS property_entrances (
        entrance_id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        entrance_type TEXT NOT NULL CHECK (entrance_type IN ('instanced', 'world')),
        coords TEXT NOT NULL,
        interior_ref TEXT DEFAULT NULL,
        price INTEGER DEFAULT NULL,
        active INTEGER DEFAULT 1 CHECK (active IN (0,1)),
        created_by TEXT DEFAULT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_entrances_coords ON property_entrances(coords)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS occasion_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seller VARCHAR(50) DEFAULT NULL,
        price INTEGER DEFAULT NULL,
        description TEXT DEFAULT NULL,
        plate VARCHAR(50) DEFAULT NULL,
        model VARCHAR(50) DEFAULT NULL,
        mods TEXT DEFAULT NULL,
        occasionid VARCHAR(50) DEFAULT NULL
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_occasion_vehicles_occasionid ON occasion_vehicles(occasionid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) DEFAULT NULL,
        amount INTEGER NOT NULL DEFAULT 0,
        society TEXT DEFAULT NULL,
        sender VARCHAR(50) DEFAULT NULL,
        sendercitizenid VARCHAR(50) DEFAULT NULL
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_invoices_citizenid ON phone_invoices(citizenid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_accounts (
        citizenid TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        name TEXT NOT NULL,
        first_name TEXT DEFAULT '',
        last_name TEXT DEFAULT '',
        handle TEXT DEFAULT '',
        bio TEXT DEFAULT '',
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_accounts_phone ON phone_accounts(phone)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_gallery (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT NOT NULL,
        image TEXT NOT NULL,
        date TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_gallery_citizenid ON phone_gallery(citizenid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS player_mails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT DEFAULT NULL,
        sender TEXT DEFAULT NULL,
        sender_number TEXT DEFAULT NULL,
        subject TEXT DEFAULT NULL,
        message TEXT DEFAULT NULL,
        read INTEGER DEFAULT 0,
        starred INTEGER DEFAULT 0,
        mailid TEXT DEFAULT NULL,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        button TEXT DEFAULT NULL
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_mails_citizenid ON player_mails(citizenid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT DEFAULT NULL,
        number TEXT DEFAULT NULL,
        display_name TEXT DEFAULT NULL,
        image TEXT DEFAULT '',
        messages TEXT DEFAULT '[]',
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_messages_citizenid ON phone_messages(citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_messages_number ON phone_messages(number)]])
    Database.Execute([[CREATE UNIQUE INDEX IF NOT EXISTS idx_phone_messages_owner_number ON phone_messages(citizenid, number)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_tweets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT DEFAULT NULL,
        firstName TEXT DEFAULT NULL,
        lastName TEXT DEFAULT NULL,
        handle TEXT DEFAULT NULL,
        message TEXT DEFAULT NULL,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        url TEXT DEFAULT NULL,
        picture TEXT DEFAULT './img/default.png',
        tweetId TEXT NOT NULL UNIQUE
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_tweets_citizenid ON phone_tweets(citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_tweets_tweetId ON phone_tweets(tweetId)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS player_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT DEFAULT NULL,
        name TEXT DEFAULT NULL,
        number TEXT DEFAULT NULL,
        image TEXT DEFAULT '',
        iban TEXT NOT NULL DEFAULT '0'
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_contacts_citizenid ON player_contacts(citizenid)]])
    Database.Execute([[CREATE UNIQUE INDEX IF NOT EXISTS idx_player_contacts_owner_number ON player_contacts(citizenid, number)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_call_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid TEXT NOT NULL,
        name TEXT DEFAULT '',
        number TEXT DEFAULT '',
        type TEXT DEFAULT '',
        missed INTEGER DEFAULT 0,
        time TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_call_history_citizenid ON phone_call_history(citizenid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_calendar_events (
        id TEXT PRIMARY KEY,
        citizenid TEXT NOT NULL,
        month INTEGER NOT NULL,
        day INTEGER NOT NULL,
        title TEXT NOT NULL,
        event_time TEXT DEFAULT '',
        detail TEXT DEFAULT '',
        accent TEXT DEFAULT 'bg-rose-500',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_calendar_events_citizenid ON phone_calendar_events(citizenid)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_tweet_reactions (
        tweet_id TEXT NOT NULL,
        citizenid TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (tweet_id, citizenid, type)
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_tweet_reactions_tweet ON phone_tweet_reactions(tweet_id)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_tweet_comments (
        id TEXT PRIMARY KEY,
        tweet_id TEXT NOT NULL,
        citizenid TEXT NOT NULL,
        firstName TEXT DEFAULT '',
        lastName TEXT DEFAULT '',
        handle TEXT DEFAULT '',
        message TEXT NOT NULL,
        date TEXT DEFAULT CURRENT_TIMESTAMP
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_tweet_comments_tweet ON phone_tweet_comments(tweet_id)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS phone_tweet_follows (
        follower_citizenid TEXT NOT NULL,
        target_citizenid TEXT DEFAULT '',
        target_name TEXT DEFAULT '',
        target_handle TEXT DEFAULT '',
        target_phone TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (follower_citizenid, target_name)
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_phone_tweet_follows_target ON phone_tweet_follows(target_name)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS playerskins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) NOT NULL,
        model VARCHAR(255) NOT NULL,
        skin TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_playerskins_citizenid ON playerskins(citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_playerskins_active ON playerskins(active)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS player_outfits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizenid VARCHAR(11) DEFAULT NULL,
        outfitname VARCHAR(50) NOT NULL,
        model VARCHAR(50) DEFAULT NULL,
        skin TEXT DEFAULT NULL,
        outfitId VARCHAR(50) NOT NULL
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_outfits_citizenid ON player_outfits(citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_outfits_outfitId ON player_outfits(outfitId)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS player_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        license VARCHAR(50) DEFAULT NULL,
        citizenid VARCHAR(11) DEFAULT NULL,
        vehicle VARCHAR(50) DEFAULT NULL,
        hash VARCHAR(50) DEFAULT NULL,
        mods TEXT DEFAULT NULL,
        plate VARCHAR(8) NOT NULL,
        fakeplate VARCHAR(8) DEFAULT NULL,
        garage VARCHAR(50) DEFAULT NULL,
        fuel INTEGER DEFAULT 1,
        engine REAL DEFAULT 1,
        body REAL DEFAULT 1,
        state INTEGER DEFAULT 1,
        depotprice INTEGER NOT NULL DEFAULT 0,
        drivingdistance INTEGER DEFAULT NULL,
        status TEXT DEFAULT NULL,
        balance INTEGER NOT NULL DEFAULT 0,
        paymentamount INTEGER NOT NULL DEFAULT 0,
        paymentsleft INTEGER NOT NULL DEFAULT 0,
        financetime INTEGER NOT NULL DEFAULT 0
    )
]])

if success then
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_vehicles_plate ON player_vehicles(plate)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_vehicles_citizenid ON player_vehicles(citizenid)]])
    Database.Execute([[CREATE INDEX IF NOT EXISTS idx_player_vehicles_license ON player_vehicles(license)]])
end

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS player_warns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderIdentifier VARCHAR(50) DEFAULT NULL,
        targetIdentifier VARCHAR(50) DEFAULT NULL,
        reason TEXT DEFAULT NULL,
        warnId VARCHAR(50) DEFAULT NULL
    )
]])

success = Database.Execute([[
    CREATE TABLE IF NOT EXISTS inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier VARCHAR(50) NOT NULL UNIQUE,
        items TEXT DEFAULT '[]'
    )
]])

function DatabaseAction(ActionType, ...)
    if not ActionType then return end

    local _, result = pcall(function(...)
        return Database[ActionType](...)
    end, ...)

    local ResultSet = {}
    if type(result) == 'userdata' and result.__name == 'TArray' then
        local Rows = result:ToTable()
        for k, v in pairs(Rows) do
            ResultSet[k] = v.Columns:ToTable()
        end
    elseif type(result) == 'boolean' then
        return result
    end

    return ResultSet
end

exports('qb-core', 'DatabaseAction', DatabaseAction)

function onShutdown()
    Database.Close()
end
