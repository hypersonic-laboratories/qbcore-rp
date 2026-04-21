for i = 1, #Config.pumpModels do
    local pumpModel = Config.pumpModels[i]
    exports['qb-target']:AddTargetModel(pumpModel, {
        distance = 1000,
        options = {
            {
                icon = 'oil-can',
                label = 'Fuel Can',
                event = 'qb-fuel:',
            },
            {
                icon = 'gas-pump',
                label = 'Refuel',
                event = 'qb-fuel:',
            }
        }
    })
end
