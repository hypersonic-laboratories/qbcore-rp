QBCore.Players = {}
QBCore.Player = {}
QBCore.PlayersByCitizenId = {}

-- ─────────────────────────── Player class ───────────────────────────────────

local Player = {}
Player.__index = Player

function Player.new(PlayerData, Offline)
    local self = setmetatable({}, Player)
    self.PlayerData = PlayerData
    self.Offline = Offline or false
    return self
end

-- ─────────────────────────── module-private helpers ─────────────────────────

local function formatItems(inventory)
    local out = {}
    for _, item in pairs(inventory) do
        if item then
            local info = QBCore.Shared.Items[item.name:lower()]
            if info then
                out[item.slot] = {
                    name = info.name,
                    amount = item.amount,
                    info = item.info or {},
                    label = info.label,
                    description = info.description or '',
                    weight = info.weight,
                    type = info.type,
                    unique = info.unique,
                    useable = info.useable,
                    image = info.image,
                    shouldClose = info.shouldClose,
                    slot = item.slot,
                    combinable = info.combinable,
                }
            end
        end
    end
    return out
end

local function applyDefaults(playerData, defaults)
    for key, value in pairs(defaults) do
        if type(value) == 'function' then
            playerData[key] = playerData[key] or value()
        elseif type(value) == 'table' then
            playerData[key] = playerData[key] or {}
            applyDefaults(playerData[key], value)
        else
            playerData[key] = playerData[key] or value
        end
    end
end

-- ─────────────────────────── instance methods ───────────────────────────────

local function makeGameplayTag(tagName)
    if tagName == nil or not UE or not UE.FGameplayTag then
        return nil
    end

    local gameplayTag = UE.FGameplayTag()
    gameplayTag.TagName = tostring(tagName)
    return gameplayTag
end

local function readLimbStates(pawn)
    if not pawn or not UE or not UE.TArray or not UE.FHLimbHealthState or type(GetTargetActorAllLimbHealthStates) ~= 'function' then
        return nil
    end

    local limbArray = UE.TArray(UE.FHLimbHealthState)
    if not limbArray then
        return nil
    end

    if GetTargetActorAllLimbHealthStates(pawn, limbArray) == false then
        return nil
    end

    local limbs = {}
    local limbsByTag = {}
    for i = 1, limbArray:Num() do
        local healthState = limbArray[i]
        local limbTag = healthState and healthState.LimbTag and healthState.LimbTag.TagName
        if limbTag ~= nil then
            local limbInfo = {
                limbTag = tostring(limbTag),
                currentHealth = tonumber(healthState.CurrentHealth),
                maxHealth = tonumber(healthState.MaxHealth),
                damageTypes = {},
            }

            local tagContainer = healthState.RecentDamageTypes
            if tagContainer and tagContainer.GameplayTags then
                for _, damageType in pairs(tagContainer.GameplayTags) do
                    if damageType.TagName ~= nil then
                        table.insert(limbInfo.damageTypes, tostring(damageType.TagName))
                    end
                end
            end

            table.insert(limbs, limbInfo)
            limbsByTag[limbInfo.limbTag] = limbInfo
        end
    end

    return limbs, limbsByTag
end

local function damageTargetLimb(pawn, limbTag, damageAmount)
    local damageData = UE.FHDamageData()
    damageData.BaseDamage = damageAmount

    -- Limb identifiers travel in AdditionalTags; FHDamageData has no LimbTag field
    local tags = UE.FGameplayTagContainer()
    tags.GameplayTags:Add(limbTag)
    damageData.AdditionalTags = tags

    return UE.UHGameplaySystemGlobals.DamageTarget(pawn, pawn, damageData)
end

local function syncPlayerVitalsMetadata(source, pawn)
    local player = QBCore.Players[source]
    if not player or not player.PlayerData or not player.PlayerData.metadata then
        return false
    end

    pawn = pawn or GetPlayerPawn(source)
    if not pawn then
        return false
    end

    local synced = false
    local healthValue = tonumber(GetHealth(pawn))
    if healthValue ~= nil then
        player.PlayerData.metadata.health = healthValue
        synced = true
    end

    local armorValue = tonumber(GetArmor(pawn))
    if armorValue ~= nil then
        player.PlayerData.metadata.armor = armorValue
        synced = true
    end

    local limbStates = readLimbStates(pawn)
    if limbStates ~= nil then
        player.PlayerData.metadata.limbs = limbStates
        synced = true
    end

    return synced
end

local function applySavedVitalsMetadata(source, attempt)
    local player = QBCore.Players[source]
    if not player or not player.PlayerData or not player.PlayerData.metadata then
        return false
    end

    local savedHealth = tonumber(player.PlayerData.metadata.health)
    local savedArmor = tonumber(player.PlayerData.metadata.armor) or 0
    local savedLimbs = type(player.PlayerData.metadata.limbs) == 'table' and player.PlayerData.metadata.limbs or nil
    local hasSavedLimbs = savedLimbs and next(savedLimbs) ~= nil
    if savedHealth == nil and savedArmor <= 0 and not hasSavedLimbs then
        return true
    end

    local pawn = GetPlayerPawn(source)
    local currentHealth = pawn and (savedHealth ~= nil) and tonumber(GetHealth(pawn)) or nil
    local currentArmor = pawn and (savedArmor > 0) and tonumber(GetArmor(pawn)) or nil
    local currentLimbsByTag = nil
    if pawn and hasSavedLimbs then
        local _, limbsByTag = readLimbStates(pawn)
        currentLimbsByTag = limbsByTag
    end
    if not pawn or (savedHealth ~= nil and currentHealth == nil) or (savedArmor > 0 and currentArmor == nil) or (hasSavedLimbs and not currentLimbsByTag) then
        attempt = (attempt or 1) + 1
        if attempt <= 5 and Timer and Timer.SetTimeout then
            Timer.SetTimeout(function()
                applySavedVitalsMetadata(source, attempt)
            end, 500)
        end
        return false
    end

    local applied = true
    if savedHealth ~= nil then
        local healthAmount = savedHealth - currentHealth
        if healthAmount > 0 then
            applied = HealTarget(pawn, healthAmount) ~= false and applied
        elseif healthAmount < 0 then
            local damageData = UE.FHDamageData()
            damageData.BaseDamage = -healthAmount
            applied = UE.UHGameplaySystemGlobals.DamageTarget(pawn, pawn, damageData) ~= false and applied
        end
    end

    if hasSavedLimbs then
        for _, savedLimb in pairs(savedLimbs) do
            local limbTagName = savedLimb.limbTag or savedLimb.LimbTag
            local savedLimbHealth = tonumber(savedLimb.currentHealth or savedLimb.CurrentHealth)
            local currentLimb = limbTagName and currentLimbsByTag[tostring(limbTagName)] or nil
            local currentLimbHealth = currentLimb and tonumber(currentLimb.currentHealth)
            local limbTag = makeGameplayTag(limbTagName)

            if limbTag and savedLimbHealth ~= nil and currentLimbHealth ~= nil then
                local limbHealthAmount = savedLimbHealth - currentLimbHealth
                if limbHealthAmount > 0 then
                    applied = HealTargetLimb(pawn, limbTag, limbHealthAmount) ~= false and applied
                elseif limbHealthAmount < 0 then
                    applied = damageTargetLimb(pawn, limbTag, -limbHealthAmount) ~= false and applied
                end
            end
        end
    end

    if savedArmor > 0 then
        currentArmor = tonumber(GetArmor(pawn)) or currentArmor
        local armorAmount = savedArmor - currentArmor
        if armorAmount > 0 then
            applied = GiveArmorToTarget(pawn, armorAmount) ~= false and applied
        end
    end

    return applied
end

local PositionCache = {}

-- ─────────────────────────── server-event hooks ─────────────────────────────

RegisterServerEvent('HEvent:PlayerUnloaded', function(source)
    QBCore.Player.Logout(source)
end)

RegisterServerEvent('HEvent:PlayerUnPossessed', function(source, Pawn)
    if Pawn then
        PositionCache[source] = Pawn:K2_GetActorLocation()
        syncPlayerVitalsMetadata(source, Pawn)
    end
end)

-- ────────────────────────────────────────────────────────

function Player:GetPlayerData()
    return self.PlayerData
end

function Player:UpdateClient(key, val)
    if self.Offline then
        return
    end
    if key ~= nil then
        TriggerLocalServerEvent('QBCore:Server:OnPlayerUpdated', self.PlayerData.source, key, val)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnPlayerUpdated', key, val)
    else
        TriggerLocalServerEvent('QBCore:Player:SetPlayerData', self.PlayerData)
        TriggerLocalServerEvent('QBCore:Server:OnPlayerUpdated', self.PlayerData.source, 'all', self.PlayerData)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnPlayerUpdated', 'all', self.PlayerData)
    end
end

function Player:SetJob(job, grade)
    job = job:lower()
    grade = grade or 1
    if not QBCore.Shared.Jobs[job] then
        return false
    end
    self.PlayerData.job = {
        name = job,
        label = QBCore.Shared.Jobs[job].label,
        onduty = QBCore.Shared.Jobs[job].defaultDuty,
        type = QBCore.Shared.Jobs[job].type or 'none',
        grade = { name = 'No Grades', level = 1, payment = 30, isboss = false },
    }
    local gradeInfo = QBCore.Shared.Jobs[job].grades[grade]
    if gradeInfo then
        self.PlayerData.job.grade.name = gradeInfo.name
        self.PlayerData.job.grade.level = grade
        self.PlayerData.job.grade.payment = gradeInfo.payment
        self.PlayerData.job.grade.isboss = gradeInfo.isboss or false
        self.PlayerData.job.isboss = gradeInfo.isboss or false
    end
    if not self.Offline then
        self:UpdateClient('job', self.PlayerData.job)
    end
    return true
end

function Player:SetGang(gang, grade)
    gang = gang:lower()
    grade = grade or 1
    if not QBCore.Shared.Gangs[gang] then
        return false
    end
    self.PlayerData.gang = {
        name = gang,
        label = QBCore.Shared.Gangs[gang].label,
        grade = { name = 'No Grades', level = 1, isboss = false },
    }
    local gradeInfo = QBCore.Shared.Gangs[gang].grades[grade]
    if gradeInfo then
        self.PlayerData.gang.grade.name = gradeInfo.name
        self.PlayerData.gang.grade.level = grade
        self.PlayerData.gang.grade.isboss = gradeInfo.isboss or false
        self.PlayerData.gang.isboss = gradeInfo.isboss or false
    end
    if not self.Offline then
        self:UpdateClient('gang', self.PlayerData.gang)
    end
    return true
end

function Player:GetGang()
    return self.PlayerData.gang
end

function Player:IsGangBoss()
    return self.PlayerData.gang.isboss
end

function Player:Notify(text, notifType, length, icon)
    TriggerClientEvent(self.PlayerData.source, 'QBCore:Notify', text, notifType, length, icon)
end

function Player:GetSource()
    return self.PlayerData.source
end

function Player:GetCitizenId()
    return self.PlayerData.citizenid
end

function Player:GetName()
    local charinfo = self.PlayerData.charinfo
    return charinfo.firstname .. ' ' .. charinfo.lastname
end

-- inventory

function Player:HasItem(items, amount)
    return exports['qb-inventory']:HasItem(self.PlayerData.source, items, amount)
end

function Player:AddItem(item, amount, slot, info)
    return exports['qb-inventory']:AddItem(self.PlayerData.source, item, amount, slot, info)
end

function Player:RemoveItem(item, amount, slot)
    return exports['qb-inventory']:RemoveItem(self.PlayerData.source, item, amount, slot)
end

function Player:GetItemBySlot(slot)
    return exports['qb-inventory']:GetItemBySlot(self.PlayerData.source, slot)
end

function Player:GetItemByName(item)
    return exports['qb-inventory']:GetItemByName(self.PlayerData.source, item)
end

function Player:GetItemsByName(item)
    return exports['qb-inventory']:GetItemsByName(self.PlayerData.source, item)
end

function Player:GetItemCount(item)
    return exports['qb-inventory']:GetItemCount(self.PlayerData.source, item)
end

function Player:CanAddItem(item, amount)
    return exports['qb-inventory']:CanAddItem(self.PlayerData.source, item, amount)
end

function Player:GetTotalWeight()
    return exports['qb-inventory']:GetTotalWeight(self.PlayerData.items)
end

function Player:GetFreeWeight()
    return exports['qb-inventory']:GetFreeWeight(self.PlayerData.source)
end

function Player:ClearInventory(filterItems)
    return exports['qb-inventory']:ClearInventory(self.PlayerData.source, filterItems)
end

function Player:SetInventory(items)
    return exports['qb-inventory']:SetInventory(self.PlayerData.source, items)
end

function Player:GetSlotsByItem(item)
    return exports['qb-inventory']:GetSlotsByItem(self.PlayerData.items, item)
end

function Player:GetFirstSlotByItem(item)
    return exports['qb-inventory']:GetFirstSlotByItem(self.PlayerData.items, item)
end

function Player:GetJob()
    return self.PlayerData.job
end

function Player:IsOnDuty()
    return self.PlayerData.job.onduty
end

function Player:IsBoss()
    return self.PlayerData.job.isboss
end

function Player:SetJobDuty(onDuty)
    self.PlayerData.job.onduty = not not onDuty
    if not self.Offline then
        self:UpdateClient('job', self.PlayerData.job)
    end
end

function Player:SetPlayerData(key, val)
    if not key or type(key) ~= 'string' then
        return
    end
    self.PlayerData[key] = val
    self:UpdateClient(key, val)
end

function Player:SetMetaData(meta, val)
    if not meta or type(meta) ~= 'string' then
        return
    end
    if meta == 'hunger' or meta == 'thirst' or meta == 'stress' or meta == 'armor' then
        val = math.min(100, math.max(0, val))
    end
    self.PlayerData.metadata[meta] = val
    self:UpdateClient('metadata', self.PlayerData.metadata)
end

function Player:GetMetaData(meta)
    if not meta or type(meta) ~= 'string' then
        return
    end
    return self.PlayerData.metadata[meta]
end

function Player:IsDead()
    return self.PlayerData.metadata.isdead
end

function Player:IsHandcuffed()
    return self.PlayerData.metadata.ishandcuffed
end

function Player:IsInJail()
    return self.PlayerData.metadata.injail > 0
end

function Player:HasLicence(licence)
    if not licence or type(licence) ~= 'string' then
        return false
    end
    return self.PlayerData.metadata.licences[licence] == true
end

function Player:SetLicence(licence, val)
    if not licence or type(licence) ~= 'string' then
        return
    end
    self.PlayerData.metadata.licences[licence] = not not val
    self:UpdateClient('metadata', self.PlayerData.metadata)
end

function Player:AddRep(rep, amount)
    if not rep or not amount then
        return
    end
    local addAmount = tonumber(amount)
    local currentRep = self.PlayerData.metadata['rep'][rep] or 0
    self.PlayerData.metadata['rep'][rep] = currentRep + addAmount
    self:UpdateClient('metadata', self.PlayerData.metadata)
end

function Player:RemoveRep(rep, amount)
    if not rep or not amount then
        return
    end
    local removeAmount = tonumber(amount)
    local currentRep = self.PlayerData.metadata['rep'][rep] or 0
    self.PlayerData.metadata['rep'][rep] = math.max(0, currentRep - removeAmount)
    self:UpdateClient('metadata', self.PlayerData.metadata)
end

function Player:GetRep(rep)
    if not rep then
        return
    end
    return self.PlayerData.metadata['rep'][rep] or 0
end

function Player:AddMoney(moneytype, amount, reason)
    reason = reason or 'unknown'
    moneytype = moneytype:lower()
    amount = tonumber(amount)
    if not amount or amount < 0 then
        return
    end
    if not self.PlayerData.money[moneytype] then
        return false
    end
    self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] + amount
    if not self.Offline then
        self:UpdateClient('money', self.PlayerData.money)
        local logExtra = amount > 100000
        TriggerLocalServerEvent('qb-log:server:CreateLog', 'playermoney', 'AddMoney', 'lightgreen', '**' .. self.PlayerData.name .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. tostring(self.PlayerData.source) .. ')** $' .. amount .. ' (' .. moneytype .. ') added, new ' .. moneytype .. ' balance: ' .. self.PlayerData.money[moneytype] .. ' reason: ' .. reason, logExtra)
        TriggerClientEvent(self.PlayerData.source, 'hud:client:OnMoneyChange', moneytype, amount, false)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'add', reason)
        TriggerLocalServerEvent('QBCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, 'add', reason)
    end
    return true
end

function Player:RemoveMoney(moneytype, amount, reason)
    reason = reason or 'unknown'
    moneytype = moneytype:lower()
    amount = tonumber(amount)
    if not amount or amount < 0 then
        return
    end
    if not self.PlayerData.money[moneytype] then
        return false
    end
    for _, mtype in pairs(QBCore.Config.Money.DontAllowMinus) do
        if mtype == moneytype and (self.PlayerData.money[moneytype] - amount) < 0 then
            return false
        end
    end
    if self.PlayerData.money[moneytype] - amount < QBCore.Config.Money.MinusLimit then
        return false
    end
    self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] - amount
    if not self.Offline then
        self:UpdateClient('money', self.PlayerData.money)
        local logExtra = amount > 100000
        TriggerLocalServerEvent('qb-log:server:CreateLog', 'playermoney', 'RemoveMoney', 'red', '**' .. self.PlayerData.name .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. tostring(self.PlayerData.source) .. ')** $' .. amount .. ' (' .. moneytype .. ') removed, new ' .. moneytype .. ' balance: ' .. self.PlayerData.money[moneytype] .. ' reason: ' .. reason, logExtra)
        TriggerClientEvent(self.PlayerData.source, 'hud:client:OnMoneyChange', moneytype, amount, true)
        if moneytype == 'bank' then
            TriggerClientEvent(self.PlayerData.source, 'qb-phone:client:RemoveBankMoney', amount)
        end
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'remove', reason)
        TriggerLocalServerEvent('QBCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, 'remove', reason)
    end
    return true
end

function Player:SetMoney(moneytype, amount, reason)
    reason = reason or 'unknown'
    moneytype = moneytype:lower()
    amount = tonumber(amount)
    if not amount or amount < 0 then
        return false
    end
    if not self.PlayerData.money[moneytype] then
        return false
    end
    local difference = amount - self.PlayerData.money[moneytype]
    self.PlayerData.money[moneytype] = amount
    if not self.Offline then
        self:UpdateClient('money', self.PlayerData.money)
        TriggerLocalServerEvent('qb-log:server:CreateLog', 'playermoney', 'SetMoney', 'green', '**' .. self.PlayerData.name .. ' (citizenid: ' .. self.PlayerData.citizenid .. ' | id: ' .. tostring(self.PlayerData.source) .. ')** $' .. amount .. ' (' .. moneytype .. ') set, new ' .. moneytype .. ' balance: ' .. self.PlayerData.money[moneytype] .. ' reason: ' .. reason)
        TriggerClientEvent(self.PlayerData.source, 'hud:client:OnMoneyChange', moneytype, math.abs(difference), difference < 0)
        TriggerClientEvent(self.PlayerData.source, 'QBCore:Client:OnMoneyChange', moneytype, amount, 'set', reason)
        TriggerLocalServerEvent('QBCore:Server:OnMoneyChange', self.PlayerData.source, moneytype, amount, 'set', reason)
    end
    return true
end

function Player:GetMoney(moneytype)
    if not moneytype then
        return false
    end
    return self.PlayerData.money[moneytype:lower()]
end

function Player:CanAfford(moneytype, amount)
    if not moneytype or not amount then
        return false
    end
    moneytype = moneytype:lower()
    amount = tonumber(amount)
    local balance = self.PlayerData.money[moneytype]
    if not balance then
        return false
    end
    return balance >= amount
end

function Player:GetCharInfo(key)
    if not key or type(key) ~= 'string' then
        return
    end
    return self.PlayerData.charinfo[key]
end

function Player:SetCharInfo(key, val)
    if not key or type(key) ~= 'string' then
        return
    end
    self.PlayerData.charinfo[key] = val
    self:UpdateClient('charinfo', self.PlayerData.charinfo)
end

function Player:SetCreditCard(cardNumber)
    self.PlayerData.charinfo.card = cardNumber
    self:UpdateClient('charinfo', self.PlayerData.charinfo)
end

function Player:GetCardSlot(cardNumber, cardType)
    local item = tostring(cardType):lower()
    local slots = GetSlotsByItem(self.PlayerData.items, item)
    for _, slot in pairs(slots) do
        if slot and self.PlayerData.items[slot].info.cardNumber == cardNumber then
            return slot
        end
    end
    return nil
end

function Player:Save()
    if self.Offline then
        QBCore.Player.SaveOffline(self.PlayerData)
    else
        QBCore.Player.Save(self.PlayerData.source)
    end
end

function Player:Logout()
    if self.Offline then
        return
    end
    QBCore.Player.Logout(self.PlayerData.source)
end

function Player:AddField(fieldName, data)
    if type(fieldName) ~= 'string' or type(data) == 'function' then
        return false
    end
    self[fieldName] = data
    return true
end

-- ─────────────────────────── login / logout ─────────────────────────────────

function QBCore.Player.Login(source, citizenid, newData)
    if not source then
        return false
    end
    if citizenid then
        local PlayerState = source:GetLyraPlayerState()
        local license = PlayerState:GetHelixUserId()
        local result = Database.Select('SELECT * FROM players where citizenid = ?', { citizenid })
        local PlayerData = result[1] and result[1].Columns:ToTable()
        if PlayerData and license == PlayerData.license then
            PlayerData.money = JSON.parse(PlayerData.money)
            PlayerData.job = JSON.parse(PlayerData.job)
            PlayerData.gang = JSON.parse(PlayerData.gang)
            PlayerData.position = JSON.parse(PlayerData.position)
            PlayerData.metadata = JSON.parse(PlayerData.metadata)
            PlayerData.charinfo = JSON.parse(PlayerData.charinfo)
            PlayerData.items = formatItems(JSON.parse(PlayerData.inventory))
            QBCore.Player.CheckPlayerData(source, PlayerData)
        else
            source:Kick(Lang:t('info.exploit_dropped'))
            TriggerLocalServerEvent('qb-log:server:CreateLog', 'anticheat', 'Anti-Cheat', 'white', tostring(source) .. ' Has Been Dropped For Character Joining Exploit', false)
            return false
        end
    else
        QBCore.Player.CheckPlayerData(source, newData)
    end
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerLoaded')
    TriggerLocalServerEvent('QBCore:Server:OnPlayerLoaded', source)
    return true
end

function QBCore.Player.Logout(source)
    if not QBCore.Players[source] then
        return
    end
    local player = QBCore.Players[source]
    player:Save()
    TriggerClientEvent(source, 'QBCore:Client:OnPlayerUnload')
    TriggerLocalServerEvent('QBCore:Server:OnPlayerUnload', source)
    QBCore.PlayersByCitizenId[player.PlayerData.citizenid] = nil
    QBCore.Players[source] = nil
end

-- ─────────────────────────── offline player lookups ─────────────────────────

function QBCore.Player.GetOfflinePlayer(citizenid)
    if not citizenid then
        return nil
    end
    local result = Database.Select('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not result or not result[1] then
        return nil
    end
    local PlayerData = result[1].Columns:ToTable()
    PlayerData.money = JSON.parse(PlayerData.money)
    PlayerData.job = JSON.parse(PlayerData.job)
    PlayerData.gang = JSON.parse(PlayerData.gang)
    PlayerData.position = JSON.parse(PlayerData.position)
    PlayerData.metadata = JSON.parse(PlayerData.metadata)
    PlayerData.charinfo = JSON.parse(PlayerData.charinfo)
    PlayerData.items = formatItems(JSON.parse(PlayerData.inventory))
    return QBCore.Player.CheckPlayerData(nil, PlayerData)
end

function QBCore.Player.GetPlayerByLicense(license)
    if not license then
        return nil
    end
    local source = QBCore.Functions.GetSource(license)
    if source and source > 0 then
        return QBCore.Players[source]
    end
    return QBCore.Player.GetOfflinePlayerByLicense(license)
end

function QBCore.Player.GetOfflinePlayerByLicense(license)
    if not license then
        return nil
    end
    local result = Database.Select('SELECT * FROM players WHERE license = ? LIMIT 1', { license })
    if not result or not result[1] then
        return nil
    end
    local PlayerData = result[1].Columns:ToTable()
    PlayerData.money = JSON.parse(PlayerData.money)
    PlayerData.job = JSON.parse(PlayerData.job)
    PlayerData.gang = JSON.parse(PlayerData.gang)
    PlayerData.position = JSON.parse(PlayerData.position)
    PlayerData.metadata = JSON.parse(PlayerData.metadata)
    PlayerData.charinfo = JSON.parse(PlayerData.charinfo)
    PlayerData.items = formatItems(JSON.parse(PlayerData.inventory))
    return QBCore.Player.CheckPlayerData(nil, PlayerData)
end

-- ─────────────────────────── data validation / construction ─────────────────

function QBCore.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local Offline = not source

    if source then
        PlayerData.source = source
        local PlayerState = source:GetLyraPlayerState()
        PlayerData.netId = PlayerState:GetPlayerId()
        PlayerData.license = PlayerState:GetHelixUserId()
        PlayerData.name = PlayerState:GetPlayerName()
    end

    local validatedJob = false
    if PlayerData.job and PlayerData.job.name ~= nil and PlayerData.job.grade and PlayerData.job.grade.level ~= nil then
        local jobInfo = QBCore.Shared.Jobs[PlayerData.job.name]
        if jobInfo then
            local jobGradeInfo = jobInfo.grades[tostring(PlayerData.job.grade.level)]
            if jobGradeInfo then
                PlayerData.job.label = jobInfo.label
                PlayerData.job.grade.name = jobGradeInfo.name
                PlayerData.job.grade.payment = jobGradeInfo.payment
                PlayerData.job.grade.isboss = jobGradeInfo.isboss or false
                PlayerData.job.isboss = jobGradeInfo.isboss or false
                validatedJob = true
            end
        end
    end

    if not validatedJob then
        PlayerData.job = nil
    end

    local validatedGang = false
    if PlayerData.gang and PlayerData.gang.name ~= nil and PlayerData.gang.grade and PlayerData.gang.grade.level ~= nil then
        local gangInfo = QBCore.Shared.Gangs[PlayerData.gang.name]
        if gangInfo then
            local gangGradeInfo = gangInfo.grades[tostring(PlayerData.gang.grade.level)]
            if gangGradeInfo then
                PlayerData.gang.label = gangInfo.label
                PlayerData.gang.grade.name = gangGradeInfo.name
                PlayerData.gang.grade.payment = gangGradeInfo.payment
                PlayerData.gang.grade.isboss = gangGradeInfo.isboss or false
                PlayerData.gang.isboss = gangGradeInfo.isboss or false
                validatedGang = true
            end
        end
    end

    if not validatedGang then
        PlayerData.gang = nil
    end

    applyDefaults(PlayerData, QBCore.Config.Player.PlayerDefaults)

    if PlayerData.job and QBCore.Shared.ForceJobDefaultDutyAtLogin then
        local jobInfo = QBCore.Shared.Jobs[PlayerData.job.name]
        if jobInfo then
            PlayerData.job.onduty = jobInfo.defaultDuty
        end
    end

    return QBCore.Player.CreatePlayer(PlayerData, Offline)
end

function QBCore.Player.CreatePlayer(PlayerData, Offline)
    local player = Player.new(PlayerData, Offline)

    if QBCore.Config.Server.Permissions[PlayerData.license] then
        AddPermission(PlayerData.source)
    end

    if not Offline then
        QBCore.Players[PlayerData.source] = player
        QBCore.PlayersByCitizenId[PlayerData.citizenid] = player
        applySavedVitalsMetadata(PlayerData.source)
        QBCore.Player.Save(PlayerData.source)
        TriggerLocalServerEvent('QBCore:Server:PlayerLoaded', player)
        player:UpdateClient()
    end

    return player
end

-- ─────────────────────────── save / persistence ─────────────────────────────

local function writePlayerToDatabase(PlayerData, position)
    local ItemsJson = {}
    if PlayerData.items and next(PlayerData.items) then
        for slot, item in pairs(PlayerData.items) do
            if item then
                ItemsJson[#ItemsJson + 1] = {
                    name = item.name,
                    amount = item.amount,
                    info = item.info,
                    slot = slot,
                }
            end
        end
    end

    Database.Execute(
        [[
        INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata, inventory)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(citizenid) DO UPDATE SET
            cid       = excluded.cid,
            name      = excluded.name,
            money     = excluded.money,
            charinfo  = excluded.charinfo,
            job       = excluded.job,
            gang      = excluded.gang,
            position  = excluded.position,
            metadata  = excluded.metadata,
            inventory = excluded.inventory;
    ]],
        {
            PlayerData.citizenid,
            tonumber(PlayerData.cid),
            PlayerData.license,
            PlayerData.name,
            JSON.stringify(PlayerData.money),
            JSON.stringify(PlayerData.charinfo),
            JSON.stringify(PlayerData.job),
            JSON.stringify(PlayerData.gang),
            JSON.stringify(position),
            JSON.stringify(PlayerData.metadata),
            JSON.stringify(ItemsJson),
        }
    )
end

function QBCore.Player.Save(source)
    local PlayerData = QBCore.Players[source] and QBCore.Players[source].PlayerData
    if not PlayerData then
        print('[ERROR] QBCORE.PLAYER.SAVE - PLAYERDATA IS EMPTY!')
        return
    end

    syncPlayerVitalsMetadata(source)

    local pcoords = QBCore.Config.DefaultSpawn
    local ped = GetPlayerPawn(source)
    pcoords = ped and GetEntityCoords(ped) or (PositionCache[source] or pcoords)

    writePlayerToDatabase(PlayerData, { x = pcoords.X, y = pcoords.Y, z = pcoords.Z })
    print(('[QBCORE] Saved player data for %s (Citizen ID: %s)'):format(PlayerData.name, PlayerData.citizenid))
end

function QBCore.Player.SaveOffline(PlayerData)
    if not PlayerData then
        print('[ERROR] QBCORE.PLAYER.SAVEOFFLINE - PLAYERDATA IS EMPTY!')
        return
    end

    writePlayerToDatabase(PlayerData, PlayerData.position)
    print(('[QBCORE] Saved offline player data for %s (Citizen ID: %s)'):format(PlayerData.name, PlayerData.citizenid))
end

-- ─────────────────────────── character deletion ─────────────────────────────

local playertables = {
    { table = 'players' },
    { table = 'apartments' },
    { table = 'bank_accounts' },
    { table = 'crypto_transactions' },
    { table = 'phone_invoices' },
    { table = 'phone_messages' },
    { table = 'playerskins' },
    { table = 'player_contacts' },
    --{ table = 'player_houses' },
    { table = 'player_mails' },
    { table = 'player_outfits' },
    { table = 'player_vehicles' },
}

function QBCore.Player.DeleteCharacter(source, citizenid)
    if not source or not citizenid then
        print('[ERROR] qb-core couldn\'t delete character')
        return false
    end
    local PlayerState = source:GetLyraPlayerState()
    local license = PlayerState:GetHelixUserId()
    local result = Database.Select('SELECT license FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not result or not result[1] or license ~= result[1].Columns:ToTable().license then
        source:Kick(Lang:t('info.exploit_dropped'))
        TriggerLocalServerEvent('qb-log:server:CreateLog', 'anticheat', 'Anti-Cheat', 'white', tostring(source) .. ' Has Been Dropped For Character Deletion Exploit', true)
        return false
    end
    if not Database.Execute('BEGIN TRANSACTION') then
        print('[ERROR] qb-core couldn\'t start a transaction when deleting a character.')
        return false
    end
    local query = 'DELETE FROM %s WHERE citizenid = ?'
    local success = true
    for i = 1, #playertables do
        if not Database.Execute(query:format(playertables[i].table), { citizenid }) then
            success = false
            break
        end
    end
    if not success then
        Database.Execute('ROLLBACK')
        return false
    end
    Database.Execute('COMMIT')
    TriggerLocalServerEvent('qb-log:server:CreateLog', 'joinleave', 'Character Deleted', 'red', tostring(source) .. ' (' .. license .. ') deleted **' .. citizenid .. '**')
    return true
end

function QBCore.Player.ForceDeleteCharacter(citizenid)
    local result = Database.Select('SELECT license FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not result or not result[1] then
        return
    end
    local existing = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if existing then
        existing.PlayerData.source:Kick('An admin deleted the character which you are currently using')
        QBCore.Player.Logout(existing.PlayerData.source)
    end
    local query = 'DELETE FROM %s WHERE citizenid = ?'
    for i = 1, #playertables do
        Database.Execute(query:format(playertables[i].table), { citizenid })
    end
    TriggerLocalServerEvent('qb-log:server:CreateLog', 'joinleave', 'Character Force Deleted', 'red', 'Character **' .. citizenid .. '** got deleted')
end

-- ─────────────────────────── export bridge ──────────────────────────────────

for functionName, func in pairs(QBCore.Player) do
    if type(func) == 'function' then
        exports('qb-core', functionName, func)
    end
end
