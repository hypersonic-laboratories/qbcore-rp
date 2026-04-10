Config = {
    Weather = {
        StartingTime = 1400,
        TransitionDelay = 5, -- in seconds between weather states
        StartingWeather = 'ClearSkies',
        AnimateTime = true,
        WeatherTypes = {
            ['ClearSkies'] = WeatherType.ClearSkies,
            ['Cloudy'] = WeatherType.Cloudy,
            ['Foggy'] = WeatherType.Foggy,
            ['Overcast'] = WeatherType.Overcast,
            ['PartlyCloudy'] = WeatherType.PartlyCloudy,
            ['Rain'] = WeatherType.Rain,
            ['RainLight'] = WeatherType.RainLight,
            ['RainThunderstorm'] = WeatherType.RainThunderstorm,
            ['SandDustCalm'] = WeatherType.SandDustCalm,
            ['SandDustStorm'] = WeatherType.SandDustStorm,
            ['Snow'] = WeatherType.Snow,
            ['SnowBlizzard'] = WeatherType.SnowBlizzard,
            ['SnowLight'] = WeatherType.SnowLight,
        }
    },
    Locations = {
        apartment_lvl_1 = {
            name = 'Apartment (Lvl 1)',
            coords = Vector(567648, 552846, 4561),
        },
        apartment_lvl_2 = {
            name = 'Apartment (Lvl 2)',
            coords = Vector(537858, 518215, 4550),
        },
        apartment_lvl_3 = {
            name = 'Apartment (Lvl 3)',
            coords = Vector(549909, 527857, 4554),
        },
        apartment_lvl_4 = {
            name = 'Apartment (Lvl 4)',
            coords = Vector(581603, 510428, 4598),
        },
        apartment_lvl_5 = {
            name = 'Apartment (Lvl 5)',
            coords = Vector(522322, 564704, 4548),
        },
        clothing_shop = {
            name = 'Clothing Shop',
            coords = Vector(567648, 494029, 4572),
        },
        gas_station = {
            name = 'Gas Station',
            coords = Vector(563566, 561573, 4563),
        },
        vehicle_shop = {
            name = 'Vehicle Shop',
            coords = Vector(569726, 543631, 4558),
        },
        fishing_shop = {
            name = 'Fishing Shop',
            coords = Vector(579531, 530509, 4555),
        },
        parking_lot = {
            name = 'Parking Lot',
            coords = Vector(567508, 527357, 4568),
        },
        fishing_beach = {
            name = 'Fishing (Beach)',
            coords = Vector(606155, 628071, 4658),
        },
        fishing_docks = {
            name = 'Fishing (Docks)',
            coords = Vector(527714, 502331, 4534),
        },
        fishing_deep_sea = {
            name = 'Fishing (Deep Sea)',
            coords = Vector(627710, 627483, 4430),
        },
        mining_area = {
            name = 'Mining Area',
            coords = Vector(573774, 620580, 4533),
        },
        cinema = {
            name = 'Cinema',
            coords = Vector(568052, 503058, 4788),
        },
        shopping_mall = {
            name = 'Shopping Mall',
            coords = Vector(570247, 493493, 4756),
        },
        industrial_area = {
            name = 'Industrial Area',
            coords = Vector(561931, 599248, 4647),
        },
        casino = {
            name = 'Casino',
            coords = Vector(582568, 609758, 4584),
        },
        mechanic_shop = {
            name = 'Mechanic Shop',
            coords = Vector(569118, 562822, 4687),
        },
        restaurant = {
            name = 'Restaurant',
            coords = Vector(580196, 544639, 4549),
        },
        residential_area = {
            name = 'Residential Area',
            coords = Vector(518340, 552608, 4610),
        },
    }
}
