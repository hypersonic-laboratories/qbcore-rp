---@class QBCore.Functions
QBCore.Functions = {}

---@type table<string, {id: HPlayer, bucket: number}> player buckets by identifier
QBCore.Player_Buckets = {}

---@type table<string, function> usable items (function not sure, probably not since the parameter given to the function is called "data"
---therefor a table, but to remember this when changin the parameter to the actual type defined as function until more information is given)
QBCore.UsableItems = {}

-- Getter Functions

---Returns the HELIX identifier for the given HPlayer object
---@nodiscard
---@param source HPlayer the HELIX player object (see HELIX documentation for more info)
---@return string identifier the HELIX identifier
function QBCore.Functions.GetIdentifier(source)
	local PlayerState = source:GetLyraPlayerState()
	return PlayerState:GetHelixUserId()
end

---Returns the HPlayer object for the given HELIX identifier.
---If the player is not found, nil is returned.
---@nodiscard
---@param identifier string the HELIX identifier
---@return HPlayer? source the HELIX player object (see HELIX documentation for more info)
function QBCore.Functions.GetSource(identifier)
	for src in pairs(QBCore.Players) do
		if QBCore.Players[src].PlayerData.license == identifier then
			return src
		end
	end
	return nil
end

---Returns the QBCore.Player object for the given source.
---If the player is not found, nil is returned.
---@nodiscard
---@param source HPlayer the HELIX player object (see HELIX documentation for more info)
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetPlayer(source)
	if not source then return end
	return QBCore.Players[source]
end

---Returns the HELIX! player name for the given source.
---@param source HPlayer the HELIX player object (see HELIX documentation for more info)
---@return string playerName the player's name
function QBCore.Functions.GetPlayerName(source)
	local PlayerState = source:GetLyraPlayerState()
	return PlayerState:GetPlayerName()
end

---Returns the QBCore.Player object for the given citizenid.
---If the player is not found, nil is returned.
---The owner of the character has to be online for this to work.
---@nodiscard
---@param citizenid string the citizenid of the player
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetPlayerByCitizenId(citizenid)
	for src in pairs(QBCore.Players) do
		if QBCore.Players[src].PlayerData.citizenid == citizenid then
			return QBCore.Players[src]
		end
	end
	return nil
end

---Returns the offline QBCore.Player object for the given citizenid.
---If the player is not found, nil is returned.
---For this to work, the player does not have to be online.
---@nodiscard
---@param citizenid string the citizenid of the player
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
	return QBCore.Player.GetOfflinePlayer(citizenid)
end

---Returns the QBCore.Player object for the given player license.
---If the player with that license is not online nil is returned.
---@nodiscard
---@param license string the license of the player
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetPlayerByLicense(license)
	return QBCore.Player.GetPlayerByLicense(license)
end

---Returns the QBCore.Player object for the given phone number.
---If no player with that phone number is online, nil is returned.
---@nodiscard
---@param number string the phone number of the player to search for
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetPlayerByPhone(number)
	for src in pairs(QBCore.Players) do
		if QBCore.Players[src].PlayerData.charinfo.phone == number then
			return QBCore.Players[src]
		end
	end
	return nil
end

---Returns the QBCore.Player object for the given banking account name.
---If no player with that account name is online, nil is returned.
---@nodiscard
---@param account string the banking account name of the player to search for
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetPlayerByAccount(account)
	for src in pairs(QBCore.Players) do
		if QBCore.Players[src].PlayerData.charinfo.account == account then
			return QBCore.Players[src]
		end
	end
	return nil
end

---Searches for a player by a specific property in their charinfo.
---If no player with that property value is online, nil is returned.
---@nodiscard
---@param property string the property in charinfo to search by
---@param value any the value of the property to search for
---@return QBCore.Player? player the QBCore.Player object
function QBCore.Functions.GetPlayerByCharInfo(property, value)
	for src in pairs(QBCore.Players) do
		local charinfo = QBCore.Players[src].PlayerData.charinfo
		if charinfo[property] ~= nil and charinfo[property] == value then
			return QBCore.Players[src]
		end
	end
	return nil
end

---Returns a list with the sources of all online players.
---@nodiscard
---@return table<HPlayer> sources a list with the sources of all online players
function QBCore.Functions.GetPlayers()
	local sources = {}
	for k in pairs(QBCore.Players) do
		sources[#sources + 1] = k
	end
	return sources
end

---Returns a map with all online QBCore.Player objects.
---The keys are the HPlayer objects and the values are the QBCore.Player objects for those sources.
---@nodiscard
---@return table<HPlayer, QBCore.Player> players a list with all online QBCore.Player objects
function QBCore.Functions.GetQBPlayers()
	return QBCore.Players
end

---Returns a list with the sources (HPlayer) of all online players on duty for the given job.
---Also returns the count of players on duty for that job.
---@nodiscard
---@param job string the job name to search for
---@return table<HPlayer> players a list with the sources of all online players on duty for the given job
---@return number count the count of players on duty for that job
function QBCore.Functions.GetPlayersOnDuty(job)
	local players = {}
	local count = 0
	for src, Player in pairs(QBCore.Players) do
		if Player.PlayerData.job.name == job then
			if Player.PlayerData.job.onduty then
				players[#players + 1] = src
				count = count + 1
			end
		end
	end
	return players, count
end

---Returns the count of online players on duty for the given job.
---@nodiscard
---@param job string the job name to search for
---@return number count the count of players on duty for that job
function QBCore.Functions.GetDutyCount(job)
	local count = 0
	for _, Player in pairs(QBCore.Players) do
		if Player.PlayerData.job.name == job then
			if Player.PlayerData.job.onduty then
				count = count + 1
			end
		end
	end
	return count
end

---Creates a new usable item with the given item name and data.
---@param item string the item name to register as usable
---@param data function the function to call when the item is used
function QBCore.Functions.CreateUseableItem(item, data)
	QBCore.UsableItems[item] = data
end

---Checks if the given item is registered as usable.
---@nodiscard
---@param item string the item name to check
---@return boolean canUse true if the item is usable, false otherwise
function QBCore.Functions.CanUseItem(item)
	return QBCore.UsableItems[item]
end

---Debugs the given table by dumping its contents to the console.
---This function only works if HPlayer is not defined (WHY???).
---@param tbl table the table to debug
function QBCore.Functions.Debug(tbl)
	if HPlayer then return end
	HELIXTable.Dump(tbl)
end

---Sends a notification to the given source.
---This function only works if HPlayer is not defined (WHY???).
---@param source HPlayer the HELIX player object (see HELIX documentation for more info)
---@param message string the message to send
---@param type string the type of notification (e.g., 'success', 'error', 'info')
---@param length number the length of time the notification should be displayed (in milliseconds)
---@param icon string the icon to display with the notification
function QBCore.Functions.Notify(source, message, type, length, icon)
	if HPlayer then return end
	TriggerClientEvent('QBCore:Notify', source, message, type, length, icon)
end

---Creates a new citizen ID.
---@nodiscard
---@return string citizenId the newly created citizen ID
function QBCore.Functions.CreateCitizenId()
	return GenerateId(3, 'string') .. GenerateId(5, 'number')
end

---Creates a new account number. (for banking?)
---@nodiscard
---@return string accountNumber the newly created account number
function QBCore.Functions.CreateAccountNumber()
	return GenerateId(10, 'number')
end

---Creates a new wallet ID. (for what?)
---@nodiscard
---@return string walletId the newly created wallet ID
function QBCore.Functions.CreateWalletId()
	return 'WLT-' .. GenerateId(12, 'mixed')
end

---Creates a new phone number.
---@nodiscard
---@return string phoneNumber the newly created phone number
function QBCore.Functions.CreatePhoneNumber()
	local areaCode = GenerateId(3, 'number')
	local prefix = GenerateId(3, 'number')
	local lineNumber = GenerateId(4, 'number')
	return areaCode .. prefix .. lineNumber
end

---Creates a new fingerprint ID.
---@nodiscard
---@return string fingerId the newly created fingerprint ID
function QBCore.Functions.CreateFingerId()
	return string.format('FP-%s-%s-%s',
		GenerateId(3, 'mixed'),
		GenerateId(4, 'mixed'),
		GenerateId(4, 'mixed')
	)
end

---Creates a new serial number. (for weapons, phones, etc.)
---@nodiscard
---@return string serialNumber the newly created serial number
function QBCore.Functions.CreateSerialNumber()
	return string.format('SN-%s-%s-%s',
		os.date('%Y'),
		GenerateId(4, 'string'):upper(),
		GenerateId(4, 'number')
	)
end

---Creates a new apartment ID.
---@nodiscard
---@return string apartmentId the newly created apartment ID
function QBCore.Functions.CreateApartmentId()
	return string.format('%s-%s%s',
		GenerateId(4, 'number'),
		GenerateId(3, 'number'),
		GenerateId(1, 'string')
	)
end

---Generates a new vehicle plate.
---@nodiscard
---@return string plate the newly created vehicle plate
function QBCore.Functions.GeneratePlate()
	return string.format('%s%s%s',
		GenerateId(1, 'number'),
		GenerateId(3, 'string'),
		GenerateId(3, 'number')
	)
end

---Dose nothing (literally empty).
---@param weapon_name any
---@param coords any
---@param rotation any
---@param itemInfo any
function QBCore.Functions.CreateWeapon(weapon_name, coords, rotation, itemInfo)

end

---Creates a new vehicle with the given parameters.
---@nodiscard
---@param vehicle_name string the name of the vehicle to create
---@param coords Vector the coordinates to spawn the vehicle at
---@param rotation Rotator? the rotation to spawn the vehicle with (default: Rotator(0, 0, 0))
---@param plate nil this is completely ignored
---@param fuel number? the fuel level to set the vehicle to (0.0 - 1.0, default: 1.0)
---@return HVehicle? vehicle the created vehicle object (see HELIX documentation for more info)
function QBCore.Functions.CreateVehicle(vehicle_name, coords, rotation, plate, fuel)
	local vehicleData = QBCore.Shared.Vehicles[vehicle_name]
	if not vehicleData then return end
	if not rotation then rotation = Rotator(0, 0, 0) end
	local vehicle = HVehicle(coords, rotation, vehicleData.asset_name, vehicleData.collision_type, vehicleData.gravity_enabled)
	if fuel then vehicle:SetFuel(fuel) else vehicle:SetFuel(1.0) end
	vehicle:SetEngineHealth(1.0)
	return vehicle
end

---Adds / Replaces a method in the QBCore.Functions table.
---Triggers 'QBCore:Server:UpdateObject' after adding / replacing the method.
---@nodiscard
---@param methodName string the name of the method to add / replace
---@param handler function the function to set as the method
---@return boolean success true if the method was added / replaced successfully, false otherwise
---@return string message the result message
function QBCore.Functions.SetMethod(methodName, handler)
	if type(methodName) ~= 'string' then
		return false, 'invalid_method_name'
	end
	QBCore.Functions[methodName] = handler
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

---Adds / Replaces a field in the QBCore table.
---Triggers 'QBCore:Server:UpdateObject' after adding / replacing the field.
---@nodiscard
---@param fieldName string the name of the field to add / replace
---@param data any the data to set as the field
---@return boolean success true if the field was added / replaced successfully, false otherwise
---@return string message the result message
function QBCore.Functions.SetField(fieldName, data)
	if type(fieldName) ~= 'string' then
		return false, 'invalid_field_name'
	end
	QBCore[fieldName] = data
	TriggerLocalServerEvent('QBCore:Server:UpdateObject')
	return true, 'success'
end

---Adds a new job to the QBCore.Shared.Jobs table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after adding the job.
---@nodiscard
---@param jobName string the name of the job to add
---@param job QBCore.JobInfo the job data to add
---@return boolean success true if the job was added successfully, false otherwise
---@return string message the result message
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

---Adds multiple new jobs to the QBCore.Shared.Jobs table.
---Triggers 'QBCore:Client:OnSharedUpdateMultiple' and 'QBCore:Server:UpdateObject' after adding the jobs.
---@nodiscard
---@param jobs table<string, QBCore.JobInfo> the jobs to add
---@return boolean success true if the jobs were added successfully, false otherwise
---@return string message the result message
---@return QBCore.JobInfo? errorItem the job that caused the error, if any
function QBCore.Functions.AddJobs(jobs)
	local shouldContinue = true
	local message = 'success'
	local errorItem = nil
	for key, value in pairs(jobs) do
		if type(key) ~= 'string' then
			message = 'invalid_job_name'
			shouldContinue = false
			errorItem = jobs[key]
			break
		end
		if QBCore.Shared.Jobs[key] then
			message = 'job_exists'
			shouldContinue = false
			errorItem = jobs[key]
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

---Removes a job from the QBCore.Shared.Jobs table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after removing the job.
---@nodiscard
---@param jobName string the name of the job to remove
---@return boolean success true if the job was removed successfully, false otherwise
---@return string message the result message
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

---Updates an existing job in the QBCore.Shared.Jobs table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after updating the job.
---@nodiscard
---@param jobName string the name of the job to update
---@param job QBCore.JobInfo the new job data
---@return boolean success true if the job was updated successfully, false otherwise
---@return string message the result message
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

---Adds a new item to the QBCore.Shared.Items table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after adding the item.
---@nodiscard
---@param itemName string the name of the item to add
---@param item QBCore.Item the item data to add
---@return boolean success true if the item was added successfully, false otherwise
---@return string message the result message
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

---Updates an existing item in the QBCore.Shared.Items table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after updating the item.
---@nodiscard
---@param itemName string the name of the item to update
---@param item QBCore.Item the new item data
---@return boolean success true if the item was updated successfully, false otherwise
---@return string message the result message
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

---Adds multiple new items to the QBCore.Shared.Items table.
---Triggers 'QBCore:Client:OnSharedUpdateMultiple' and 'QBCore:Server:UpdateObject' after adding the items.
---@nodiscard
---@param items table<string, QBCore.Item> the items to add
---@return boolean success true if the items were added successfully, false otherwise
---@return string message the result message
function QBCore.Functions.AddItems(items)
	local shouldContinue = true
	local message = 'success'
	local errorItem = nil
	for key, value in pairs(items) do
		if type(key) ~= 'string' then
			message = 'invalid_item_name'
			shouldContinue = false
			errorItem = items[key]
			break
		end
		if QBCore.Shared.Items[key] then
			message = 'item_exists'
			shouldContinue = false
			errorItem = items[key]
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

---Removes an item from the QBCore.Shared.Items table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after removing the item.
---@nodiscard
---@param itemName string the name of the item to remove
---@return boolean success true if the item was removed successfully, false otherwise
---@return string message the result message
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

---Adds a new gang to the QBCore.Shared.Gangs table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after adding the gang.
---@nodiscard
---@param gangName string the name of the gang to add
---@param gang QBCore.GangInfo the gang data to add
---@return boolean success true if the gang was added successfully, false otherwise
---@return string message the result message
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

---Adds multiple new gangs to the QBCore.Shared.Gangs table.
---Triggers 'QBCore:Client:OnSharedUpdateMultiple' and 'QBCore:Server:UpdateObject' after adding the gangs.
---@nodiscard
---@param gangs table<string, QBCore.GangInfo> the gangs to add
---@return boolean success true if the gangs were added successfully, false otherwise
---@return string message the result message
---@return QBCore.GangInfo? errorItem the gang that caused the error, if any
function QBCore.Functions.AddGangs(gangs)
	local shouldContinue = true
	local message = 'success'
	local errorItem = nil
	for key, value in pairs(gangs) do
		if type(key) ~= 'string' then
			message = 'invalid_gang_name'
			shouldContinue = false
			errorItem = gangs[key]
			break
		end
		if QBCore.Shared.Gangs[key] then
			message = 'gang_exists'
			shouldContinue = false
			errorItem = gangs[key]
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

---Removes a gang from the QBCore.Shared.Gangs table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after removing the gang.
---@nodiscard
---@param gangName string the name of the gang to remove
---@return boolean success true if the gang was removed successfully, false otherwise
---@return string message the result message
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

---Updates an existing gang in the QBCore.Shared.Gangs table.
---Triggers 'QBCore:Client:OnSharedUpdate' and 'QBCore:Server:UpdateObject' after updating the gang.
---@param gangName string the name of the gang to update
---@param gang QBCore.GangInfo the new gang data
---@return boolean success true if the gang was updated successfully, false otherwise
---@return string message the result message
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

---Sets the player's bucket (instance) to the given bucket number.
---Also updates the player's dimension to match the bucket.
---@nodiscard
---@param source HPlayer the HELIX player object (see HELIX documentation for more info)
---@param bucket number the bucket number to set the player to
---@return boolean success true if the player's bucket was set successfully, false otherwise
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

---Adds a new method to the specified players.
---@param ids number|table<number> the source(s) of the player(s) to add
---@param methodName string the name of the method to add
---@param handler function the function to set as the method
function QBCore.Functions.AddPlayerMethod(ids, methodName, handler)
	local idType = type(ids)
	if idType == 'number' then
		if ids == -1 then
			for _, v in pairs(QBCore.Players) do
				v.Functions.AddMethod(methodName, handler)
			end
		else
			if not QBCore.Players[ids] then
				return
			end

			QBCore.Players[ids].Functions.AddMethod(methodName, handler)
		end
	elseif idType == 'table' and table.type(ids) == 'array' then
		for i = 1, #ids do
			QBCore.Functions.AddPlayerMethod(ids[i], methodName, handler)
		end
	end
end

---Adds a new field to the specified players.
---@param ids number|table<number> the source(s) of the player(s) to add
---@param fieldName string the name of the field to add
---@param data any the data to set as the field
function QBCore.Functions.AddPlayerField(ids, fieldName, data)
	local idType = type(ids)
	if idType == 'number' then
		if ids == -1 then
			for _, v in pairs(QBCore.Players) do
				v.Functions.AddField(fieldName, data)
			end
		else
			if not QBCore.Players[ids] then
				return
			end

			QBCore.Players[ids].Functions.AddField(fieldName, data)
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
