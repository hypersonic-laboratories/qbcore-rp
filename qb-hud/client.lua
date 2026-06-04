-- State

local isLoggedIn  = false
local my_webui    = WebUI('qb-hud', 'qb-hud/html/index.html')
local player_data = {}
local health      = 100
local playerDead  = false
local round       = math.floor

-- Helpers

local function disableDefaultHUD()
    SetHUDVisibility({
        Healthbar = false,
        Inventory = false,
        Shortcuts = false,
        --Minimap = false
    })
end

local function GetPackageDir()
    local info = debug.getinfo(1, 'S')
    local src  = info.source or ''
    if src:sub(1, 1) == '@' then src = src:sub(2) end
    return src:match('^(.*)[/\\].-$') or '.'
end

local function SendHUDUpdate()
    if not my_webui or not isLoggedIn then return end
    local meta = player_data.metadata
    if not meta then return end
    my_webui:SendEvent('UpdateHUD', health, meta['armor'], meta['hunger'], meta['thirst'], meta['stress'], playerDead)
end

-- Markers

local MarkerTextures = {}
local MarkerHandles  = {}
local nextMarkerId   = 0

local function GetMarkerTexture(iconName)
    if not iconName then return nil end
    if not MarkerTextures[iconName] then
        MarkerTextures[iconName] = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(
            HWorld, GetPackageDir() .. '/images/' .. iconName .. '.png'
        )
    end
    return MarkerTextures[iconName]
end

exports('qb-hud', 'AddMarker', function(coords, opts)
    opts = opts or {}
    local handle = HMap.AddMarkerAt(coords, {
        Title           = opts.title or '',
        Description     = opts.description or '',
        MarkerType      = opts.markerType or 'Store',
        SizeMultiplier  = opts.size or 1.0,
        OverrideColor   = opts.color,
        OverrideTexture = GetMarkerTexture(opts.icon),
    })
    if not handle or handle == 0 then return nil end
    nextMarkerId = nextMarkerId + 1
    MarkerHandles[nextMarkerId] = handle
    return nextMarkerId
end)

exports('qb-hud', 'RemoveMarker', function(id)
    local handle = MarkerHandles[id]
    if not handle then return end
    HMap.RemoveMarkerAt(handle)
    MarkerHandles[id] = nil
end)

-- Lifecycle

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

-- Player Events

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn  = true
    player_data = exports['qb-core']:GetPlayerData()
    disableDefaultHUD()
    if my_webui and player_data.money then
        my_webui:SendEvent('ShowCashAmount', round(player_data.money['cash'] or 0))
    end
    SendHUDUpdate()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn  = false
    player_data = {}
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'all' then
        player_data = val or {}
        SendHUDUpdate()
    elseif key == 'metadata' then
        player_data.metadata = val
        SendHUDUpdate()
    elseif key then
        player_data[key] = val
    end
end)

-- Money Events

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
    local money      = player_data.money or {}
    local cashAmount = money['cash'] or 0
    local bankAmount = money['bank'] or 0
    my_webui:SendEvent('UpdateMoney', {
        cashAmount   = round(cashAmount),
        bankAmount   = round(bankAmount),
        changeAmount = round(amount),
        isMinus      = isMinus,
        type         = type,
    })
end)

-- Game Events

RegisterClientEvent('HEvent:HealthChanged', function(_, newHealth)
    health = newHealth
    if newHealth > 0 and playerDead then playerDead = false end
    SendHUDUpdate()
end)

RegisterClientEvent('HEvent:Death', function()
    playerDead = true
    SendHUDUpdate()
end)

RegisterClientEvent('HEvent:VoiceStateChanged', function(isTalking)
    if not my_webui then return end
    my_webui:SendEvent('IsTalking', isTalking)
end)

RegisterClientEvent('HEvent:WeaponEquipped', function(displayName, weaponName)
    print('Equipped weapon: ' .. weaponName .. ' (' .. displayName .. ')')
end)

RegisterClientEvent('HEvent:WeaponUnequipped', function()
    print('Unequipped weapon')
end)

RegisterClientEvent('HEvent:EnteredVehicle', function(seat)
    print('Entered vehicle, seat: ' .. seat)
end)

RegisterClientEvent('HEvent:ExitedVehicle', function(seat)
    print('Exited vehicle, seat: ' .. seat)
end)

RegisterClientEvent('qb-hud:client:onRadio', function(bool)
    if not my_webui then return end
    my_webui:SendEvent('onRadio', bool)
end)
