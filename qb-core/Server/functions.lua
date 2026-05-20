QBCore.Functions = {}
QBCore.UsableItems = {}

-- Player Getters

function QBCore.Functions.GetIdentifier(source)
    local PlayerState = source:GetLyraPlayerState()
    return PlayerState:GetHelixUserId()
end

function QBCore.Functions.GetSource(identifier)
    for src, player in pairs(QBCore.Players) do
        if player.PlayerData.license == identifier then
            return src
        end
    end
    return 0
end

function QBCore.Functions.GetPlayer(source)
    if not source then return end
    if type(source) == 'number' then
        local player = GetPlayerById(source)
        if not player then return nil end
        return QBCore.Players[player]
    end
    return QBCore.Players[source]
end

function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    return QBCore.PlayersByCitizenId[citizenid]
end

function QBCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
    return QBCore.Player.GetOfflinePlayer(citizenid)
end

function QBCore.Functions.GetPlayerByLicense(license)
    return QBCore.Player.GetPlayerByLicense(license)
end

function QBCore.Functions.GetPlayerByPhone(number)
    for _, Player in pairs(QBCore.Players) do
        if Player.PlayerData.charinfo.phone == number then
            return Player
        end
    end
    return nil
end

function QBCore.Functions.GetPlayerByAccount(account)
    for _, Player in pairs(QBCore.Players) do
        if Player.PlayerData.charinfo.account == account then
            return Player
        end
    end
    return nil
end

function QBCore.Functions.GetPlayerByCharInfo(property, value)
    for _, Player in pairs(QBCore.Players) do
        local charinfo = Player.PlayerData.charinfo
        if charinfo[property] ~= nil and charinfo[property] == value then
            return Player
        end
    end
    return nil
end

function QBCore.Functions.GetPlayers()
    local sources = {}
    for k in pairs(QBCore.Players) do
        sources[#sources + 1] = k
    end
    return sources
end

function QBCore.Functions.GetQBPlayers()
    return QBCore.Players
end

function QBCore.Functions.GetPlayersByJob(job, checkOnDuty)
    local players = {}
    local count = 0
    for src, Player in pairs(QBCore.Players) do
        local playerData = Player.PlayerData
        if playerData.job.name == job or playerData.job.type == job then
            if checkOnDuty then
                if playerData.job.onduty then
                    players[#players + 1] = src
                    count += 1
                end
            else
                players[#players + 1] = src
                count += 1
            end
        end
    end
    return players, count
end

function QBCore.Functions.GetPlayersOnDuty(job)
    return QBCore.Functions.GetPlayersByJob(job, true)
end

function QBCore.Functions.GetDutyCount(job)
    local _, count = QBCore.Functions.GetPlayersByJob(job, true)
    return count
end

-- Paycheck

function PaycheckInterval()
    if not next(QBCore.Players) then
        SetTimeout(QBCore.Config.Money.PayCheckTimeOut * (60 * 1000), PaycheckInterval)
        return
    end
    CreateThread(function()
        for _, Player in pairs(QBCore.Players) do
            if Player then
                local jobData = QBCore.Shared.Jobs[Player.PlayerData.job.name]
                local gradeData = jobData and jobData['grades'][tostring(Player.PlayerData.job.grade.level)]
                local payment = gradeData and gradeData.payment
                if not payment then payment = Player.PlayerData.job.payment end
                if Player.PlayerData.job and payment > 0 and (QBCore.Shared.Jobs[Player.PlayerData.job.name].offDutyPay or Player.PlayerData.job.onduty) then
                    if QBCore.Config.Money.PayCheckSociety then
                        local account = exports['qb-banking']:GetAccountBalance(Player.PlayerData.job.name)
                        if account ~= 0 then
                            if account < payment then
                                TriggerClientEvent(Player.PlayerData.source, 'QBCore:Notify', Lang:t('error.company_too_poor'), 'error')
                            else
                                Player.Functions.AddMoney('bank', payment, 'paycheck')
                                exports['qb-banking']:RemoveMoney(Player.PlayerData.job.name, payment, 'Employee Paycheck')
                                TriggerClientEvent(Player.PlayerData.source, 'QBCore:Notify', Lang:t('info.received_paycheck', { value = payment }))
                            end
                        else
                            Player.Functions.AddMoney('bank', payment, 'paycheck')
                            TriggerClientEvent(Player.PlayerData.source, 'QBCore:Notify', Lang:t('info.received_paycheck', { value = payment }))
                        end
                    else
                        Player.Functions.AddMoney('bank', payment, 'paycheck')
                        TriggerClientEvent(Player.PlayerData.source, 'QBCore:Notify', Lang:t('info.received_paycheck', { value = payment }))
                    end
                end
                Wait(50)
            end
        end
    end)
    SetTimeout(QBCore.Config.Money.PayCheckTimeOut * (60 * 1000), PaycheckInterval)
end

-- Callbacks

function QBCore.Functions.TriggerClientCallback(name, source, ...)
    if not source then return end
    local cb = nil
    local args = { ... }

    if type(args[1]) == 'function' then
        cb = args[1]
        table.remove(args, 1)
    end

    QBCore.ClientCallbacks[name .. source] = {
        callback = cb,
        promise = promise.new()
    }

    TriggerClientEvent(source, 'QBCore:Client:TriggerClientCallback', name, table.unpack(args))

    if cb == nil then
        Citizen.Await(QBCore.ClientCallbacks[name .. source].promise)
        local value = QBCore.ClientCallbacks[name .. source].promise.value
        QBCore.ClientCallbacks[name .. source] = nil
        return value
    end
end

function QBCore.Functions.CreateCallback(name, cb)
    QBCore.ServerCallbacks[name] = cb
end

-- Items

function QBCore.Functions.CreateUseableItem(item, data)
    local rawFunc = nil

    if type(data) == 'table' then
        if rawget(data, '__cfx_functionReference') then
            rawFunc = data
        elseif data.cb and rawget(data.cb, '__cfx_functionReference') then
            rawFunc = data.cb
        elseif data.callback and rawget(data.callback, '__cfx_functionReference') then
            rawFunc = data.callback
        end
    elseif type(data) == 'function' then
        rawFunc = data
    end

    if rawFunc then
        QBCore.UsableItems[item] = {
            func = rawFunc,
            resource = GetInvokingResource()
        }
    end
end

function QBCore.Functions.CanUseItem(item)
    return QBCore.UsableItems[item]
end

function QBCore.Functions.UseItem(source, item)
    if GetResourceState('qb-inventory') == 'missing' then return end
    exports['qb-inventory']:UseItem(source, item)
end

function QBCore.Functions.HasItem(source, items, amount)
    if GetResourceState('qb-inventory') == 'missing' then return end
    return exports['qb-inventory']:HasItem(source, items, amount)
end

-- Permissions

function QBCore.Functions.Kick(source, reason, setKickReason, deferrals)
    reason = '\n' .. reason .. '\n🔸 Check our Discord for further information: ' .. QBCore.Config.Server.Discord
    if setKickReason then
        setKickReason(reason)
    end
    CreateThread(function()
        if deferrals then
            deferrals.update(reason)
            Wait(2500)
        end
        if source then
            DropPlayer(source, reason)
        end
        for _ = 0, 4 do
            while true do
                if source then
                    if GetPlayerPing(source) < 0 then
                        break
                    end
                    CreateThread(function()
                        DropPlayer(source, reason)
                    end)
                end
                Wait(100)
            end
            Wait(5000)
        end
    end)
end

function QBCore.Functions.IsWhitelisted(source)
    if not QBCore.Config.Server.Whitelist then return true end
    if QBCore.Functions.HasPermission(source, QBCore.Config.Server.WhitelistPermission) then return true end
    return false
end

function QBCore.Functions.AddPermission(source, permission)
    if not IsPlayerAceAllowed(source, permission) then
        ExecuteCommand(('add_principal player.%s qbcore.%s'):format(source, permission))
        QBCore.Commands.Refresh(source)
    end
end

function QBCore.Functions.RemovePermission(source, permission)
    if permission then
        if IsPlayerAceAllowed(source, permission) then
            ExecuteCommand(('remove_principal player.%s qbcore.%s'):format(source, permission))
            QBCore.Commands.Refresh(source)
        end
    else
        for _, v in pairs(QBCore.Config.Server.Permissions) do
            if IsPlayerAceAllowed(source, v) then
                ExecuteCommand(('remove_principal player.%s qbcore.%s'):format(source, v))
                QBCore.Commands.Refresh(source)
            end
        end
    end
end

function QBCore.Functions.HasPermission(source, permission)
    if type(permission) == 'string' then
        if IsPlayerAceAllowed(source, permission) then return true end
    elseif type(permission) == 'table' then
        for _, permLevel in pairs(permission) do
            if IsPlayerAceAllowed(source, permLevel) then return true end
        end
    end
    return false
end

function QBCore.Functions.GetPermission(source)
    local src = source
    local perms = {}
    for _, v in pairs(QBCore.Config.Server.Permissions) do
        if IsPlayerAceAllowed(src, v) then
            perms[v] = true
        end
    end
    return perms
end

function QBCore.Functions.IsOptin(source)
    local license = QBCore.Functions.GetIdentifier(source, 'license')
    if not license or not QBCore.Functions.HasPermission(source, 'admin') then return false end
    local Player = QBCore.Functions.GetPlayer(source)
    return Player.PlayerData.optin
end

function QBCore.Functions.ToggleOptin(source)
    local license = QBCore.Functions.GetIdentifier(source, 'license')
    if not license or not QBCore.Functions.HasPermission(source, 'admin') then return end
    local Player = QBCore.Functions.GetPlayer(source)
    Player.PlayerData.optin = not Player.PlayerData.optin
    Player.Functions.SetPlayerData('optin', Player.PlayerData.optin)
end

function QBCore.Functions.IsPlayerBanned(source)
    local plicense = QBCore.Functions.GetIdentifier(source, 'license')
    local result = MySQL.single.await('SELECT id, reason, expire FROM bans WHERE license = ?', { plicense })
    if not result then return false end
    if os.time() < result.expire then
        local timeTable = os.date('*t', tonumber(result.expire))
        return true, 'You have been banned from the server:\n' .. result.reason .. '\nYour ban expires ' .. timeTable.day .. '/' .. timeTable.month .. '/' .. timeTable.year .. ' ' .. timeTable.hour .. ':' .. timeTable.min .. '\n'
    else
        MySQL.query('DELETE FROM bans WHERE id = ?', { result.id })
    end
    return false
end

function QBCore.Functions.IsLicenseInUse(license)
    local players = GetPlayers()
    for _, player in pairs(players) do
        local playerLicense = QBCore.Functions.GetIdentifier(player, 'license')
        if playerLicense == license then return true end
    end
    return false
end

function QBCore.Functions.Notify(source, text, type, length)
    TriggerClientEvent(source, 'QBCore:Notify', text, type, length)
end

-- ─────────────────────────── unique ID generators ───────────────────────────

function QBCore.Functions.CreateCitizenId()
    return GenerateId(3, 'string') .. GenerateId(5, 'number')
end

function QBCore.Functions.CreateAccountNumber()
    return GenerateId(10, 'number')
end

function QBCore.Functions.CreateWalletId()
    return 'WLT-' .. GenerateId(12, 'mixed')
end

function QBCore.Functions.CreatePhoneNumber()
    local areaCode = GenerateId(3, 'number')
    local prefix = GenerateId(3, 'number')
    local lineNumber = GenerateId(4, 'number')
    return areaCode .. prefix .. lineNumber
end

function QBCore.Functions.CreateFingerId()
    return string.format('FP-%s-%s-%s',
        GenerateId(3, 'mixed'),
        GenerateId(4, 'mixed'),
        GenerateId(4, 'mixed')
    )
end

function QBCore.Functions.CreateSerialNumber()
    return string.format('SN-%s-%s-%s',
        os.date('%Y'),
        GenerateId(4, 'string'):upper(),
        GenerateId(4, 'number')
    )
end

function QBCore.Functions.CreateApartmentId()
    return string.format('%s-%s%s',
        GenerateId(4, 'number'),
        GenerateId(3, 'number'),
        GenerateId(1, 'string')
    )
end

function QBCore.Functions.GeneratePlate()
    return string.format('%s%s%s',
        GenerateId(1, 'number'),
        GenerateId(3, 'string'),
        GenerateId(3, 'number')
    )
end

for functionName, func in pairs(QBCore.Functions) do
    if type(func) == 'function' then
        exports(functionName, func)
    end
end

-- local function createUniqueId(generator, query)
--     for _ = 1, 100 do
--         local value  = generator()
--         local result = Database.Select(query, { value })
--         if result and result[1] then
--             local row = result[1].Columns:ToTable()
--             if (row.uniqueCheck or 0) == 0 then return value end
--         end
--     end
--     print('[ERROR] qb-core: createUniqueId exceeded 100 retries')
--     return nil
-- end

-- function QBCore.Player.CreateCitizenId()
--     return createUniqueId(
--         function() return tostring(QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(5)):upper() end,
--         'SELECT COUNT(*) AS uniqueCheck FROM players WHERE citizenid = ?'
--     )
-- end

-- function QBCore.Functions.CreateAccountNumber()
--     return createUniqueId(
--         function()
--             return 'US0' .. math.random(1, 9) .. 'QBCore' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
--         end,
--         "SELECT COUNT(*) AS uniqueCheck FROM players WHERE json_extract(charinfo, '$.account') = ?"
--     )
-- end

-- function QBCore.Functions.CreatePhoneNumber()
--     return createUniqueId(
--         function() return math.random(100, 999) .. math.random(1000000, 9999999) end,
--         "SELECT COUNT(*) AS uniqueCheck FROM players WHERE json_extract(charinfo, '$.phone') = ?"
--     )
-- end

-- function QBCore.Player.CreateFingerId()
--     return createUniqueId(
--         function()
--             return tostring(
--                 QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) ..
--                 QBCore.Shared.RandomStr(1) .. QBCore.Shared.RandomInt(2) ..
--                 QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(4)
--             )
--         end,
--         "SELECT COUNT(*) AS uniqueCheck FROM players WHERE json_extract(metadata, '$.fingerprint') = ?"
--     )
-- end

-- function QBCore.Player.CreateWalletId()
--     return createUniqueId(
--         function() return 'QB-' .. math.random(11111111, 99999999) end,
--         "SELECT COUNT(*) AS uniqueCheck FROM players WHERE json_extract(metadata, '$.walletid') = ?"
--     )
-- end

-- function QBCore.Player.CreateSerialNumber()
--     return createUniqueId(
--         function() return math.random(11111111, 99999999) end,
--         "SELECT COUNT(*) AS uniqueCheck FROM players WHERE json_extract(metadata, '$.phonedata.SerialNumber') = ?"
--     )
-- end
