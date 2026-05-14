QBCore.Players = {}
QBCore.Player  = {}

-- ─────────────────────────── Player class ───────────────────────────────────

local Player   = {}
Player.__index = Player

function Player.new(PlayerData, Offline)
    local instance      = setmetatable({}, Player)
    instance.PlayerData = PlayerData
    instance.Offline    = Offline or false
    return instance
end

-- ─────────────────────────── server-event hooks ─────────────────────────────

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    QBCore.Player.Logout(source)
end)

local PositionCache = {}
RegisterServerEvent('HEvent:PlayerUnPossessed', function(source, Pawn)
    if Pawn then
        PositionCache[source] = Pawn:K2_GetActorLocation()
    end
end)

-- ─────────────────────────── module-private helpers ─────────────────────────

local function formatItems(inventory)
    local out = {}
    for _, item in pairs(inventory) do
        if item then
            local info = QBCore.Shared.Items[item.name:lower()]
            if info then
                out[item.slot] = {
                    name        = info.name,
                    amount      = item.amount,
                    info        = item.info or {},
                    label       = info.label,
                    description = info.description or '',
                    weight      = info.weight,
                    type        = info.type,
                    unique      = info.unique,
                    useable     = info.useable,
                    image       = info.image,
                    shouldClose = info.shouldClose,
                    slot        = item.slot,
                    combinable  = info.combinable,
                }
            end
        end
    end
    return out
end

local function applyDefaults(playerData, defaults)
    for key, value in pairs(defaults) do
        if type(value) == 'function' then
            playerData[key] = playerData[key] or value()
        elseif type(value) == 'table' then
            playerData[key] = playerData[key] or {}
            applyDefaults(playerData[key], value)
        else
            playerData[key] = playerData[key] or value
        end
    end
end

-- ─────────────────────────── instance methods ───────────────────────────────

function Player:GetPlayerData()
    return self.PlayerData
end

-- Full sync on first load; targeted field update on subsequent mutations.
function Player:UpdateClient(key, value)
    if self.Offline then return end
    if key ~= nil then
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Player:OnFieldUpdate', key, value)
    else
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Player:SetPlayerData', self.PlayerData)
    end
end

function Player:SetJob(job, grade)
    job   = job:lower()
    grade = grade or 1
    if not QBCore.Shared.Jobs[job] then return false end
    self.PlayerData.job = {
        name   = job,
        label  = QBCore.Shared.Jobs[job].label,
        onduty = QBCore.Shared.Jobs[job].defaultDuty,
        type   = QBCore.Shared.Jobs[job].type or 'none',
        grade  = { name = 'No Grades', level = 1, payment = 30, isboss = false },
    }
    local gradeInfo = QBCore.Shared.Jobs[job].grades[grade]
    if gradeInfo then
        self.PlayerData.job.grade.name    = gradeInfo.name
        self.PlayerData.job.grade.level   = grade
        self.PlayerData.job.grade.payment = gradeInfo.payment
        self.PlayerData.job.grade.isboss  = gradeInfo.isboss or false
        self.PlayerData.job.isboss        = gradeInfo.isboss or false
    end
    if not self.Offline then
        self:UpdateClient('job', self.PlayerData.job)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnJobUpdate', self.PlayerData.job)
    end
    return true
end

function Player:SetGang(gang, grade)
    gang  = gang:lower()
    grade = grade or 1
    if not QBCore.Shared.Gangs[gang] then return false end
    self.PlayerData.gang = {
        name  = gang,
        label = QBCore.Shared.Gangs[gang].label,
        grade = { name = 'No Grades', level = 1, isboss = false },
    }
    local gradeInfo = QBCore.Shared.Gangs[gang].grades[grade]
    if gradeInfo then
        self.PlayerData.gang.grade.name   = gradeInfo.name
        self.PlayerData.gang.grade.level  = grade
        self.PlayerData.gang.grade.isboss = gradeInfo.isboss or false
        self.PlayerData.gang.isboss       = gradeInfo.isboss or false
    end
    if not self.Offline then
        self:UpdateClient('gang', self.PlayerData.gang)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnGangUpdate', self.PlayerData.gang)
    end
    return true
end

function Player:Notify(text, notifType, length, icon)
    TriggerClientEvent(self.PlayerData.source, 'QBCore:Notify', text, notifType, length, icon)
end

function Player:HasItem(items, amount)
    return QBCore.Functions.HasItem(self.PlayerData.source, items, amount)
end

function Player:SetJobDuty(onDuty)
    self.PlayerData.job.onduty = not not onDuty
    if not self.Offline then
        self:UpdateClient('job', self.PlayerData.job)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnJobUpdate', self.PlayerData.job)
    end
end

function Player:SetPlayerData(key, val)
    if not key or type(key) ~= 'string' then return end
    self.PlayerData[key] = val
    self:UpdateClient(key, val)
end

function Player:SetMetaData(meta, val)
    if not meta or type(meta) ~= 'string' then return end
    if meta == 'hunger' or meta == 'thirst' then
        val = val > 100 and 100 or val
    end
    self.PlayerData.metadata[meta] = val
    self:UpdateClient('metadata', self.PlayerData.metadata)
end

function Player:GetMetaData(meta)
    if not meta or type(meta) ~= 'string' then return end
    return self.PlayerData.metadata[meta]
end

function Player:AddJobReputation(amount)
    if not amount then return end
    amount = tonumber(amount)
    local jobName = self.PlayerData.job.name
    self.PlayerData.metadata.jobrep[jobName] = self.PlayerData.metadata.jobrep[jobName] + amount
    self:UpdateClient('metadata', self.PlayerData.metadata)
end

function Player:AddMoney(moneytype, amount, reason)
    reason    = reason or 'unknown'
    moneytype = moneytype:lower()
    amount    = tonumber(amount)
    if amount < 0 then return end
    if not self.PlayerData.money[moneytype] then return false end
    self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] + amount
    if not self.Offline then
        self:UpdateClient('money', self.PlayerData.money)
        TriggerClientEvent(self.PlayerData.source, 'qb-hud:client:OnMoneyChange', moneytype, amount, false)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'add', reason)
    end
    return true
end

function Player:RemoveMoney(moneytype, amount, reason)
    reason    = reason or 'unknown'
    moneytype = moneytype:lower()
    amount    = tonumber(amount)
    if amount < 0 then return end
    if not self.PlayerData.money[moneytype] then return false end
    for _, mtype in pairs(QBCore.Config.Money.DontAllowMinus) do
        if mtype == moneytype and (self.PlayerData.money[moneytype] - amount) < 0 then
            return false
        end
    end
    self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] - amount
    if not self.Offline then
        self:UpdateClient('money', self.PlayerData.money)
        TriggerClientEvent(self.PlayerData.source, 'qb-hud:client:OnMoneyChange', moneytype, amount, true)
        if moneytype == 'bank' then
            TriggerClientEvent(self.PlayerData.source, 'qb-phone:client:RemoveBankMoney', amount)
        end
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'remove', reason)
    end
    return true
end

function Player:SetMoney(moneytype, amount, reason)
    reason    = reason or 'unknown'
    moneytype = moneytype:lower()
    amount    = tonumber(amount)
    if amount < 0 then return false end
    if not self.PlayerData.money[moneytype] then return false end
    local difference = amount - self.PlayerData.money[moneytype]
    self.PlayerData.money[moneytype] = amount
    if not self.Offline then
        self:UpdateClient('money', self.PlayerData.money)
        TriggerClientEvent(self.PlayerData.source, 'qb-hud:client:OnMoneyChange', moneytype, math.abs(difference), difference < 0)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'set', reason)
    end
    return true
end

function Player:GetMoney(moneytype)
    if not moneytype then return false end
    moneytype = moneytype:lower()
    return self.PlayerData.money[moneytype]
end

function Player:SetCreditCard(cardNumber)
    self.PlayerData.charinfo.card = cardNumber
    self:UpdateClient('charinfo', self.PlayerData.charinfo)
end

function Player:GetCardSlot(cardNumber, cardType)
    local item  = tostring(cardType):lower()
    local slots = GetSlotsByItem(self.PlayerData.items, item)
    for _, slot in pairs(slots) do
        if slot and self.PlayerData.items[slot].info.cardNumber == cardNumber then
            return slot
        end
    end
    return nil
end

function Player:Save()
    if self.Offline then
        QBCore.Player.SaveOffline(self.PlayerData)
    else
        QBCore.Player.Save(self.PlayerData.source)
    end
end

function Player:Logout()
    if self.Offline then return end
    QBCore.Player.Logout(self.PlayerData.source)
end

-- Adds a method to this specific instance (does not affect other players).
function Player:AddMethod(methodName, handler)
    if type(methodName) ~= 'string' or type(handler) ~= 'function' then return false end
    self[methodName] = handler
    return true
end

function Player:AddField(fieldName, data)
    if type(fieldName) ~= 'string' or type(data) == 'function' then return false end
    self[fieldName] = data
    return true
end

-- ─────────────────────────── static functions ───────────────────────────────

function QBCore.Player.Login(source, citizenid, newData)
    if not source then return false end
    if citizenid then
        local PlayerState = source:GetLyraPlayerState()
        local license     = PlayerState:GetHelixUserId()
        local result      = Database.Select('SELECT * FROM players where citizenid = ?', { citizenid })
        local PlayerData  = result[1] and result[1].Columns:ToTable()
        if PlayerData and license == PlayerData.license then
            PlayerData.money    = JSON.parse(PlayerData.money)
            PlayerData.job      = JSON.parse(PlayerData.job)
            PlayerData.gang     = JSON.parse(PlayerData.gang)
            PlayerData.position = JSON.parse(PlayerData.position)
            PlayerData.metadata = JSON.parse(PlayerData.metadata)
            PlayerData.charinfo = JSON.parse(PlayerData.charinfo)
            PlayerData.items    = formatItems(JSON.parse(PlayerData.inventory))
            QBCore.Player.CheckPlayerData(source, PlayerData)
        end
    else
        QBCore.Player.CheckPlayerData(source, newData)
    end
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerLoaded')
    TriggerLocalServerEvent('QBCore:Server:OnPlayerLoaded', source)
    return true
end

function QBCore.Player.GetOfflinePlayer(citizenid)
    if not citizenid then return nil end
    local result = Database.Select('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not result or #result == 0 then return nil end
    local PlayerData = result[1].Columns:ToTable()
    PlayerData.money    = JSON.parse(PlayerData.money)
    PlayerData.job      = JSON.parse(PlayerData.job)
    PlayerData.gang     = JSON.parse(PlayerData.gang)
    PlayerData.position = JSON.parse(PlayerData.position)
    PlayerData.metadata = JSON.parse(PlayerData.metadata)
    PlayerData.charinfo = JSON.parse(PlayerData.charinfo)
    PlayerData.items    = formatItems(JSON.parse(PlayerData.inventory))
    return QBCore.Player.CheckPlayerData(nil, PlayerData)
end

function QBCore.Player.GetPlayerByLicense(license)
    if not license then return nil end
    local source = QBCore.Functions.GetSource(license)
    if source > 0 then return QBCore.Players[source] end
    return nil
end

function QBCore.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local Offline = not source
    if source then
        PlayerData.source  = source
        local PlayerState  = source:GetLyraPlayerState()
        PlayerData.netId   = PlayerState:GetPlayerId()
        PlayerData.license = PlayerState:GetHelixUserId()
        PlayerData.name    = PlayerState:GetPlayerName()
    end
    applyDefaults(PlayerData, QBCore.Config.Player.PlayerDefaults)
    return QBCore.Player.CreatePlayer(PlayerData, Offline)
end

function QBCore.Player.CreatePlayer(PlayerData, Offline)
    local player = Player.new(PlayerData, Offline)

    if QBCore.Config.Server.Permissions[PlayerData.license] then
        AddPermission(PlayerData.source)
    end

    if not Offline then
        QBCore.Players[PlayerData.source] = player
        QBCore.Player.Save(PlayerData.source)
        exports['qb-multicharacter']:SetPlayerLoaded(player)
        player:UpdateClient()
    end

    return player
end

function QBCore.Player.Logout(source)
    if not QBCore.Players[source] then return end
    local player = QBCore.Players[source]
    player:Save()
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerUnload')
    TriggerLocalServerEvent('QBCore:Server:OnPlayerUnload', source)
    QBCore.Player_Buckets[player.PlayerData.license] = nil
    QBCore.Players[source] = nil
end

function QBCore.Player.Save(source)
    local pcoords    = QBCore.Config.DefaultSpawn
    local ped        = GetPlayerPawn(source)
    pcoords          = ped and GetEntityCoords(ped) or (PositionCache[source] or pcoords)

    local PlayerData = QBCore.Players[source].PlayerData
    if not PlayerData then
        print('ERROR QBCORE.PLAYER.SAVE - PLAYERDATA IS EMPTY!')
        return
    end

    local ItemsJson = {}
    if PlayerData.items and next(PlayerData.items) then
        for slot, item in pairs(PlayerData.items) do
            if item then
                ItemsJson[#ItemsJson + 1] = {
                    name   = item.name,
                    amount = item.amount,
                    info   = item.info,
                    slot   = slot,
                }
            end
        end
    end

    Database.Execute([[
        INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata, inventory)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(citizenid) DO UPDATE SET
            cid       = excluded.cid,
            name      = excluded.name,
            money     = excluded.money,
            charinfo  = excluded.charinfo,
            job       = excluded.job,
            gang      = excluded.gang,
            position  = excluded.position,
            metadata  = excluded.metadata,
            inventory = excluded.inventory;
    ]], {
        PlayerData.citizenid,
        tonumber(PlayerData.cid),
        PlayerData.license,
        PlayerData.name,
        JSON.stringify(PlayerData.money),
        JSON.stringify(PlayerData.charinfo),
        JSON.stringify(PlayerData.job),
        JSON.stringify(PlayerData.gang),
        JSON.stringify({ x = pcoords.X, y = pcoords.Y, z = pcoords.Z }),
        JSON.stringify(PlayerData.metadata),
        JSON.stringify(ItemsJson),
    })

    print(('[QBCORE] Saved player data for %s (Citizen ID: %s)'):format(PlayerData.name, PlayerData.citizenid))
end

local playertables = {
    { table = 'players' },
    { table = 'apartments' },
    { table = 'bank_accounts' },
    { table = 'crypto_transactions' },
    { table = 'phone_invoices' },
    { table = 'phone_messages' },
    { table = 'playerskins' },
    { table = 'player_contacts' },
    { table = 'player_mails' },
    { table = 'player_outfits' },
    { table = 'player_vehicles' },
}

function QBCore.Player.DeleteCharacter(source, citizenid)
    if not source or not citizenid then
        print('[Error] qb-core couldn\'t delete character')
        return false
    end
    local PlayerState = source:GetLyraPlayerState()
    local license     = PlayerState:GetHelixUserId()
    local result      = Database.Select('SELECT license FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not result or #result == 0 or license ~= result[1].Columns:ToTable().license then
        source:Kick(Lang:t('info.exploit_dropped'))
        return false
    end
    if not Database.Execute('BEGIN TRANSACTION') then
        print('[Error] qb-core couldn\'t start a transaction when deleting a character.')
        return false
    end
    local query   = 'DELETE FROM %s WHERE citizenid = ?'
    local Success = true
    for i = 1, #playertables do
        if not Database.Execute(query:format(playertables[i].table), { citizenid }) then
            Success = false
            break
        end
    end
    if not Success then
        Database.Execute('ROLLBACK')
        return false
    end
    Database.Execute('COMMIT')
    return true
end

-- ─────────────────────────── export bridge ──────────────────────────────────

for functionName, func in pairs(QBCore.Player) do
    if type(func) == 'function' then
        exports('qb-core', functionName, func)
    end
end
