QBCore.Shared = {}
QBCore.ClientCallbacks = {}
QBCore.ServerCallbacks = {}
QBCore.IsLoggedIn = false

--- @param filters ('Config'|'Shared'|'ClientCallbacks'|'ServerCallbacks'|'PlayerData'|'Functions'|'Players'|'PlayersByCitizenId'|'Player_Buckets'|'Entity_Buckets'|'UsableItems'|'Commands')[]?
--- @return table
local function GetCoreObject(filters)
    if not filters then return QBCore end
    local results = {}
    for i = 1, #filters do
        local key = filters[i]
        if QBCore[key] then
            results[key] = QBCore[key]
        end
    end
    return results
end
exports('qb-core', 'GetCoreObject', GetCoreObject)

--- @param namespace 'Vehicles' | 'VehicleHashes' | 'Items' | 'Gangs' | 'Jobs' | 'Locations' | 'Weapons' | 'StarterItems'
--- @param item string?
--- @return table?
function GetShared(namespace, item)
    local ns = QBCore.Shared[namespace]
    if not ns then return nil end
    return item and ns[item] or ns
end

exports('qb-core', 'GetShared', GetShared)
