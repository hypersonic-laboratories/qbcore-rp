local Weapons = exports['qb-core']:GetShared('Weapons')
local EvidenceTypes = {
    Casings = {},
    BloodDrops = {},
    Fingerprints = {},
}
local PlayerStatus = {}

-- Functions

-- Only trigger events to police
local function TriggerCLPoliceEvent(event, ...)
    local Players = exports['qb-core']:GetQBPlayers()
    for _, Player in pairs(Players) do
        if Player.PlayerData.job.type == 'leo' then
            TriggerClientEvent(Player.PlayerData.source, event, ...)
        end
    end
end

---@param EvidenceType string The key of the evidence type to create a unique id for
local function CreateEvidenceId(EvidenceType)
    if not EvidenceTypes[EvidenceType] then
        return
    end

    local UniqueId = GenerateId(8, 'number')
    if EvidenceTypes[EvidenceType][UniqueId] then
        return CreateEvidenceId(EvidenceType)
    end -- if id already exists, try again

    return UniqueId
end

-- Events

RegisterServerEvent('qb-policejob:server:CreateCasing', function(source, weapon, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local WeaponItem = Player.GetItemByName(weapon)
    local SerialNumber
    if WeaponItem and type(WeaponItem.info) == 'table' then
        SerialNumber = WeaponItem.info.serie
    end

    local casing = {
        id = CreateEvidenceId('Casings'),
        weapon = weapon,
        serialNumber = SerialNumber,
        coords = coords,
        time = os.time(),
    }
    EvidenceTypes.Casings[casing.id] = casing
    TriggerCLPoliceEvent('qb-policejob:client:SyncNewCasing', casing)
end)

--@TODO: Sync with ambulance job damage system
RegisterServerEvent('qb-policejob:server:CreateBlooddrop', function(source, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local CitizenId = Player.PlayerData.citizenid
    local BloodType = Player.PlayerData.metadata.bloodtype

    local BloodDrop = {
        id = CreateEvidenceId('BloodDrops'),
        citizenId = CitizenId,
        bloodType = BloodType,
        coords = coords,
    }
    EvidenceTypes.BloodDrops[BloodDrop.id] = BloodDrop
    TriggerCLPoliceEvent('qb-policejob:client:SyncNewBlooddrop', BloodDrop)
end)

-- Triggered by packages to create a player fingerprint
RegisterServerEvent('qb-policejob:server:CreateFingerprint', function(source, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local Fingerprint = {
        id = CreateEvidenceId('Fingerprints'),
        playerFingerprint = Player.PlayerData.metadata.fingerprint,
        coords = coords,
    }
    Fingerprints[Fingerprint.id] = Fingerprint
    TriggerCLPoliceEvent('qb-policejob:client:SyncNewFingerprint', Fingerprint)
end)

RegisterServerEvent('qb-policejob:server:UpdateStatus', function(source, statusList)
    PlayerStatus[source] = statusList
end)

-- Callbacks

RegisterCallback('GetPlayerStatus', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    if Player.PlayerData.job.type ~= 'leo' then
        return
    end

    local PlayerPawn = GetPlayerPawn(source)
    if not PlayerPawn then
        return
    end

    local PlayerCoords = GetEntityCoords(PlayerPawn)
    local ClosestPawn = GetClosestPawn(PlayerCoords, 500)
    if not ClosestPawn or not ClosestPawn:IsPlayerControlled() then
        exports['qb-core']:NotifyPlayer(source, 'You\'re not close enough to check status', 'error')
        return
    end

    local ClosestPlayerStatus = PlayerStatus[ClosestPawn:GetController()]
    if not ClosestPlayerStatus then
        exports['qb-core']:NotifyPlayer(source, 'Player status is normal')
        return
    end

    local FormattedStatuses = {}
    for k, v in pairs(ClosestPlayerStatus) do
        table.insert(FormattedStatuses, v.text)
    end

    if #FormattedStatuses <= 0 then
        exports['qb-core']:NotifyPlayer(source, 'Player status is normal')
        return
    end

    return FormattedStatuses
end)
