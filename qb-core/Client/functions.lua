QBCore.Functions = {}
local my_webui = WebUI('qb-core', 'qb-core/Client/html/index.html', 0)

-- Getter Functions

function QBCore.Functions.GetPlayerData()
    return QBCore.PlayerData
end

-- Functions

function QBCore.Functions.DebugClient(tbl)
    if not HPlayer then return end
    HELIXTable.Dump(tbl)
end

-- UI

function QBCore.Functions.HideText()
    if not my_webui then return end
    my_webui:SendEvent('hideText')
    my_webui:SetInputMode(0)
end

function QBCore.Functions.DrawText(text, position)
    if not my_webui then return end
    if type(position) ~= 'string' then position = 'left' end
    my_webui:SendEvent('drawText', text, position)
end

function QBCore.Functions.ChangeText(text, position)
    if not my_webui then return end
    if type(position) ~= 'string' then position = 'left' end
    my_webui:SendEvent('changeText', text, position)
end

function QBCore.Functions.KeyPressed()
    if not my_webui then return end
    my_webui:SendEvent('keyPressed')
    QBCore.Functions.HideText()
end

function QBCore.Functions.Notify(text, texttype, length, icon)
    if not HPlayer then return end
    if not my_webui then return end
    local noti_type = texttype or 'primary'
    if type(text) == 'table' then
        my_webui:SendEvent('showNotif', {
            text = text.text,
            length = length or 5000,
            type = noti_type,
            caption = text.caption or '',
            icon = icon or nil
        })
    else
        my_webui:SendEvent('showNotif', {
            text = text,
            length = length or 5000,
            type = noti_type,
            caption = '',
            icon = icon or nil
        })
    end
end

for functionName, func in pairs(QBCore.Functions) do
    if type(func) == 'function' then
        exports('qb-core', functionName, func)
    end
end
