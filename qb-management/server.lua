local Lang = require('locales/en')

-- Functions

-- Events

RegisterServerEvent('qb-management:server:jobStash', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local playerJob = Player.PlayerData.job
    if not playerJob.isboss then return end
    local ped = GetPlayerPawn(source)
    if not ped then return end
    local playerCoords = GetEntityCoords(ped)
    if not Config.BossMenus[playerJob.name] then return end
    local bossCoords = Config.BossMenus[playerJob.name]
    for i = 1, #bossCoords do
        local coords = bossCoords[i]
        if GetDistanceBetweenCoords(playerCoords, coords) < 1000 then
            local stashName = 'boss_' .. playerJob.name
            exports['qb-inventory']:OpenInventory(source, stashName, {
                maxweight = 4000000,
                slots = 25,
            })
            return
        end
    end
end)

RegisterServerEvent('qb-management:server:gangStash', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local playerGang = Player.PlayerData.gang
    if not playerGang.isboss then return end
    local ped = GetPlayerPawn(source)
    if not ped then return end
    local playerCoords = GetEntityCoords(ped)
    if not Config.GangMenus[playerGang.name] then return end
    local bossCoords = Config.GangMenus[playerGang.name]
    for i = 1, #bossCoords do
        local coords = bossCoords[i]
        if GetDistanceBetweenCoords(playerCoords, coords) < 1000 then
            local stashName = 'gang_' .. playerGang.name
            exports['qb-inventory']:OpenInventory(source, stashName, {
                maxweight = 4000000,
                slots = 25,
            })
            return
        end
    end
end)

-- Gangs

RegisterServerEvent('qb-management:server:GradeUpdateGang', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local Member = exports['qb-core']:GetPlayerByCitizenId(data.cid) or exports['qb-core']:GetOfflinePlayerByCitizenId(data.cid)
    if not Member then return end

    -- if not Player.PlayerData.gang.isboss then
    --     ExploitBan(source, 'GradeUpdateGang Exploiting')
    --     return
    -- end

    if data.grade > Player.PlayerData.gang.grade.level then
        TriggerClientEvent(source, 'QBCore:Notify', 'You cannot promote to this rank!', 'error')
        return
    end

    if Member then
        if exports['qb-core']:Player(Member, 'SetGang', Player.PlayerData.gang.name, data.grade) then
            TriggerClientEvent(source, 'QBCore:Notify', 'Sucessfully promoted!', 'success')
            exports['qb-core']:Player(Member, 'Save')
            if Member.PlayerData.source then
                TriggerClientEvent(Member.PlayerData.source, 'QBCore:Notify', 'You have been promoted to ' .. data.gradename .. '.', 'success')
            end
        else
            TriggerClientEvent(source, 'QBCore:Notify', 'Promotion grade does not exist.', 'error')
        end
    end
    TriggerClientEvent(source, 'qb-management:client:OpenGangMenu')
end)

RegisterServerEvent('qb-management:server:FireMember', function(source, target)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local Member = exports['qb-core']:GetPlayerByCitizenId(target) or exports['qb-core']:GetOfflinePlayerByCitizenId(target)

    -- if not Player.PlayerData.gang.isboss then
    --     ExploitBan(source, 'FireMember Exploiting')
    --     return
    -- end

    if Member then
        if target == Player.PlayerData.citizenid then
            TriggerClientEvent(source, 'QBCore:Notify', 'You can\'t fire yourself', 'error')
            return
        elseif Member.PlayerData.gang.grade.level > Player.PlayerData.gang.grade.level then
            TriggerClientEvent(source, 'QBCore:Notify', 'You cannot fire this citizen!', 'error')
            return
        end
        if exports['qb-core']:Player(Member, 'SetGang', 'none', '0') then
            exports['qb-core']:Player(Member, 'Save')
            TriggerClientEvent(source, 'QBCore:Notify', 'Gang member fired!', 'success')

            if Member.PlayerData.source then
                TriggerClientEvent(Member.PlayerData.source, 'QBCore:Notify', 'You have been fired from the gang! Good luck.', 'error')
            end
        else
            TriggerClientEvent(source, 'QBCore:Notify', 'Error..', 'error')
        end
    end
    TriggerClientEvent(source, 'qb-management:client:OpenGangMenu')
end)

RegisterServerEvent('qb-management:server:HireMember', function(source, recruit)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local Target = exports['qb-core']:GetPlayer(recruit)
    if not Target then return end

    if not Player.PlayerData.gang.isboss then
        ExploitBan(source, 'HireMember Exploiting')
        return
    end

    if Target and exports['qb-core']:Player(Target, 'SetGang', Player.PlayerData.gang.name, 0) then
        TriggerClientEvent(source, 'QBCore:Notify', 'You recruited ' .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' come ' .. Player.PlayerData.gang.label .. '', 'success')
        TriggerClientEvent(Target.PlayerData.source, 'QBCore:Notify', 'You were recruited into ' .. Player.PlayerData.gang.label .. '', 'success')
    end
    TriggerClientEvent(source, 'qb-management:client:OpenGangMenu')
end)

-- Jobs

RegisterServerEvent('qb-management:server:GradeUpdate', function(source, data)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local Employee = exports['qb-core']:GetPlayerByCitizenId(data.cid) or exports['qb-core']:GetOfflinePlayerByCitizenId(data.cid)
    if not Employee then return end

    -- if not Player.PlayerData.job.isboss then
    --     ExploitBan(source, 'GradeUpdate Exploiting')
    --     return
    -- end

    if data.grade > Player.PlayerData.job.grade.level then
        TriggerClientEvent(source, 'QBCore:Notify', 'You cannot promote to this rank!', 'error')
        return
    end

    if Employee then
        if exports['qb-core']:Player(Employee, 'SetJob', Player.PlayerData.job.name, data.grade) then
            TriggerClientEvent(source, 'QBCore:Notify', 'Sucessfully promoted!', 'success')
            exports['qb-core']:Player(Employee, 'Save')
            if Employee.PlayerData.source then
                TriggerClientEvent(Employee.PlayerData.source, 'QBCore:Notify', 'You have been promoted to ' .. data.gradename .. '.', 'success')
            end
        else
            TriggerClientEvent(source, 'QBCore:Notify', 'Promotion grade does not exist.', 'error')
        end
    end
    TriggerClientEvent(source, 'qb-management:client:openBossMenu')
end)

RegisterServerEvent('qb-management:server:FireEmployee', function(source, target)
    local Player = exports['qb-core']:GetPlayer(src)
    local Employee = exports['qb-core']:GetPlayerByCitizenId(target) or exports['qb-core']:GetOfflinePlayerByCitizenId(target)

    -- if not Player.PlayerData.job.isboss then
    --     ExploitBan(source, 'FireEmployee Exploiting')
    --     return
    -- end

    if Employee then
        if target == Player.PlayerData.citizenid then
            TriggerClientEvent(source, 'QBCore:Notify', 'You can\'t fire yourself', 'error')
            return
        elseif Employee.PlayerData.job.grade.level > Player.PlayerData.job.grade.level then
            TriggerClientEvent(source, 'QBCore:Notify', 'You cannot fire this citizen!', 'error')
            return
        end
        if exports['qb-core']:Player(Employee, 'SetJob', 'unemployed', '0') then
            exports['qb-core']:Player(Employee, 'Save')
            TriggerClientEvent(source, 'QBCore:Notify', 'Employee fired!', 'success')

            if Employee.PlayerData.source then
                TriggerClientEvent(Employee.PlayerData.source, 'QBCore:Notify', 'You have been fired! Good luck.', 'error')
            end
        else
            TriggerClientEvent(source, 'QBCore:Notify', 'Error..', 'error')
        end
    end
    TriggerClientEvent(source, 'qb-management:client:openBossMenu')
end)

RegisterServerEvent('qb-management:server:HireEmployee', function(source, recruit)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    local Target = exports['qb-core']:GetPlayerByCitizenId(recruit)
    if not Target then return end

    -- if not Player.PlayerData.job.isboss then
    --     ExploitBan(source, 'HireEmployee Exploiting')
    --     return
    -- end

    if Target and exports['qb-core']:Player(Target.PlayerData.source, 'SetJob', Player.PlayerData.job.name, 0) then
        TriggerClientEvent(source, 'QBCore:Notify', 'You hired ' .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' come ' .. Player.PlayerData.job.label .. '', 'success')
        TriggerClientEvent(Target.PlayerData.source, 'QBCore:Notify', 'You were hired as ' .. Player.PlayerData.job.label .. '', 'success')
    end
    TriggerClientEvent(source, 'qb-management:client:openBossMenu')
end)

-- Callbacks

RegisterCallback('GetEmployees', function(source, jobname)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

    -- if not Player.PlayerData.job.isboss then
    --     ExploitBan(source, 'GetEmployees Exploiting')
    --     return
    -- end

    local employees = {}
    local foundEmployees = {}

    local onlinePlayers = exports['qb-core']:GetPlayers()
    for i = 1, #onlinePlayers do
        local src = onlinePlayers[i]
        local player = exports['qb-core']:GetPlayer(src)
        local playerData = player and player.PlayerData
        if playerData and playerData.job and playerData.job.name == jobname then
            employees[#employees + 1] = {
                empSource = playerData.citizenid,
                grade = playerData.job.grade,
                isboss = playerData.job.isboss,
                name = '🟢 ' .. playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
            }
            foundEmployees[playerData.citizenid] = true
        end
    end

    local offlinePlayers = exports['qb-core']:DatabaseAction('Select', "SELECT * FROM `players` WHERE `job` LIKE '%" .. jobname .. "%'", {})
    if offlinePlayers[1] then
        for _, data in pairs(offlinePlayers) do
            local jobData = JSON.parse(data.job)
            if jobData.name == jobname and not foundEmployees[data.citizenid] then
                local charInfo = JSON.parse(data.charinfo)
                employees[#employees + 1] = {
                    empSource = data.citizenid,
                    grade = jobData.grade,
                    isboss = jobData.isboss,
                    name = '❌ ' .. charInfo.firstname .. ' ' .. charInfo.lastname
                }
            end
        end
    end

    table.sort(employees, function(a, b)
        return a.grade.level > b.grade.level
    end)

    return employees
end)

RegisterCallback('GetMembers', function(source, gangname)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

    -- if not Player.PlayerData.gang.isboss then
    --     ExploitBan(source, 'GetMembers Exploiting')
    --     return
    -- end

    local members = {}
    local foundMembers = {}

    local onlinePlayers = exports['qb-core']:GetPlayers()
    for i = 1, #onlinePlayers do
        local src = onlinePlayers[i]
        local player = exports['qb-core']:GetPlayer(src)
        local playerData = player and player.PlayerData
        if playerData and playerData.gang and playerData.gang.name == gangname then
            members[#members + 1] = {
                empSource = playerData.citizenid,
                grade = playerData.gang.grade,
                isboss = playerData.gang.isboss,
                name = '🟢 ' .. playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
            }
            foundMembers[playerData.citizenid] = true
        end
    end

    local offlinePlayers = exports['qb-core']:DatabaseAction('Select', "SELECT * FROM `players` WHERE `gang` LIKE '%" .. gangname .. "%'", {})
    if offlinePlayers[1] then
        for _, data in pairs(offlinePlayers) do
            local gangData = JSON.parse(data.gang)
            if gangData.name == gangname and not foundMembers[data.citizenid] then
                local charInfo = JSON.parse(data.charinfo)
                members[#members + 1] = {
                    empSource = data.citizenid,
                    grade = gangData.grade,
                    isboss = gangData.isboss,
                    name = '❌ ' .. charInfo.firstname .. ' ' .. charInfo.lastname
                }
            end
        end
    end

    table.sort(members, function(a, b)
        return a.grade.level > b.grade.level
    end)

    return members
end)

RegisterCallback('GetPlayers', function(source)
    local players = {}
    local PlayerPed = GetPlayerPawn(source)
    if not PlayerPed then return end
    local pCoords = GetEntityCoords(PlayerPed)
    local worldPawns = GetPawnsInArea(pCoords, 1000)
    for _, pawn in pairs(worldPawns) do
        if PlayerPed ~= pawn then
            local controller = pawn:GetController()
            if not controller then return end
            local targetPlayer = exports['qb-core']:GetPlayer(controller)
            players[#players + 1] = {
                name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
                citizenid = targetPlayer.PlayerData.citizenid,
            }
        end
    end

    table.sort(players, function(a, b)
        return a.name < b.name
    end)

    return players
end)
