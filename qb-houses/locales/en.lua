local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        to_far_from_door = 'You are too far away from the doorbell',
        nobody_home = 'There is nobody home..',
        nobody_at_door = 'There is nobody at the door..',
        not_owner = 'You do not own this property',
        too_far_from_garage = 'You are too far away from the garage store point',
        not_vehicle_owner = 'You do not own this vehicle',
        full_garage = 'This garage is full',
        not_in_vehicle = 'You are not in a vehicle',
        not_enough_money = 'You do not have enough money to purchase this property',
    },
    success = {
        receive_apart = 'You received a new property: ',
        purchased_apart = 'You have purchased a property: ',
    },
    info = {
        at_the_door = 'Someone is at the door!',
    },
    text = {
        options = '[E] Apartment Options',
        enter = 'Enter Property',
        ring_doorbell = 'Ring Doorbell',
        logout = 'Logout Character',
        change_outfit = 'Change Outfit',
        open_stash = 'Open Stash',
        open_furn_stash = 'Open Furniture Stash',
        move_here = 'Move Here',
        open_door = 'Open Door',
        leave = 'Leave Property',
        close_menu = '⬅ Close Menu',
        tennants = 'Properties',
        purchase = 'Purchase Property',
        furniture = 'Furniture Menu',
        permissions = 'Manage Permissions',
        go_to_garage = 'Visit Garage',
        return_to_apartment = 'Return to Property',
        exit_garage = 'Exit Garage',
        use_kitchen = 'Use Kitchen',
        open_fridge = 'Open Fridge',
        open_totem = 'CraftCorp Terminal',
        default_property = 'Set as Default Property',
        store_vehicle = '[E] Store Vehicle',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
