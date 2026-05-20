QBCore.PlayerData = {}
QBCore.Functions = {}

QBCore.webui = WebUI('qb-core', 'qb-core/html/index.html')
QBCore.webui:RegisterEventHandler('getNotifyConfig', function()
    QBCore.webui:SendEvent('notifyConfig', QBCore.Config.Notify)
end)

-- Callbacks

function QBCore.Functions.CreateClientCallback(name, cb)
    QBCore.ClientCallbacks[name] = cb
end

function QBCore.Functions.TriggerCallback(name, ...)
    local cb = nil
    local args = { ... }

    if type(args[1]) == 'function' then
        cb = args[1]
        table.remove(args, 1)
    end

    QBCore.ServerCallbacks[name] = {
        callback = cb,
        promise = promise.new()
    }

    TriggerServerEvent('QBCore:Server:TriggerCallback', name, table.unpack(args))

    if cb == nil then
        Citizen.Await(QBCore.ServerCallbacks[name].promise)
        return QBCore.ServerCallbacks[name].promise.value
    end
end

function QBCore.Debug(resource, obj, depth)
    TriggerServerEvent('QBCore:DebugSomething', resource, obj, depth)
end

-- Player

function QBCore.Functions.GetPlayerData(cb)
    if not cb then return QBCore.PlayerData end
    cb(QBCore.PlayerData)
end

function QBCore.Functions.GetName()
    local charinfo = QBCore.PlayerData.charinfo
    return charinfo.firstname .. ' ' .. charinfo.lastname
end

function QBCore.Functions.HasItem(items, amount)
    return exports['qb-inventory']:HasItem(items, amount)
end

function QBCore.Functions.GetCoords(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

function QBCore.Functions.GetPlate(vehicle)
    if vehicle == 0 then return end
    return QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
end

-- Notifications

function QBCore.Functions.Notify(text, texttype, length, icon)
    local message = {
        action = 'notify',
        type = texttype or 'primary',
        length = length or 5000,
    }

    if type(text) == 'table' then
        message.text = text.text or 'Placeholder'
        message.caption = text.caption or 'Placeholder'
    else
        message.text = text
    end

    if icon then
        message.icon = icon
    end

    QBCore.webui:SendEvent(message.action, message)
end

for functionName, func in pairs(QBCore.Functions) do
    if type(func) == 'function' then
        exports(functionName, func)
    end
end
