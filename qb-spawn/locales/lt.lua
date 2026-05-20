local Locale = exports['qb-core']:GetLocale()

local Translations = {
    ui = {
        last_location = 'Paskutinė vieta',
        confirm = 'Patvirtinti',
        where_would_you_like_to_start = 'Kur norėtumėte pradėti?',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
