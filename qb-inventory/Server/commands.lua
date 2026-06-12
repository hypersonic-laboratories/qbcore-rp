-- Commands

QBCore.Commands.Add(
    'giveitem',
    'Give An Item (Admin Only)',
    {
        { name = 'id', help = 'Player ID' },
        { name = 'item', help = 'Name of the item (not a label)' },
        { name = 'amount', help = 'Amount of items' },
    },
    true,
    function(source, args)
        local id = tonumber(args[1])
        local player = exports['qb-core']:GetPlayer(id)
        if not player then
            exports['qb-core']:NotifyPlayer(source, Lang.t('notify.pdne'), 'error')
            return
        end
        local amount = tonumber(args[3])
        if not amount then
            amount = 1
        end
        local itemData = QBShared.Items[tostring(args[2]):lower()]
        if not itemData then
            exports['qb-core']:NotifyPlayer(source, Lang.t('notify.idne'), 'error')
            return
        end
        local info = {}
        if itemData['name'] == 'id_card' then
            info.citizenid = player.PlayerData.citizenid
            info.firstname = player.PlayerData.charinfo.firstname
            info.lastname = player.PlayerData.charinfo.lastname
            info.birthdate = player.PlayerData.charinfo.birthdate
            info.gender = player.PlayerData.charinfo.gender
            info.nationality = player.PlayerData.charinfo.nationality
        elseif itemData['name'] == 'driver_license' then
            info.firstname = player.PlayerData.charinfo.firstname
            info.lastname = player.PlayerData.charinfo.lastname
            info.birthdate = player.PlayerData.charinfo.birthdate
            info.type = 'Class C Driver License'
        elseif itemData['type'] == 'weapon' then
            amount = 1
            info.serie = tostring(QBShared.RandomInt(2) .. QBShared.RandomStr(3) .. QBShared.RandomInt(1) .. QBShared.RandomStr(2) .. QBShared.RandomInt(3) .. QBShared.RandomStr(4))
            info.quality = 100
        elseif itemData['name'] == 'harness' then
            info.uses = 20
        elseif itemData['name'] == 'markedbills' then
            info.worth = math.random(5000, 10000)
        elseif itemData['name'] == 'printerdocument' then
            info.url = 'https://cdn.discordapp.com/attachments/870094209783308299/870104331142189126/Logo_-_Display_Picture_-_Stylized_-_Red.png'
        end

        if AddItem(id, itemData['name'], amount, false, info, 'give item command') then
            exports['qb-core']:NotifyPlayer(source, Lang.t('notify.yhg') .. player.PlayerData.name .. ' ' .. amount .. ' ' .. itemData['name'] .. '', 'success')
            TriggerClientEvent('qb-inventory:client:ItemBox', player.PlayerData.source, itemData, 'add', amount)
        --if Player(id).state.inv_busy then TriggerClientEvent('qb-inventory:client:updateInventory', id) end
        else
            exports['qb-core']:NotifyPlayer(source, Lang.t('notify.cgitem'), 'error')
        end
    end,
    'admin'
)

QBCore.Commands.Add('randomitems', 'Receive random items', {}, false, function(source)
    local player = exports['qb-core']:GetPlayer(source)
    if not player then
        return
    end
    local playerInventory = player.PlayerData.items
    local filteredItems = {}
    for k, v in pairs(QBShared.Items) do
        if QBShared.Items[k]['type'] ~= 'weapon' then
            filteredItems[#filteredItems + 1] = v
        end
    end
    for _ = 1, 10, 1 do
        local randitem = filteredItems[math.random(1, #filteredItems)]
        local amount = math.random(1, 10)
        if randitem['unique'] then
            amount = 1
        end
        local emptySlot = nil
        for i = 1, Config.MaxSlots do
            if not playerInventory[i] then
                emptySlot = i
                break
            end
        end
        if emptySlot then
            if AddItem(source, randitem.name, amount, emptySlot, false, 'random items command') then
                TriggerClientEvent('qb-inventory:client:ItemBox', source, QBShared.Items[randitem.name], 'add')
                player = exports['qb-core']:GetPlayer(source)
                if not player then
                    return
                end
                playerInventory = player.PlayerData.items
                --if Player(source).state.inv_busy then TriggerClientEvent('qb-inventory:client:updateInventory', source) end
            end
        end
    end
end, 'god')

QBCore.Commands.Add('clearinv', 'Clear Inventory (Admin Only)', { { name = 'id', help = 'Player ID' } }, false, function(source, args)
    local id = tonumber(args[1])
    if not id then
        ClearInventory(source)
        return
    end
    ClearInventory(id)
end, 'admin')
