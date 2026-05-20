local Locale = exports['qb-core']:GetLocale()

local Translations = {
    error = {
        no_vehicles = 'Šioje vietoje nėra transporto priemonių!',
        not_depot = 'Jūsų transporto priemonė nėra depozite',
        not_owned = 'Šios transporto priemonės negalima laikyti',
        not_correct_type = 'Šio tipo transporto priemonės čia laikyti negalite',
        not_enough = 'Nepakanka pinigų',
        no_garage = 'Nėra',
        vehicle_occupied = 'Negalite pastatyti šios transporto priemonės, nes joje kas nors sėdi',
        vehicle_not_tracked = 'Nepavyko surasti transporto priemonės',
        no_spawn = 'Aplinka per pilna',
    },
    success = {
        vehicle_parked = 'Transporto priemonė pastatyta',
        vehicle_tracked = 'Transporto priemonė surasta',
    },
    status = {
        out = 'Naudojama',
        garaged = 'Garaže',
        impound = 'Policijos konfiskuota',
        house = 'Namas',
    },
    info = {
        car_e = 'E - Garažas',
        sea_e = 'E - Prieplauka',
        air_e = 'E - Angaras',
        rig_e = 'E - Platformos aikštelė',
        depot_e = 'E - Depas',
        house_garage = 'E - Namų garažas',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

return Lang
