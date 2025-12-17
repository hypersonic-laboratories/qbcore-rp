for i = 1, #Config.pumpModels do
    local pumpModel = Config.pumpModels[i]
    exports['qb-target']:AddTargetModel(pumpModel, {
        distance = 1000,
        options = {
            {
                icon = 'fas fa-oil-can',
                label = 'Fuel Can',
                event = 'qb-fuel:',
            },
            {
                icon = 'fas fa-gas-pump',
                label = 'Refuel',
                event = 'qb-fuel:',
            }
        }
    })
end