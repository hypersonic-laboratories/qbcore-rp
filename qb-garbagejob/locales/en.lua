local Locale = exports['qb-core']:GetLocale()

local Translations = {
    info = {
        ['load_bag'] = 'Garbage bag collected! Load it into your truck',
        ['stops_remaining'] = '%{stops} stop(s) remaining on your route',
    },
    error = {
        ['route_busy'] = 'You already have an active route!',
        ['no_route'] = 'You do not have an active route!',
        ['already_holding_bag'] = 'You are already holding a garbage bag!',
        ['already_collected'] = 'You have already collected from this dumpster!',
        ['no_bag'] = 'You are not holding a garbage bag!',
        ['truck_not_returned'] = 'You must return your truck to complete the job!',
        ['truck_too_far'] = 'You must be near your garbage truck to complete the job!',
        ['no_vehicle'] = 'You do not have an active vehicle!',
    },
    success = {
        ['reward'] = 'Job completed! You earned $%{amount}',
        ['new_route'] = 'New route started! Collect garbage from %{stops} dumpsters',
        ['route_complete'] = 'All stops completed! Return to the depot to get paid',
    },
    target = {
        ['collect_garbage'] = 'Collect Garbage',
        ['toggle_duty'] = 'Toggle Duty',
        ['start_job'] = 'Start Job',
        ['complete_route'] = 'Complete Route & Return Truck',
        ['deposit_garbage'] = 'Deposit Garbage',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
