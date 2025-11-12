local Lang = require('locales/en')
local Accounts = {}
local Statements = {}

-- Functions

local function getPlayerAndCitizenId(playerId)
    local Player = exports['qb-core']:GetPlayer(playerId)
    if not Player then return nil, nil end
    return Player, Player.PlayerData.citizenid
end

local function GetNumberOfAccounts(citizenid)
    local numberOfAccounts = 0
    for _, account in pairs(Accounts) do
        if account.citizenid == citizenid then
            numberOfAccounts = numberOfAccounts + 1
        end
    end
    return numberOfAccounts
end

-- Exported Functions

local function CreatePlayerAccount(playerId, accountName, accountBalance, accountUsers)
    local Player, citizenid = getPlayerAndCitizenId(playerId)
    if not Player or not citizenid then return false end

    if Accounts[accountName] then
        return false
    end

    Accounts[accountName] = {
        citizenid = citizenid,
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'shared',
        users = accountUsers
    }

    local insertSuccess = exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bank_accounts (citizenid, account_name, account_balance, account_type, users) VALUES (?, ?, ?, ?, ?)', { citizenid, accountName, accountBalance, 'shared', accountUsers })
    return insertSuccess
end
exports('qb-banking', 'CreatePlayerAccount', CreatePlayerAccount)

local function CreateJobAccount(accountName, accountBalance)
    Accounts[accountName] = {
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'job'
    }
    local insertSuccess = exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bank_accounts (account_name, account_balance, account_type) VALUES (?, ?, ?)', { accountName, accountBalance, 'job' })
    return insertSuccess
end
exports('qb-banking', 'CreateJobAccount', CreateJobAccount)

local function CreateGangAccount(accountName, accountBalance)
    Accounts[accountName] = {
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'gang'
    }
    local insertSuccess = exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bank_accounts (account_name, account_balance, account_type) VALUES (?, ?, ?)', { accountName, accountBalance, 'gang' })
    return insertSuccess
end
exports('qb-banking', 'CreateGangAccount', CreateGangAccount)

local function CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    local Player, citizenid = getPlayerAndCitizenId(playerId)
    if not Player or not citizenid then return false end

    local newStatement = {
        citizenid = citizenid,
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = statementType
    }
    if accountType == 'player' or accountType == 'shared' then
        if accountType == 'player' then account = 'checking' end
        if not Statements[citizenid] then Statements[citizenid] = {} end
        if not Statements[citizenid][account] then Statements[citizenid][account] = {} end
        Statements[citizenid][account][#Statements[citizenid][account] + 1] = newStatement
    else
        if not Statements[account] then Statements[account] = {} end
        Statements[account][#Statements[account] + 1] = newStatement
    end

    local insertSuccess = exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bank_statements (citizenid, account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?, ?)', { citizenid, account, amount, reason, statementType })
    if not insertSuccess then return false end
    return true
end
exports('qb-banking', 'CreateBankStatement', CreateBankStatement)

local function AddMoney(accountName, amount, reason)
    if not reason then reason = 'External Deposit' end
    local newStatement = {
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = 'deposit'
    }
    if Accounts[accountName] then
        local accountToUpdate = Accounts[accountName]
        accountToUpdate.account_balance = accountToUpdate.account_balance + amount
        if not Statements[accountName] then Statements[accountName] = {} end
        Statements[accountName][#Statements[accountName] + 1] = newStatement
        exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)', { accountName, amount, reason, 'deposit' })
        local updateSuccess = exports['qb-core']:DatabaseAction('Execute', 'UPDATE bank_accounts SET account_balance = account_balance + ? WHERE account_name = ?', { amount, accountName })
        return updateSuccess
    end
    return false
end
exports('qb-banking', 'AddMoney', AddMoney)
exports('qb-banking', 'AddGangMoney', AddMoney)

local function RemoveMoney(accountName, amount, reason)
    if not reason then reason = 'External Withdrawal' end
    local newStatement = {
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = 'withdraw'
    }
    if Accounts[accountName] then
        local accountToUpdate = Accounts[accountName]
        accountToUpdate.account_balance = accountToUpdate.account_balance - amount
        if not Statements[accountName] then Statements[accountName] = {} end
        Statements[accountName][#Statements[accountName] + 1] = newStatement
        exports['qb-core']:DatabaseAction('Execute', 'INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)', { accountName, amount, reason, 'withdraw' })
        local updateSuccess = exports['qb-core']:DatabaseAction('Execute', 'UPDATE bank_accounts SET account_balance = account_balance - ? WHERE account_name = ?', { amount, accountName })
        return updateSuccess
    end
    return false
end
exports('qb-banking', 'RemoveMoney', RemoveMoney)
exports('qb-banking', 'RemoveGangMoney', RemoveMoney)

local function GetAccount(accountName)
    if Accounts[accountName] then
        return Accounts[accountName]
    end
    return nil
end
exports('qb-banking', 'GetAccount', GetAccount)
exports('qb-banking', 'GetGangAccount', GetAccount)

local function GetAccountBalance(accountName)
    local account = GetAccount(accountName)
    return account and account.account_balance or 0
end
exports('qb-banking', 'GetAccountBalance', GetAccountBalance)

-- Callbacks

RegisterCallback('openBank', function(source)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local accounts = {}
    local statements = {}
    if job.name ~= 'unemployed' and not Accounts[job.name] then CreateJobAccount(job.name, 0) end
    if gang.name ~= 'none' and not Accounts[gang.name] then CreateGangAccount(gang.name, 0) end
    accounts[#accounts + 1] = { account_name = 'checking', account_type = 'checking', account_balance = Player.PlayerData.money.bank }
    statements['checking'] = Statements[citizenid] and Statements[citizenid]['checking'] or {}
    for accountName, accountInfo in pairs(Accounts) do
        if accountInfo.citizenid == citizenid then
            accounts[#accounts + 1] = accountInfo
            if Statements[accountName] then statements[accountName] = Statements[accountName] end
        end
        if accountInfo.users and string.find(accountInfo.users, citizenid) then
            accounts[#accounts + 1] = accountInfo
            if Statements[accountName] then statements[accountName] = Statements[accountName] end
        end
        if (accountName == job.name and job.isboss) or (accountName == gang.name and gang.isboss) then
            accounts[#accounts + 1] = accountInfo
            if Statements[accountName] then statements[accountName] = Statements[accountName] end
        end
    end
    return { accounts = accounts, statements = statements, playerData = Player.PlayerData }
end)

RegisterCallback('openATM', function(source)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return end
    local bankCards = exports['qb-inventory']:GetItemsByName(source, 'bank_card')
    if not bankCards then return TriggerClientEvent(source, 'QBCore:Notify', Lang:t('error.card'), 'error') end
    local acceptablePins = {}
    for _, bankCard in ipairs(bankCards) do acceptablePins[#acceptablePins + 1] = bankCard.info.cardPin end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local accounts = {}
    accounts[#accounts + 1] = { account_name = 'checking', account_type = 'checking', account_balance = Player.PlayerData.money.bank }
    for accountName, accountInfo in pairs(Accounts) do
        if accountInfo.citizenid == citizenid then
            accounts[#accounts + 1] = accountInfo
        end
        if accountInfo.users and string.find(accountInfo.users, citizenid) then
            accounts[#accounts + 1] = accountInfo
        end
        if (accountName == job.name and job.isboss) or (accountName == gang.name and gang.isboss) then
            accounts[#accounts + 1] = accountInfo
        end
    end
    return { accounts = accounts, playerData = Player.PlayerData, acceptablePins = acceptablePins }
end)

RegisterCallback('withdraw', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local accountName = data.accountName
    local withdrawAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'Bank Withdrawal'
    if accountName == 'checking' then
        local accountBalance = Player.PlayerData.money.bank
        if accountBalance < withdrawAmount then return { success = false, message = Lang:t('error.money') } end
        exports['qb-core']:Player(source, 'RemoveMoney', 'bank', withdrawAmount, 'bank withdrawal')
        exports['qb-core']:Player(source, 'AddMoney', 'cash', withdrawAmount, 'bank withdrawal')
        if not CreateBankStatement(source, 'checking', withdrawAmount, reason, 'withdraw', 'player') then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.withdraw') }
    end
    if Accounts[accountName] then
        local job = Player.PlayerData.job
        local gang = Player.PlayerData.gang
        if Accounts[accountName].account_type == 'job' and job.name ~= accountName and not job.isboss then return { success = false, message = Lang:t('error.access') } end
        if Accounts[accountName].account_type == 'gang' and gang.name ~= accountName and not gang.isboss then return { success = false, message = Lang:t('error.access') } end
        local accountBalance = GetAccountBalance(accountName)
        if accountBalance < withdrawAmount then return { success = false, message = Lang:t('error.money') } end
        if not RemoveMoney(accountName, withdrawAmount) then return { success = false, message = Lang:t('error.error') } end
        exports['qb-core']:Player(source, 'AddMoney', 'cash', withdrawAmount, 'bank account: ' .. accountName .. ' withdrawal')
        if not CreateBankStatement(source, accountName, withdrawAmount, reason, 'withdraw', Accounts[accountName].account_type) then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.withdraw') }
    end
end)

RegisterCallback('deposit', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local accountName = data.accountName
    local depositAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'Bank Deposit'
    if accountName == 'checking' then
        local accountBalance = Player.PlayerData.money.cash
        if accountBalance < depositAmount then return { success = false, message = Lang:t('error.money') } end
        exports['qb-core']:Player(source, 'RemoveMoney', 'cash', depositAmount, 'bank deposit')
        exports['qb-core']:Player(source, 'AddMoney', 'bank', depositAmount, 'bank deposit')
        if not CreateBankStatement(source, 'checking', depositAmount, reason, 'deposit', 'player') then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.deposit') }
    end
    if Accounts[accountName] then
        local job = Player.PlayerData.job
        local gang = Player.PlayerData.gang
        if Accounts[accountName].account_type == 'job' and job.name ~= accountName and not job.isboss then return { success = false, message = Lang:t('error.access') } end
        if Accounts[accountName].account_type == 'gang' and gang.name ~= accountName and not gang.isboss then return { success = false, message = Lang:t('error.access') } end
        if Player.PlayerData.money.cash < depositAmount then return { success = false, message = Lang:t('error.money') } end
        exports['qb-core']:Player(source, 'RemoveMoney', 'cash', depositAmount, 'bank account: ' .. accountName .. ' deposit')
        if not AddMoney(accountName, depositAmount) then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.deposit') }
    end
end)

RegisterCallback('internalTransfer', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local fromAccountName = data.fromAccountName
    local toAccountName = data.toAccountName
    local transferAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'Internal transfer'
    if fromAccountName == 'checking' then
        if Player.PlayerData.money.bank < transferAmount then return { success = false, message = Lang:t('error.money') } end
        exports['qb-core']:Player(source, 'RemoveMoney', 'bank', transferAmount, reason)
        if toAccountName == 'checking' then
            exports['qb-core']:Player(source, 'AddMoney', 'bank', transferAmount, reason)
        else
            if not AddMoney(toAccountName, transferAmount) then return { success = false, message = Lang:t('error.error') } end
        end
        if not CreateBankStatement(source, 'checking', transferAmount, reason, 'withdraw', 'player') then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.transfer') }
    elseif toAccountName == 'checking' then
        if Accounts[fromAccountName].account_type == 'job' and job.name ~= fromAccountName and not job.isboss then return { success = false, message = Lang:t('error.access') } end
        if Accounts[fromAccountName].account_type == 'gang' and gang.name ~= fromAccountName and not gang.isboss then return { success = false, message = Lang:t('error.access') } end
        local fromAccountBalance = GetAccountBalance(fromAccountName)
        if fromAccountBalance < transferAmount then return { success = false, message = Lang:t('error.money') } end
        if not RemoveMoney(fromAccountName, transferAmount) then return { success = false, message = Lang:t('error.error') } end
        exports['qb-core']:Player(source, 'AddMoney', 'bank', transferAmount, reason)
        if not CreateBankStatement(source, 'checking', transferAmount, reason, 'deposit', 'player') then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.transfer') }
    else
        if Accounts[fromAccountName].account_type == 'job' and job.name ~= fromAccountName and not job.isboss then return { success = false, message = Lang:t('error.access') } end
        if Accounts[fromAccountName].account_type == 'gang' and gang.name ~= fromAccountName and not gang.isboss then return { success = false, message = Lang:t('error.access') } end
        local fromAccountBalance = GetAccountBalance(fromAccountName)
        if fromAccountBalance < transferAmount then return { success = false, message = Lang:t('error.money') } end
        if not RemoveMoney(fromAccountName, transferAmount) then return { success = false, message = Lang:t('error.error') } end
        if not AddMoney(toAccountName, transferAmount) then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.transfer') }
    end
end)

RegisterCallback('externalTransfer', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    local toAccountName = data.toAccountNumber
    local toPlayer = exports['qb-core']:GetPlayerByCitizenId(toAccountName)
    if not toPlayer then return { success = false, message = Lang:t('error.error') } end
    local fromAccountName = data.fromAccountName
    local transferAmount = tonumber(data.amount)
    local reason = (data.reason ~= '' and data.reason) or 'External transfer'
    if fromAccountName == 'checking' then
        if Player.PlayerData.money.bank < transferAmount then return { success = false, message = Lang:t('error.money') } end
        exports['qb-core']:Player(source, 'RemoveMoney', 'bank', transferAmount, reason)
        exports['qb-core']:Player(toPlayer.PlayerData.source, 'AddMoney', 'bank', transferAmount, reason)
        if not CreateBankStatement(source, 'checking', transferAmount, reason, 'withdraw', 'player') then return { success = false, message = Lang:t('error.error') } end
        if not CreateBankStatement(toPlayer.PlayerData.source, 'checking', transferAmount, reason, 'deposit', 'player') then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.transfer') }
    else
        if Accounts[fromAccountName].account_type == 'job' and job.name ~= fromAccountName and not job.isboss then return { success = false, message = Lang:t('error.access') } end
        if Accounts[fromAccountName].account_type == 'gang' and gang.name ~= fromAccountName and not gang.isboss then return { success = false, message = Lang:t('error.access') } end
        local fromAccountBalance = GetAccountBalance(fromAccountName)
        if fromAccountBalance < transferAmount then return { success = false, message = Lang:t('error.money') } end
        if not RemoveMoney(fromAccountName, transferAmount) then return { success = false, message = Lang:t('error.error') } end
        exports['qb-core']:Player(toPlayer.PlayerData.source, 'AddMoney', 'bank', transferAmount, reason)
        if not CreateBankStatement(toPlayer.PlayerData.source, 'checking', transferAmount, reason, 'deposit', 'player') then return { success = false, message = Lang:t('error.error') } end
        return { success = true, message = Lang:t('success.transfer') }
    end
end)

RegisterCallback('orderCard', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local cardNumber = math.random(1000000000000000, 9999999999999999)
    local pinNumber = tonumber(data.pin)
    if not pinNumber then return { success = false, message = Lang:t('error.pin') } end
    local info = {
        citizenid = citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        cardNumber = cardNumber,
        cardPin = pinNumber,
    }
    if not exports['qb-inventory']:AddItem(source, 'bank_card', 1, false, info, 'qb-banking:server:orderCard') then
        return { success = false, message = Lang:t('error.error') }
    end
    return { success = true, message = Lang:t('success.card') }
end)

RegisterCallback('openAccount', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local accountName = data.accountName
    local initialAmount = tonumber(data.amount)
    if GetNumberOfAccounts(citizenid) >= Config.maxAccounts then return { success = false, message = Lang:t('error.accounts') } end
    if Player.PlayerData.money.bank < initialAmount then return { success = false, message = Lang:t('error.money') } end
    exports['qb-core']:Player(source, 'RemoveMoney', 'bank', initialAmount, 'Opened account ' .. accountName)
    if not CreatePlayerAccount(source, accountName, initialAmount, JSON.stringify({})) then return { success = false, message = Lang:t('error.error') } end
    if not CreateBankStatement(source, accountName, initialAmount, 'Initial deposit', 'deposit', 'shared') then return { success = false, message = Lang:t('error.error') } end
    if not CreateBankStatement(source, 'checking', initialAmount, 'Initial deposit for ' .. accountName, 'withdraw', 'player') then return { success = false, message = Lang:t('error.error') } end
    --TriggerEvent('qb-log:server:CreateLog', 'banking', 'Account Opened', 'green', string.format('**%s** opened account **%s** with an initial deposit of **$%s**', GetPlayerName(src), accountName, initialAmount))
    return { success = true, message = Lang:t('success.account') }
end)

RegisterCallback('renameAccount', function(source, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local oldName = data.oldName
    local newName = data.newName
    if not Accounts[oldName] then return { success = false, message = Lang:t('error.error') } end
    if Accounts[oldName].citizenid ~= citizenid then return { success = false, message = Lang:t('error.access') } end
    Accounts[newName] = Accounts[oldName]
    Accounts[newName].account_name = newName
    Accounts[oldName] = nil
    local result = exports['qb-core']:DatabaseAction('Execute', 'UPDATE bank_accounts SET account_name = ? WHERE account_name = ? AND citizenid = ?', { newName, oldName, citizenid })
    if not result then return { success = false, message = Lang:t('error.error') } end
    --TriggerEvent('qb-log:server:CreateLog', 'banking', 'Account Renamed', 'red', string.format('**%s** renamed **%s** to **%s**', GetPlayerName(src), oldName, newName))
    return { success = true, message = Lang:t('success.rename') }
end)

RegisterCallback('deleteAccount', function(source, cb, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local accountName = data.accountName
    if not Accounts[accountName] then return { success = false, message = Lang:t('error.error') } end
    if Accounts[accountName].citizenid ~= citizenid then return { success = false, message = Lang:t('error.access') } end
    Accounts[accountName] = nil
    local result = exports['qb-core']:DatabaseAction('Execute', 'DELETE FROM bank_accounts WHERE account_name = ? AND citizenid = ?', { accountName, citizenid })
    if not result then return { success = false, message = Lang:t('error.error') } end
    --TriggerEvent('qb-log:server:CreateLog', 'banking', 'Account Deleted', 'red', string.format('**%s** deleted account **%s**', GetPlayerName(src), accountName))
    return { success = true, message = Lang:t('success.delete') }
end)

RegisterCallback('addUser', function(source, cb, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local userToAdd = data.userName
    local accountName = data.accountName
    if not Accounts[accountName] then return { success = false, message = Lang:t('error.account') } end
    if Accounts[accountName].citizenid ~= citizenid then return { success = false, message = Lang:t('error.access') } end
    local account = Accounts[accountName]
    local users = JSON.parse(account.users)
    for _, cid in ipairs(users) do
        if cid == userToAdd then return { success = false, message = Lang:t('error.user') } end
    end
    users[#users + 1] = userToAdd
    local usersData = JSON.stringify(users)
    Accounts[accountName].users = usersData
    local result = exports['qb-core']:DatabaseAction('Execute', 'UPDATE bank_accounts SET users = ? WHERE account_name = ? AND citizenid = ?', { usersData, accountName, citizenid })
    if not result then return { success = false, message = Lang:t('error.error') } end
    --TriggerEvent('qb-log:server:CreateLog', 'banking', 'User Added', 'green', string.format('**%s** added **%s** to **%s**', GetPlayerName(src), userToAdd, accountName))
    return { success = true, message = Lang:t('success.userAdd') }
end)

RegisterCallback('removeUser', function(source, cb, data)
    local Player, citizenid = getPlayerAndCitizenId(source)
    if not Player or not citizenid then return { success = false, message = Lang:t('error.error') } end
    local userToRemove = data.userName
    local accountName = data.accountName
    if not Accounts[accountName] then return { success = false, message = Lang:t('error.account') } end
    if Accounts[accountName].citizenid ~= citizenid then return { success = false, message = Lang:t('error.access') } end
    local account = Accounts[accountName]
    local users = JSON.parse(account.users)
    local userFound = false
    for i = #users, 1, -1 do
        if users[i] == userToRemove then
            table.remove(users, i)
            userFound = true
            break
        end
    end
    if not userFound then return { success = false, message = Lang:t('error.noUser') } end
    local usersData = JSON.stringify(users)
    Accounts[accountName].users = usersData
    local result = exports['qb-core']:DatabaseAction('Execute', 'UPDATE bank_accounts SET users = ? WHERE account_name = ? AND citizenid = ?', { usersData, accountName, citizenid })
    if not result then return { success = false, message = Lang:t('error.error') } end
    --TriggerEvent('qb-log:server:CreateLog', 'banking', 'User Removed', 'red', string.format('**%s** removed **%s** from **%s**', GetPlayerName(src), userToRemove, accountName))
    return { success = true, message = Lang:t('success.userRemove') }
end)

-- Items

-- QBCore.Functions.CreateUseableItem('bank_card', function(source, item)
--     local Player = exports['qb-core']:GetPlayer(source)
--     if not Player then return end
--     if Player.Functions.GetItemByName(item.name) then
--         TriggerClientEvent('qb-banking:client:useCard', source)
--     end
-- end)

-- Threads

local Jobs = exports['qb-core']:GetShared('Jobs')

local accounts = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM bank_accounts')
for _, account in ipairs(accounts) do
    Accounts[account.account_name] = account
end
for job in pairs(Jobs) do
    if Accounts[job] == nil then
        CreateJobAccount(job, 0)
    end
end

local statements = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM bank_statements')
for _, statement in ipairs(statements) do
    if statement.account_name == 'checking' then
        if not Statements[statement.citizenid] then Statements[statement.citizenid] = {} end
        if not Statements[statement.citizenid][statement.account_name] then Statements[statement.citizenid][statement.account_name] = {} end
        Statements[statement.citizenid][statement.account_name][#Statements[statement.citizenid][statement.account_name] + 1] = statement
    else
        if not Statements[statement.account_name] then Statements[statement.account_name] = {} end
        Statements[statement.account_name][#Statements[statement.account_name] + 1] = statement
    end
end

-- Commands

-- QBCore.Commands.Add('givecash', 'Give Cash', { { name = 'id', help = 'Player ID' }, { name = 'amount', help = 'Amount' } }, true, function(source, args)
--     local src = source
--     local Player = exports['qb-core']:GetPlayer(src)
--     if not Player then return end
--     local playerPed = GetPlayerPed(src)
--     local playerCoords = GetEntityCoords(playerPed)
--     local target = exports['qb-core']:GetPlayer(tonumber(args[1]))
--     if not target then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.noUser'), 'error') end
--     local targetPed = GetPlayerPed(tonumber(args[1]))
--     local targetCoords = GetEntityCoords(targetPed)
--     local amount = tonumber(args[2])
--     if not amount then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.amount'), 'error') end
--     if amount <= 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.amount'), 'error') end
--     if #(playerCoords - targetCoords) > 5 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.toofar'), 'error') end
--     if Player.PlayerData.money.cash < amount then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.money'), 'error') end
--     Player.Functions.RemoveMoney('cash', amount, 'cash transfer')
--     target.Functions.AddMoney('cash', amount, 'cash transfer')
--     TriggerClientEvent('QBCore:Notify', src, string.format(Lang:t('success.give'), amount), 'success')
--     TriggerClientEvent('QBCore:Notify', target.PlayerData.source, string.format(Lang:t('success.receive'), amount), 'success')
-- end)

StaticMesh(Vector(-6570, 2835.962, -390), Rotator(0, -90, 0), '/Game/QBCore/Meshes/SM_ATM.SM_ATM')
