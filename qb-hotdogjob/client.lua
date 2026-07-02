local Lang = require('locales/en')

local my_webui = WebUI('qb-hotdogjob', 'qb-hotdogjob/html/ui.html')
local PlayerData = exports['qb-core']:GetPlayerData() or {}
local IsWorking = false
local StandObject = nil
local IsPushing = false
local IsUIActive = false
local PreparingFood = false
local uiTimer = nil
local depotMarkers = {}
local registeredTargets = {}

local SellingData = {
    Enabled = false,
    Target = nil,
    HasTarget = false,
    Hotdog = nil,
    Offer = nil,
}

local function Notify(text, notifyType, length)
    exports['qb-core']:Notify(text, notifyType or 'primary', length)
end

local function addRegisteredTarget(entity, options, distance)
    if not entity then
        return
    end

    exports['qb-target']:AddTargetEntity(entity, {
        options = options,
        distance = distance or Config.TargetDistance,
    })
    registeredTargets[#registeredTargets + 1] = entity
end

local function removeRegisteredTarget(entity)
    if not entity then
        return
    end

    exports['qb-target']:RemoveTargetEntity(entity)
    for i = #registeredTargets, 1, -1 do
        if registeredTargets[i] == entity then
            table.remove(registeredTargets, i)
        end
    end
end

local function clearRegisteredTargets()
    for _, entity in ipairs(registeredTargets) do
        exports['qb-target']:RemoveTargetEntity(entity)
    end
    registeredTargets = {}
end

local function addMapMarker(coords, marker)
    local markerId = exports['qb-hud']:AddMarker(coords, {
        title = marker.label,
        description = marker.description or '',
        icon = marker.blipIcon or 'fast-food',
        color = marker.blipColor,
        markerType = marker.markerType or 'Store',
    })

    if markerId then
        depotMarkers[#depotMarkers + 1] = markerId
    end
end

local function clearDepotMarkers()
    for _, id in ipairs(depotMarkers) do
        exports['qb-hud']:RemoveMarker(id)
    end
    depotMarkers = {}
end

local function UpdateBlip()
    clearDepotMarkers()

    if PlayerData.job and PlayerData.job.name == Config.Job and Config.Locations.take.showBlip then
        addMapMarker(Config.Locations.take.coords, Config.Locations.take)
    end
end

local function GetAvailableHotdog()
    local availableHotdogs = {}
    for k, v in pairs(Config.Stock) do
        if v.Current > 0 then
            availableHotdogs[#availableHotdogs + 1] = {
                key = k,
                value = v,
            }
        end
    end

    if next(availableHotdogs) == nil then
        return nil
    end

    return availableHotdogs[math.random(1, #availableHotdogs)].key
end

local function UpdateLevel()
    local rep = PlayerData.metadata and PlayerData.metadata.rep or {}
    local myRep = tonumber(rep.hotdog) or 0

    if myRep >= 1 and myRep < 50 then
        Config.MyLevel = 1
    elseif myRep >= 50 and myRep < 100 then
        Config.MyLevel = 2
    elseif myRep >= 100 and myRep < 200 then
        Config.MyLevel = 3
    elseif myRep >= 200 then
        Config.MyLevel = 4
    else
        Config.MyLevel = 1
    end

    return {
        lvl = Config.MyLevel,
        rep = myRep,
    }
end

local function SendStockUpdate()
    if not my_webui then
        return
    end

    my_webui:SendEvent('UpdateUI', {
        IsActive = IsUIActive,
        Stock = Config.Stock,
        Level = UpdateLevel(),
    })
end

local function UpdateUI()
    IsUIActive = true
    SendStockUpdate()

    if uiTimer then
        Timer.ClearInterval(uiTimer)
    end

    uiTimer = Timer.SetInterval(function()
        if not IsUIActive then
            Timer.ClearInterval(uiTimer)
            uiTimer = nil
            SendStockUpdate()
            return
        end

        SendStockUpdate()
    end, 1000)
end

local function HideUI()
    IsUIActive = false
    SendStockUpdate()

    if uiTimer then
        Timer.ClearInterval(uiTimer)
        uiTimer = nil
    end
end

local function ResetStock()
    for _, v in pairs(Config.Stock) do
        v.Current = 0
    end
end

local function ClearCustomer()
    if SellingData.Target then
        removeRegisteredTarget(SellingData.Target)
    end

    SellingData.Target = nil
    SellingData.HasTarget = false
    SellingData.Hotdog = nil
    SellingData.Offer = nil
end

local function CancelSelling()
    SellingData.Enabled = false
    ClearCustomer()
    TriggerServerEvent('qb-hotdogjob:server:CancelCustomer')
end

local function CleanupWorkState()
    CancelSelling()

    if StandObject then
        removeRegisteredTarget(StandObject)
    end

    IsWorking = false
    StandObject = nil
    IsPushing = false
    PreparingFood = false
    HideUI()
    ResetStock()
    exports['qb-core']:HideText()
end

local function IsNearStand(distance)
    if not StandObject then
        return false
    end

    local pawn = GetPlayerPawn()
    if not pawn then
        return false
    end

    return GetDistanceBetweenActors(pawn, StandObject) <= (distance or Config.Stand.InteractionDistance)
end

local function TakeHotdogStand()
    if not IsWorking or not StandObject then
        return
    end

    if SellingData.Enabled then
        CancelSelling()
    end

    TriggerServerEvent('qb-hotdogjob:server:TakeStand')
end

local function LetKraamLose()
    if not IsPushing then
        return
    end

    TriggerServerEvent('qb-hotdogjob:server:DropStand')
end

local function FinishMinigame(faults)
    local Quality = 'common'
    if faults == 0 then
        Quality = 'exotic'
    elseif faults == 1 then
        Quality = 'rare'
    end

    if Config.Stock[Quality].Current + 1 <= Config.Stock[Quality].Max[Config.MyLevel] then
        TriggerServerEvent('qb-hotdogjob:server:UpdateReputation', Quality)
        if Config.MyLevel == 1 then
            Notify(Lang.t('success.made_hotdog', { value = Config.Stock[Quality].Label }), 'success')
            Config.Stock[Quality].Current = Config.Stock[Quality].Current + 1
        else
            local Luck = math.random(1, 2)
            local LuckyNumber = math.random(1, 2)
            local LuckyAmount = math.random(1, Config.MyLevel)
            if Luck == LuckyNumber then
                Notify(Lang.t('success.made_luck_hotdog', { value = LuckyAmount, value2 = Config.Stock[Quality].Label }), 'success')
                Config.Stock[Quality].Current = Config.Stock[Quality].Current + LuckyAmount
            else
                Notify(Lang.t('success.made_hotdog', { value = Config.Stock[Quality].Label }), 'success')
                Config.Stock[Quality].Current = Config.Stock[Quality].Current + 1
            end
        end
    else
        Notify(Lang.t('error.no_more', { value = Config.Stock[Quality].Label }), 'error')
    end

    PreparingFood = false
    SendStockUpdate()
end

local function StartHotdogMinigame()
    if PreparingFood or IsPushing or not IsWorking or not IsNearStand(Config.Stand.InteractionDistance) then
        return
    end

    PreparingFood = true
    local result = exports['qb-minigames']:KeyMinigame(10)
    if result.quit then
        PreparingFood = false
        return
    end

    FinishMinigame(result.faults)
end

local function CreateOffer()
    local hotdog = GetAvailableHotdog()
    if not hotdog then
        return nil
    end

    local stock = Config.Stock[hotdog]
    local hotdogsForSale = 1
    if stock.Current > 1 then
        if stock.Current >= Config.Customer.MaxHotdogsPerSale then
            hotdogsForSale = math.random(1, Config.Customer.MaxHotdogsPerSale)
        else
            hotdogsForSale = math.random(1, stock.Current)
        end
    end

    local priceRange = stock.Price[Config.MyLevel]
    return {
        hotdog = hotdog,
        amount = hotdogsForSale,
        price = math.random(priceRange.min, priceRange.max),
    }
end

local function RequestCustomer()
    if not SellingData.Enabled or SellingData.HasTarget then
        return
    end

    if not GetAvailableHotdog() then
        SellingData.Enabled = false
        Notify(Lang.t('error.no_dogs'), 'error')
        return
    end

    SellingData.HasTarget = true
    TriggerServerEvent('qb-hotdogjob:server:RequestCustomer')
end

local function AddCustomerTarget(customer, offer)
    addRegisteredTarget(customer, {
        {
            icon = 'hand-coins',
            label = Lang.t('info.sell_dogs_target', { value = offer.amount, value2 = offer.amount * offer.price }),
            type = 'client',
            event = 'qb-hotdogjob:client:SellToCustomer',
        },
        {
            icon = 'x',
            label = Lang.t('info.decline_offer'),
            type = 'client',
            event = 'qb-hotdogjob:client:DeclineCustomer',
        },
    }, Config.Customer.TargetDistance)
end

local function CompleteCustomerSale()
    local offer = SellingData.Offer
    local customer = SellingData.Target
    if not offer or not customer or not Config.Stock[offer.hotdog] then
        ClearCustomer()
        return
    end

    if Config.Stock[offer.hotdog].Current < offer.amount then
        Notify(Lang.t('error.no_dogs'), 'error')
        ClearCustomer()
        return
    end

    Notify(Lang.t('success.sold_hotdogs', { value = offer.amount, value2 = offer.amount * offer.price }), 'success')
    TriggerServerEvent('qb-hotdogjob:server:Sell', GetEntityCoords(customer), offer.amount, offer.price)
    Config.Stock[offer.hotdog].Current = Config.Stock[offer.hotdog].Current - offer.amount
    ClearCustomer()
    SendStockUpdate()

    if SellingData.Enabled then
        Timer.SetTimeout(function()
            RequestCustomer()
        end, Config.Customer.NextDelayMs or 2500)
    end
end

local function DeclineCustomer()
    Notify(Lang.t('error.cust_refused'), 'error')
    ClearCustomer()
    TriggerServerEvent('qb-hotdogjob:server:CancelCustomer')

    if SellingData.Enabled then
        Timer.SetTimeout(function()
            RequestCustomer()
        end, Config.Customer.NextDelayMs or 2500)
    end
end

local function ToggleSell()
    if not StandObject then
        Notify(Lang.t('error.no_stand'), 'error')
        return
    end

    if IsPushing then
        Notify(Lang.t('error.drop_stand_first'), 'error')
        return
    end

    if not IsNearStand(Config.Customer.RequestDistance) then
        Notify(Lang.t('error.too_far'), 'error')
        return
    end

    if not SellingData.Enabled then
        SellingData.Enabled = true
        RequestCustomer()
    else
        CancelSelling()
    end
end

local function RegisterStandTarget(stand)
    if not stand then
        return
    end

    addRegisteredTarget(stand, {
        {
            icon = 'hand',
            label = Lang.t('info.grab'),
            type = 'client',
            event = 'qb-hotdogjob:client:TogglePushStand',
            canInteract = function()
                return IsWorking
            end,
        },
        {
            icon = 'hotdog',
            label = Lang.t('info.prepare'),
            type = 'client',
            event = 'qb-hotdogjob:client:PrepareHotdog',
            canInteract = function()
                return IsWorking and not IsPushing
            end,
        },
        {
            icon = 'hand-coins',
            label = Lang.t('info.toggle_sell'),
            type = 'client',
            event = 'qb-hotdogjob:client:ToggleSell',
            canInteract = function()
                return IsWorking and not IsPushing
            end,
        },
        {
            icon = 'circle-check',
            label = Lang.t('info.stop_work'),
            type = 'client',
            event = 'qb-hotdogjob:client:StopWorking',
            canInteract = function()
                return IsWorking
            end,
        },
    }, Config.TargetDistance)
end

local function StartWorking()
    TriggerCallback('HasMoney', function(result)
        local success = result == true or (type(result) == 'table' and result.success)
        if not success then
            local reason = type(result) == 'table' and result.reason or 'no_money'
            if reason == 'invalid_job' then
                Notify(Lang.t('error.invalid_job'), 'error')
            elseif reason == 'stand_spawn_failed' then
                Notify(Lang.t('error.stand_spawn_failed'), 'error')
            else
                Notify(Lang.t('error.no_money'), 'error')
            end
            return
        end

        StandObject = type(result) == 'table' and result.stand or StandObject
        if not StandObject then
            Notify(Lang.t('error.no_stand_found'), 'error')
            return
        end

        IsWorking = true
        IsPushing = false
        RegisterStandTarget(StandObject)
        UpdateUI()

        if not result.alreadyWorking then
            Notify(Lang.t('success.deposit', { deposit = Config.StandDeposit }), 'success')
        end
    end)
end

local function StopWorking()
    TriggerCallback('BringBack', function(DidBail)
        if DidBail then
            CleanupWorkState()
            Notify(Lang.t('success.deposit_returned', { deposit = Config.StandDeposit }), 'success')
        else
            CleanupWorkState()
            Notify(Lang.t('error.deposit_notreturned'), 'error')
        end
    end)
end

local function setupPeds()
    TriggerCallback('getPeds', function(jobPeds)
        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc
            local options = {
                {
                    type = 'server',
                    event = 'QBCore:ToggleDuty',
                    label = Lang.t('target.toggle_duty'),
                    icon = 'clipboard',
                    job = Config.Job,
                },
                {
                    type = 'client',
                    event = 'qb-hotdogjob:client:ToggleWork',
                    label = Lang.t('target.toggle_work'),
                    icon = 'bean',
                    job = Config.Job,
                },
            }
            addRegisteredTarget(ped, options)
        end
    end)
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = exports['qb-core']:GetPlayerData() or {}
    setupPeds()
    UpdateBlip()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    CleanupWorkState()
    clearRegisteredTargets()
    clearDepotMarkers()
    PlayerData = {}
end)

RegisterClientEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    if key == 'job' then
        PlayerData.job = val
        UpdateBlip()
    elseif key == 'metadata' then
        PlayerData.metadata = val
        UpdateLevel()
        SendStockUpdate()
    elseif key == 'all' then
        PlayerData = val or {}
        UpdateBlip()
        UpdateLevel()
        SendStockUpdate()
    elseif key then
        PlayerData[key] = val
    end
end)

RegisterClientEvent('qb-hotdogjob:client:UpdateReputation', function(JobRep)
    PlayerData.metadata = PlayerData.metadata or {}
    PlayerData.metadata.rep = JobRep
    UpdateLevel()
    SendStockUpdate()
end)

RegisterClientEvent('qb-hotdogjob:client:ToggleWork', function()
    if IsWorking then
        StopWorking()
    else
        StartWorking()
    end
end)

RegisterClientEvent('qb-hotdogjob:client:StopWorking', StopWorking)
RegisterClientEvent('qb-hotdogjob:client:PrepareHotdog', StartHotdogMinigame)
RegisterClientEvent('qb-hotdogjob:client:ToggleSell', ToggleSell)

RegisterClientEvent('qb-hotdogjob:client:TogglePushStand', function()
    if IsPushing then
        LetKraamLose()
    else
        TakeHotdogStand()
    end
end)

RegisterClientEvent('qb-hotdogjob:client:StandPushState', function(isPushing)
    IsPushing = isPushing == true
    if IsPushing then
        exports['qb-core']:DrawText(Lang.t('info.drop_stall'), 'left')
    else
        exports['qb-core']:HideText()
    end
end)

RegisterClientEvent('qb-hotdogjob:client:CustomerSpawned', function(customer)
    SellingData.Target = customer
end)

RegisterClientEvent('qb-hotdogjob:client:CustomerArrived', function(customer)
    if not SellingData.Enabled then
        TriggerServerEvent('qb-hotdogjob:server:CancelCustomer')
        ClearCustomer()
        return
    end

    SellingData.Target = customer
    local offer = CreateOffer()
    if not offer then
        Notify(Lang.t('error.no_dogs'), 'error')
        CancelSelling()
        return
    end

    SellingData.Hotdog = offer.hotdog
    SellingData.Offer = offer
    SellingData.HasTarget = true
    AddCustomerTarget(customer, offer)
    Notify(Lang.t('info.customer_ready'), 'primary')
end)

RegisterClientEvent('qb-hotdogjob:client:ClearCustomer', ClearCustomer)
RegisterClientEvent('qb-hotdogjob:client:SellToCustomer', CompleteCustomerSale)
RegisterClientEvent('qb-hotdogjob:client:DeclineCustomer', DeclineCustomer)

RegisterClientEvent('qb-hotdogjob:client:StandRemoved', function()
    CleanupWorkState()
end)

Input.BindKey('K', function()
    if IsPushing then
        LetKraamLose()
    end
end)

Input.BindKey('E', function()
    if IsWorking and not IsPushing and IsNearStand(Config.Stand.InteractionDistance) then
        StartHotdogMinigame()
    end
end)

function onShutdown()
    CleanupWorkState()
    clearRegisteredTargets()
    clearDepotMarkers()

    if my_webui then
        my_webui:Destroy()
        my_webui = nil
    end
end
