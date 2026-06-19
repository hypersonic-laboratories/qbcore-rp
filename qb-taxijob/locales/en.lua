local Locale = exports['qb-core']:GetLocale()

local Translations = {
    target = {
        ['toggle_duty'] = 'Toggle Duty',
        ['take_vehicle'] = 'Retrieve Taxi',
        ['finish_work'] = 'Finish Working',
    },
    marker = {
        ['pickup'] = 'Taxi Pickup',
        ['pickup_description'] = 'Pick up your passenger',
        ['dropoff'] = 'Taxi Dropoff',
        ['dropoff_description'] = 'Drop off your passenger',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
