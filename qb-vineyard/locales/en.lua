local Locale = exports['qb-core']:GetLocale()

local Lang = Locale.new({
    phrases = {
        error = {
            ['invalid_job'] = 'I don\'t think I work here...',
            ['invalid_items'] = 'You do not have the correct items!',
            ['no_items'] = 'You do not have any items!',
        },
        task = {
            ['start_shift'] = 'Start Shift',
            ['pick_grapes'] = 'Pick Grapes',
            ['load_ingrediants'] = 'Load Ingredients',
            ['wine_process'] = 'Start Wine Process',
            ['get_wine'] = 'Collect Wine',
            ['make_grape_juice'] = 'Make Grape Juice',
            ['cancel_task'] = 'You have cancelled the task',
        },
        text = {
            ['start_shift'] = 'You have started your shift at the vineyard!',
            ['end_shift'] = 'Your shift at the vineyard has ended!',
            ['pick_grapes'] = 'Pick Grapes',
        },
    },
    warnOnMissing = true,
})

return Lang
