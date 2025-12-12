Config = {
	Key = 'F7',
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
}