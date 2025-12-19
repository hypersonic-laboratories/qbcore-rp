local Weapons = exports['qb-core']:GetShared('Weapons')
local EvidenceTypes = [
    Casings = {},
    BloodDrops = {},
]

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
    if not EvidenceTypes[EvidenceType] then return end
    
    local UniqueId = GenerateId(8, 'number')
    if EvidenceTypes[EvidenceType][UniqueId] then return CreateEvidenceId(EvidenceType) end -- if id already exists, try again
    
    return UniqueId
end

-- Events

RegisterServerEvent('qb-policejob:server:CreateCasing', function(source, weapon, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

    local WeaponItem = exports['qb-inventory']:GetItemByName(source, weapon)
    local SerialNumber
    if WeaponItem and type(WeaponItem.info) == 'table'then
        SerialNumber = WeaponItem.info.serie
    end

    local casing = {
        id = CreateEvidenceId('Casings'),
        weapon = weapon,
        serialNumber = SerialNumber,
        coords = coords,
        time = os.time()
    }
    EvidenceTypes.Casings[casing.id] = casing
    TriggerCLPoliceEvent('qb-policejob:client:SyncNewCasing', casing)
end)

--@TODO: Sync with ambulance job damage system
RegisterServerEvent('qb-policejob:server:CreateBlooddrop', function(source, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

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