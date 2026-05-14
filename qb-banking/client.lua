local my_webui = WebUI('qb-banking', 'qb-banking/html/index.html')

RegisterClientEvent('QBCore:Player:OnFieldUpdate', function(key, val)
    if key == 'money' and my_webui then
        my_webui:SendEvent('updatePlayerMoney', {
            cash = val.cash or 0,
            bank = val.bank or 0
        })
    end
end)

-- Functions

my_webui:RegisterEventHandler('closeApp', function()
    my_webui:SetInputMode(0)
end)

my_webui:RegisterEventHandler('withdraw', function(data, cb)
    TriggerCallback('withdraw', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('deposit', function(data, cb)
    TriggerCallback('deposit', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('internalTransfer', function(data, cb)
    TriggerCallback('internalTransfer', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('externalTransfer', function(data, cb)
    TriggerCallback('externalTransfer', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('orderCard', function(data, cb)
    TriggerCallback('orderCard', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('openAccount', function(data, cb)
    TriggerCallback('openAccount', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('renameAccount', function(data, cb)
    TriggerCallback('renameAccount', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('deleteAccount', function(data, cb)
    TriggerCallback('deleteAccount', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('addUser', function(data, cb)
    TriggerCallback('addUser', function(status)
        cb(status)
    end, data)
end)

my_webui:RegisterEventHandler('removeUser', function(data, cb)
    TriggerCallback('removeUser', function(status)
        cb(status)
    end, data)
end)

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

local function OpenBank()
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    TriggerCallback('openBank', function(data)
        my_webui:SendEvent('openBank', {
            accounts = data.accounts,
            statements = data.statements,
            playerData = data.playerData
        })
    end)
end

RegisterClientEvent('qb-banking:client:openBank', function()
    OpenBank()
end)

local function OpenATM()
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    TriggerCallback('openATM', function(data)
        my_webui:SendEvent('openATM', {
            accounts = data.accounts,
            pinNumbers = data.acceptablePins,
            playerData = data.playerData
        })
    end)
end

RegisterClientEvent('qb-banking:client:openATM', function()
    OpenATM()
end)

-- Events

-- RegisterClientEvent('qb-banking:client:useCard', function()
--     if NearATM() then OpenATM() end
-- end)

-- Threads

-- CreateThread(function()
--     for i = 1, #Config.locations do
--         local blip = AddBlipForCoord(Config.locations[i])
--         SetBlipSprite(blip, Config.blipInfo.sprite)
--         SetBlipDisplay(blip, 4)
--         SetBlipScale(blip, Config.blipInfo.scale)
--         SetBlipColour(blip, Config.blipInfo.color)
--         SetBlipAsShortRange(blip, true)
--         BeginTextCommandSetBlipName('STRING')
--         AddTextComponentSubstringPlayerName(tostring(Config.blipInfo.name))
--         EndTextCommandSetBlipName(blip)
--     end
-- end)

Timer.SetTimeout(function()
    for i = 1, #Config.locations do
        exports['qb-target']:AddMeshTarget(
            'bank_' .. i,
            Config.locations[i].coords,
            Rotator(0, Config.locations[i].heading, 0),
            '/QBCoreAssets/Meshes/SM_Clipboard.SM_Clipboard', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
            {
                {
                    icon = 'university',
                    label = 'Open Bank',
                    event = 'qb-banking:client:openBank',
                }
            }
        )
    end

    for i = 1, #Config.atm_locations do
        exports['qb-target']:AddMeshTarget(
            'atm_' .. i,
            Config.atm_locations[i].coords,
            Rotator(0, Config.atm_locations[i].heading, 0),
            '/QBCoreAssets/Meshes/SM_ATM.SM_ATM', { collision = CollisionType.Normal, stationary = true, distance = 1000 },
            {
                {
                    icon = 'university',
                    label = 'Open ATM',
                    -- event = 'qb-banking:client:openATM',
                    event = 'qb-banking:client:openBank',
                }
            }
        )
    end

    -- for i = 1, #Config.atmModels do
    --     local atmModel = Config.atmModels[i]
    --     exports['qb-target']:AddTargetModel(atmModel, {
    --         options = {
    --             {
    --                 icon = 'university',
    --                 label = 'Open ATM',
    --                 --item = 'bank_card',
    --                 event = 'qb-banking:client:openATM',
    --             }
    --         },
    --         distance = 1000
    --     })
    -- end
end, 2000)
