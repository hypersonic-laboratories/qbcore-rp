local Locale = exports['qb-core']:GetLocale()

local Translations = {
    headers = {
        ['bsm'] = 'Vadovo meniu - ',
    },
    body = {
        ['manage'] = 'Valdyti darbuotojus',
        ['managed'] = 'Peržiūrėti darbuotojų sąrašą',
        ['hire'] = 'Įdarbinti darbuotojus',
        ['hired'] = 'Samdyti netoliese esančius civilius',
        ['storage'] = 'Sandėlio prieiga',
        ['storaged'] = 'Atidaryti sandėlį',
        ['outfits'] = 'Aprangos',
        ['outfitsd'] = 'Peržiūrėti išsaugotas aprangas',
        ['money'] = 'Finansų valdymas',
        ['moneyd'] = 'Peržiūrėti įmonės balansą',
        ['mempl'] = 'Valdyti darbuotojus - ',
        ['mngpl'] = 'Valdyti ',
        ['grade'] = 'Pareigos: ',
        ['fireemp'] = 'Atleisti darbuotoją',
        ['hireemp'] = 'Įdarbinti darbuotojus - ',
        ['cid'] = 'Piliečio ID: ',
        ['balance'] = 'Likutis: $',
        ['deposit'] = 'Įnešti',
        ['depositd'] = 'Įnešti pinigus į sąskaitą',
        ['withdraw'] = 'Išimti',
        ['withdrawd'] = 'Išimti pinigus iš sąskaitos',
        ['depositm'] = 'Įnešti pinigus <br> Turimas likutis: $',
        ['withdrawm'] = 'Išimti pinigus <br> Turimas likutis: $',
        ['submit'] = 'Patvirtinti',
        ['amount'] = 'Suma',
        ['return'] = 'Grįžti',
        ['exit'] = 'Grįžti',
    },
    drawtext = {
        ['label'] = '[E] Atidaryti darbo valdymą',
    },
    target = {
        ['label'] = 'Vadovo meniu',
    },
    headersgang = {
        ['bsm'] = 'Gaujos valdymas - ',
    },
    bodygang = {
        ['manage'] = 'Valdyti gaujos narius',
        ['managed'] = 'Priimti arba atleisti narius',
        ['hire'] = 'Priimti narius',
        ['hired'] = 'Priimti gaujos narius',
        ['storage'] = 'Sandėlio prieiga',
        ['storaged'] = 'Atidaryti gaujos slėptuvę',
        ['outfits'] = 'Aprangos',
        ['outfitsd'] = 'Persirengti',
        ['money'] = 'Finansų valdymas',
        ['moneyd'] = 'Peržiūrėti gaujos balansą',
        ['mempl'] = 'Valdyti gaujos narius - ',
        ['mngpl'] = 'Valdyti ',
        ['grade'] = 'Rangas: ',
        ['fireemp'] = 'Atleisti',
        ['hireemp'] = 'Priimti gaujos narius - ',
        ['cid'] = 'Piliečio ID: ',
        ['balance'] = 'Likutis: $',
        ['deposit'] = 'Įnešti',
        ['depositd'] = 'Įnešti pinigus į sąskaitą',
        ['withdraw'] = 'Išimti',
        ['withdrawd'] = 'Išimti pinigus iš sąskaitos',
        ['depositm'] = 'Įnešti pinigus <br> Turimas likutis: $',
        ['withdrawm'] = 'Išimti pinigus <br> Turimas likutis: $',
        ['submit'] = 'Patvirtinti',
        ['amount'] = 'Suma',
        ['return'] = 'Grįžti',
        ['exit'] = 'Išeiti',
    },
    drawtextgang = {
        ['label'] = '[E] Atidaryti gaujos valdymą',
    },
    targetgang = {
        ['label'] = 'Gaujos meniu',
    }
}

Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
