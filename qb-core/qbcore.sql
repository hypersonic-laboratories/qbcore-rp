CREATE TABLE IF NOT EXISTS apartments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) DEFAULT NULL,
  type VARCHAR(255) DEFAULT NULL,
  label VARCHAR(255) DEFAULT NULL,
  citizenid VARCHAR(11) DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_apartments_citizenid ON apartments (citizenid);
CREATE INDEX IF NOT EXISTS idx_apartments_name ON apartments (name);

CREATE TABLE IF NOT EXISTS bank_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid VARCHAR(11) DEFAULT NULL,
  account_name VARCHAR(50) UNIQUE,
  account_balance INT NOT NULL DEFAULT 0,
  account_type VARCHAR(10) CHECK (account_type IN ('shared', 'job', 'gang')),
  users TEXT DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS bank_statements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid VARCHAR(11) DEFAULT NULL,
  account_name VARCHAR(50) DEFAULT 'checking',
  amount INT DEFAULT NULL,
  reason VARCHAR(50) DEFAULT NULL,
  statement_type VARCHAR(10) CHECK (statement_type IN ('deposit', 'withdraw')),
  date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_statements_citizenid ON bank_statements (citizenid);

CREATE TRIGGER IF NOT EXISTS bank_statements_update_date
AFTER UPDATE ON bank_statements
FOR EACH ROW
BEGIN
    UPDATE bank_statements SET date = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TABLE IF NOT EXISTS bans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(50) DEFAULT NULL,
  license VARCHAR(50) DEFAULT NULL,
  discord VARCHAR(50) DEFAULT NULL,
  ip VARCHAR(50) DEFAULT NULL,
  reason TEXT DEFAULT NULL,
  expire INT DEFAULT NULL,
  bannedby VARCHAR(255) NOT NULL DEFAULT 'LeBanhammer'
);

CREATE INDEX IF NOT EXISTS idx_bans_license ON bans (license);
CREATE INDEX IF NOT EXISTS idx_bans_discord ON bans (discord);
CREATE INDEX IF NOT EXISTS idx_bans_ip ON bans (ip);

CREATE TABLE IF NOT EXISTS crypto (
  crypto VARCHAR(50) PRIMARY KEY DEFAULT 'qbit',
  worth INT NOT NULL DEFAULT 0,
  history TEXT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS crypto_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid VARCHAR(11) DEFAULT NULL,
  title VARCHAR(50) DEFAULT NULL,
  message VARCHAR(50) DEFAULT NULL,
  date TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crypto_transactions_citizenid ON crypto_transactions (citizenid);

CREATE TABLE IF NOT EXISTS dealers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(50) NOT NULL DEFAULT '0',
  coords TEXT DEFAULT NULL,
  time TEXT DEFAULT NULL,
  createdby VARCHAR(50) NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS houselocations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) DEFAULT NULL,
  label VARCHAR(255) DEFAULT NULL,
  coords TEXT DEFAULT NULL,
  owned INTEGER DEFAULT NULL,
  price INT DEFAULT NULL,
  tier INTEGER DEFAULT NULL,
  garage TEXT DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_houselocations_name ON houselocations (name);

CREATE TABLE IF NOT EXISTS inventories (
  id INTEGER,
  identifier VARCHAR(50) NOT NULL PRIMARY KEY,
  items TEXT DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS player_houses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  house VARCHAR(50) NOT NULL,
  identifier VARCHAR(50) DEFAULT NULL,
  citizenid VARCHAR(11) DEFAULT NULL,
  keyholders TEXT DEFAULT NULL,
  decorations TEXT DEFAULT NULL,
  stash TEXT DEFAULT NULL,
  outfit TEXT DEFAULT NULL,
  logout TEXT DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_player_houses_house ON player_houses (house);
CREATE INDEX IF NOT EXISTS idx_player_houses_citizenid ON player_houses (citizenid);
CREATE INDEX IF NOT EXISTS idx_player_houses_identifier ON player_houses (identifier);

CREATE TABLE IF NOT EXISTS house_plants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  building VARCHAR(50) DEFAULT NULL,
  stage INT DEFAULT 1,
  sort VARCHAR(50) DEFAULT NULL,
  gender VARCHAR(50) DEFAULT NULL,
  food INT DEFAULT 100,
  health INT DEFAULT 100,
  progress INT DEFAULT 0,
  coords TEXT DEFAULT NULL,
  plantid VARCHAR(50) DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_house_plants_building ON house_plants (building);
CREATE INDEX IF NOT EXISTS idx_house_plants_plantid ON house_plants (plantid);

CREATE TABLE IF NOT EXISTS lapraces (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(50) DEFAULT NULL,
  checkpoints TEXT DEFAULT NULL,
  records TEXT DEFAULT NULL,
  creator VARCHAR(50) DEFAULT NULL,
  distance INT DEFAULT NULL,
  raceid VARCHAR(50) DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_lapraces_raceid ON lapraces (raceid);

CREATE TABLE IF NOT EXISTS occasion_vehicles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller VARCHAR(50) DEFAULT NULL,
  price INT DEFAULT NULL,
  description TEXT DEFAULT NULL,
  plate VARCHAR(50) DEFAULT NULL,
  model VARCHAR(50) DEFAULT NULL,
  mods TEXT DEFAULT NULL,
  occasionid VARCHAR(50) DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_occasion_vehicles_occasionid ON occasion_vehicles (occasionid);

CREATE TABLE IF NOT EXISTS phone_accounts (
  citizenid TEXT PRIMARY KEY,
  phone TEXT NOT NULL,
  name TEXT NOT NULL,
  first_name TEXT DEFAULT '',
  last_name TEXT DEFAULT '',
  handle TEXT DEFAULT '',
  bio TEXT DEFAULT '',
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_phone_accounts_phone ON phone_accounts (phone);

CREATE TABLE IF NOT EXISTS phone_gallery (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid TEXT NOT NULL,
  image TEXT NOT NULL,
  date TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_phone_gallery_citizenid ON phone_gallery (citizenid);

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
);

CREATE INDEX IF NOT EXISTS idx_player_mails_citizenid ON player_mails (citizenid);

CREATE TABLE IF NOT EXISTS phone_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid TEXT DEFAULT NULL,
  number TEXT DEFAULT NULL,
  display_name TEXT DEFAULT NULL,
  image TEXT DEFAULT '',
  messages TEXT DEFAULT '[]',
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_phone_messages_citizenid ON phone_messages (citizenid);
CREATE INDEX IF NOT EXISTS idx_phone_messages_number ON phone_messages (number);
CREATE UNIQUE INDEX IF NOT EXISTS idx_phone_messages_owner_number ON phone_messages (citizenid, number);

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
);

CREATE INDEX IF NOT EXISTS idx_phone_tweets_citizenid ON phone_tweets (citizenid);
CREATE INDEX IF NOT EXISTS idx_phone_tweets_tweetId ON phone_tweets (tweetId);

CREATE TABLE IF NOT EXISTS player_contacts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid TEXT DEFAULT NULL,
  name TEXT DEFAULT NULL,
  number TEXT DEFAULT NULL,
  image TEXT DEFAULT '',
  iban TEXT NOT NULL DEFAULT '0'
);

CREATE INDEX IF NOT EXISTS idx_player_contacts_citizenid ON player_contacts (citizenid);
CREATE UNIQUE INDEX IF NOT EXISTS idx_player_contacts_owner_number ON player_contacts (citizenid, number);

CREATE TABLE IF NOT EXISTS phone_call_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid TEXT NOT NULL,
  name TEXT DEFAULT '',
  number TEXT DEFAULT '',
  type TEXT DEFAULT '',
  missed INTEGER DEFAULT 0,
  time TEXT DEFAULT '',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_phone_call_history_citizenid ON phone_call_history (citizenid);

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
);

CREATE INDEX IF NOT EXISTS idx_phone_calendar_events_citizenid ON phone_calendar_events (citizenid);

CREATE TABLE IF NOT EXISTS phone_tweet_reactions (
  tweet_id TEXT NOT NULL,
  citizenid TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (tweet_id, citizenid, type)
);

CREATE INDEX IF NOT EXISTS idx_phone_tweet_reactions_tweet ON phone_tweet_reactions (tweet_id);

CREATE TABLE IF NOT EXISTS phone_tweet_comments (
  id TEXT PRIMARY KEY,
  tweet_id TEXT NOT NULL,
  citizenid TEXT NOT NULL,
  firstName TEXT DEFAULT '',
  lastName TEXT DEFAULT '',
  handle TEXT DEFAULT '',
  message TEXT NOT NULL,
  date TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_phone_tweet_comments_tweet ON phone_tweet_comments (tweet_id);

CREATE TABLE IF NOT EXISTS phone_tweet_follows (
  follower_citizenid TEXT NOT NULL,
  target_citizenid TEXT DEFAULT '',
  target_name TEXT DEFAULT '',
  target_handle TEXT DEFAULT '',
  target_phone TEXT DEFAULT '',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (follower_citizenid, target_name)
);

CREATE INDEX IF NOT EXISTS idx_phone_tweet_follows_target ON phone_tweet_follows (target_name);

CREATE TABLE IF NOT EXISTS players (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid VARCHAR(11) NOT NULL UNIQUE,
  cid INT DEFAULT NULL,
  license VARCHAR(100) NOT NULL,
  name VARCHAR(50) NOT NULL,
  money TEXT NOT NULL,
  charinfo TEXT DEFAULT NULL,
  job TEXT NOT NULL,
  gang TEXT DEFAULT NULL,
  position TEXT NOT NULL,
  metadata TEXT NOT NULL,
  inventory TEXT DEFAULT NULL,
  last_updated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_players_last_updated ON players (last_updated);
CREATE INDEX IF NOT EXISTS idx_players_license ON players (license);

CREATE TRIGGER IF NOT EXISTS players_update_last_updated
AFTER UPDATE ON players
FOR EACH ROW
BEGIN
    UPDATE players SET last_updated = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TABLE IF NOT EXISTS playerskins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid VARCHAR(11) NOT NULL,
  model VARCHAR(255) NOT NULL,
  skin TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_playerskins_citizenid ON playerskins (citizenid);
CREATE INDEX IF NOT EXISTS idx_playerskins_active ON playerskins (active);

CREATE TABLE IF NOT EXISTS player_outfits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  citizenid VARCHAR(11) DEFAULT NULL,
  outfitname VARCHAR(50) NOT NULL,
  model VARCHAR(50) DEFAULT NULL,
  skin TEXT DEFAULT NULL,
  outfitId VARCHAR(50) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_player_outfits_citizenid ON player_outfits (citizenid);
CREATE INDEX IF NOT EXISTS idx_player_outfits_outfitId ON player_outfits (outfitId);

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
  fuel INT DEFAULT 100,
  engine REAL DEFAULT 1000,
  body REAL DEFAULT 1000,
  state INT DEFAULT 1,
  depotprice INT NOT NULL DEFAULT 0,
  drivingdistance INT DEFAULT NULL,
  status TEXT DEFAULT NULL,
  balance INT NOT NULL DEFAULT 0,
  paymentamount INT NOT NULL DEFAULT 0,
  paymentsleft INT NOT NULL DEFAULT 0,
  financetime INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_player_vehicles_plate ON player_vehicles (plate);
CREATE INDEX IF NOT EXISTS idx_player_vehicles_citizenid ON player_vehicles (citizenid);
CREATE INDEX IF NOT EXISTS idx_player_vehicles_license ON player_vehicles (license);

CREATE TABLE IF NOT EXISTS player_warns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  senderIdentifier VARCHAR(50) DEFAULT NULL,
  targetIdentifier VARCHAR(50) DEFAULT NULL,
  reason TEXT DEFAULT NULL,
  warnId VARCHAR(50) DEFAULT NULL
);
