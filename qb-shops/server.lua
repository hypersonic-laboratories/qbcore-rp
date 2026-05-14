local peds = {}
local dir = debug.getinfo(1, 'S').source .. '/../' -- append trailing slash, exit file dir

-- Functions

local function readStockFile()
	local fileHandle, msg = io.open(dir .. './' .. Config.ShopsInvJsonFile, 'r')
	if not fileHandle then
		print("[qb-shops] Error: Couldn't read shops inventory", msg)
		return
	end
	local content = fileHandle:read('a')
	fileHandle:close()

	local stock = JSON.parse(content)
	return stock
end

local function checkTable(inputValue, requiredValue)
	if type(inputValue) == 'table' and type(requiredValue) == 'table' then
		for _, v in ipairs(requiredValue) do
			if inputValue[v] then
				return true
			end
		end
	elseif type(requiredValue) == 'table' then
		for _, v in ipairs(requiredValue) do
			if v == inputValue then
				return true
			end
		end
	elseif type(inputValue) == 'string' and type(requiredValue) == 'string' then
		return inputValue == requiredValue
	elseif type(inputValue) == 'table' and type(requiredValue) == 'string' then
		return inputValue[requiredValue] == true
	elseif type(inputValue) == 'string' and type(requiredValue) == 'table' then
		for _, v in ipairs(requiredValue) do
			if v == inputValue then
				return true
			end
		end
	end
	return false
end

local function saveShopInv(shop, products)
	local existingData = readStockFile()
	existingData[shop] = { products = products }
	local fileHandle = io.open(dir .. './' .. Config.ShopsInvJsonFile, 'w')
	fileHandle:write(JSON.stringify(existingData))
	fileHandle:close()
end

local function deliveryPay(source, shop)
	local Player = QBCore.Functions.GetPlayer(source)
	if not Player then
		return
	end
	local player_ped = source:GetControlledCharacter()
	local player_coords = player_ped:GetLocation()
	local deliverCoords = Config.Locations[shop].delivery
	local distance = #(player_coords - deliverCoords)
	if distance > 10 then
		return
	end
	Player.AddMoney('bank', Config.DeliveryPrice, 'qb-shops:deliveryPay')
	if math.random(100) <= 10 then
		AddItem(source, Config.RewardItem, 1, false, false, 'qb-shops:deliveryPay')
	end
end

local function UpdateShopItems(shop, itemData, amount)
	if not shop or not itemData or not amount then
		return
	end
	if not Config.Locations[shop] then
		return
	end
	if not Config.Locations[shop].useStock then
		return
	end
	Config.Locations[shop].products[itemData.slot].amount = Config.Locations[shop].products[itemData.slot].amount
		- amount
	if Config.Locations[shop].products[itemData.slot].amount < 0 then
		Config.Locations[shop].products[itemData.slot].amount = 0
	end
	saveShopInv(shop, Config.Locations[shop].products)
	--Events.BroadcastRemote('qb-shops:client:SetShopItems', shop, Config.Locations[shop].products)
end
exports('qb-shops', 'UpdateShopItems', UpdateShopItems)

-- Events

RegisterServerEvent('qb-shops:server:RestockShopItems', function(source, shop)
	if not shop then
		return
	end
	if not Config.Locations[shop] then
		return
	end
	deliveryPay(source, shop)
	if not Config.Locations[shop].useStock then
		return
	end
	local randAmount = math.random(10, 50)
	for k in pairs(Config.Locations[shop].products) do
		Config.Locations[shop].products[k].amount = Config.Locations[shop].products[k].amount + randAmount
	end
	saveShopInv(shop, Config.Locations[shop].products)
	--Events.BroadcastRemote('qb-shops:client:SetShopItems', shop, Config.Locations[shop].products)
end)

RegisterServerEvent('qb-shops:server:UpdateShopItems', function(shop, itemData, amount) -- called from inventory
	UpdateShopItems(shop, itemData, amount)
end)

RegisterServerEvent('qb-shops:server:openShop', function(source, data)
	local shopName = data.shop
	local shopData = Config.Locations[shopName]
	if not shopData then
		return
	end
	local Player = exports['qb-core']:GetPlayer(source)
	if not Player then
		return
	end
	local playerData = Player.PlayerData
	local products = shopData.products
	local items = {}

	if shopData.useStock then
		local shopInvJson = readStockFile()
		if shopInvJson then
			local shopInventory = shopInvJson[shopName]
			if shopInventory then
				for _, product in pairs(shopInventory.products) do
					local slot = product.slot
					if products[slot] then
						products[slot].amount = product.amount
					end
				end
			end
		end
	end

	for i = 1, #products do
		local curProduct = products[i]
		local addProduct = true

		if curProduct.requiredGrade and playerData.job.grade.level < curProduct.requiredGrade then
			addProduct = false
		end

		if addProduct and curProduct.requiredJob and not checkTable(playerData.job.name, curProduct.requiredJob) then
			addProduct = false
		end

		if addProduct and curProduct.requiredGang and not checkTable(playerData.gang.name, curProduct.requiredGang) then
			addProduct = false
		end

		if
			addProduct
			and curProduct.requiredLicense
			and not checkTable(playerData.metadata['licences'], curProduct.requiredLicense)
		then
			addProduct = false
		end

		if addProduct then
			curProduct.slot = #items + 1
			items[#items + 1] = curProduct
		end
	end

	exports['qb-inventory']:CreateShop({
		name = shopName,
		label = shopData.label,
		slots = shopData.slots,
		coords = shopData.coords,
		items = items,
	})
	exports['qb-inventory']:OpenShop(source, shopName)
end)
