local Consumables = {
    -- Food
    tosti = { hunger = 40 },
    sandwich = { hunger = 35 },
    fish = { hunger = 30 },
    grape = { hunger = 15 },
    twerks_candy = { hunger = 10 },
    snikkel_candy = { hunger = 10 },
    -- Drinks
    water_bottle = { thirst = 40 },
    grapejuice = { thirst = 25 },
    kurkakola = { thirst = 25 },
    coffee = { thirst = 20 },
    beer = { thirst = 20 },
    wine = { thirst = 20 },
    whiskey = { thirst = 15 },
    vodka = { thirst = 15 },
}

for itemName in pairs(Consumables) do
    exports['qb-core']:CreateUseableItem(itemName, { event = 'qb-consumables:server:useItem' })
end

local EatingAnim = '/HelixAnimation/Unified/Animations/Actions/Consumables/A_Eating_Standing.A_Eating_Standing'
local DrinkingAnim = '/HelixAnimation/Unified/Animations/Actions/Consumables/A_Drinking_Bottle.A_Drinking_Bottle'

RegisterServerEvent('qb-consumables:server:useItem', function(source, itemData)
    local Player = exports['qb-core']:GetPlayer(source)
    if not Player then
        return
    end
    local effects = Consumables[itemData.name]
    if not effects then
        return
    end
    if effects.hunger then
        Player.SetMetaData('hunger', Player.PlayerData.metadata['hunger'] + effects.hunger)
    end
    if effects.thirst then
        Player.SetMetaData('thirst', Player.PlayerData.metadata['thirst'] + effects.thirst)
    end
    Player.RemoveItem(itemData.name, 1, itemData.slot)
    local pawn = GetPlayerPawn(source)
    if pawn then
        Animation.Stop(pawn)
        Animation.Play(pawn, effects.hunger and EatingAnim or DrinkingAnim, nil, function() end)
    end
end)
