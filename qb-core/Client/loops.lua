Timer.SetInterval(function()
    if not QBCore.IsLoggedIn then return end
    TriggerServerEvent('QBCore:UpdatePlayer')
end, (1000 * 60) * QBCore.Config.UpdateInterval)

Timer.SetInterval(function()
    if not QBCore.IsLoggedIn then return end
    local metadata = QBCore.PlayerData.metadata
    if (metadata['hunger'] <= 0 or metadata['thirst'] <= 0) and not (metadata['isdead'] or metadata['inlaststand']) then
        TriggerServerEvent('QBCore:Server:ApplyHungerThirstDamage', math.random(5, 10))
    end
end, QBCore.Config.StatusInterval)
