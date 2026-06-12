local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

-- Functions

local function CraftItem(craftedItem, requiredItems, amountToCraft, xpEarned, xpType)
    TriggerCallback('getPlayerInventory', function(inventory)
        local hasAllMaterials = true
        for _, reqItem in pairs(requiredItems) do
            local itemAmount = 0
            for _, invItem in pairs(inventory) do
                if invItem.name == reqItem.item then
                    itemAmount = invItem.amount
                    break
                end
            end
            if itemAmount < reqItem.amount then
                hasAllMaterials = false
                exports['qb-core']:Notify(Lang.t('notifications.notenoughMaterials') .. ' ' .. amountToCraft .. 'x ' .. sharedItems[craftedItem].label, 'error')
                break
            end
        end

        if not hasAllMaterials then
            return
        end

        local function doCraft()
            local duration = math.random(2000, 5000) * amountToCraft
            Timer.SetTimeout(duration, function()
                TriggerServerEvent('qb-crafting:server:receiveItem', craftedItem, requiredItems, amountToCraft, xpEarned, xpType)
            end)
        end

        if Config.EnableSkillCheck then
            local success = exports['qb-minigames']:Skillbar('easy', '12345')
            if success then
                doCraft()
            else
                local randomItem = requiredItems[math.random(#requiredItems)]
                local randomAmount = math.random(1, randomItem.amount)
                TriggerServerEvent('qb-crafting:server:removeMaterials', randomItem.item, randomAmount)
                exports['qb-core']:Notify('Crafting failed, some materials have been lost!', 'error')
            end
        else
            doCraft()
        end
    end)
end

local function CraftAmount(craftedItem, requiredItems, xpGain, xpType)
    local dialog = exports['qb-input']:ShowInput({
        header = Lang.t('menus.entercraftAmount'),
        submitText = 'Confirm',
        inputs = {
            {
                type = 'number',
                name = 'amount',
                label = 'Amount',
                text = 'Enter Amount',
                isRequired = true,
            },
        },
    })
    if dialog and tonumber(dialog.amount) then
        local amount = tonumber(dialog.amount)
        if amount > 0 then
            local multipliedItems = {}
            for _, reqItem in ipairs(requiredItems) do
                multipliedItems[#multipliedItems + 1] = {
                    item = reqItem.item,
                    amount = reqItem.amount * amount,
                }
            end
            CraftItem(craftedItem, multipliedItems, amount, xpGain, xpType)
        else
            exports['qb-core']:Notify(Lang.t('notifications.invalidAmount'), 'error')
        end
    else
        exports['qb-core']:Notify(Lang.t('notifications.invalidInput'), 'error')
    end
end

local function OpenCraftingMenu(benchType)
    local PlayerData = exports['qb-core']:GetPlayerData()
    local xpType = Config[benchType].xpType
    local recipes = Config[benchType].recipes
    local currentXP = PlayerData.metadata[xpType] or 0

    TriggerCallback('getPlayerInventory', function(inventory)
        local craftableItems = {}
        local nonCraftableItems = {}
        for _, recipe in pairs(recipes) do
            if currentXP >= recipe.xpRequired then
                local canCraft = true
                local itemsText = ''
                for _, reqItem in pairs(recipe.requiredItems) do
                    local hasItem = false
                    for _, invItem in pairs(inventory) do
                        if invItem.name == reqItem.item and invItem.amount >= reqItem.amount then
                            hasItem = true
                            break
                        end
                    end
                    local itemLabel = sharedItems[reqItem.item].label
                    itemsText = itemsText .. ' x' .. tostring(reqItem.amount) .. ' ' .. itemLabel .. '<br>'
                    if not hasItem then
                        canCraft = false
                    end
                end
                itemsText = string.sub(itemsText, 1, -5)
                local menuItem = {
                    header = sharedItems[recipe.item].label,
                    txt = itemsText,
                    icon = Config.ImageBasePath .. sharedItems[recipe.item].image,
                    params = {
                        isAction = true,
                        event = function()
                            CraftAmount(recipe.item, recipe.requiredItems, recipe.xpGain, xpType)
                        end,
                        args = {},
                    },
                    disabled = not canCraft,
                }
                if canCraft then
                    craftableItems[#craftableItems + 1] = menuItem
                else
                    nonCraftableItems[#nonCraftableItems + 1] = menuItem
                end
            end
        end

        local menuItems = {
            {
                header = Lang.t('menus.header'),
                icon = 'fas fa-drafting-compass',
                isMenuHeader = true,
            },
        }
        for _, item in ipairs(craftableItems) do
            menuItems[#menuItems + 1] = item
        end
        for _, item in ipairs(nonCraftableItems) do
            menuItems[#menuItems + 1] = item
        end
        exports['qb-menu']:openMenu(menuItems)
    end)
end

-- Events

RegisterClientEvent('qb-crafting:client:openMenu', function(benchType)
    OpenCraftingMenu(benchType)
end)

local activeBenchActor = nil

RegisterClientEvent('qb-crafting:client:openMenuFromTarget', function(data)
    OpenCraftingMenu(data.benchType)
end)

RegisterClientEvent('qb-crafting:client:registerBench', function(actor, benchType)
    if activeBenchActor then
        exports['qb-target']:RemoveTargetEntity(activeBenchActor)
    end
    activeBenchActor = actor
    exports['qb-target']:AddTargetEntity(actor, {
        distance = 200,
        options = {
            {
                label = Lang.t('menus.header'),
                icon = 'hammer',
                event = 'qb-crafting:client:openMenuFromTarget',
                type = 'client',
                benchType = benchType,
            },
            {
                label = Lang.t('menus.pickupworkBench'),
                icon = 'package',
                event = 'qb-crafting:server:pickupBench',
                type = 'server',
            },
        },
    })
end)

RegisterClientEvent('qb-crafting:client:removeBench', function()
    if activeBenchActor then
        exports['qb-target']:RemoveTargetEntity(activeBenchActor)
        activeBenchActor = nil
    end
end)
