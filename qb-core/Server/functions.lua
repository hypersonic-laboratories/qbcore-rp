QBCore.Functions = {}
QBCore.Player_Buckets = {}
QBCore.Entity_Buckets = {}
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

function QBCore.Functions.DebugServer(tbl)
	if HPlayer then return end
	HELIXTable.Dump(tbl)
end

function QBCore.Functions.NotifyPlayer(source, message, type, length, icon)
	if HPlayer then return end
	TriggerClientEvent(source, 'QBCore:Notify', message, type, length, icon)
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

function QBCore.Functions.CreateWeapon(weapon_name, coords, rotation, itemInfo)

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

function QBCore.Functions.SetMethod(methodName, handler)
	if type(methodName) ~= 'string' then
		return false, 'invalid_method_name'
	end
	QBCore.Functions[methodName] = handler
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.SetField(fieldName, data)
	if type(fieldName) ~= 'string' then
		return false, 'invalid_field_name'
	end
	QBCore[fieldName] = data
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.AddJob(jobName, job)
	if type(jobName) ~= 'string' then
		return false, 'invalid_job_name'
	end
	if QBCore.Shared.Jobs[jobName] then
		return false, 'job_exists'
	end
	QBCore.Shared.Jobs[jobName] = job
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.AddJobs(jobs)
	local shouldContinue = true
	local message = 'success'
	local errorItem = nil
	for key, value in pairs(jobs) do
		if type(key) ~= 'string' then
			message = 'invalid_job_name'
			shouldContinue = false
			errorItem = value
			break
		end
		if QBCore.Shared.Jobs[key] then
			message = 'job_exists'
			shouldContinue = false
			errorItem = value
			break
		end
		QBCore.Shared.Jobs[key] = value
	end
	if not shouldContinue then
		return false, message, errorItem
	end
	TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Jobs', jobs)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, message, nil
end

function QBCore.Functions.RemoveJob(jobName)
	if type(jobName) ~= 'string' then
		return false, 'invalid_job_name'
	end
	if not QBCore.Shared.Jobs[jobName] then
		return false, 'job_not_exists'
	end
	QBCore.Shared.Jobs[jobName] = nil
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Jobs', jobName, nil)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.UpdateJob(jobName, job)
	if type(jobName) ~= 'string' then
		return false, 'invalid_job_name'
	end
	if not QBCore.Shared.Jobs[jobName] then
		return false, 'job_not_exists'
	end
	QBCore.Shared.Jobs[jobName] = job
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.AddItem(itemName, item)
	if type(itemName) ~= 'string' then
		return false, 'invalid_item_name'
	end
	if QBCore.Shared.Items[itemName] then
		return false, 'item_exists'
	end
	QBCore.Shared.Items[itemName] = item
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, item)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.UpdateItem(itemName, item)
	if type(itemName) ~= 'string' then
		return false, 'invalid_item_name'
	end
	if not QBCore.Shared.Items[itemName] then
		return false, 'item_not_exists'
	end
	QBCore.Shared.Items[itemName] = item
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, item)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.AddItems(items)
	local shouldContinue = true
	local message = 'success'
	local errorItem = nil
	for key, value in pairs(items) do
		if type(key) ~= 'string' then
			message = 'invalid_item_name'
			shouldContinue = false
			errorItem = value
			break
		end
		if QBCore.Shared.Items[key] then
			message = 'item_exists'
			shouldContinue = false
			errorItem = value
			break
		end
		QBCore.Shared.Items[key] = value
	end
	if not shouldContinue then
		return false, message, errorItem
	end
	TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Items', items)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, message, nil
end

function QBCore.Functions.RemoveItem(itemName)
	if type(itemName) ~= 'string' then
		return false, 'invalid_item_name'
	end
	if not QBCore.Shared.Items[itemName] then
		return false, 'item_not_exists'
	end
	QBCore.Shared.Items[itemName] = nil
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, nil)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.AddGang(gangName, gang)
	if type(gangName) ~= 'string' then
		return false, 'invalid_gang_name'
	end
	if QBCore.Shared.Gangs[gangName] then
		return false, 'gang_exists'
	end
	QBCore.Shared.Gangs[gangName] = gang
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.AddGangs(gangs)
	local shouldContinue = true
	local message = 'success'
	local errorItem = nil
	for key, value in pairs(gangs) do
		if type(key) ~= 'string' then
			message = 'invalid_gang_name'
			shouldContinue = false
			errorItem = value
			break
		end
		if QBCore.Shared.Gangs[key] then
			message = 'gang_exists'
			shouldContinue = false
			errorItem = value
			break
		end
		QBCore.Shared.Gangs[key] = value
	end
	if not shouldContinue then
		return false, message, errorItem
	end
	TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Gangs', gangs)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, message, nil
end

function QBCore.Functions.RemoveGang(gangName)
	if type(gangName) ~= 'string' then
		return false, 'invalid_gang_name'
	end
	if not QBCore.Shared.Gangs[gangName] then
		return false, 'gang_not_exists'
	end
	QBCore.Shared.Gangs[gangName] = nil
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Gangs', gangName, nil)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.UpdateGang(gangName, gang)
	if type(gangName) ~= 'string' then
		return false, 'invalid_gang_name'
	end
	if not QBCore.Shared.Gangs[gangName] then
		return false, 'gang_not_exists'
	end
	QBCore.Shared.Gangs[gangName] = gang
	TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

function QBCore.Functions.SetPlayerBucket(source, bucket)
	if source and bucket then
		local plicense = QBCore.Functions.GetIdentifier(source)
		source:SetValue('instance', bucket, true)
		source:SetDimension(bucket)
		QBCore.Player_Buckets[plicense] = { id = source, bucket = bucket }
		return true
	else
		return false
	end
end

function QBCore.Functions.AddPlayerMethod(ids, methodName, handler)
	local idType = type(ids)
	if idType == 'number' then
		if ids == -1 then
			for _, v in pairs(QBCore.Players) do
				v:AddMethod(methodName, handler)
			end
		else
			local p = QBCore.Players[ids]
			if not p then return end
			p:AddMethod(methodName, handler)
		end
	elseif idType == 'table' and table.type(ids) == 'array' then
		for i = 1, #ids do
			QBCore.Functions.AddPlayerMethod(ids[i], methodName, handler)
		end
	end
end

function QBCore.Functions.AddPlayerField(ids, fieldName, data)
	local idType = type(ids)
	if idType == 'number' then
		if ids == -1 then
			for _, v in pairs(QBCore.Players) do
				v:AddField(fieldName, data)
			end
		else
			local p = QBCore.Players[ids]
			if not p then return end
			p:AddField(fieldName, data)
		end
	elseif idType == 'table' and table.type(ids) == 'array' then
		for i = 1, #ids do
			QBCore.Functions.AddPlayerField(ids[i], fieldName, data)
		end
	end
end

for functionName, func in pairs(QBCore.Functions) do
	if type(func) == 'function' then
		exports('qb-core', functionName, func)
	end
end
