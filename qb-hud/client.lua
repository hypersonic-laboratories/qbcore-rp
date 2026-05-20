local isLoggedIn = false
local inputTimer = nil
local my_webui = WebUI('qb-hud', 'qb-hud/html/index.html')
local player_data = {}
local playerPawn = nil
local health = 100
local hunger = 100
local thirst = 100
local playerDead = false
local round = math.floor

function onShutdown()
    if inputTimer then
        Timer.ClearInterval(inputTimer)
        inputTimer = nil
    end
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

local function disableDefaultHUD()
    SetHUDVisibility({
        Healthbar = false,
        Inventory = false,
        Shortcuts = false,
    })
end

-- Event Handlers

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    disableDefaultHUD()
    player_data = exports['qb-core']:GetPlayerData()
    if my_webui and player_data.money then
        my_webui:SendEvent('ShowCashAmount', round(player_data.money['cash'] or 0))
    end
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    playerPawn = nil
    player_data = {}
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'all' then
        player_data = val or {}
    elseif key then
        player_data[key] = val
    end
end)

RegisterClientEvent('qb-hud:client:onRadio', function(bool)
    if not my_webui then return end
    my_webui:SendEvent('onRadio', bool)
end)

-- Money HUD

RegisterClientEvent('qb-hud:client:ShowAccounts', function(type, amount)
    if not my_webui then return end
    if type == 'cash' then
        my_webui:SendEvent('ShowCashAmount', round(amount))
    else
        my_webui:SendEvent('ShowBankAmount', round(amount))
    end
end)

RegisterClientEvent('qb-hud:client:OnMoneyChange', function(type, amount, isMinus)
    if not my_webui then return end
    local money = player_data.money or {}
    local cashAmount = money['cash'] or 0
    local bankAmount = money['bank'] or 0
    my_webui:SendEvent('UpdateMoney', {
        cashAmount = round(cashAmount),
        bankAmount = round(bankAmount),
        changeAmount = round(amount),
        isMinus = isMinus,
        type = type
    })
end)

-- Game Events

RegisterClientEvent('HEvent:HealthChanged', function(_, newHealth)
    if not my_webui then return end
    health = newHealth
    if newHealth > 0 and playerDead then playerDead = false end
end)

RegisterClientEvent('HEvent:Death', function()
    playerDead = true
end)

RegisterClientEvent('HEvent:WeaponEquipped', function(displayName, weaponName)
    if not my_webui then return end
    print('Equipped weapon: ' .. weaponName .. ' (' .. displayName .. ')')
end)

RegisterClientEvent('HEvent:WeaponUnequipped', function()
    if not my_webui then return end
    print('Unequipped weapon')
end)

RegisterClientEvent('HEvent:EnteredVehicle', function(seat)
    if not my_webui then return end
    print('Entered vehicle, seat: ' .. seat)
end)

RegisterClientEvent('HEvent:ExitedVehicle', function(seat)
    if not my_webui then return end
    print('Exited vehicle, seat: ' .. seat)
end)

RegisterClientEvent('HEvent:PlayerPossessed', function()
    playerPawn = GetPlayerPawn()
end)

RegisterClientEvent('HEvent:PlayerUnPossessed', function()
    playerPawn = nil
end)

RegisterClientEvent('HEvent:VoiceStateChanged', function(isTalking)
    if not my_webui then return end
    my_webui:SendEvent('IsTalking', isTalking)
end)

-- HUD Thread

inputTimer = Timer.SetInterval(function()
    if not isLoggedIn then return end
    if not GetPlayerPawn() then return end
    if not player_data then return end
    local armor  = player_data.metadata['armor']
    hunger       = player_data.metadata['hunger']
    thirst       = player_data.metadata['thirst']
    local stress = player_data.metadata['stress']
    --local playerDead = player_data.metadata['inlaststand'] or player_data.metadata['isdead'] or false

    if my_webui then
        my_webui:SendEvent('UpdateHUD', health, armor, hunger, thirst, stress, playerDead)
    end
end, 1000)
