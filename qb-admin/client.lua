local my_webui = WebUI('qb-admin', 'qb-admin/html/index.html')
local ui_open = false
local sky

-- Spawn Sky

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerCallback('syncRequest', function(skyInfo)
        sky = Sky()
        sky:SetTimeOfDay(skyInfo.time)
        sky:SetAnimateTimeOfDay(Config.AnimateTime)
        sky:ChangeWeather(Config.Weather.WeatherTypes[skyInfo.weather])
    end)
end)

-- Events

RegisterClientEvent('qb-admin:client:changeTime', function(hour)
    if not sky then return end
    sky:SetTimeOfDay(hour)
end)

RegisterClientEvent('qb-admin:client:changeWeather', function(weatherType)
    if not sky then return end
    local enumWeather = Config.Weather.WeatherTypes[weatherType] or WeatherType.ClearSkies
    sky:ChangeWeather(enumWeather, Config.Weather.TransitionDelay)
end)

-- NUI Events

my_webui:RegisterEventHandler('developer:teleportToLocation', function(data)
    local locationKey = tostring(data.key or data.name or '')
    if locationKey == '' then
        return
    end

    TriggerServerEvent('qb-admin:server:developer:teleportToLocation', {
        key = locationKey,
    })
end)

my_webui:RegisterEventHandler('developer:teleportToCoordinates', function(data)
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if not x or not y or not z then
        return
    end

    TriggerServerEvent('qb-admin:server:developer:teleportToCoordinates', {
        x = x,
        y = y,
        z = z,
    })
end)

my_webui:RegisterEventHandler('developer:spawnVehicle', function(data)
    TriggerServerEvent('qb-admin:server:developer:spawnVehicle', data)
end)

my_webui:RegisterEventHandler('developer:spawnObject', function(data)
    TriggerServerEvent('qb-admin:server:developer:spawnObject', data)
end)

my_webui:RegisterEventHandler('developer:copyCoords', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local coords = GetEntityCoords(pawn)
    CopyToClipboard(('%s, %s, %s'):format(math.modf(coords.X), math.modf(coords.Y), math.modf(coords.Z)))
end)

my_webui:RegisterEventHandler('developer:copyRotation', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local rot = GetEntityRotation(pawn)
    CopyToClipboard(('%s, %s, %s'):format(math.modf(rot.Yaw), math.modf(rot.Roll), math.modf(rot.Pitch)))
end)

my_webui:RegisterEventHandler('developer:copyHeading', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local heading = GetEntityHeading(pawn)
    CopyToClipboard(('%s'):format(math.modf(heading)))
end)

my_webui:RegisterEventHandler('developer:runConsoleCommand', function(data)
    local command = tostring(data.command or '')
    if command == '' then
        return
    end

    local Console = GetActorByTag('HConsole')
    if not Console then
        return
    end

    Console:Execute(command)
end)

my_webui:RegisterEventHandler('players:context-action', function(data)
    TriggerServerEvent('qb-admin:server:players:context-action', data)
end)

my_webui:RegisterEventHandler('players:vehicleAction', function(data)
    TriggerServerEvent('qb-admin:server:players:vehicleAction', data)
end)

my_webui:RegisterEventHandler('players:gangAction', function(data)
    TriggerServerEvent('qb-admin:server:players:gangAction', data)
end)

my_webui:RegisterEventHandler('players:jobAction', function(data)
    TriggerServerEvent('qb-admin:server:players:jobAction', data)
end)

my_webui:RegisterEventHandler('players:quickControl', function(data)
    TriggerServerEvent('qb-admin:server:players:quickControl', data)
end)

my_webui:RegisterEventHandler('players:replenishVital', function(data)
    TriggerServerEvent('qb-admin:server:players:replenishVital', data)
end)

my_webui:RegisterEventHandler('players:currencyAdjust', function(data)
    TriggerServerEvent('qb-admin:server:players:currencyAdjust', data)
end)

my_webui:RegisterEventHandler('dashboard:announce', function(data)
    TriggerServerEvent('qb-admin:server:dashboard:announce', data)
end)

my_webui:RegisterEventHandler('dashboard:quickAction', function(data)
    TriggerServerEvent('qb-admin:server:dashboard:quickAction', data)
end)

my_webui:RegisterEventHandler('chat:send', function(data)
    TriggerServerEvent('qb-admin:server:chat:send', data)
end)

my_webui:RegisterEventHandler('environment:cleanup', function(data)
    TriggerServerEvent('qb-admin:server:environment:cleanup', data)
end)

my_webui:RegisterEventHandler('environment:changeWeather', function(data)
    TriggerServerEvent('qb-admin:server:changeWeather', data.weather)
end)

my_webui:RegisterEventHandler('environment:changeTime', function(data)
    TriggerServerEvent('qb-admin:server:changeTime', data.hour)
end)

my_webui:RegisterEventHandler('reports:updateState', function(data)
    TriggerServerEvent('qb-admin:server:reports:updateState', data)
end)

my_webui:RegisterEventHandler('reports:resolved', function(data)
    TriggerServerEvent('qb-admin:server:reports:resolved', data)
end)

my_webui:RegisterEventHandler('reports:investigationAction', function(data)
    TriggerServerEvent('qb-admin:server:reports:investigationAction', data)
end)

my_webui:RegisterEventHandler('reports:clearResolved', function(data)
    TriggerServerEvent('qb-admin:server:reports:clearResolved', data)
end)

my_webui:RegisterEventHandler('ui:close', function()
    ui_open = false
    my_webui:SetInputMode(0)
end)

-- Inputs

Input.BindKey('F3', function()
    if not ui_open then
        ui_open = true
        my_webui:BringToFront()
        my_webui:SetInputMode(1)
        TriggerCallback('getOpenContext', function(response)
            my_webui:SendEvent('openAdmin', response.context)
        end)
    end
end, 'Released')

RegisterClientEvent('qb-admin:client:chatMessage', function(entry)
    my_webui:SendEvent('qb-admin:chatMessage', entry)
end)

RegisterClientEvent('qb-admin:client:reportFiled', function(payload)
    my_webui:SendEvent('qb-admin:reportFiled', payload)
end)

RegisterClientEvent('qb-admin:client:reportsUpdateState', function(payload)
    my_webui:SendEvent('qb-admin:reportsUpdateState', payload)
end)

RegisterClientEvent('qb-admin:client:reportResolved', function(payload)
    my_webui:SendEvent('qb-admin:reportResolved', payload)
end)

RegisterClientEvent('qb-admin:client:reportsClearedResolved', function(payload)
    my_webui:SendEvent('qb-admin:reportsClearedResolved', payload)
end)

RegisterClientEvent('qb-admin:client:dashboardAnnounce', function() end)

-- Admin action handlers

local frozenState = {}
RegisterClientEvent('qb-admin:client:setFrozen', function(frozen)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local controller = pawn:GetController()
    if frozen then
        pawn:DisableInput(controller)
    else
        pawn:EnableInput(controller)
    end
end)

RegisterClientEvent('qb-admin:client:setHealth', function(value)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    pcall(function()
        local comps = pawn:GetComponentsByClass(UE.UHActorHealthComponent)
        if comps and comps:Length() > 0 then
            local comp = comps:Get(1)
            comp:SetHealth(comp:GetMaxHealth() * (value / 100))
        end
    end)
end)

RegisterClientEvent('qb-admin:client:setArmor', function(value)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    pcall(function()
        local comps = pawn:GetComponentsByClass(UE.UHActorArmorComponent)
        if comps and comps:Length() > 0 then
            comps:Get(1):SetArmor(value)
        end
    end)
end)

RegisterClientEvent('qb-admin:client:revivePlayer', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    pcall(function()
        local comps = pawn:GetComponentsByClass(UE.UHActorHealthComponent)
        if comps and comps:Length() > 0 then
            local comp = comps:Get(1)
            comp:SetHealth(comp:GetMaxHealth())
        end
    end)
end)

RegisterClientEvent('qb-admin:client:killPlayer', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    pcall(function()
        local comps = pawn:GetComponentsByClass(UE.UHActorHealthComponent)
        if comps and comps:Length() > 0 then
            comps:Get(1):SetHealth(0)
        end
    end)
end)

local function getOccupiedVehicle(pawn)
    if not pawn then return nil end
    local parent = pawn:GetAttachParentActor()
    if parent and parent:IsValid() then
        return parent
    end
    return nil
end

RegisterClientEvent('qb-admin:client:vehicleRepair', function()
    local pawn = GetPlayerPawn()
    local vehicle = getOccupiedVehicle(pawn)
    if not vehicle then return end
    pcall(function()
        if vehicle.Repair then vehicle:Repair() end
    end)
end)

RegisterClientEvent('qb-admin:client:vehicleRefuel', function()
    local pawn = GetPlayerPawn()
    local vehicle = getOccupiedVehicle(pawn)
    if not vehicle then return end
    pcall(function()
        if vehicle.SetFuelLevel then
            vehicle:SetFuelLevel(100)
        end
    end)
end)

RegisterClientEvent('qb-admin:client:vehicleDelete', function()
    local pawn = GetPlayerPawn()
    local vehicle = getOccupiedVehicle(pawn)
    if not vehicle then return end
    vehicle:DestroyActor()
end)

RegisterClientEvent('qb-admin:client:openClothing', function()
    TriggerLocalEvent('qb-clothing:client:openMenu')
end)

RegisterClientEvent('qb-admin:client:openInventory', function(targetPlayerId)
    TriggerLocalEvent('qb-inventory:client:openInventory', targetPlayerId)
end)

local noclipActive = false
RegisterClientEvent('qb-admin:client:toggleNoclip', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    noclipActive = not noclipActive
    pcall(function()
        local movComp = pawn:GetMovementComponent()
        if noclipActive then
            movComp:SetMovementMode(UE.EMovementMode.MOVE_Flying)
            pawn:SetActorEnableCollision(false)
        else
            movComp:SetMovementMode(UE.EMovementMode.MOVE_Walking)
            pawn:SetActorEnableCollision(true)
        end
    end)
end)

local godModeActive = false
RegisterClientEvent('qb-admin:client:toggleGodMode', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    godModeActive = not godModeActive
    pcall(function()
        SetEntityInvincible(pawn, godModeActive)
    end)
end)

local invisActive = false
RegisterClientEvent('qb-admin:client:toggleInvisibility', function()
    local pawn = GetPlayerPawn()
    if not pawn then return end
    invisActive = not invisActive
    pawn:SetActorHiddenInGame(invisActive)
end)

local adminDutyActive = false
RegisterClientEvent('qb-admin:client:toggleAdminDuty', function()
    adminDutyActive = not adminDutyActive
end)

local overheadNamesActive = false
RegisterClientEvent('qb-admin:client:toggleOverheadNames', function()
    overheadNamesActive = not overheadNamesActive
    TriggerLocalEvent('qb-admin:client:overheadNamesChanged', overheadNamesActive)
end)

local spectateTargetId = nil
RegisterClientEvent('qb-admin:client:spectatePlayer', function(targetPlayerId)
    if spectateTargetId == targetPlayerId then
        spectateTargetId = nil
        return
    end
    spectateTargetId = targetPlayerId
end)

RegisterClientEvent('qb-admin:client:cleanupNearby', function(data)
    local pawn = GetPlayerPawn()
    if not pawn then return end
    local coords = GetEntityCoords(pawn)
    local radiusCm = (tonumber(data.radius) or 50) * 100
    local cleanType = tostring(data.type or 'all')

    pcall(function()
        local ObjectTypes = UE.TArray(0)
        ObjectTypes:Add(UE.ECollisionChannel.ECC_WorldDynamic)
        local hits = UE.TArray(UE.AActor)
        UE.UKismetSystemLibrary.SphereOverlapActors(HWorld, coords, radiusCm, ObjectTypes, nil, nil, hits)

        for i = 1, hits:Length() do
            local actor = hits:Get(i)
            if actor and actor:IsValid() and actor ~= pawn then
                local isVehicle = pcall(function() return actor:IsA(UE.AHVehicleCar) end) and actor:IsA(UE.AHVehicleCar)
                local isChar = pcall(function() return actor:IsA(UE.ACharacter) end) and actor:IsA(UE.ACharacter)
                local isPlayer = isChar and actor:IsPlayerControlled()
                if not isPlayer then
                    if cleanType == 'vehicles' and isVehicle then
                        actor:DestroyActor()
                    elseif cleanType == 'peds' and isChar then
                        actor:DestroyActor()
                    elseif cleanType == 'objects' and not isVehicle and not isChar then
                        actor:DestroyActor()
                    elseif cleanType == 'all' and (isVehicle or isChar) then
                        actor:DestroyActor()
                    end
                end
            end
        end
    end)
end)

-- Commands

local HConsole = GetActorByTag('HConsole')

if HConsole then
    HConsole:RegisterCommand('report', 'Make a report', nil, { HWorld, function()
        TriggerServerEvent('qb-admin:server:fileReport', { message = 'Test' })
    end })
end
