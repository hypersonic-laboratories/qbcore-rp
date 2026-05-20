QBCore.PlayerData = {}
QBCore.IsLoggedIn = false

-- Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.IsLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    QBCore.IsLoggedIn = false
    QBCore.PlayerData = {}
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'all' then
        QBCore.PlayerData = val
        TriggerLocalClientEvent('QBCore:Player:SetPlayerData', val)
        TriggerLocalClientEvent('QBCore:Client:OnJobUpdate', val.job)
        TriggerLocalClientEvent('QBCore:Client:OnGangUpdate', val.gang)
    elseif QBCore.PlayerData and key then
        QBCore.PlayerData[key] = val
        if key == 'job' then TriggerLocalClientEvent('QBCore:Client:OnJobUpdate', val) end
        if key == 'gang' then TriggerLocalClientEvent('QBCore:Client:OnGangUpdate', val) end
    end
end)

RegisterClientEvent('QBCore:Client:OnSharedUpdate', function(tableName, key, value)
    QBCore.Shared[tableName][key] = value
    TriggerEvent('QBCore:Client:UpdateObject')
end)

RegisterClientEvent('QBCore:Client:OnSharedUpdateMultiple', function(tableName, values)
    for key, value in pairs(values) do
        QBCore.Shared[tableName][key] = value
    end
    TriggerEvent('QBCore:Client:UpdateObject')
end)

RegisterClientEvent('QBCore:Notify', function(text, type, length, icon)
    QBCore.Functions.Notify(text, type, length, icon)
end)

RegisterClientEvent('qb-core:client:DrawText', function(text, position)
    QBCore.Functions.DrawText(text, position)
end)

RegisterClientEvent('qb-core:client:ChangeText', function(text, position)
    QBCore.Functions.ChangeText(text, position)
end)

RegisterClientEvent('qb-core:client:HideText', function()
    QBCore.Functions.HideText()
end)

RegisterClientEvent('qb-core:client:KeyPressed', function()
    QBCore.Functions.KeyPressed()
end)
