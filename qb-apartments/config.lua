Apartments = {}
Apartments.Starting = true
Apartments.InitialOffset = 15000
Apartments.SpawnOffset = 2500
Apartments.Locations = {
	apartment1 = {
		name = 'apartment1',
		label = 'Brightside Motel',
		description = 'Residential apartments',
		coords = { 575700, 598131, 4573 },
		polyzoneBoxData = {
			heading = 180,
			length = 100,
			width = 100,
			distance = 1000,
			debug = true,
			created = false,
		},
	},
	apartment2 = {
		name = 'apartment2',
		label = 'Marlin Hotel',
		description = 'Residential apartments',
		coords = { 579492, 552078, 4549 },
		polyzoneBoxData = {
			heading = 90,
			length = 100,
			width = 100,
			distance = 1000,
			debug = true,
			created = false,
		},
	},
	apartment3 = {
		name = 'apartment3',
		label = 'Docks Condo',
		description = 'Residential apartments',
		coords = { 544686, 502562, 4562 },
		polyzoneBoxData = {
			heading = 90,
			length = 100,
			width = 100,
			distance = 1000,
			debug = true,
			created = false,
		},
	},
}

exports('qb-apartments', 'Apartments', function()
	return Apartments
end)
