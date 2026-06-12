local Locale = exports['qb-core']:GetLocale()

local Translations = {
    target = {
        ['toggle_duty'] = 'Toggle Duty',
        ['take_vehicle'] = 'Retrieve Taxi',
        ['finish_work'] = 'Finish Working',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
