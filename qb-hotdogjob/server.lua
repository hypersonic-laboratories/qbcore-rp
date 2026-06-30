local Lang = require('locales/en')

local Bail = {}
local jobPeds = {}
local activeStands = {}
local strikes = {}
local initialised = false

local function getPlayerKey(source)
    local Player = exports['qb-core']:GetPlayer(source)
    return Player and Player.PlayerData and Player.PlayerData.citizenid or tostring(GetPlayerId(source))
end

local function getPlayerId(source)
    return GetPlayerId(source)
end

local function getActor(entity)
    if entity and entity.Object then
        return entity.Object
    end
    return entity
end

local function isValidActor(actor)
    return actor and (not actor.IsValid or actor:IsValid())
end

local function deleteActor(actor)
    actor = getActor(actor)
    if isValidActor(actor) then
        DeleteEntity(actor)
    end
end

local function notify(source, message, notifyType, length)
    TriggerClientEvent(source, 'QBCore:Notify', message, notifyType or 'primary', length)
end

local function strike(source, reason)
    local key = getPlayerKey(source)
    strikes[key] = (strikes[key] or 0) + 1

    if strikes[key] >= 3 and source and source.Kick then
        source:Kick(('You were removed for exploiting: %s'):format(reason))
    end
end

local function getSession(source)
    return activeStands[getPlayerId(source)]
end

local function getStandCoords(session)
    if not session or not isValidActor(session.stand) then
        return nil
    end
    return GetEntityCoords(session.stand)
end

local function getSaleCoords(session)
    local standCoords = getStandCoords(session)
    if not standCoords then
        return nil
    end

    local offset = Config.Stand.CustomerOffset or Vector(120, 0, 0)
    return Vector(standCoords.X + offset.X, standCoords.Y + offset.Y, standCoords.Z + offset.Z)
end

local function isNearStand(source, maxDistance)
    local session = getSession(source)
    local pawn = GetPlayerPawn(source)
    local standCoords = getStandCoords(session)
    if not pawn or not standCoords then
        return false
    end

    local pawnCoords = GetEntityCoords(pawn)
    return GetDistanceBetweenCoords(pawnCoords, standCoords) <= (maxDistance or Config.ServerDistance)
end

local function clearCustomer(source, shouldNotify)
    local session = getSession(source)
    if not session then
        return
    end

    if session.customerTimer then
        Timer.ClearInterval(session.customerTimer)
        session.customerTimer = nil
    end

    if session.customerController then
        pcall(function()
            session.customerController:StopMovement()
        end)
    end

    deleteActor(session.customer)
    session.customer = nil
    session.customerController = nil
    session.customerArrived = false

    if shouldNotify ~= false then
        TriggerClientEvent(source, 'qb-hotdogjob:client:ClearCustomer')
    end
end

local function clearStand(source, shouldNotify)
    local playerId = getPlayerId(source)
    local session = activeStands[playerId]
    if not session then
        return
    end

    clearCustomer(source, false)
    deleteActor(session.stand)
    activeStands[playerId] = nil

    if shouldNotify ~= false then
        TriggerClientEvent(source, 'qb-hotdogjob:client:StandRemoved')
    end
end

local function spawnJobPed(location, depotIndex)
    local pedName = location.pedName or location.label or 'Hotdog Stand'
    HPawn(location.coords, Rotator(0, location.heading or 0, 0), function(npc)
        if not npc then
            return
        end

        jobPeds[#jobPeds + 1] = { npc = npc, depot = depotIndex }
        npc:SetCharacterName(pedName)
        SetEntityInvincible(npc, true)
    end, { CharacterName = pedName, bShowNameplate = true })
end

local function spawnStand(source)
    local existing = getSession(source)
    if existing and isValidActor(existing.stand) then
        return existing.stand
    end

    local spawn = Config.Locations.spawn
    local stand = StaticMesh(spawn.coords, Rotator(0, spawn.heading or 0, 0), Config.Stand.Mesh, CollisionType.Normal, true)
    if not stand or not stand.Object then
        return nil
    end

    local standActor = stand.Object
    if Config.Stand.Scale then
        standActor:SetActorScale3D(Config.Stand.Scale)
    end

    activeStands[getPlayerId(source)] = {
        source = source,
        stand = standActor,
        isPushing = false,
    }

    return standActor
end

local function trySetWalking(pawn)
    pcall(function()
        local movement = pawn:GetComponentByClass(UE.UCharacterMovementComponent)
        if movement then
            movement:SetMovementMode(UE.EMovementMode.MOVE_Walking, nil)
        end
    end)
end

local function getController(pawn)
    local controller
    pcall(function()
        pawn:SpawnDefaultController()
        controller = pawn:GetController()
    end)
    return controller
end

local function moveCustomerTowardStand(source)
    local session = getSession(source)
    if not session or not isValidActor(session.customer) or not session.customerController then
        clearCustomer(source)
        return
    end

    local targetCoords = getSaleCoords(session)
    local customerCoords = GetEntityCoords(session.customer)
    if not targetCoords or not customerCoords then
        return
    end

    local acceptanceRadius = Config.Customer.AcceptanceRadius or 150.0
    if GetDistanceBetweenCoords(customerCoords, targetCoords) <= acceptanceRadius then
        pcall(function()
            session.customerController:StopMovement()
        end)

        if session.customerTimer then
            Timer.ClearInterval(session.customerTimer)
            session.customerTimer = nil
        end

        session.customerArrived = true
        TriggerClientEvent(source, 'qb-hotdogjob:client:CustomerArrived', session.customer)
        return
    end

    pcall(function()
        session.customerController:MoveToLocation(targetCoords, acceptanceRadius, false, false, false, true, nil, true)
    end)
end

local function beginCustomerMove(source)
    local session = getSession(source)
    if not session or not isValidActor(session.customer) then
        return
    end

    trySetWalking(session.customer)
    local controller = getController(session.customer)
    if not controller then
        clearCustomer(source)
        return
    end

    session.customerController = controller
    moveCustomerTowardStand(source)

    if session.customerTimer then
        Timer.ClearInterval(session.customerTimer)
    end

    session.customerTimer = Timer.SetInterval(function()
        moveCustomerTowardStand(source)
    end, Config.Customer.MoveTickMs or 500)
end

local function getCustomerSpawn()
    local base = Config.Customer.SpawnLocation
    local radius = Config.Customer.SpawnRadius or 0
    if radius <= 0 then
        return base
    end

    return Vector(base.X + math.random(-radius, radius), base.Y + math.random(-radius, radius), base.Z)
end

local function getMaxHotdogPrice()
    local maxPrice = 0
    for _, stock in pairs(Config.Stock) do
        for _, price in pairs(stock.Price) do
            maxPrice = math.max(maxPrice, tonumber(price.max) or 0)
        end
    end
    return maxPrice
end

RegisterServerEvent('HEvent:PlayerPossessed', function()
    if initialised then
        return
    end

    if Config.Locations.take then
        spawnJobPed(Config.Locations.take, 1)
    end

    initialised = true
end)

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    clearStand(source, false)
    Bail[getPlayerKey(source)] = nil
    strikes[getPlayerKey(source)] = nil
end)

function onShutdown()
    for _, session in pairs(activeStands) do
        if session.customerTimer then
            Timer.ClearInterval(session.customerTimer)
        end
        deleteActor(session.customer)
        deleteActor(session.stand)
    end
    activeStands = {}

    for i = 1, #jobPeds do
        deleteActor(jobPeds[i].npc)
    end
    jobPeds = {}
end

RegisterCallback('getPeds', function()
    return jobPeds
end)

RegisterCallback('HasMoney', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return { success = false }
    end

    if Player.PlayerData.job.name ~= Config.Job then
        return { success = false, reason = 'invalid_job' }
    end

    local existing = getSession(source)
    if existing and isValidActor(existing.stand) then
        return { success = true, stand = existing.stand, alreadyWorking = true }
    end

    if not Player.RemoveMoney('bank', Config.StandDeposit, 'hot dog deposit') then
        Bail[getPlayerKey(source)] = false
        return { success = false, reason = 'no_money' }
    end

    local stand = spawnStand(source)
    if not stand then
        Player.AddMoney('bank', Config.StandDeposit, 'hot dog deposit refund')
        Bail[getPlayerKey(source)] = false
        return { success = false, reason = 'stand_spawn_failed' }
    end

    Bail[getPlayerKey(source)] = true
    return { success = true, stand = stand }
end)

RegisterCallback('BringBack', function(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return false
    end

    local key = getPlayerKey(source)
    if not Bail[key] or not getSession(source) then
        return false
    end

    clearStand(source)
    Bail[key] = nil
    Player.AddMoney('bank', Config.StandDeposit, 'hot dog deposit')
    return true
end)

RegisterServerEvent('qb-hotdogjob:server:TakeStand', function(source)
    local session = getSession(source)
    local pawn = GetPlayerPawn(source)
    if not session or not pawn or not isValidActor(session.stand) then
        return
    end

    if not isNearStand(source, Config.Stand.InteractionDistance) then
        notify(source, Lang.t('error.too_far'), 'error')
        return
    end

    clearCustomer(source)

    local attached = AttachActorToActor(session.stand, pawn, Config.Stand.PushOffset, Config.Stand.PushRotation, 'root')
    if attached then
        session.isPushing = true
        TriggerClientEvent(source, 'qb-hotdogjob:client:StandPushState', true)
    end
end)

RegisterServerEvent('qb-hotdogjob:server:DropStand', function(source)
    local session = getSession(source)
    if not session or not isValidActor(session.stand) then
        return
    end

    if session.stand.GetAttachParentActor and session.stand:GetAttachParentActor() then
        DetachActor(session.stand, {
            Location = DetachmentRule.KeepWorld,
            Rotation = DetachmentRule.KeepWorld,
            Scale = DetachmentRule.KeepWorld,
        })
    end

    session.isPushing = false
    TriggerClientEvent(source, 'qb-hotdogjob:client:StandPushState', false)
end)

RegisterServerEvent('qb-hotdogjob:server:RequestCustomer', function(source)
    local session = getSession(source)
    if not session or not isValidActor(session.stand) then
        notify(source, Lang.t('error.no_stand'), 'error')
        TriggerClientEvent(source, 'qb-hotdogjob:client:ClearCustomer')
        return
    end

    if session.isPushing then
        notify(source, Lang.t('error.drop_stand_first'), 'error')
        TriggerClientEvent(source, 'qb-hotdogjob:client:ClearCustomer')
        return
    end

    if not isNearStand(source, Config.Customer.RequestDistance) then
        notify(source, Lang.t('error.too_far'), 'error')
        TriggerClientEvent(source, 'qb-hotdogjob:client:ClearCustomer')
        return
    end

    if isValidActor(session.customer) then
        return
    end

    HPawn(getCustomerSpawn(), Rotator(0, Config.Customer.SpawnHeading or 0, 0), function(npc)
        session = getSession(source)
        if not session then
            deleteActor(npc)
            return
        end

        if not npc then
            notify(source, Lang.t('error.customer_failed'), 'error')
            TriggerClientEvent(source, 'qb-hotdogjob:client:ClearCustomer')
            return
        end

        session.customer = npc
        session.customerArrived = false
        npc:SetCharacterName(Config.Customer.Name or 'Hotdog Customer')
        SetEntityInvincible(npc, true)
        TriggerClientEvent(source, 'qb-hotdogjob:client:CustomerSpawned', npc)
        beginCustomerMove(source)
    end, { CharacterName = Config.Customer.Name or 'Hotdog Customer', bShowNameplate = true })
end)

RegisterServerEvent('qb-hotdogjob:server:CancelCustomer', function(source)
    clearCustomer(source)
end)

RegisterServerEvent('qb-hotdogjob:server:Sell', function(source, coords, amount, price)
    local session = getSession(source)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player or not session or not isValidActor(session.customer) then
        return
    end

    if not isNearStand(source, Config.ServerDistance) then
        strike(source, 'hotdog job distance')
        return
    end

    amount = math.floor(tonumber(amount) or 0)
    price = math.floor(tonumber(price) or 0)
    if amount < 1 or amount > (Config.Customer.MaxHotdogsPerSale or 3) or price < 1 or price > getMaxHotdogPrice() then
        strike(source, 'hotdog job sale values')
        return
    end

    if coords and type(coords) == 'table' and coords.X then
        local customerCoords = GetEntityCoords(session.customer)
        if GetDistanceBetweenCoords(customerCoords, coords) > (Config.Customer.AcceptanceRadius or 150.0) + 150.0 then
            strike(source, 'hotdog job customer coords')
            return
        end
    end

    Player.AddMoney('cash', amount * price, 'sold hotdog')
    clearCustomer(source, false)
end)

RegisterServerEvent('qb-hotdogjob:server:UpdateReputation', function(source, quality)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end

    local repIncrease = ({ exotic = 3, rare = 2, common = 1 })[quality]
    if not repIncrease then
        return
    end

    local currentRep = Player.GetRep('hotdog')
    local cappedIncrease = math.min(repIncrease, math.max(Config.MaxReputation - currentRep, 0))
    if cappedIncrease > 0 then
        Player.AddRep('hotdog', cappedIncrease)
    end

    TriggerClientEvent(source, 'qb-hotdogjob:client:UpdateReputation', Player.PlayerData.metadata['rep'])
end)

RegisterCommand('removestand', Lang.t('info.command'), function(source)
    local pawn = GetPlayerPawn(source)
    if not pawn then
        return
    end

    local pawnCoords = GetEntityCoords(pawn)
    for _, session in pairs(activeStands) do
        if isValidActor(session.stand) and GetDistanceBetweenCoords(pawnCoords, GetEntityCoords(session.stand)) <= Config.AdminRemoveDistance then
            clearStand(session.source)
            notify(source, Lang.t('info.admin_removed'), 'primary')
            return
        end
    end
end, true)
