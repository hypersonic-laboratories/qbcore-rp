RegisterCallback('GetPlayerSkin', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then return nil end
    local citizenId = Player.PlayerData.citizenid
    if not citizenId then return nil end
    local result = exports['qb-core']:DatabaseAction('Select', 'SELECT skin FROM playerskins WHERE citizenid = ? LIMIT 1', { citizenId })
    if result and result[1] then
        return result[1].skin
    end
    return nil
end)

RegisterServerEvent('qb-clothing:server:SaveSkin', function(source, skinJson)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not skinJson then return end
    local citizenId = Player.PlayerData.citizenid
    if not citizenId then return nil end
    exports['qb-core']:DatabaseAction('Execute', [[
        INSERT INTO playerskins (citizenid, model, skin)
        VALUES (?, 'helix', ?)
        ON CONFLICT(citizenid) DO UPDATE SET skin = excluded.skin
    ]], { citizenId, skinJson })
end)
