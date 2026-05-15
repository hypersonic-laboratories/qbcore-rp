-- Events

RegisterClientEvent('QBCore:Player:SetPlayerData', function(val)
    QBCore.PlayerData = val
end)

RegisterClientEvent('QBCore:Player:OnFieldUpdate', function(key, value)
    QBCore.PlayerData[key] = value
end)

RegisterClientEvent('QBCore:Player:OnSubFieldUpdate', function(key, subKey, value)
    if QBCore.PlayerData[key] then
        QBCore.PlayerData[key][subKey] = value
    end
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function(job)
    QBCore.PlayerData.job = job
end)

RegisterClientEvent('QBCore:Client:OnGangUpdate', function(gang)
    QBCore.PlayerData.gang = gang
end)

RegisterClientEvent('QBCore:Player:UpdatePlayerData', function()
    TriggerServerEvent('QBCore:UpdatePlayer')
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
