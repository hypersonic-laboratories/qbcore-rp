local function hideText()
    QBCore.webui:SendEvent('HIDE_TEXT', {})
end

local function drawText(text, position)
    if type(position) ~= 'string' then position = 'left' end
    QBCore.webui:SendEvent('DRAW_TEXT', { text = text, position = position })
end

local function changeText(text, position)
    if type(position) ~= 'string' then position = 'left' end
    QBCore.webui:SendEvent('CHANGE_TEXT', { text = text, position = position })
end

local function keyPressed()
    QBCore.webui:SendEvent('KEY_PRESSED', {})
    hideText()
end

RegisterClientEvent('qb-core:client:DrawText', function(text, position)
    drawText(text, position)
end)

RegisterClientEvent('qb-core:client:ChangeText', function(text, position)
    changeText(text, position)
end)

RegisterClientEvent('qb-core:client:HideText', function()
    hideText()
end)

RegisterClientEvent('qb-core:client:KeyPressed', function()
    keyPressed()
end)

exports('qb-core', 'DrawText', drawText)
exports('qb-core', 'ChangeText', changeText)
exports('qb-core', 'HideText', hideText)
exports('qb-core', 'KeyPressed', keyPressed)
