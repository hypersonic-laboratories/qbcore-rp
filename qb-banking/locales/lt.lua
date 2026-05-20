local Locale = exports['qb-core']:GetLocale()

local Translations = {
    success = {
        withdraw = 'Išėmimas sėkmingas',
        deposit = 'Įnešimas sėkmingas',
        transfer = 'Pervedimas sėkmingas',
        account = 'Sąskaita sukurta',
        rename = 'Sąskaita pervadinta',
        delete = 'Sąskaita ištrinta',
        userAdd = 'Vartotojas pridėtas',
        userRemove = 'Vartotojas pašalintas',
        card = 'Kortelė sukurta',
        give = 'Duota $%s grynais',
        receive = 'Gauta $%s grynais',
    },
    error = {
        error = 'Įvyko klaida',
        access = 'Nesate autorizuotas',
        account = 'Sąskaita nerasta',
        accounts = 'Sukurtas maksimalus sąskaitų skaičius',
        user = 'Vartotojas jau pridėtas',
        noUser = 'Vartotojas nerastas',
        money = 'Nepakanka pinigų',
        pin = 'Neteisingas PIN',
        card = 'Nerasta banko kortelė',
        amount = 'Neteisinga suma',
        toofar = 'Esate per toli',
    },
    progress = {
        atm = 'Jungiamasi prie bankomato',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
