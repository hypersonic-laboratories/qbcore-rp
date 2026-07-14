local my_webui = WebUI('qb-fps', 'qb-fps/html/index.html')
local ui_open = false

-- Settings applied this session, as a cvar -> value map. Re-applied on player
-- load so a saved choice survives the reset that happens each launch.
local currentState = {}
local currentPreset = nil

local function notify(text, kind)
    if not Config.NotifyOnApply then return end
    pcall(function()
        exports['qb-core']:Notify(text, kind or 'primary')
    end)
end

-- Integer-valued numbers print without a trailing ".0" so int cvars parse
-- cleanly; fractional values keep their decimals.
local function fmtValue(v)
    if type(v) == 'number' then
        if v == math.floor(v) then
            return string.format('%d', v)
        end
        return tostring(v)
    end
    return tostring(v)
end

local function execConsole(cmd)
    return pcall(function()
        UE.UKismetSystemLibrary.ExecuteConsoleCommand(HWorld, cmd, nil)
    end)
end

local function applyCvar(cvar, value)
    if not execConsole(string.format('%s %s', cvar, fmtValue(value))) then
        return false
    end
    currentState[cvar] = value
    return true
end

local function findPreset(id)
    for i = 1, #Config.Presets do
        if Config.Presets[i].id == id then
            return Config.Presets[i]
        end
    end
    return nil
end

local function applyPreset(id)
    local preset = findPreset(id)
    if not preset then
        return false
    end
    for i = 1, #Config.Cvars do
        local cvar = Config.Cvars[i].cvar
        local value = preset.values[cvar]
        if value ~= nil then
            execConsole(string.format('%s %s', cvar, fmtValue(value)))
            currentState[cvar] = value
        end
    end
    currentPreset = id
    return true
end

local function applyState(state, presetId)
    if type(state) ~= 'table' then
        return false
    end
    for i = 1, #Config.Cvars do
        local cvar = Config.Cvars[i].cvar
        local value = state[cvar]
        if value ~= nil then
            execConsole(string.format('%s %s', cvar, fmtValue(value)))
            currentState[cvar] = value
        end
    end
    currentPreset = presetId
    return true
end

local function buildOpenPayload()
    return {
        cvars = Config.Cvars,
        presets = Config.Presets,
        presetOrder = Config.PresetOrder,
        current = currentState,
        currentPreset = currentPreset,
        command = Config.Command,
    }
end

local function openMenu()
    if not my_webui then return end
    ui_open = true
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    my_webui:SendEvent('open', buildOpenPayload())
end

local function closeMenu()
    if not my_webui then return end
    ui_open = false
    my_webui:SetInputMode(0)
    my_webui:SendEvent('close')
end

local function toggleMenu()
    if ui_open then
        closeMenu()
    elseif HPlayer:GetInputMode() ~= 1 then
        openMenu()
    end
end

-- The UI reports its saved settings once it is ready; re-apply them.
my_webui:RegisterEventHandler('fpsReady', function(data)
    data = data or {}
    if Config.ReapplyOnLoad and type(data.values) == 'table' and next(data.values) then
        applyState(data.values, data.preset)
    end
end)

my_webui:RegisterEventHandler('fpsApplyPreset', function(data)
    local id = data and tostring(data.id or '')
    if not id or id == '' then return end
    if applyPreset(id) then
        local preset = findPreset(id)
        notify(('Graphics preset: %s'):format(preset and preset.label or id), 'success')
        my_webui:SendEvent('applied', { preset = id, values = currentState })
    end
end)

my_webui:RegisterEventHandler('fpsSetCvar', function(data)
    if not data then return end
    local cvar = tostring(data.cvar or '')
    if cvar == '' or data.value == nil then return end
    if applyCvar(cvar, data.value) then
        currentPreset = nil
        my_webui:SendEvent('applied', { preset = nil, values = currentState })
    end
end)

my_webui:RegisterEventHandler('fpsClose', function()
    closeMenu()
end)

-- The /fps command toggles the menu.
if Config.Command and Config.Command ~= '' then
    local HConsole = GetActorByTag('HConsole')
    if HConsole then
        HConsole:RegisterCommand(Config.Command, 'Toggle the FPS / graphics menu', nil, {
            HWorld,
            function()
                toggleMenu()
            end,
        })
    end
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    if Config.ReapplyOnLoad and next(currentState) then
        applyState(currentState, currentPreset)
    end
end)

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

exports('qb-fps', 'ApplyPreset', function(id) return applyPreset(id) end)
exports('qb-fps', 'OpenMenu', openMenu)
exports('qb-fps', 'CloseMenu', closeMenu)
