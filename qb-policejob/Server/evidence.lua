local Weapons = exports['qb-core']:GetShared('Weapons')

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

-- Events

RegisterServerEvent('qb-policejob:server:CreateCasing', function(weapon, coords)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return end

    local WeaponItem = exports['qb-inventory']:GetItemByName(source, weapon)
    local SerialNumber
    if WeaponItem and type(WeaponItem.info) == 'table'then
        SerialNumber = WeaponItem.info.serie
    end

    local casing = {
        id = GenerateId(8, 'number'),
        weapon = weapon,
        serialNumber = SerialNumber,
        coords = coords,
        time = os.time()
    }
    TriggerCLPoliceEvent('qb-policejob:client:SyncNewCasing', casing)
end)
