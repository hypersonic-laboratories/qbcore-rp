local Locale = exports['qb-core']:GetLocale()

local Translations = {
    success = {
        you_have_been_clocked_in = 'You Have Been Clocked In',
        sold = 'You Have Sold %{amount} %{item} For $%{price}',
    },
    text = {
        toggle_duty = 'Toggle Duty',
        hand_in_package = 'Hand In Package',
        get_package = 'Get Package',
        clock_in = 'You Have Clocked In',
        clock_out = 'You Have Clocked Out',
        sell_materials = 'Sell Materials',
        price = 'Price: $%{price}',
        amount = 'Amount',
        sell = 'Sell',
    },
    error = {
        you_have_clocked_out = 'You Have Clocked Out',
        nothing_to_sell = 'You Have Nothing To Sell',
        out_of_stock = '%{item} Is Out Of Stock',
        too_far_to_sell = 'You Are Too Far Away To Sell',
        invalid_amount = 'Invalid Amount',
        inventory_full = 'You Do Not Have Enough Inventory Space',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
