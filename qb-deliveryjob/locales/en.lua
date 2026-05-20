local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        too_far = 'You are too far away from the location.',
        inside_vehicle = 'You cannot deliver packages when in a vehicle.',
        no_packages = 'You don\'t have any more packages.',
    },
    success = {
        paid = 'Route Completed! You were paid: %{Amount}',
        incomplete_paid = 'You didn\'t complete your route. You were paid: %{Amount}'
    },
    status = {
        location_info = 'Stop: %{Current}/%{Max}'
    },
    info = {
        start_delivering = 'Start Delivering',
        pickup_box = 'Pickup Box',
        deliver_package = '[E] Deliver Package',
        finish_delivering = 'Finish Route',
    }
}

Lang = Lang or Locale.new({
    phrases = Translations,
    warnOnMissing = true
})
