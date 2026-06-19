local properties = nil
local my_webui = WebUI('qb-input', 'qb-input/html/index.html')

my_webui:RegisterEventHandler('buttonSubmit', function(data, cb)
    my_webui:SetInputMode(0)
    if cb then cb('ok') end
    if not properties then return end
    properties:resolve(data.data)
    properties = nil
end)

my_webui:RegisterEventHandler('closeMenu', function(_, cb)
    my_webui:SetInputMode(0)
    if cb then cb('ok') end
    if not properties then return end
    properties:resolve(nil)
    properties = nil
end)

function onShutdown()
    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end

local function ShowInput(data)
    if not data then return end
    if properties then return end
    if not my_webui then return end
    properties = promise.new()
    my_webui:SendEvent('OpenMenu', data)
    my_webui:BringToFront()
    my_webui:SetInputMode(1)
    return properties:await()
end

local function CloseMenu()
    if not my_webui then return end
    if properties then
        properties:resolve(nil)
        properties = nil
    end
    my_webui:SendEvent('CloseMenu')
    my_webui:SetInputMode(0)
end

-- Events

RegisterClientEvent('qb-input:client:ShowMenu', function(data)
    ShowInput(data)
end)

RegisterClientEvent('qb-input:client:CloseMenu', function()
    CloseMenu()
end)

exports('qb-input', 'ShowInput', ShowInput)
exports('qb-input', 'CloseMenu', CloseMenu)
