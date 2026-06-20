local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        to_far_from_door = 'You are too far away from the doorbell',
        nobody_home = 'There is nobody home..',
        nobody_at_door = 'There is nobody at the door..',
        not_owner = 'You do not own this apartment',
    },
    success = {
        receive_apart = 'You got an apartment',
        changed_apart = 'You moved apartments',
    },
    info = {
        at_the_door = 'Someone is at the door!',
    },
    text = {
        options = '[E] Apartment Options',
        enter = 'Enter Apartment',
        ring_doorbell = 'Ring Doorbell',
        logout = 'Logout Character',
        change_outfit = 'Change Outfit',
        open_stash = 'Open Stash',
        move_here = 'Move Here',
        open_door = 'Open Door',
        leave = 'Leave Apartment',
        close_menu = '⬅ Close Menu',
        tennants = 'Units',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
