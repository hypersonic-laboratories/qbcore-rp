local Lang = require('locales/en')

exports['qb-target']:AddTargetModel('SM_Dumpster', {
    options = {
        {
            icon = 'box',
            label = Lang.t('target.collect_garbage'),
            type = 'server',
            event = 'qb-garbagejob:server:grabBag',
            job = 'garbage'
        }
    },
    distance = 1000
})

exports['qb-target']:AddTargetModel('GarbageTruck', {
    options = {
        {
            label = Lang.t('target.deposit_garbage'),
            icon = 'truck-ramp-box',
            type = 'server',
            event = 'qb-garbagejob:server:loadBag',
            job = 'garbage',
        }
    },
    distance = 1000
})

local function setupPeds()
    TriggerCallback('getPeds', function(jobPeds)
        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc
            print('NPC Client: ', ped)
            local distance = 1000
            local options = {
                {
                    type = 'server',
                    event = 'QBCore:ToggleDuty',
                    label = Lang.t('target.toggle_duty'),
                    icon = 'clipboard',
                    job = 'garbage',
                },
                {
                    type = 'server',
                    event = 'qb-garbagejob:server:startJob',
                    label = Lang.t('target.start_job'),
                    icon = 'truck-field',
                    job = 'garbage',
                    depot = jobPeds[i].depot
                },
                {
                    type = 'server',
                    event = 'qb-garbagejob:server:completeJob',
                    label = Lang.t('target.complete_route'),
                    icon = 'circle-check',
                    job = 'garbage',
                }
            }
            exports['qb-target']:AddTargetEntity(ped, { options = options, distance = distance })
        end
    end)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    setupPeds()
end)

RegisterClientEvent('qb-garbagejob:client:removeTargets', function(vehicle)
    if vehicle then
        exports['qb-target']:RemoveTargetEntity(vehicle)
    end
end)
