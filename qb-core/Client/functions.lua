---@class QBCore.Functions
QBCore.Functions = {}
local my_webui = WebUI('qb-core', 'qb-core/Client/html/index.html', 0)

---Returns this players playerdata.
---@nodiscard
---@return QBCore.PlayerData PlayerData the qb-core playerdata of this player
function QBCore.Functions.GetPlayerData()
    return QBCore.PlayerData
end

---Debug function to dump tables to console.
---@param tbl table The table to dump
function QBCore.Functions.Debug(tbl)
    if not HPlayer then return end
    HELIXTable.Dump(tbl)
end

---Hides the current Text.
function QBCore.Functions.HideText()
    if not my_webui then return end
    my_webui:SendEvent('hideText')
    my_webui:SetInputMode(0)
end

---Draws text on the players screen.
---@param text string The text to draw
---@param position string The position on the screen to draw the text (default: "left")
function QBCore.Functions.DrawText(text, position)
    if not my_webui then return end
    if type(position) ~= 'string' then position = 'left' end
    my_webui:SendEvent('drawText', text, position)
end

---Changes the text currently being drawn on the players screen.
---@param text string The new text to draw
---@param position string The position on the screen to draw the text (default: "left")
function QBCore.Functions.ChangeText(text, position)
    if not my_webui then return end
    if type(position) ~= 'string' then position = 'left' end
    my_webui:SendEvent('changeText', text, position)
end

---Notifies the server that the key has been pressed (???)
function QBCore.Functions.KeyPressed()
    if not my_webui then return end
    my_webui:SendEvent('keyPressed')
    QBCore.Functions.HideText()
end

---Sends a notification to the player.
---@param text string|{text: string, caption?: string} The text to display in the notification. If a table is provided, it should contain 'text' and optionally 'caption'.
---@param texttype string The type of notification
---@param length number The length of time the notification should be displayed in milliseconds
---@param icon string? The icon to display in the notification
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
