--[[ QBCore.Commands.Add('cam', Lang.t('commands.camera'), { { name = 'camid', help = Lang.t('info.camera_id') } }, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' and not Player.PlayerData.job.onduty then
        Events.CallRemote('QBCore:Notify', source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end
    local camera_id = tonumber(args[1])
    if not Config.SecurityCameras.cameras[camera_id] then
        Events.CallRemote('QBCore:Notify', source, Lang.t('error.no_camera'), 'error')
        return
    end
    local ped = source:GetControlledCharacter()
    if ped then
        source:UnPossess()
        ped:Destroy()
    end
    Events.CallRemote('qb-policejob:client:viewCamera', source, camera_id)
end, 'user')

QBCore.Commands.Add('911p', Lang.t('commands.police_report'), { { name = 'message', help = Lang.t('commands.message_sent') } }, false, function(source, args)
    local message
    if args[1] then message = table.concat(args, ' ') else message = Lang.t('commands.civilian_call') end
    local ped = source:GetControlledCharacter()
    local coords = ped:GetLocation()
    local players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(players) do
        if v and v.PlayerData.job.type == 'leo' and v.PlayerData.job.onduty then
            Events.CallRemote('qb-policejob:client:policeAlert', v.PlayerData.source, coords, message)
        end
    end
end, 'user')

QBCore.Commands.Add('tracker', Lang.t('commands.ankletlocation'), { { name = 'cid', help = Lang.t('info.citizen_id') } }, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.PlayerData.job.type ~= 'leo' and not Player.PlayerData.job.onduty then
        Events.CallRemote('QBCore:Notify', source, Lang.t('error.on_duty_police_only'), 'error')
        return
    end
    local citizenid = args[1]
    local OtherPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not OtherPlayer then return end
    if OtherPlayer.PlayerData.metadata['tracker'] then
        local target_ped = OtherPlayer.PlayerData.source:GetControlledCharacter()
        if not target_ped then return end
        local target_coords = target_ped:GetLocation()
        Events.CallRemote('qb-policejob:client:tracker', source, target_coords, citizenid)
    else
        Events.CallRemote('QBCore:Notify', source, Lang.t('error.no_anklet'), 'error')
    end
end)
 ]]
