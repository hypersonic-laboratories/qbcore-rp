local Lang = require('locales/en')
local heldDrop = nil
CurrentDrop = nil
local activeDropTargets = {}

local function IsInventoryBusy()
    local player = HPlayer or GetLocalPlayer()
    return (player and GetValue(player, 'inv_busy') == true) or false
end

-- Events

RegisterClientEvent('qb-inventory:client:openDrop', function(data)
    if IsInventoryBusy() then
        return
    end
    CurrentDrop = data.dropId
    TriggerServerEvent('qb-inventory:server:openDrop', data.dropId)
end)

RegisterClientEvent('qb-inventory:client:holdDrop', function(dropId)
    exports['qb-core']:DrawText(Lang.t('interaction.d_bag', { value = Config.Keybinds.BagDrop }), 'right')
    heldDrop = dropId
end)

RegisterClientEvent('qb-inventory:client:registerDropTarget', function(actor, dropId)
    -- the bag actor may not have replicated yet when this event lands; the
    -- server re-broadcasts once, so bail and let that retry carry the actor
    if not actor then
        return
    end
    if activeDropTargets[dropId] == actor then
        return
    end
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
                label = Lang.t('menu.p_bag'),
                icon = 'package',
                event = 'qb-inventory:server:pickupDrop',
                type = 'server',
                dropId = dropId,
            },
        },
    })
end)

RegisterClientEvent('qb-inventory:client:setDropCollision', function(dropId, profileName)
    -- collision profiles are not replicated by Unreal; the server broadcasts
    -- this so each client applies the profile to its own copy of the bag
    local actor = activeDropTargets[dropId]
    if not actor then
        return
    end
    local comp = (actor.GetStaticMeshComponent and actor:GetStaticMeshComponent()) or actor:GetComponentByClass(UE.UStaticMeshComponent)
    if not comp then
        return
    end
    comp:SetMobility(UE.EComponentMobility.Movable)
    comp:SetCollisionProfileName(profileName, true)
end)

RegisterClientEvent('qb-inventory:client:removeDropTarget', function(dropId)
    if activeDropTargets[dropId] then
        exports['qb-target']:RemoveTargetEntity(activeDropTargets[dropId])
        activeDropTargets[dropId] = nil
    end
end)

-- KeyPress

Input.BindKey(Config.Keybinds.BagDrop, function()
    if not heldDrop then
        return
    end
    exports['qb-core']:HideText()
    TriggerServerEvent('qb-inventory:server:updateDrop', heldDrop)
    heldDrop = nil
end)
