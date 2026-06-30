local LastEquippedBySlot = {}

local function Tag(tagName)
    local tag = UE.FGameplayTag()
    tag.TagName = tagName
    return tag
end

local function Notify(message, notifyType)
    TriggerLocalClientEvent('QBCore:Notify', message, notifyType or 'primary')
end

local function GetCosmeticsSystem()
    local pawn = GetPlayerPawn()
    if not pawn then
        return nil
    end
    return pawn:GetCosmeticsSystem()
end

local function GetEquippedItemId(System, slotName)
    local entry = System:GetCosmeticSlotEntry(Tag(slotName))
    if entry and entry.ItemID and entry.ItemID ~= '' then
        return entry.ItemID
    end
    return nil
end

local function ToggleCosmeticSlot(data)
    local slotName = data and data.slot or data
    if type(slotName) ~= 'string' or slotName == '' then
        Notify('Missing cosmetic slot', 'error')
        return
    end

    local System = GetCosmeticsSystem()
    if not System then
        Notify('Cosmetics system unavailable', 'error')
        return
    end

    local label = data and data.title or slotName
    local itemId = GetEquippedItemId(System, slotName)

    if itemId then
        LastEquippedBySlot[slotName] = itemId
        System:UnequipCosmeticSlot(Tag(slotName))
        Notify(('Toggled off %s'):format(label), 'primary')
        return
    end

    local cachedItemId = LastEquippedBySlot[slotName]
    if not cachedItemId then
        Notify(('No saved item for %s'):format(label), 'error')
        return
    end

    local accepted = System:EquipCosmeticItem(cachedItemId)
    if accepted == false then
        Notify(('Could not toggle on %s'):format(label), 'error')
        return
    end

    Notify(('Toggled on %s'):format(label), 'success')
end

RegisterClientEvent('qb-radialmenu:client:ToggleCosmeticSlot', function(data)
    ToggleCosmeticSlot(data)
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    LastEquippedBySlot = {}
end)
