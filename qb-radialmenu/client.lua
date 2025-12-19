local my_webui = WebUI('qb-radialmenu', 'qb-radialmenu/html/index.html')
local inRadialMenu = false
local jobIndex = nil
local vehicleIndex = nil
local DynamicMenuItems = {}
local FinalMenuItems = {}
local PlayerData = {}

-- Function

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if not orig.canOpen or orig.canOpen() then
            local toRemove = {}
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                if type(orig_value) == 'table' then
                    if not orig_value.canOpen or orig_value.canOpen() then
                        copy[deepcopy(orig_key)] = deepcopy(orig_value)
                    else
                        toRemove[orig_key] = true
                    end
                else
                    copy[deepcopy(orig_key)] = deepcopy(orig_value)
                end
            end
            for i = 1, #toRemove do table.remove(copy, i) end
            if copy and next(copy) then setmetatable(copy, deepcopy(getmetatable(orig))) end
        end
    elseif orig_type ~= 'function' then
        copy = orig
    end
    return copy
end

local function selectOption(t, t2)
    for _, v in pairs(t) do
        if v.items then
            local found, hasAction, val = selectOption(v.items, t2)
            if found then return true, hasAction, val end
        else
            if v.id == t2.id and ((v.event and v.event == t2.event) or v.action) and (not v.canOpen or v.canOpen()) then
                return true, v
            end
        end
    end
    return false
end

local function AddOption(data, id)
    local menuID = id ~= nil and id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    DynamicMenuItems[menuID].res = _G.__PackageName
    return menuID
end

local function RemoveOption(id)
    DynamicMenuItems[id] = nil
end

local function SetupJobMenu()
    local JobInteractionCheck = PlayerData.job.name
    if PlayerData.job.type == 'leo' then JobInteractionCheck = 'police' end
    local JobMenu = {
        id = 'jobinteractions',
        title = 'Work',
        icon = 'briefcase',
        items = {}
    }
    if Config.JobInteractions[JobInteractionCheck] and next(Config.JobInteractions[JobInteractionCheck]) then
        JobMenu.items = Config.JobInteractions[JobInteractionCheck]
    end
    if #JobMenu.items == 0 then
        if jobIndex then
            RemoveOption(jobIndex)
            jobIndex = nil
        end
    else
        jobIndex = AddOption(JobMenu, jobIndex)
    end
end

local function SetupVehicleMenu()
    local VehicleMenu = {
        id = 'vehicle',
        title = 'Vehicle',
        icon = 'car',
        items = {}
    }

    -- local vehicle = GetVehiclePedIsIn(GetPlayerPawn())
    -- local wheels = vehicle:GetNumberOfWheels()
    -- local wheelsOnGround = vehicle:GetNumberOfDriveWheelsTouchingGround()
    -- if wheels == wheelsOnGround then

    -- local ped = PlayerPedId()
    -- local Vehicle = GetVehiclePedIsIn(ped) ~= 0 and GetVehiclePedIsIn(ped) or getNearestVeh()
    -- if Vehicle ~= 0 then
    --     VehicleMenu.items[#VehicleMenu.items + 1] = Config.VehicleDoors
    --     if Config.EnableExtraMenu then VehicleMenu.items[#VehicleMenu.items + 1] = Config.VehicleExtras end

    --     if not IsVehicleOnAllWheels(Vehicle) then
    --         VehicleMenu.items[#VehicleMenu.items + 1] = {
    --             id = 'vehicle-flip',
    --             title = 'Flip Vehicle',
    --             icon = 'car-burst',
    --             type = 'client',
    --             event = 'qb-radialmenu:flipVehicle',
    --             shouldClose = true
    --         }
    --     end

    --     if IsPedInAnyVehicle(ped) then
    --         local seatIndex = #VehicleMenu.items + 1
    --         VehicleMenu.items[seatIndex] = deepcopy(Config.VehicleSeats)

    --         local seatTable = {
    --             [1] = Lang:t('options.driver_seat'),
    --             [2] = Lang:t('options.passenger_seat'),
    --             [3] = Lang:t('options.rear_left_seat'),
    --             [4] = Lang:t('options.rear_right_seat'),
    --         }

    --         local AmountOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(Vehicle))
    --         for i = 1, AmountOfSeats do
    --             local newIndex = #VehicleMenu.items[seatIndex].items + 1
    --             VehicleMenu.items[seatIndex].items[newIndex] = {
    --                 id = i - 2,
    --                 title = seatTable[i] or Lang:t('options.other_seats'),
    --                 icon = 'caret-up',
    --                 type = 'client',
    --                 event = 'qb-radialmenu:client:ChangeSeat',
    --                 shouldClose = false,
    --             }
    --         end
    --     end
    -- end

    if #VehicleMenu.items == 0 then
        if vehicleIndex then
            RemoveOption(vehicleIndex)
            vehicleIndex = nil
        end
    else
        vehicleIndex = AddOption(VehicleMenu, vehicleIndex)
    end
end

local function SetupSubItems()
    SetupJobMenu()
    SetupVehicleMenu()
end

local function SetupRadialMenu()
    FinalMenuItems = {}
    -- if (IsDowned() and IsPoliceOrEMS()) then
    --     FinalMenuItems = {
    --         [1] = {
    --             id = 'emergencybutton2',
    --             title = Lang:t('options.emergency_button'),
    --             icon = 'circle-exclamation',
    --             type = 'client',
    --             event = 'police:client:SendPoliceEmergencyAlert',
    --             shouldClose = true,
    --         },
    --     }
    -- else
    SetupSubItems()
    FinalMenuItems = deepcopy(Config.MenuItems)
    for _, v in pairs(DynamicMenuItems) do
        FinalMenuItems[#FinalMenuItems + 1] = v
    end
    --end
end

local function openRadial()
    if not my_webui then return end
    if inRadialMenu then return end
    SetupRadialMenu()
    my_webui:SendEvent('ui', {
        radial = true,
        items = FinalMenuItems
    })
    inRadialMenu = true
    my_webui:SetInputMode(1) -- fire key released
end

local function closeRadial()
    if not my_webui then return end
    if not inRadialMenu then return end
    my_webui:SendEvent('ui', {
        radial = false,
        items = FinalMenuItems
    })
    inRadialMenu = false
    my_webui:SetInputMode(0)
end

-- Handlers

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    PlayerData = exports['qb-core']:GetPlayerData()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
end)

RegisterClientEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerData.gang = gang
end)

RegisterClientEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

-- UI Event Handlers

my_webui:RegisterEventHandler('selectItem', function(inData)
    local itemData = inData.itemData
    local found, data = selectOption(FinalMenuItems, itemData)
    if found and data then
        if data.type == 'client' then
            TriggerLocalClientEvent(data.event, data)
        elseif data.type == 'server' then
            TriggerServerEvent(data.event, data)
        end
    end
end)

my_webui:RegisterEventHandler('closeRadial', function()
    closeRadial()
end)

-- Inputs

Input.BindKey(Config.Keybind, function()
    if not isLoggedIn then return end
    if HPlayer:GetInputMode() == 1 and inRadialMenu then
        closeRadial()
    else
        openRadial()
    end
end, 'Pressed')

-- Input.BindKey(Config.Keybind, function()
--     if not isLoggedIn then return end
--     if not inRadialMenu then return end
--     closeRadial()
-- end, 'Released')
