---@type table<QBCore.Player> the logged in players
QBCore.Players = {}

---@class QBCore.Player
---@field public PlayerData QBCore.PlayerData The player data of the player
---@field public Offline boolean Whether the player is offline (true) or online (false)
---@field public Functions table<string, fun(... : any) : any> The functions available for the player
QBCore.Player = {}

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    print('HEvent:PlayerUnloaded:', source)
    QBCore.Player.Logout(source)
end)

-- Cache location on UnPossess
local PositionCache = {}
RegisterServerEvent('HEvent:PlayerUnPossessed', function(source, Pawn)
    if Pawn then
        PositionCache[source] = Pawn:K2_GetActorLocation()
    end
end)

-- Logout

---Logs out the player.
---This will save and unload the players character, as well as
---mark the player as no longer known, meaning trying to receive
---the player after a call to this function will probably result
---in errors.
---@param source HPlayer the HPlayer object of the player to log out (see HELIX documentation for more info)
function QBCore.Player.Logout(source)
    if not QBCore.Players[source] then return end
    local Player = QBCore.Players[source]
    Player.Functions.Save()
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerUnload')
    QBCore.Player_Buckets[Player.PlayerData.license] = nil
    QBCore.Players[source] = nil
end

-- Functions

local function formatItems(inventory)
    local formattedItems = {}
    for _, item in pairs(inventory) do
        if item then
            local itemInfo = QBCore.Shared.Items[item.name:lower()]
            if itemInfo then
                formattedItems[item.slot] = {
                    name = itemInfo['name'],
                    amount = item.amount,
                    info = item.info or {},
                    label = itemInfo['label'],
                    description = itemInfo['description'] or '',
                    weight = itemInfo['weight'],
                    type = itemInfo['type'],
                    unique = itemInfo['unique'],
                    useable = itemInfo['useable'],
                    image = itemInfo['image'],
                    shouldClose = itemInfo['shouldClose'],
                    slot = item.slot,
                    combinable = itemInfo['combinable']
                }
            end
        end
    end
    return formattedItems
end

-- Login

---Logs in the player.
---This will load the players character from the database,
---create a player object, and call the 'QBCore:Server:OnPlayerLoaded' and
---'QBCore:Client:OnPlayerLoaded' events.
---@nodiscard
---@param source HPlayer the HPlayer object of the player to log in (see HELIX documentation for more info)
---@param citizenid string? the citizen ID of the character to load. If nil a new character will be created with the provided newData.
---@param newData QBCore.PlayerData? the data for the new character to create. This will be ignored if the citizenid parameter is provided.
---@return boolean success true if the player was successfully logged in, false otherwise
function QBCore.Player.Login(source, citizenid, newData)
    if not source then return false end
    if citizenid then
        local PlayerState = source:GetLyraPlayerState()
        local license = PlayerState:GetHelixUserId()
        local result = Database.Select('SELECT * FROM players where citizenid = ?', { citizenid })
        local PlayerData = result[1] and result[1].Columns:ToTable()
        if PlayerData and license == PlayerData.license then
            PlayerData.money = JSON.parse(PlayerData.money)
            PlayerData.job = JSON.parse(PlayerData.job)
            PlayerData.gang = JSON.parse(PlayerData.gang)
            PlayerData.position = JSON.parse(PlayerData.position)
            PlayerData.metadata = JSON.parse(PlayerData.metadata)
            PlayerData.charinfo = JSON.parse(PlayerData.charinfo)
            PlayerData.items = formatItems(JSON.parse(PlayerData.inventory))
            QBCore.Player.CheckPlayerData(source, PlayerData)
        end
    else
        QBCore.Player.CheckPlayerData(source, newData)
    end
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerLoaded')
    TriggerLocalServerEvent('QBCore:Server:OnPlayerLoaded', source)
    return true
end

---Gets a player object by their license identifier.
---This requires the player to be logged in.
---@nodiscard
---@param license string the license identifier of the player
---@return QBCore.Player? player the player object if found, nil otherwise
function QBCore.Player.GetPlayerByLicense(license)
    if license then
        local source = QBCore.Functions.GetSource(license)
        if source > 0 then
            return QBCore.Players[source]
        end
    end
    return nil
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

---Ensures that the provided player data has all required fields,
---and creates a new player object. This should not be called if the
---player is already logged in.
---@nodiscard
---@param source HPlayer the HPlayer object of the player to create (see HELIX documentation for more info)
---@param PlayerData QBCore.PlayerData? the player data to check and create the player object with
---@return QBCore.Player player the created player object
function QBCore.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local Offline = not source
    if source then
        PlayerData.source = source
        local PlayerState = source:GetLyraPlayerState()
        PlayerData.netId = PlayerState:GetPlayerId()
        PlayerData.license = PlayerState:GetHelixUserId()
        PlayerData.name = PlayerState:GetPlayerName()
    end
    applyDefaults(PlayerData, QBCore.Config.Player.PlayerDefaults)
    return QBCore.Player.CreatePlayer(PlayerData, Offline)
end

-- TODO: create a QBCore.Player function factory creating the player
-- data functions, create dummy implementations for proper doc generation
-- and remove the function creation from the CreatePlayer function and
-- instead generate them with the function factory.
---@type table<string, fun(self: QBCore.Player): function>
local functionFactory = {}
function functionFactory.UpdatePlayerData(self)
    ---@cast self QBCore.Player
    return function()
        if self.Offline then return end
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Player:SetPlayerData', self.PlayerData)
    end
end

function functionFactory.SetJob(self)
    ---@cast self QBCore.Player
    return function(job, grade)
        job = job:lower()
        grade = grade or 1
        if not QBCore.Shared.Jobs[job] then return false end
        self.PlayerData.job = {
            name = job,
            label = QBCore.Shared.Jobs[job].label,
            onduty = QBCore.Shared.Jobs[job].defaultDuty,
            type = QBCore.Shared.Jobs[job].type or 'none',
            grade = {
                name = 'No Grades',
                level = 1,
                payment = 30,
                isboss = false
            },
            isboss = false
        }
        local jobGradeInfo = QBCore.Shared.Jobs[job].grades[grade]
        if jobGradeInfo then
            self.PlayerData.job.grade.name = jobGradeInfo.name
            self.PlayerData.job.grade.level = grade
            self.PlayerData.job.grade.payment = jobGradeInfo.payment
            self.PlayerData.job.grade.isboss = jobGradeInfo.isboss or false
            self.PlayerData.job.isboss = jobGradeInfo.isboss or false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnJobUpdate', self.PlayerData.job)
        end

        return true
    end
end

function functionFactory.SetGang(self)
    ---@cast self QBCore.Player
    return  function(gang, grade)
        gang = gang:lower()
        grade = grade or 1
        if not QBCore.Shared.Gangs[gang] then return false end
        self.PlayerData.gang = {
            name = gang,
            label = QBCore.Shared.Gangs[gang].label,
            grade = {
                name = 'No Grades',
                level = 1,
                isboss = false
            },
            isboss = false
        }
        local gangGradeInfo = QBCore.Shared.Gangs[gang].grades[grade]
        if gangGradeInfo then
            self.PlayerData.gang.grade.name = gangGradeInfo.name
            self.PlayerData.gang.grade.level = grade
            self.PlayerData.gang.grade.isboss = gangGradeInfo.isboss or false
            self.PlayerData.gang.isboss = gangGradeInfo.isboss or false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnGangUpdate', self.PlayerData.gang)
        end

        return true
    end
end

function functionFactory.Notify(self)
    ---@cast self QBCore.Player
    return function(text, type, length, icon)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Notify', text, type, length, icon)
    end
end

function functionFactory.HasItem(self)
    ---@cast self QBCore.Player
    return function(items, amount)
        return QBCore.Functions.HasItem(self.PlayerData.source, items, amount)
    end
end

function functionFactory.SetJobDuty(self)
    ---@cast self QBCore.Player
    return function(onDuty)
        self.PlayerData.job.onduty = not not onDuty
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnJobUpdate', self.PlayerData.job)
        self.Functions.UpdatePlayerData()
    end
end

function functionFactory.SetPlayerData(self)
    ---@cast self QBCore.Player
    return function(key, val)
        if not key or type(key) ~= 'string' then return end
        self.PlayerData[key] = val
        self.Functions.UpdatePlayerData()
    end
end


function functionFactory.SetMetaData(self)
    ---@cast self QBCore.Player
    return function(meta, val)
        if not meta or type(meta) ~= 'string' then return end
        if meta == 'hunger' or meta == 'thirst' then
            val = val > 100 and 100 or val
        end
        self.PlayerData.metadata[meta] = val
        self.Functions.UpdatePlayerData()
    end
end

function functionFactory.GetMetaData(self)
    ---@cast self QBCore.Player
    return function(meta)
        if not meta or type(meta) ~= 'string' then return end
        return self.PlayerData.metadata[meta]
    end
end

function functionFactory.AddJobReputation(self)
    ---@cast self QBCore.Player
    return function(amount)
        if not amount then return end
        amount = tonumber(amount)
        self.PlayerData.metadata['jobrep'][self.PlayerData.job.name] = self.PlayerData.metadata['jobrep'][self.PlayerData.job.name] + amount
        self.Functions.UpdatePlayerData()
    end
end

function functionFactory.AddMoney(self)
    ---@cast self QBCore.Player
    return function(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then return false end
        if not self.PlayerData.money[moneytype] then return false end
        self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] + amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerClientEvent(self.PlayerData.source, 'qb-hud:client:OnMoneyChange', moneytype, amount, false)
            TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'add', reason)
        end

        return true
    end
end

function functionFactory.RemoveMoney(self)
    ---@cast self QBCore.Player
    return function(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then return false end
        if not self.PlayerData.money[moneytype] then return false end
        for _, mtype in pairs(QBCore.Config.Money.DontAllowMinus) do
            if mtype == moneytype then
                if (self.PlayerData.money[moneytype] - amount) < 0 then
                    return false
                end
            end
        end
        self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] - amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerClientEvent(self.PlayerData.source, 'qb-hud:client:OnMoneyChange', moneytype, amount, true)
            if moneytype == 'bank' then
                TriggerClientEvent(self.PlayerData.source, 'qb-phone:client:RemoveBankMoney', amount)
            end
            TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'remove', reason)
        end

        return true
    end
end

function functionFactory.SetMoney(self)
    ---@cast self QBCore.Player
    return function(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then return false end
        if not self.PlayerData.money[moneytype] then return false end
        local difference = amount - self.PlayerData.money[moneytype]
        self.PlayerData.money[moneytype] = amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerClientEvent(self.PlayerData.source, 'qb-hud:client:OnMoneyChange', moneytype, math.abs(difference), difference < 0)
            TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'set', reason)
        end

        return true
    end
end

function functionFactory.GetMoney(self)
    ---@cast self QBCore.Player
    return function(moneytype)
        if not moneytype then return false end
        moneytype = moneytype:lower()
        return self.PlayerData.money[moneytype]
    end
end

function functionFactory.SetCreditCard(self)
    ---@cast self QBCore.Player
    return function(cardNumber)
        self.PlayerData.charinfo.card = cardNumber
        self.Functions.UpdatePlayerData()
    end
end

function functionFactory.GetCreditCardSlot(self)
    ---@cast self QBCore.Player
    return function(cardNumber, cardType)
        local item = tostring(cardType):lower()
        local slots = GetSlotsByItem(self.PlayerData.items, item)
        for _, slot in pairs(slots) do
            if slot then
                if self.PlayerData.items[slot].info.cardNumber == cardNumber then
                    return slot
                end
            end
        end
        return nil
    end
end

function functionFactory.Save(self)
    ---@cast self QBCore.Player
    return function()
        if self.Offline then
            -- TODO: requires implementation?
            QBCore.Player.SaveOffline(self.PlayerData)
        else
            QBCore.Player.Save(self.PlayerData.source)
        end
    end
end

function functionFactory.Logout(self)
    ---@cast self QBCore.Player
    return function()
        if self.Offline then return end
        QBCore.Player.Logout(self.PlayerData.source)
    end
end

function functionFactory.AddMethod(self)
    ---@cast self QBCore.Player
    return function(methodName, handler)
        self.Functions[methodName] = handler
    end
end

function functionFactory.AddField(self)
    ---@cast self QBCore.Player
    return function(fieldName, data)
        self[fieldName] = data
    end
end

---Updates the player data on the client.
---This will trigger the 'QBCore:Player:SetPlayerData' event on the client with the players
---current player data.
---If the player is offline this function will do nothing.
---@none-static
function QBCore.Player.Functions.UpdatePlayerData()
    error('Dummy implementation for doc generation only')
end

---Sets the job of the player.
---This will update the players job data and trigger the 'QBCore:Client:OnJobUpdate' event on the client.
---If the player is offline this will still update the job data, but will not trigger any client events.
---@none-static
---@nodiscard
---@param job string the name of the job to set
---@param grade number the grade level of the job to set
---@return boolean success true if the job was successfully set, false otherwise
function QBCore.Player.Functions.SetJob(job, grade)
    error('Dummy implementation for doc generation only')
end

---Sets the gang of the player.
---This will update the players gang data and trigger the 'QBCore:Client:OnGangUpdate' event on the client.
---If the player is offline this will still update the gang data, but will not trigger any client events.
---@none-static
---@nodiscard
---@param gang string the name of the gang to set
---@param grade number the grade level of the gang to set
---@return boolean success true if the gang was successfully set, false otherwise
function QBCore.Player.Functions.SetGang(gang, grade)
    error('Dummy implementation for doc generation only')
end

---Sends a notification to the player.
---This will trigger the 'QBCore:Notify' event on the client with the provided parameters.
---@none-static
---@param text string the text of the notification
---@param type string? the type of the notification (default: 'primary')
---@param length number? the length of time the notification should be displayed
---@param icon string? the icon to display with the notification
function QBCore.Player.Functions.Notify(text, type, length, icon)
    error('Dummy implementation for doc generation only')
end

---Checks if the player has the given item(s).
---This will check if the player has the given item or list of items.
---@none-static
---@nodiscard
---@param items string|table<string, any>|table<string> not sure about the table format.
---the code of that is a little hard to read.
---@param amount number? the amount of the item(s) to check for (default: 1)
---@return boolean hasItem true if the player has the item(s), false otherwise
function QBCore.Player.Functions.HasItem(items, amount)
    error('Dummy implementation for doc generation only')
end

---Sets the job duty status of the player.
---This will update the players job duty status and trigger the 'QBCore:Client:OnJobUpdate' event on the client.
---@none-static
---@param onDuty boolean whether the player is on duty for their job
function QBCore.Player.Functions.SetJobDuty(onDuty)
    error('Dummy implementation for doc generation only')
end

---Sets a key in the player's data to the given value.
---This will update the player's data and trigger the 'QBCore:Player:SetPlayerData' event on the client.
---@none-static
---@param key string the key in the player's data to set
---@param val any the value to set the key to
function QBCore.Player.Functions.SetPlayerData(key, val)
    error('Dummy implementation for doc generation only')
end

---Sets a metadata key in the player's metadata to the given value.
---This will update the player's metadata and trigger the 'QBCore:Player:SetPlayerData' event on the client.
---@none-static
---@param meta string the metadata key to set
---@param val any the value to set the metadata key to
function QBCore.Player.Functions.SetMetaData(meta, val)
    error('Dummy implementation for doc generation only')
end

---Gets a metadata value from the player's metadata.
---This will return the value of the given metadata key.
---@none-static
---@nodiscard
---@param meta string the metadata key to get
---@return any value the value of the metadata key
function QBCore.Player.Functions.GetMetaData(meta)
    error('Dummy implementation for doc generation only')
end

---Adds job reputation to the player for their current job.
---This will update the player's job reputation in their metadata
---and trigger the 'QBCore:Player:SetPlayerData' event on the client.
---@none-static
---@param amount number the amount of job reputation to add
function QBCore.Player.Functions.AddJobReputation(amount)
    error('Dummy implementation for doc generation only')
end

---Adds money to the player's account.
---This will update the player's money and trigger the 'QBCore:Client:OnMoneyChange'
---as well as 'qb-hud:client:OnMoneyChange' events on the client.
---A negative amount will be ignored and the function will return false.
---@none-static
---@nodiscard
---@param moneytype string the type of money to add (e.g. 'cash', 'bank', etc.)
---@param amount number the amount of money to add
---@param reason string? the reason for adding the money (default: 'unknown')
---@return boolean success true if the money was successfully added, false otherwise
function QBCore.Player.Functions.AddMoney(moneytype, amount, reason)
    error('Dummy implementation for doc generation only')
end

---Removes money from the player's account.
---This will update the player's money and trigger the 'QBCore:Client:OnMoneyChange'
---as well as 'qb-hud:client:OnMoneyChange' events on the client.
---If the account is 'bank' it will also trigger the 'qb-phone:client:RemoveBankMoney' event.
---A negative amount will be ignored and the function will return false.
---@none-static
---@nodiscard
---@param moneytype string the type of money to remove (e.g. 'cash', 'bank', etc.)
---@param amount number the amount of money to remove
---@param reason string? the reason for removing the money (default: 'unknown')
---@return boolean success true if the money was successfully removed, false otherwise
function QBCore.Player.Functions.RemoveMoney(moneytype, amount, reason)
    error('Dummy implementation for doc generation only')
end

---Sets the player's money to the given amount.
---This will update the player's money and trigger the 'QBCore:Client:OnMoneyChange'
---as well as 'qb-hud:client:OnMoneyChange' events on the client.
---A negative amount will be ignored and the function will return false.
---@none-static
---@nodiscard
---@param moneytype string the type of money to set (e.g. 'cash', 'bank', etc.)
---@param amount number the amount of money to set
---@param reason string? the reason for setting the money (default: 'unknown')
---@return boolean success true if the money was successfully set, false otherwise
function QBCore.Player.Functions.SetMoney(moneytype, amount, reason)
    error('Dummy implementation for doc generation only')
end

---Gets the amount of money the player has for the given money type.
---@none-static
---@nodiscard
---@param moneytype string the type of money to get (e.g. 'cash', 'bank', etc.)
---@return number? amount the amount of money the player has, or nil if the money type is invalid
function QBCore.Player.Functions.GetMoney(moneytype)
    error('Dummy implementation for doc generation only')
end

---Sets the player's credit/debit card number.
---This will update the player's character info and trigger the 'QBCore:Player:SetPlayerData' event on the client.
---@none-static
---@param cardNumber string the credit/debit card number to set
function QBCore.Player.Functions.SetCreditCard(cardNumber)
    error('Dummy implementation for doc generation only')
end

---Gets the inventory slot of the player's card with the given card number and type.
---This will search the player's inventory for the card and return the slot if found.
---If not found, it will return nil.
---@none-static
---@nodiscard
---@param cardNumber string the credit/debit card number to search for
---@param cardType string the type of card to search for (e.g. 'credit', 'debit', etc.)
---@return number? slot the inventory slot of the card if found, or nil if not found
function QBCore.Player.Functions.GetCardSlot(cardNumber, cardType)
    error('Dummy implementation for doc generation only')
end

---Saves the player to the database.
---If the player is offline, this will save the offline player data.
---If the player is online, this will save the online player data.
---@none-static
function QBCore.Player.Functions.Save()
    error('Dummy implementation for doc generation only')
end

---Logs out the player.
---This will save and unload the players character, as well as
---mark the player as no longer known, meaning trying to receive
---the player after a call to this function will probably result
---in errors.
---@none-static
function QBCore.Player.Functions.Logout()
    error('Dummy implementation for doc generation only')
end

---Adds a new method to the player object.
---This will add the given method to the player's Functions table.
---This will only affect the current player object and not all player objects.
---@none-static
---@param methodName string the name of the method to add
---@param handler function the function to add as the method
function QBCore.Player.Functions.AddMethod(methodName, handler)
    error('Dummy implementation for doc generation only')
end

---Adds a new field to the player object.
---This will add the given field to the player object.
---This will only affect the current player object and not all player objects.
---@none-static
---@param fieldName string the name of the field to add
---@param data any the data to set the field to
function QBCore.Player.Functions.AddField(fieldName, data)
    error('Dummy implementation for doc generation only')
end

---Creates a new player object for the given player data.
---@nodiscard
---@param PlayerData QBCore.PlayerData the player data to create the player object with
---@param Offline boolean whether the player is offline (true) or online (false)
---@return QBCore.Player player the created player object
function QBCore.Player.CreatePlayer(PlayerData, Offline)
    local self = {}
    self.Functions = {}
    self.PlayerData = PlayerData
    self.Offline = Offline

    for key, func in pairs(functionFactory) do
        self.Functions[key] = func(self)
    end

    if QBCore.Config.Server.Permissions[license] then
        AddPermission(self.PlayerData.source)
    end

    if self.Offline then
        return self
    else
        QBCore.Players[self.PlayerData.source] = self
        QBCore.Player.Save(self.PlayerData.source)
        exports['qb-multicharacter']:SetPlayerLoaded(self)
        self.Functions.UpdatePlayerData()
        return self
    end
end

---Saves the player to the database.
---@param source HPlayer the HPlayer object of the player to save (see HELIX documentation for more info)
function QBCore.Player.Save(source)
    local pcoords = QBCore.Config.DefaultSpawn
    local ped = GetPlayerPawn(source)
    if ped then
        pcoords = GetEntityCoords(ped)
    else
        pcoords = PositionCache[source] or pcoords
    end
    local PlayerData = QBCore.Players[source].PlayerData
    if not PlayerData then
        print('ERROR QBCORE.PLAYER.SAVE - PLAYERDATA IS EMPTY!')
        return
    end

    local items = PlayerData.items
    local ItemsJson = {}

    if items and next(items) then
        for slot, item in pairs(items) do
            if item then
                ItemsJson[#ItemsJson + 1] = {
                    name = item.name,
                    amount = item.amount,
                    info = item.info,
                    slot = slot,
                }
            end
        end
    end

    local result = Database.Execute([[INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata, inventory)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(citizenid) DO UPDATE SET
            cid = excluded.cid,
            name = excluded.name,
            money = excluded.money,
            charinfo = excluded.charinfo,
            job = excluded.job,
            gang = excluded.gang,
            position = excluded.position,
            metadata = excluded.metadata,
            inventory = excluded.inventory;
        ]],
        {
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
    { table = 'player_houses' },
    { table = 'player_mails' },
    { table = 'player_outfits' },
    { table = 'player_vehicles' }
}

---Attempts to delete the character with the given citizenid for the player
---with the given source.
---@nodiscard
---@param source HPlayer the HPlayer object to delete the character for
---@param citizenid string the citizenid of the chracter to delete
---@return boolean success true if the character was successfully deleted, false otherwise
function QBCore.Player.DeleteCharacter(source, citizenid)
    if not source or not citizenid then
        print('[Error] qb-core couldn\'t delete character')
        return
    end
    local PlayerState = source:GetLyraPlayerState()
    local license = PlayerState:GetHelixUserId()
    local result = Database.Select('SELECT license FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if license == result[1].Columns:ToTable().license then
        local transactionStarted = Database.Execute('BEGIN TRANSACTION')
        if not transactionStarted then
            print('[Error] qb-core couldn\'t start a transaction when deleting a character.')
            return
        end
        local query = 'DELETE FROM %s WHERE citizenid = ?'
        local tableCount = #playertables
        local queries = {}

        local Success = true
        for i = 1, tableCount do
            local v = playertables[i]
            local QuerySuccess = Database.Execute(query:format(v.table), { citizenid })
            if not QuerySuccess then
                Success = false
                break
            end
        end

        if not Success then
            Database.Execute('ROLLBACK')
        else
            Database.Execute('COMMIT')
            return true
        end
    else
        source:Kick(Lang:t('info.exploit_dropped'))
    end
    return false
end

for functionName, func in pairs(QBCore.Player) do
    if type(func) == 'function' then
        exports('qb-core', functionName, func)
    end
end

exports('qb-core', 'Player', function(Player, MethodName, ...)
    if not QBCore.Players[Player] then return end
    if not MethodName then return end

    return QBCore.Players[Player].Functions[MethodName](...)
end)
