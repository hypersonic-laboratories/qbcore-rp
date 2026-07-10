QBCore.Functions = {}
QBCore.UsableItems = {}

function QBCore.Functions.GetIdentifier(source)
	local PlayerState = source:GetLyraPlayerState()
	return PlayerState:GetHelixUserId()
end

function QBCore.Functions.GetSource(identifier)
	for src, player in pairs(QBCore.Players) do
		if player.PlayerData.license == identifier then
			return src
		end
	end
	return 0
end

function QBCore.Functions.GetPlayer(source)
	if not source then return end
	if type(source) == 'number' then
		local player = GetPlayerById(source)
		if not player then return nil end
		return QBCore.Players[player]
	end
	return QBCore.Players[source]
end

function QBCore.Functions.GetPlayerName(source)
	if not source then return end
	if type(source) == 'number' then
		local player = GetPlayerById(source)
		if not player then return nil end
		local PlayerState = player:GetLyraPlayerState()
		return PlayerState:GetPlayerName()
	end
	local PlayerState = source:GetLyraPlayerState()
	return PlayerState:GetPlayerName()
end

function QBCore.Functions.GetPlayerByCitizenId(citizenid)
	for _, player in pairs(QBCore.Players) do
		if player.PlayerData.citizenid == citizenid then
			return player
		end
	end
	return nil
end

function QBCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
	return QBCore.Player.GetOfflinePlayer(citizenid)
end

function QBCore.Functions.GetPlayerByLicense(license)
	return QBCore.Player.GetPlayerByLicense(license)
end

function QBCore.Functions.GetOfflinePlayerByLicense(license)
	return QBCore.Player.GetOfflinePlayerByLicense(license)
end

function QBCore.Functions.GetPlayerByPhone(number)
	for _, player in pairs(QBCore.Players) do
		local charinfo = player.PlayerData.charinfo
		if charinfo.phone == number then
			return player
		end
	end
	return nil
end

function QBCore.Functions.GetPlayerByAccount(account)
	for _, player in pairs(QBCore.Players) do
		local charinfo = player.PlayerData.charinfo
		if charinfo.account == account then
			return player
		end
	end
	return nil
end

function QBCore.Functions.GetPlayerByCharInfo(property, value)
	for _, player in pairs(QBCore.Players) do
		local charinfo = player.PlayerData.charinfo
		if charinfo[property] == value then
			return player
		end
	end
	return nil
end

function QBCore.Functions.GetPlayers()
	local sources = {}
	for k in pairs(QBCore.Players) do
		sources[#sources + 1] = k
	end
	return sources
end

function QBCore.Functions.GetQBPlayers()
	return QBCore.Players
end

function QBCore.Functions.GetPlayersOnDuty(job)
	local players = {}
	local count = 0
	for src, Player in pairs(QBCore.Players) do
		local jobData = Player.PlayerData.job
		if jobData.name == job and jobData.onduty then
			players[#players + 1] = src
			count = count + 1
		end
	end
	return players, count
end

function QBCore.Functions.GetDutyCount(job)
	local count = 0
	for _, Player in pairs(QBCore.Players) do
		local jobData = Player.PlayerData.job
		if jobData.name == job and jobData.onduty then
			count = count + 1
		end
	end
	return count
end

function QBCore.Functions.CreateUseableItem(item, data)
	QBCore.UsableItems[item] = data
end

function QBCore.Functions.CanUseItem(item)
	return QBCore.UsableItems[item]
end

function QBCore.Functions.Debug(tbl)
	if HPlayer then return end
	HELIXTable.Dump(tbl)
end

function QBCore.Functions.CreateCitizenId()
	return GenerateId(3, 'string') .. GenerateId(5, 'number')
end

function QBCore.Functions.CreateAccountNumber()
	return GenerateId(10, 'number')
end

function QBCore.Functions.CreateWalletId()
	return 'WLT-' .. GenerateId(12, 'mixed')
end

function QBCore.Functions.CreatePhoneNumber()
	local areaCode = GenerateId(3, 'number')
	local prefix = GenerateId(3, 'number')
	local lineNumber = GenerateId(4, 'number')
	return areaCode .. prefix .. lineNumber
end

function QBCore.Functions.CreateFingerId()
	return string.format('FP-%s-%s-%s',
		GenerateId(3, 'mixed'),
		GenerateId(4, 'mixed'),
		GenerateId(4, 'mixed')
	)
end

function QBCore.Functions.CreateSerialNumber()
	return string.format('SN-%s-%s-%s',
		os.date('%Y'),
		GenerateId(4, 'string'):upper(),
		GenerateId(4, 'number')
	)
end

function QBCore.Functions.CreateApartmentId()
	return string.format('%s-%s%s',
		GenerateId(4, 'number'),
		GenerateId(3, 'number'),
		GenerateId(1, 'string')
	)
end

function QBCore.Functions.GeneratePlate()
	return string.format('%s%s%s',
		GenerateId(1, 'number'),
		GenerateId(3, 'string'),
		GenerateId(3, 'number')
	)
end

function QBCore.Functions.CreateVehicle(vehicle_name, coords, rotation, plate, fuel)
	local vehicleData = QBCore.Shared.Vehicles[vehicle_name]
	if not vehicleData then return end
	if not rotation then rotation = Rotator(0, 0, 0) end
	local vehicle = HVehicle(coords, rotation, vehicleData.asset_name, vehicleData.collision_type, vehicleData.gravity_enabled)
	if fuel then vehicle:SetFuel(fuel) else vehicle:SetFuel(100.0) end
	vehicle:SetEngineHealth(1.0)
	return vehicle
end

for functionName, func in pairs(QBCore.Functions) do
	if type(func) == 'function' then
		exports('qb-core', functionName, func)
	end
end
