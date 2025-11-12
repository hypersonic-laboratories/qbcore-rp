local Lang = require('locales/en')
local hasDonePreloading = {}
local dir = debug.getinfo(1, 'S').source .. '/../' -- append trailing slash, exit file dir
local Countries = {}

-- Handling Player Load

RegisterServerEvent('qb-multicharacter:server:chooseChar', function(source)
    if exports['qb-core']:GetPlayer(source) then return end
    TriggerClientEvent(source, 'qb-multicharacter:client:chooseChar')
end)

-- Functions

local function GiveStarterItems(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end
    for item, amount in pairs(exports['qb-core']:GetConfig().StarterItems) do
        local info = {}
        if item == 'id_card' then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif item == 'driver_license' then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = 'Class C Driver License'
        end
        exports['qb-inventory']:AddItem(source, item, amount, false, info)
    end
end

local function GetOwnedApartment(cid)
    if cid then
        local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM apartments WHERE citizenid = ?', { cid })
        if result[1] ~= nil then
            return result[1]
        end
        return nil
    end
    return nil
end

local function readCountriesFile()
	local fileHandle, msg = io.open(dir .. './countries.json', 'r')
	if not fileHandle then
		print("[qb-multicharacter] Error: Couldn't read countries list", msg)
		return
	end
	local content = fileHandle:read('a')
	fileHandle:close()

	local countries = JSON.parse(content)
	return countries
end
Countries = readCountriesFile() or {}

-- Commands

-- QBCore.Commands.Add('logout', Lang:t('commands.logout_description'), {}, false, function(source)
--     local Player = exports['qb-core']:GetPlayer(source)
--     if not Player then return end
--     local inside_meta = Player.PlayerData.metadata.inside
--     if inside_meta.apartment.apartmentId then
--         TriggerClientEvent('qb-apartments:client:leaveApartment', source)
--     end
--     QBCore.Player.Logout(source)
--     TriggerClientEvent('qb-multicharacter:client:chooseChar', source)
-- end, 'admin')

-- Events

exports('qb-multicharacter', 'SetPlayerLoaded', function(Player)
    hasDonePreloading[Player.PlayerData.netId] = true
end)

RegisterServerEvent('QBCore:Server:OnPlayerUnload', function(source)
    hasDonePreloading[source] = false
end)

RegisterServerEvent('qb-multicharacter:server:disconnect', function(source)
    source:Kick(source, Lang:t('commands.droppedplayer'))
end)

RegisterServerEvent('qb-multicharacter:server:loadUserData', function(source, cData) -- TO DO ADD APARTMENTS SUPPORT
    if exports['qb-core']:Login(source, cData.citizenid) then
        local PlayerState = source:GetLyraPlayerState()
        local netId = PlayerState:GetPlayerId()
        CheckUserInterval = Timer.SetInterval(function()
            if hasDonePreloading[netId] then
                print('[qb-core] ' .. PlayerState:GetPlayerName() .. ' (Citizen ID: ' .. cData.citizenid .. ') has successfully loaded!')
                TriggerClientEvent(source, 'qb-multicharacter:client:closeNUI')
                --QBCore.Commands.Refresh(source)
                --loadHouseData(source)
                if Config.SkipSelection then
                    local result = GetOwnedApartment(cData.citizenid)
                    if result then
                        local Player = exports['qb-core']:GetPlayer(source)
                        local insideMeta = Player.PlayerData.metadata['inside']
                        if insideMeta.house then
                            TriggerClientEvent(source, 'qb-houses:client:LastLocationHouse', insideMeta.house)
                        elseif insideMeta.apartment.apartmentType and insideMeta.apartment.apartmentId then
                            TriggerClientEvent(source, 'qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
                        end
                    else
                        local coords = JSON.parse(cData.position)
                        local pawn = GetPlayerPawn(source)
                        if pawn then SetEntityCoords(pawn, Vector(coords.x, coords.y, coords.z)) end
                    end
                else
                    local Apartments = exports['qb-apartments']:Apartments()
                    if Apartments.Starting then
                        TriggerClientEvent(source, 'qb-apartments:client:setupSpawnUI', cData)
                    else
                        TriggerClientEvent(source, 'qb-spawn:client:openUI', true, cData, false, nil)
                    end
                end
                Timer.ClearInterval(CheckUserInterval)
            end
        end, 10)
    end
end)

RegisterServerEvent('qb-multicharacter:server:createCharacter', function(source, data)
    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data
    if exports['qb-core']:Login(source, false, newData) then
        local PlayerState = source:GetLyraPlayerState()
        local netId = PlayerState:GetPlayerId()
        CheckInterval = Timer.SetInterval(function()
            if hasDonePreloading[netId] then
                local Apartments = exports['qb-apartments']:Apartments()
                if Apartments.Starting then
                    print('^2[qb-core]^7 ' .. PlayerState:GetPlayerName() .. ' has successfully loaded!')
                    --QBCore.Commands.Refresh(source)
                    --loadHouseData(source)
                    TriggerClientEvent(source, 'qb-multicharacter:client:closeNUI')
                    TriggerClientEvent(source, 'qb-apartments:client:setupSpawnUI', newData)
                    GiveStarterItems(source)
                    Timer.ClearInterval(CheckInterval)
                else
                    print('^2[qb-core]^7 ' .. PlayerState:GetPlayerName() .. ' has successfully loaded!')
                    --QBCore.Commands.Refresh(source)
                    --loadHouseData(source)
                    TriggerClientEvent(source, 'qb-multicharacter:client:closeNUIdefault')
                    GiveStarterItems(source)
                    Timer.ClearInterval(CheckInterval)
                end
            end
        end, 10)
    end
end)

RegisterServerEvent('qb-multicharacter:server:deleteCharacter', function(source, citizenid)
    local Success = exports['qb-core']:DeleteCharacter(source, citizenid)
    if not Success then return end
    TriggerClientEvent(source, 'QBCore:Notify', Lang:t('notifications.char_deleted'), 'success')
    TriggerClientEvent(source, 'qb-multicharacter:client:chooseChar')
end)

-- Callbacks

RegisterCallback('GetNumberOfCharacters', function(source)
    local playerState = source:GetLyraPlayerState()
    local license = playerState:GetHelixUserId()
    local numOfChars = 0
    if next(Config.PlayersNumberOfCharacters) then
        for _, v in pairs(Config.PlayersNumberOfCharacters) do
            if v.license == license then
                numOfChars = v.numberOfChars
                break
            else
                numOfChars = Config.DefaultNumberOfCharacters
            end
        end
    else
        numOfChars = Config.DefaultNumberOfCharacters
    end

    return {charCount = numOfChars, countries = Countries}
end)

RegisterCallback('setupCharacters', function(source)
    local playerState = source:GetLyraPlayerState()
    local license = playerState:GetHelixUserId()
    local plyChars = {}
    local result = exports['qb-core']:DatabaseAction('Select', 'SELECT * FROM players WHERE license = ?', { license })
    if not result then return end
    for i = 1, #result do
        local rowData = result[i]
        if type(rowData) == 'table' then
            local row = {}
            for CName, CValue in pairs(rowData) do
                row[CName] = CValue
            end
            row.charinfo            = JSON.parse(row.charinfo)
            row.money               = JSON.parse(row.money)
            row.job                 = JSON.parse(row.job)
            plyChars[#plyChars + 1] = row
        end
    end
    return plyChars
end)
