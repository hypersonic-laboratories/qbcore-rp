Config = {}

-- General
Config.OpenKey = 'F5'            -- key to toggle the MDT
Config.RequireOnDuty = true      -- must be on duty to access
Config.SupervisorGrade = 3       -- grade level (or isboss) required for supervisor actions
Config.PageSize = 25             -- pagination size for lists
Config.MaxSearchResults = 25     -- max results per search category
Config.CallRetentionHours = 24   -- calls older than this are auto-closed

-- Maps job.type -> MDT role. Add more roles here (e.g. doj) and the shell adapts.
Config.Roles = {
    leo = 'police',
    ems = 'ems',
}

-- Unit statuses selectable in the UI
Config.UnitStatuses = { 'available', 'busy', 'enroute', 'onscene', 'unavailable' }

-- Unit slots per role. Connecting to a unit from the MDT sets the officer's
-- callsign AND joins the unit's voice channel, so partners who pick the same
-- unit share a private radio frequency. Multiple officers per unit is allowed.
--
-- Channel isolation: unit channels live in the reserved 30000-30999 band —
-- qb-radio manual dials are small integers (and its client blocks this band),
-- qb-phone allocates 50000-99999. `freq` is the cosmetic MHz label shown in
-- the UI; `channel` is the real HELIX voice channel.
-- (Dispatch/all-units broadcast role: flagged for later.)
Config.UnitVoiceBand = { min = 30000, max = 30999 } -- keep other resources out
Config.PttKey = 'CapsLock'                          -- hold to transmit on the unit radio (prox + radio)
Config.UnitProxRangeCm = 4000                       -- crew within this range (cm, ~40m) hear you via proximity;
                                                    -- beyond it your voice is muted for them unless you hold PTT
Config.Units = {
    police = {
        { id = 'ADAM-1', channel = 30101, freq = '126.525' },
        { id = 'ADAM-2', channel = 30102, freq = '126.550' },
        { id = 'ADAM-3', channel = 30103, freq = '126.575' },
        { id = 'ADAM-4', channel = 30104, freq = '126.600' },
        { id = 'ADAM-5', channel = 30105, freq = '126.625' },
        { id = 'ADAM-6', channel = 30106, freq = '126.650' },
        { id = 'LINCOLN-1', channel = 30111, freq = '127.100' },
        { id = 'LINCOLN-2', channel = 30112, freq = '127.125' },
    },
    ems = {
        { id = 'MEDIC-1', channel = 30201, freq = '128.200' },
        { id = 'MEDIC-2', channel = 30202, freq = '128.225' },
        { id = 'MEDIC-3', channel = 30203, freq = '128.250' },
        { id = 'MEDIC-4', channel = 30204, freq = '128.275' },
    },
}

-- Call priorities
Config.CallPriorities = {
    [1] = { label = 'Emergency', color = '#ff4757' },
    [2] = { label = 'Priority', color = '#ffa502' },
    [3] = { label = 'Routine', color = '#2ed573' },
}

-- Penal code. sentence is in months, fine in dollars.
-- class: 'infraction' | 'misdemeanor' | 'felony'
Config.PenalCode = {
    {
        category = 'Offenses Against Persons',
        charges = {
            { code = 'P-01', label = 'Assault', class = 'misdemeanor', fine = 250, sentence = 10 },
            { code = 'P-02', label = 'Battery', class = 'misdemeanor', fine = 500, sentence = 15 },
            { code = 'P-03', label = 'Assault with a Deadly Weapon', class = 'felony', fine = 2000, sentence = 30 },
            { code = 'P-04', label = 'Attempted Murder', class = 'felony', fine = 5000, sentence = 60 },
            { code = 'P-05', label = 'Murder', class = 'felony', fine = 10000, sentence = 120 },
            { code = 'P-06', label = 'Kidnapping', class = 'felony', fine = 4000, sentence = 45 },
            { code = 'P-07', label = 'Hostage Taking', class = 'felony', fine = 6000, sentence = 60 },
            { code = 'P-08', label = 'Threats of Violence', class = 'misdemeanor', fine = 300, sentence = 5 },
        },
    },
    {
        category = 'Offenses Against Property',
        charges = {
            { code = 'PR-01', label = 'Petty Theft', class = 'misdemeanor', fine = 250, sentence = 5 },
            { code = 'PR-02', label = 'Grand Theft', class = 'felony', fine = 1500, sentence = 20 },
            { code = 'PR-03', label = 'Grand Theft Auto', class = 'felony', fine = 2000, sentence = 25 },
            { code = 'PR-04', label = 'Burglary', class = 'felony', fine = 1500, sentence = 20 },
            { code = 'PR-05', label = 'Robbery', class = 'felony', fine = 2500, sentence = 30 },
            { code = 'PR-06', label = 'Armed Robbery', class = 'felony', fine = 5000, sentence = 45 },
            { code = 'PR-07', label = 'Vandalism', class = 'misdemeanor', fine = 400, sentence = 5 },
            { code = 'PR-08', label = 'Arson', class = 'felony', fine = 3000, sentence = 35 },
            { code = 'PR-09', label = 'Trespassing', class = 'infraction', fine = 200, sentence = 0 },
        },
    },
    {
        category = 'Public Order & Justice',
        charges = {
            { code = 'PO-01', label = 'Disorderly Conduct', class = 'infraction', fine = 150, sentence = 0 },
            { code = 'PO-02', label = 'Obstruction of Justice', class = 'misdemeanor', fine = 500, sentence = 10 },
            { code = 'PO-03', label = 'Resisting Arrest', class = 'misdemeanor', fine = 750, sentence = 15 },
            { code = 'PO-04', label = 'Evading Arrest', class = 'felony', fine = 1500, sentence = 20 },
            { code = 'PO-05', label = 'Escaping Custody', class = 'felony', fine = 3000, sentence = 30 },
            { code = 'PO-06', label = 'False Report', class = 'misdemeanor', fine = 300, sentence = 5 },
            { code = 'PO-07', label = 'Impersonating a Public Servant', class = 'felony', fine = 2000, sentence = 25 },
            { code = 'PO-08', label = 'Bribery', class = 'felony', fine = 2500, sentence = 20 },
        },
    },
    {
        category = 'Drug Offenses',
        charges = {
            { code = 'D-01', label = 'Possession of a Controlled Substance', class = 'misdemeanor', fine = 500, sentence = 10 },
            { code = 'D-02', label = 'Possession with Intent to Distribute', class = 'felony', fine = 2000, sentence = 25 },
            { code = 'D-03', label = 'Drug Trafficking', class = 'felony', fine = 5000, sentence = 50 },
            { code = 'D-04', label = 'Manufacturing of a Controlled Substance', class = 'felony', fine = 4000, sentence = 40 },
        },
    },
    {
        category = 'Weapons Offenses',
        charges = {
            { code = 'W-01', label = 'Possession of an Illegal Firearm', class = 'felony', fine = 1500, sentence = 20 },
            { code = 'W-02', label = 'Brandishing a Weapon', class = 'misdemeanor', fine = 500, sentence = 10 },
            { code = 'W-03', label = 'Discharge of a Firearm in Public', class = 'felony', fine = 1500, sentence = 15 },
            { code = 'W-04', label = 'Weapons Trafficking', class = 'felony', fine = 5000, sentence = 50 },
        },
    },
    {
        category = 'Traffic Offenses',
        charges = {
            { code = 'T-01', label = 'Speeding', class = 'infraction', fine = 150, sentence = 0 },
            { code = 'T-02', label = 'Reckless Driving', class = 'misdemeanor', fine = 400, sentence = 5 },
            { code = 'T-03', label = 'Driving Without a License', class = 'infraction', fine = 250, sentence = 0 },
            { code = 'T-04', label = 'Driving Under the Influence', class = 'misdemeanor', fine = 750, sentence = 10 },
            { code = 'T-05', label = 'Hit and Run', class = 'felony', fine = 1500, sentence = 15 },
            { code = 'T-06', label = 'Fleeing and Eluding', class = 'felony', fine = 2000, sentence = 20 },
        },
    },
}
