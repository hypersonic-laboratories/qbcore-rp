local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        to_far_from_door = 'Esate per toli nuo durų skambučio',
        nobody_home = 'Niekam neatsiliepia...',
        nobody_at_door = 'Prie durų nieko nėra..',
    },
    success = {
        receive_apart = 'Jūs gavote butą',
        changed_apart = 'Jūs persikraustėte į kitą butą',
    },
    info = {
        at_the_door = 'Kažkas stovi prie durų!',
    },
    text = {
        options = '[E] Buto nustatymai',
        enter = 'Eiti į butą',
        ring_doorbell = 'Skambinti į duris',
        logout = 'Atsijungti',
        change_outfit = 'Persirengti',
        open_stash = 'Atidaryti daiktadėžę',
        move_here = 'Persikraustyti čia',
        open_door = 'Atidaryti duris',
        leave = 'Išeiti iš buto',
        close_menu = '⬅ Uždaryti meniu',
        tennants = 'Gyventojai',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
