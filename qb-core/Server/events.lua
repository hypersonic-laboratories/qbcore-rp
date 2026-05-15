-- Events

RegisterServerEvent('QBCore:UpdatePlayer', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local newHunger = Player.PlayerData.metadata['hunger'] - QBCore.Config.Player.HungerRate
    local newThirst = Player.PlayerData.metadata['thirst'] - QBCore.Config.Player.ThirstRate
    if newHunger <= 0 then newHunger = 0 end
    if newThirst <= 0 then newThirst = 0 end
    Player:SetMetaData('thirst', newThirst)
    Player:SetMetaData('hunger', newHunger)
    Player:Save()
end)

RegisterServerEvent('QBCore:ToggleDuty', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.onduty then
        Player:SetJobDuty(false)
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.off_duty'))
    else
        Player:SetJobDuty(true)
        TriggerClientEvent(source, 'QBCore:Notify', Lang:t('info.on_duty'))
    end
end)
