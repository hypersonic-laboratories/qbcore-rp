local Locale = exports['qb-core']:GetLocale()

local Translations = {
    target = {
        ['toggle_duty'] = 'Toggle Duty',
        ['take_vehicle'] = 'Retrieve Taxi',
        ['finish_work'] = 'Finish Working',
    }
}

Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
