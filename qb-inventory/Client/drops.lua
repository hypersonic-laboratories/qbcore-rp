local Lang = require('locales/en')
local heldDrop = nil
CurrentDrop = nil
local activeDropTargets = {}

-- Events

RegisterClientEvent('qb-inventory:client:openDrop', function(data)
    CurrentDrop = data.dropId
    TriggerServerEvent('qb-inventory:server:openDrop', data.dropId)
end)

RegisterClientEvent('qb-inventory:client:holdDrop', function(dropId)
    exports['qb-core']:DrawText('Press [K] to drop Bag', 'right')
    heldDrop = dropId
end)

RegisterClientEvent('qb-inventory:client:registerDropTarget', function(actor, dropId)
    if activeDropTargets[dropId] then
        exports['qb-target']:RemoveTargetEntity(activeDropTargets[dropId])
    end
    activeDropTargets[dropId] = actor
    exports['qb-target']:AddTargetEntity(actor, {
        distance = 200,
        options = {
            {
                label = Lang.t('menu.o_bag'),
                icon = 'backpack',
                event = 'qb-inventory:client:openDrop',
                type = 'client',
                dropId = dropId,
            },
            {
                label = 'Pick Up Bag',
                icon = 'package',
                event = 'qb-inventory:server:pickupDrop',
                type = 'server',
                dropId = dropId,
            },
        },
    })
end)

RegisterClientEvent('qb-inventory:client:removeDropTarget', function(dropId)
    if activeDropTargets[dropId] then
        exports['qb-target']:RemoveTargetEntity(activeDropTargets[dropId])
        activeDropTargets[dropId] = nil
    end
end)

-- KeyPress

Input.BindKey('K', function()
    if not heldDrop then
        return
    end
    exports['qb-core']:HideText()
    TriggerServerEvent('qb-inventory:server:updateDrop', heldDrop)
    heldDrop = nil
end)
