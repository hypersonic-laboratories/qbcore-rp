local Locale = exports['qb-core']:GetLocale()

local Translations = {
    ['not_on_radio'] = 'You\'re not connected to a signal',
    ['joined_to_radio'] = 'You\'re connected to: %{channel}',
    ['restricted_channel_error'] = 'You can not connect to this signal!',
    ['invalid_radio'] = 'This frequency is not available.',
    ['you_on_radio'] = 'You\'re already connected to this channel',
    ['you_leave'] = 'You left the channel.',
    ['volume_radio'] = 'New volume %{value}',
    ['decrease_radio_volume'] = 'The radio is already set to maximum volume',
    ['increase_radio_volume'] = 'The radio is already set to the lowest volume',
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
