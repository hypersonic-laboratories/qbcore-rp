local Locale = exports['qb-core']:GetLocale()

local Translations = {
    ui = {
        last_location = 'Last Location',
        confirm = 'Confirm',
        where_would_you_like_to_start = 'Where would you like to start?',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
