local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items') or {}

local CurrentStatusList = {}
local Casings = {}
local Blooddrops = {}
local Fingerprints = {}
local EvidenceZones = {
    casing = {},
    blood = {},
    fingerprint = {},
}
local evidenceStatusTimerStarted = false
local CurrentWeapon = nil
local WeaponFireTagName = 'Event.Movement.WeaponFire'
local WeaponFireTag = nil
local WeaponFireCallback = nil
local WeaponFirePawn = nil
local WeaponFireListenerRequested = false
local LastCasingDropAt = 0

local StatusList = {
    ['fight'] = Lang.t('evidence.red_hands'),
    ['widepupils'] = Lang.t('evidence.wide_pupils'),
    ['redeyes'] = Lang.t('evidence.red_eyes'),
    ['weedsmell'] = Lang.t('evidence.weed_smell'),
    ['gunpowder'] = Lang.t('evidence.gunpowder'),
    ['chemicals'] = Lang.t('evidence.chemicals'),
    ['heavybreath'] = Lang.t('evidence.heavy_breathing'),
    ['sweat'] = Lang.t('evidence.sweat'),
    ['handbleed'] = Lang.t('evidence.handbleed'),
    ['confused'] = Lang.t('evidence.confused'),
    ['alcohol'] = Lang.t('evidence.alcohol'),
    ['heavyalcohol'] = Lang.t('evidence.heavy_alcohol'),
    ['agitated'] = Lang.t('evidence.agitated'),
}

local function coordsToVector(coords)
    return Vector(coords.X or coords.x, coords.Y or coords.y, coords.Z or coords.z)
end

local function DnaHash(s)
    return string.gsub(tostring(s or ''), '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
end

local function removeEvidenceZone(kind, id)
    local zoneName = EvidenceZones[kind][id]
    if zoneName then
        exports['qb-target']:RemoveZone(zoneName)
        EvidenceZones[kind][id] = nil
    end
end

local function getEvidenceConfig(key, default)
    local evidenceConfig = Config.Evidence or {}
    if evidenceConfig[key] == nil then
        return default
    end
    return evidenceConfig[key]
end

local function addEvidenceZone(kind, id, coords, label, eventName, icon)
    removeEvidenceZone(kind, id)
    local zoneName = ('police_evidence_%s_%s'):format(kind, id)
    EvidenceZones[kind][id] = zoneName
    exports['qb-target']:AddSphereZone(zoneName, coordsToVector(coords), getEvidenceConfig('ZoneRadius', 100), {
        distance = getEvidenceConfig('TargetDistance', 300),
        debug = getEvidenceConfig('DebugZones', true),
    }, {
        {
            type = 'client',
            event = eventName,
            icon = icon,
            label = label,
            evidenceId = id,
            jobType = 'leo',
        },
    })
end

local function getStreetLabel(_)
    -- TODO(helix): Street-name lookup is not available yet.
    return 'Unknown'
end

local function getLocalPlayerPawn()
    if HPlayer then
        return GetPlayerPawn(HPlayer)
    end
    return GetPlayerPawn()
end

local function getWeaponItem(weapon)
    if not weapon then
        return nil
    end

    local weaponName = tostring(weapon)
    local itemInfo = sharedItems[weaponName] or sharedItems[string.lower(weaponName)]
    if itemInfo and itemInfo.type == 'weapon' then
        return itemInfo
    end

    local loweredWeaponName = string.lower(weaponName)
    for _, sharedItem in pairs(sharedItems) do
        if sharedItem.type == 'weapon' and sharedItem.asset_name and string.lower(sharedItem.asset_name) == loweredWeaponName then
            return sharedItem
        end
    end

    return nil
end

local function getCurrentWeaponName()
    if not CurrentWeapon or CurrentWeapon == '' then
        return 'unknown_weapon'
    end

    local weaponInfo = getWeaponItem(CurrentWeapon)
    if weaponInfo then
        return weaponInfo.name
    end

    return tostring(CurrentWeapon)
end

local function shouldCreateCasingEvidence()
    local cooldown = tonumber(getEvidenceConfig('CasingDropCooldown', 2)) or 0
    local now = os.time()
    if cooldown > 0 and LastCasingDropAt > 0 and (now - LastCasingDropAt) < cooldown then
        return false
    end

    local chance = tonumber(getEvidenceConfig('CasingDropChance', 35)) or 100
    if chance <= 0 then
        return false
    end
    if chance < 100 and math.random(1, 100) > chance then
        return false
    end

    LastCasingDropAt = now
    return true
end

local function handleWeaponFire(ownerActor)
    local pawn = ownerActor or getLocalPlayerPawn()
    if not pawn then
        return
    end

    if shouldCreateCasingEvidence() then
        local coords = GetEntityCoords(pawn)
        if coords then
            TriggerServerEvent('qb-policejob:server:CreateCasing', getCurrentWeaponName(), coords)
        end
    end

    local gunpowderStatus = CurrentStatusList['gunpowder']
    if not gunpowderStatus or (gunpowderStatus.time or 0) < 20 then
        TriggerLocalClientEvent('qb-policejob:client:SetStatus', 'gunpowder', 300)
    end
end

local function clearWeaponFireListener()
    if WeaponFirePawn and WeaponFireTag and WeaponFireCallback and UE and UE.UHAbilitySystemGlobals then
        UE.UHAbilitySystemGlobals.UnregisterDynamicGameplayTagEventForActor(WeaponFirePawn, WeaponFireTag, WeaponFireCallback)
    end

    WeaponFirePawn = nil
    WeaponFireTag = nil
    WeaponFireCallback = nil
end

local function registerWeaponFireListener()
    WeaponFireListenerRequested = true
    clearWeaponFireListener()

    if not UE or not UE.FGameplayTag or not UE.UHAbilitySystemGlobals then
        -- TODO(helix): Re-enable weapon-fire evidence when the gameplay tag bridge is available.
        return
    end

    local pawn = getLocalPlayerPawn()
    if not pawn then
        Timer.SetTimeout(function()
            if WeaponFireListenerRequested then
                registerWeaponFireListener()
            end
        end, 1000)
        return
    end

    WeaponFireTag = UE.FGameplayTag()
    WeaponFireTag.TagName = WeaponFireTagName
    WeaponFireCallback = {
        HWorld,
        function(_, ownerActor, tagAdded)
            if tagAdded then
                handleWeaponFire(ownerActor)
            end
        end,
    }

    local registered = UE.UHAbilitySystemGlobals.RegisterDynamicGameplayTagEventForActor(pawn, WeaponFireTag, WeaponFireCallback)
    if registered then
        WeaponFirePawn = pawn
    else
        clearWeaponFireListener()
    end
end

local function unregisterWeaponFireListener()
    WeaponFireListenerRequested = false
    clearWeaponFireListener()
end

RegisterClientEvent('HEvent:WeaponEquipped', function(_, weaponName)
    CurrentWeapon = weaponName
end)

RegisterClientEvent('HEvent:WeaponUnequipped', function()
    CurrentWeapon = nil
end)

RegisterClientEvent('qb-policejob:client:SetStatus', function(statusId, time)
    if time > 0 and StatusList[statusId] then
        if (CurrentStatusList == nil or CurrentStatusList[statusId] == nil) or (CurrentStatusList[statusId] and CurrentStatusList[statusId].time < 20) then
            CurrentStatusList[statusId] = {
                text = StatusList[statusId],
                time = time,
            }
            exports['qb-core']:Notify(CurrentStatusList[statusId].text, 'error')
        end
    elseif StatusList[statusId] then
        CurrentStatusList[statusId] = nil
    end
    TriggerServerEvent('qb-policejob:server:UpdateStatus', CurrentStatusList)
end)

RegisterClientEvent('qb-policejob:client:AddBlooddrop', function(bloodId, citizenid, bloodtype, coords)
    Blooddrops[bloodId] = {
        citizenid = citizenid,
        bloodtype = bloodtype,
        coords = {
            x = coords.x or coords.X,
            y = coords.y or coords.Y,
            z = (coords.z or coords.Z) - 0.9,
        },
    }
    addEvidenceZone('blood', bloodId, Blooddrops[bloodId].coords, Lang.t('info.blood'), 'qb-policejob:client:CollectBlooddrop', 'droplet')
end)

RegisterClientEvent('qb-policejob:client:RemoveBlooddrop', function(bloodId)
    Blooddrops[bloodId] = nil
    removeEvidenceZone('blood', bloodId)
end)

RegisterClientEvent('qb-policejob:client:AddFingerPrint', function(fingerId, fingerprint, coords)
    Fingerprints[fingerId] = {
        fingerprint = fingerprint,
        coords = {
            x = coords.x or coords.X,
            y = coords.y or coords.Y,
            z = (coords.z or coords.Z) - 0.9,
        },
    }
    addEvidenceZone('fingerprint', fingerId, Fingerprints[fingerId].coords, Lang.t('info.fingerprint'), 'qb-policejob:client:CollectFingerprint', 'fingerprint')
end)

RegisterClientEvent('qb-policejob:client:RemoveFingerprint', function(fingerId)
    Fingerprints[fingerId] = nil
    removeEvidenceZone('fingerprint', fingerId)
end)

RegisterClientEvent('qb-policejob:client:ClearBlooddropsInArea', function()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end

    local pos = GetEntityCoords(pawn)
    local blooddropList = {}
    for bloodId, blooddrop in pairs(Blooddrops) do
        if GetDistanceBetweenCoords(pos, coordsToVector(blooddrop.coords)) < 1000.0 then
            blooddropList[#blooddropList + 1] = bloodId
        end
    end

    TriggerServerEvent('qb-policejob:server:ClearBlooddrops', blooddropList)
    exports['qb-core']:Notify(Lang.t('success.blood_clear'), 'success')
end)

RegisterClientEvent('qb-policejob:client:AddCasing', function(casingId, weapon, coords, serie)
    Casings[casingId] = {
        type = weapon,
        serie = serie or Lang.t('evidence.serial_not_visible'),
        coords = {
            x = coords.x or coords.X,
            y = coords.y or coords.Y,
            z = (coords.z or coords.Z) - 0.9,
        },
    }
    addEvidenceZone('casing', casingId, Casings[casingId].coords, Lang.t('info.casing'), 'qb-policejob:client:CollectCasing', 'shell')
end)

RegisterClientEvent('qb-policejob:client:RemoveCasing', function(casingId)
    Casings[casingId] = nil
    removeEvidenceZone('casing', casingId)
end)

RegisterClientEvent('qb-policejob:client:ClearCasingsInArea', function()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end

    local pos = GetEntityCoords(pawn)
    local casingList = {}
    for casingId, casing in pairs(Casings) do
        if GetDistanceBetweenCoords(pos, coordsToVector(casing.coords)) < 1000.0 then
            casingList[#casingList + 1] = casingId
        end
    end

    TriggerServerEvent('qb-policejob:server:ClearCasings', casingList)
    exports['qb-core']:Notify(Lang.t('success.bullet_casing_removed'), 'success')
end)

RegisterClientEvent('qb-policejob:client:CollectCasing', function(data)
    local casingId = data and data.evidenceId
    local casing = casingId and Casings[casingId]
    if not casing then
        return
    end

    local weaponInfo = getWeaponItem(casing.type) or {}
    local ammoType = weaponInfo.ammo_type or casing.type
    local info = {
        label = Lang.t('info.casing'),
        type = 'casing',
        street = getStreetLabel(casing.coords),
        ammolabel = Config.AmmoLabels[ammoType] or tostring(ammoType),
        weapon = casing.type,
        serie = casing.serie,
    }
    TriggerServerEvent('qb-policejob:server:AddCasingToInventory', casingId, info)
end)

RegisterClientEvent('qb-policejob:client:CollectBlooddrop', function(data)
    local bloodId = data and data.evidenceId
    local blooddrop = bloodId and Blooddrops[bloodId]
    if not blooddrop then
        return
    end

    local info = {
        label = Lang.t('info.blood'),
        type = 'blood',
        street = getStreetLabel(blooddrop.coords),
        dnalabel = DnaHash(blooddrop.citizenid),
        bloodtype = blooddrop.bloodtype,
    }
    TriggerServerEvent('qb-policejob:server:AddBlooddropToInventory', bloodId, info)
end)

RegisterClientEvent('qb-policejob:client:CollectFingerprint', function(data)
    local fingerId = data and data.evidenceId
    local fingerprint = fingerId and Fingerprints[fingerId]
    if not fingerprint then
        return
    end

    local info = {
        label = Lang.t('info.fingerprint'),
        type = 'fingerprint',
        street = getStreetLabel(fingerprint.coords),
        fingerprint = fingerprint.fingerprint,
    }
    TriggerServerEvent('qb-policejob:server:AddFingerprintToInventory', fingerId, info)
end)

local function ensureEvidenceStatusTimer()
    if evidenceStatusTimerStarted then
        return
    end
    evidenceStatusTimerStarted = true

    Timer.SetInterval(function()
        if CurrentStatusList and next(CurrentStatusList) then
            for k in pairs(CurrentStatusList) do
                CurrentStatusList[k].time = math.max((CurrentStatusList[k].time or 0) - 10, 0)
            end
            TriggerServerEvent('qb-policejob:server:UpdateStatus', CurrentStatusList)
        end
    end, 10000)
end

PoliceLoadedHandlers[#PoliceLoadedHandlers + 1] = function()
    ensureEvidenceStatusTimer()
    registerWeaponFireListener()
end

PoliceUnloadHandlers[#PoliceUnloadHandlers + 1] = function()
    CurrentStatusList = {}
    unregisterWeaponFireListener()
end

function onShutdown()
    TriggerLocalClientEvent('qb-policejob:client:CloseCamera')
    if PoliceMugshotTeardown then PoliceMugshotTeardown() end -- client/mugshot.lua
    unregisterWeaponFireListener()
    for kind, zones in pairs(EvidenceZones) do
        for id in pairs(zones) do
            removeEvidenceZone(kind, id)
        end
    end
    if PoliceJobUI then
        PoliceJobUI:Destroy()
        PoliceJobUI = nil
    end
end
