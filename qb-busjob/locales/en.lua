local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        ['already_driving_bus'] = 'You are already driving a bus',
        ['not_in_bus'] = 'You are not in a bus',
        ['one_bus_active'] = 'You can only have one active bus at a time',
        ['drop_off_passengers'] = 'Drop off the passenger before you stop working',
        ['no_route'] = 'You do not have an active bus route',
        ['no_seat'] = 'There are no open seats on this bus',
        ['too_far'] = 'You are too far from the bus stop',
    },
    success = {
        ['dropped_off'] = 'Passenger dropped off. You earned $%{amount}',
        ['route_started'] = 'Bus route started',
        ['route_finished'] = 'Bus returned',
    },
    info = {
        ['goto_busstop'] = 'Go to the bus stop',
        ['board_passenger'] = '[E] Board Passenger',
        ['drop_off_passenger'] = '[E] Drop Off Passenger',
        ['bus_depot'] = 'Bus Depot',
    },
    target = {
        ['toggle_duty'] = 'Toggle Duty',
        ['take_vehicle'] = 'Retrieve Bus',
        ['finish_work'] = 'Finish Route',
    },
}

---@type { t: fun(key: string, subs?: table<string, any>): string, has: fun(key: string): boolean }
Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true,
})

return Lang
