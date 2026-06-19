local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        negative = 'Trying to sell a negative amount?',
        no_melt = 'You didn\'t give me anything to melt...',
        no_items = 'Not enough items',
        inventory_full = 'Inventory too full to receive all possible items. Try making sure inventory isn\'t full next time. Items Lost: %{value}',
        already_melting = 'You already have items melting.',
        invalid_item = 'I can\'t take that item.',
    },
    success = {
        sold = 'You have sold %{value} x %{value2} for $%{value3}',
        items_received = 'You received %{value} x %{value2}',
    },
    info = {
        title = 'Pawn Shop',
        subject = 'Melting Items',
        message = 'We finished melting your items. You can come pick them up at any time.',
        sell = 'Sell Items',
        sell_pawn = 'Sell Items To The Pawn Shop',
        melt = 'Melt Items',
        melt_pawn = 'Open the Melting Shop',
        melt_pickup = 'Pickup Melted Items',
        pawn_closed = 'Pawnshop is closed. Come back between %{value}:00 AM - %{value2}:00 PM',
        sell_items = 'Selling Price $%{value}',
        back = 'Go Back',
        melt_item = 'Melt %{value}',
        max = 'Max Amount %{value}',
        submit = 'Melt',
        melt_wait = 'Give me %{value} minutes and I\'ll have your stuff melted',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
