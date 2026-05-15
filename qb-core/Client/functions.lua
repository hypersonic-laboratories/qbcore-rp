QBCore.Functions = {}
local my_webui = WebUI('qb-core', 'qb-core/Client/html/index.html', 0)

-- Getter Functions

function QBCore.Functions.GetPlayerData()
    return QBCore.PlayerData
end

function QBCore.Functions.GetCitizenId()
    return QBCore.PlayerData.citizenid
end

function QBCore.Functions.GetJob()
    return QBCore.PlayerData.job
end

function QBCore.Functions.GetGang()
    return QBCore.PlayerData.gang
end

function QBCore.Functions.IsOnDuty()
    return QBCore.PlayerData.job and QBCore.PlayerData.job.onduty or false
end

function QBCore.Functions.IsBoss()
    return QBCore.PlayerData.job and QBCore.PlayerData.job.isboss or false
end

function QBCore.Functions.IsGangBoss()
    return QBCore.PlayerData.gang and QBCore.PlayerData.gang.isboss or false
end

function QBCore.Functions.IsDead()
    return QBCore.PlayerData.metadata and QBCore.PlayerData.metadata['isdead'] or false
end

function QBCore.Functions.IsHandcuffed()
    return QBCore.PlayerData.metadata and QBCore.PlayerData.metadata['ishandcuffed'] or false
end

function QBCore.Functions.IsInJail()
    return QBCore.PlayerData.metadata and QBCore.PlayerData.metadata['injail'] or false
end

function QBCore.Functions.HasLicence(licence)
    local licences = QBCore.PlayerData.metadata and QBCore.PlayerData.metadata.licences
    if not licences then return false end
    return licences[licence] or false
end

function QBCore.Functions.GetCharInfo(key)
    if not QBCore.PlayerData.charinfo then return nil end
    return QBCore.PlayerData.charinfo[key]
end

function QBCore.Functions.CanAfford(moneytype, amount)
    if not QBCore.PlayerData.money then return false end
    return (QBCore.PlayerData.money[moneytype] or 0) >= amount
end

-- Functions

function QBCore.Functions.Debug(tbl)
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
