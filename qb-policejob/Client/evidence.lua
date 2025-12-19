local CurrentStatusList = {}
local Casings = {}
local CurrentCasing = nil
local Blooddrops = {}
local CurrentBlooddrop = nil
local Fingerprints = {}
local CurrentFingerprint = 0
local shotAmount = 0

local StatusList = {
    ['fight'] = Lang:t('evidence.red_hands'),
    ['widepupils'] = Lang:t('evidence.wide_pupils'),
    ['redeyes'] = Lang:t('evidence.red_eyes'),
    ['weedsmell'] = Lang:t('evidence.weed_smell'),
    ['gunpowder'] = Lang:t('evidence.gunpowder'),
    ['chemicals'] = Lang:t('evidence.chemicals'),
    ['heavybreath'] = Lang:t('evidence.heavy_breathing'),
    ['sweat'] = Lang:t('evidence.sweat'),
    ['handbleed'] = Lang:t('evidence.handbleed'),
    ['confused'] = Lang:t('evidence.confused'),
    ['alcohol'] = Lang:t('evidence.alcohol'),
    ['heavyalcohol'] = Lang:t('evidence.heavy_alcohol'),
    ['agitated'] = Lang:t('evidence.agitated')
}

--[[@TODO:
* Casings
* Blooddrop
* Fingerprint
]]

-- Functions

local function dropCasing(weapon, ped)
    local placing_position = ped:GetActorForwardVector() * 100
    local coords = GetEntityCoords(ped) + placing_position
    TriggerServerEvent('qb-policejob:server:CreateCasing', weapon, coords)
end
--[[
-- Events

Events.Subscribe('evidence:client:SetStatus', function(statusId, time)
    if time > 0 and StatusList[statusId] then
        if (CurrentStatusList == nil or CurrentStatusList[statusId] == nil) or
            (CurrentStatusList[statusId] and CurrentStatusList[statusId].time < 20) then
            CurrentStatusList[statusId] = {
                text = StatusList[statusId],
                time = time
            }
            QBCore.Functions.Notify(CurrentStatusList[statusId].text, 'error')
        end
    elseif StatusList[statusId] then
        CurrentStatusList[statusId] = nil
    end
    Events.CallRemote('evidence:server:UpdateStatus', CurrentStatusList)
end)]]

RegisterClientEvent('qb-policejob:client:SyncNewCasing', function(Casing)
    Casings[Casing.id] = {
        type = Casing.weapon,
        serialNumber = Casing.serialNumber and Casing.serialNumber or Lang:t('evidence.serial_not_visible'),
        coords = {
            x = Casing.coords.X,
            y = Casing.coords.Y,
            z = Casing.coords.Z
        }
    }
end)

RegisterClientEvent('qb-policejob:client:SyncNewBlooddrop', function(BloodDrop)
    Blooddrops[BloodDrop.id] = {
        citizenId = BloodDrop.citizenId,
        bloodType = BloodDrop.bloodType,
        coords = {
            x = BloodDrop.coords.X,
            y = BloodDrop.coords.Y,
            z = BloodDrop.coords.Z
        }
    }
end)

-- Handlers
--[[
HCharacter.Subscribe('Fire', function(self, weapon)
    local player = Client.GetLocalPlayer()
    local ped = player:GetControlledCharacter()
    if self ~= ped then return end
    if shotAmount > 5 and (CurrentStatusList == nil or CurrentStatusList['gunpowder'] == nil) then
        if math.random(1, 10) <= 7 then
            Events.Call('evidence:client:SetStatus', 'gunpowder', 200)
        end
    end
    dropCasing(weapon, ped)
end)]]

---@TODO Awaiting support for weapon fire event, need more info on data passed
RegisterClientEvent('HEvent:ShotFired', function()
    local ped = GetPlayerPawn(HPlayer)
    if not ped then return end
    --@TODO Maybe need to check ped to ensure it's the local player
    if shotAmount > 5 and (CurrentStatusList == nil or CurrentStatusList['gunpowder'] == nil) then
        if math.random(1, 10) <= 7 then
            TriggerLocalClientEvent('evidence:client:SetStatus', 'gunpowder', 200)
        end
    end
    dropCasing(weapon, ped)
end)
--[[
Input.Subscribe('MouseDown', function(key_name)
    if key_name == 'RightMouseButton' then
        local player = Client.GetLocalPlayer()
        local ped = player:GetControlledCharacter()
        if not ped then return end
        local ped_coords = ped:GetLocation()
        local has_flashlight = ped:GetValue('holding_flashlight', false)
        if not has_flashlight then return end
        local flashlight = ped:GetValue('flashlight')
        if not flashlight then return end
        local light = flashlight:GetValue('light')
        if not light then return end
        local light_active = light:GetValue('light_active', false)
        if not light_active then return end
        if next(Casings) then
            for k, v in pairs(Casings) do
                local dist = ped_coords:Distance(v.coords)
                if dist < 1.5 then
                    CurrentCasing = k
                end
            end
        end
        if next(Blooddrops) then
            for k, v in pairs(Blooddrops) do
                local dist = ped_coords:Distance(v.coords)
                if dist < 1.5 then
                    CurrentBlooddrop = k
                end
            end
        end
        if next(Fingerprints) then
            for k, v in pairs(Fingerprints) do
                local dist = ped_coords:Distance(v.coords)
                if dist < 1.5 then
                    CurrentFingerprint = k
                end
            end
        end
    end
end)

-- Timers

Timer.SetInterval(function()
    if Client.GetValue('isLoggedIn', false) then
        if CurrentStatusList and next(CurrentStatusList) then
            for k, _ in pairs(CurrentStatusList) do
                if CurrentStatusList[k].time > 0 then
                    CurrentStatusList[k].time = CurrentStatusList[k].time - 10
                else
                    CurrentStatusList[k].time = 0
                end
            end
            Events.CallRemote('evidence:server:UpdateStatus', CurrentStatusList)
        end
        if shotAmount > 0 then shotAmount = 0 end
    end
end, 10000)
 ]]