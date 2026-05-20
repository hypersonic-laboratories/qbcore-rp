local Locale = exports['qb-core']:GetLocale()

local Translations = {
    ['not_on_radio'] = 'Nesate prisijungę prie kanalo',
    ['joined_to_radio'] = 'Prisijungėte prie: %{channel}',
    ['restricted_channel_error'] = 'Negalite prisijungti prie šio kanalo!',
    ['invalid_radio'] = 'Šis dažnis nepasiekiamas.',
    ['you_on_radio'] = 'Jau esate prisijungę prie šio kanalo',
    ['you_leave'] = 'Palikote kanalą.',
    ['volume_radio'] = 'Naujas garsumas %{value}',
    ['decrease_radio_volume'] = 'Radijas jau nustatytas į maksimalų garsumą',
    ['increase_radio_volume'] = 'Radijas jau nustatytas į minimalų garsumą',
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
