local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items') or {}

local Casings = {}
local BloodDrops = {}
local FingerDrops = {}
local PlayerStatus = {}
local LastCasingCreatedAt = {}

local function notify(source, text, notifyType)
    TriggerClientEvent(source, 'QBCore:Notify', text, notifyType)
end

local function CreateBloodId()
    local bloodId = 'blood-' .. GenerateId(8, 'mixed')
    while BloodDrops[bloodId] do
        bloodId = 'blood-' .. GenerateId(8, 'mixed')
    end
    return bloodId
end

local function CreateFingerId()
    local fingerId = 'fingerprint-' .. GenerateId(8, 'mixed')
    while FingerDrops[fingerId] do
        fingerId = 'fingerprint-' .. GenerateId(8, 'mixed')
    end
    return fingerId
end

local function CreateCasingId()
    local caseId = 'casing-' .. GenerateId(8, 'mixed')
    while Casings[caseId] do
        caseId = 'casing-' .. GenerateId(8, 'mixed')
    end
    return caseId
end

local function getEvidenceConfig(key, default)
    local evidenceConfig = Config.Evidence or {}
    if evidenceConfig[key] == nil then
        return default
    end
    return evidenceConfig[key]
end

local function canCreateCasingForSource(source)
    local cooldown = tonumber(getEvidenceConfig('CasingDropCooldown', 2)) or 0
    if cooldown <= 0 then
        return true
    end

    local now = os.time()
    local lastCreatedAt = LastCasingCreatedAt[source] or 0
    if lastCreatedAt > 0 and (now - lastCreatedAt) < cooldown then
        return false
    end

    LastCasingCreatedAt[source] = now
    return true
end

local function GetWeaponItem(weapon)
    if not weapon then
        return nil
    end

    local weaponName = tostring(weapon)
    local itemInfo = sharedItems[weaponName] or sharedItems[string.lower(weaponName)]
    if itemInfo and itemInfo.type == 'weapon' then
        return itemInfo
    end

    local loweredWeaponName = string.lower(weaponName)
    for _, sharedItem in pairs(sharedItems) do
        if sharedItem.type == 'weapon' and sharedItem.asset_name and string.lower(sharedItem.asset_name) == loweredWeaponName then
            return sharedItem
        end
    end

    return nil
end

RegisterCallback('qb-policejob:GetPlayerStatus', function(_, playerId)
    local Player = exports['qb-core']:GetPlayer(playerId)
    local statList = {}
    if Player and PlayerStatus[Player.PlayerData.source] and next(PlayerStatus[Player.PlayerData.source]) then
        for k in pairs(PlayerStatus[Player.PlayerData.source]) do
            statList[#statList + 1] = PlayerStatus[Player.PlayerData.source][k].text
        end
    end
    return statList
end)

RegisterServerEvent('qb-policejob:server:UpdateStatus', function(source, data)
    PlayerStatus[source] = data
end)

RegisterServerEvent('qb-policejob:server:CreateBloodDrop', function(_, citizenid, bloodtype, coords)
    local bloodId = CreateBloodId()
    BloodDrops[bloodId] = {
        dna = citizenid,
        bloodtype = bloodtype,
    }
    BroadcastEvent('qb-policejob:client:AddBlooddrop', bloodId, citizenid, bloodtype, coords)
end)

RegisterServerEvent('qb-policejob:server:CreateFingerDrop', function(source, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local fingerId = CreateFingerId()
    FingerDrops[fingerId] = Player.PlayerData.metadata['fingerprint']
    BroadcastEvent('qb-policejob:client:AddFingerPrint', fingerId, Player.PlayerData.metadata['fingerprint'], coords)
end)

RegisterServerEvent('qb-policejob:server:ClearBlooddrops', function(_, blooddropList)
    if blooddropList and next(blooddropList) then
        for _, v in pairs(blooddropList) do
            BroadcastEvent('qb-policejob:client:RemoveBlooddrop', v)
            BloodDrops[v] = nil
        end
    end
end)

RegisterServerEvent('qb-policejob:server:AddBlooddropToInventory', function(source, bloodId, bloodInfo)
    if exports['qb-inventory']:RemoveItem(source, 'empty_evidence_bag', 1, false, 'qb-policejob:server:AddBlooddropToInventory') then
        if exports['qb-inventory']:AddItem(source, 'filled_evidence_bag', 1, false, bloodInfo, 'qb-policejob:server:AddBlooddropToInventory') then
            TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['filled_evidence_bag'], 'add')
            BroadcastEvent('qb-policejob:client:RemoveBlooddrop', bloodId)
            BloodDrops[bloodId] = nil
        end
    else
        notify(source, Lang.t('error.have_evidence_bag'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:AddFingerprintToInventory', function(source, fingerId, fingerInfo)
    if exports['qb-inventory']:RemoveItem(source, 'empty_evidence_bag', 1, false, 'qb-policejob:server:AddFingerprintToInventory') then
        if exports['qb-inventory']:AddItem(source, 'filled_evidence_bag', 1, false, fingerInfo, 'qb-policejob:server:AddFingerprintToInventory') then
            TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['filled_evidence_bag'], 'add')
            BroadcastEvent('qb-policejob:client:RemoveFingerprint', fingerId)
            FingerDrops[fingerId] = nil
        end
    else
        notify(source, Lang.t('error.have_evidence_bag'), 'error')
    end
end)

RegisterServerEvent('qb-policejob:server:CreateCasing', function(source, weapon, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if not coords then
        return
    end
    if not canCreateCasingForSource(source) then
        return
    end

    local casingId = CreateCasingId()
    local weaponInfo = GetWeaponItem(weapon)
    local serieNumber = nil
    if weaponInfo then
        local weaponItem = Player.GetItemByName(Player, weaponInfo.name)
        if weaponItem and weaponItem.info and weaponItem.info ~= '' then
            serieNumber = weaponItem.info.serie
        end
    end

    Casings[casingId] = {
        weapon = weapon,
        serie = serieNumber,
    }
    BroadcastEvent('qb-policejob:client:AddCasing', casingId, weapon, coords, serieNumber)
end)

RegisterServerEvent('qb-policejob:server:ClearCasings', function(_, casingList)
    if casingList and next(casingList) then
        for _, v in pairs(casingList) do
            BroadcastEvent('qb-policejob:client:RemoveCasing', v)
            Casings[v] = nil
        end
    end
end)

RegisterServerEvent('qb-policejob:server:AddCasingToInventory', function(source, casingId, casingInfo)
    if exports['qb-inventory']:RemoveItem(source, 'empty_evidence_bag', 1, false, 'qb-policejob:server:AddCasingToInventory') then
        if exports['qb-inventory']:AddItem(source, 'filled_evidence_bag', 1, false, casingInfo, 'qb-policejob:server:AddCasingToInventory') then
            TriggerClientEvent(source, 'qb-inventory:client:ItemBox', sharedItems['filled_evidence_bag'], 'add')
            BroadcastEvent('qb-policejob:client:RemoveCasing', casingId)
            Casings[casingId] = nil
        end
    else
        notify(source, Lang.t('error.have_evidence_bag'), 'error')
    end
end)
