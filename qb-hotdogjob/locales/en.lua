local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        no_money = 'Not enough money',
        too_far = 'You are too far from your Hot Dog Stand',
        no_stand = 'You do not have a hotdog stand',
        cust_refused = 'Customer refused!',
        no_stand_found = 'Your hot dog stand was nowhere to be seen. You will not receive your deposit back!',
        no_more = 'You cannot hold more %{value} hotdogs',
        deposit_notreturned = 'You did not have a Hot Dog Stand',
        no_dogs = 'You do not have any hotdogs',
        invalid_job = 'You are not a hotdog worker',
        stand_spawn_failed = 'Could not place a hotdog stand',
        customer_failed = 'Could not find a customer',
        drop_stand_first = 'Drop the hotdog stand first',
    },
    success = {
        deposit = 'You paid a $%{deposit} deposit!',
        deposit_returned = 'Your $%{deposit} deposit has been returned!',
        sold_hotdogs = '%{value} x Hotdog(s) sold for $%{value2}',
        made_hotdog = 'You made %{value} Hot Dogs',
        made_luck_hotdog = 'You made %{value} x %{value2} Hot Dogs',
    },
    info = {
        command = 'Delete Stand (Admin Only)',
        blip_name = 'Hotdog Stand',
        start_working = '[E] Start Working',
        start_work = 'Start Working',
        stop_working = '[E] Stop Working',
        stop_work = 'Stop Working',
        grab_stall = '[G] Grab Stall',
        drop_stall = '[K] Release Stall',
        grab = 'Grab Stall',
        prepare = 'Prepare Hotdog',
        toggle_sell = 'Toggle Selling',
        selling_prep = '[E] Hotdog prepare [Sale: Selling]',
        not_selling = '[E] Hotdog prepare [Sale: Not Selling]',
        sell_dogs = '[7] Sell %{value} x HotDogs for $%{value2} / [8] Reject',
        sell_dogs_target = 'Sell %{value} x HotDogs for $%{value2}',
        decline_offer = 'Decline offer',
        customer_ready = 'A customer is ready at your stand',
        admin_removed = 'Hot Dog Stand Removed',
        label_a = 'Perfect (A)',
        label_b = 'Rare (B)',
        label_c = 'Common (C)',
    },
    target = {
        toggle_duty = 'Toggle Duty',
        toggle_work = 'Toggle Work',
    },
    keymapping = {
        gkey = 'Let go of hotdog stand',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
