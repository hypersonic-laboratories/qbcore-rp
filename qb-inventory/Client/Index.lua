local Lang = require('Shared/locales/en')
local player_data = {}
local hotbarShown = false
local inv_open = false
local my_webui = WebUI('Inventory', 'qb-inventory/Client/html/index.html', 0)

require('Client/drops')
require('Client/vehicles')

-- Handlers

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
	player_data = exports['qb-core']:GetPlayerData()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
	player_data = {}
end)

RegisterClientEvent('QBCore:Player:SetPlayerData', function(val)
	player_data = val
end)

RegisterClientEvent('QBCore:Player:OnFieldUpdate', function(key, value)
	if key ~= 'items' then return end
	player_data.items = value
	if inv_open and my_webui then
		my_webui:SendEvent('updateInventory', { inventory = value })
	end
end)

-- Functions

local function FormatWeaponAttachments(itemdata)
	if not itemdata.info or not itemdata.info.attachments or #itemdata.info.attachments == 0 then
		return {}
	end
	local attachments = {}
	local weaponName = itemdata.name
	local WeaponAttachments = getConfigWeaponAttachments()
	if not WeaponAttachments then
		return {}
	end
	for attachmentType, weapons in pairs(WeaponAttachments) do
		local componentHash = weapons[weaponName]
		if componentHash then
			for _, attachmentData in pairs(itemdata.info.attachments) do
				if attachmentData.component == componentHash then
					local label = QBShared.Items[attachmentType] and QBShared.Items[attachmentType].label or 'Unknown'
					attachments[#attachments + 1] = {
						attachment = attachmentType,
						label = label,
					}
				end
			end
		end
	end
	return attachments
end

-- Events

RegisterClientEvent('qb-inventory:client:requiredItems', function(items, bool)
	local itemTable = {}
	if bool then
		for k in pairs(items) do
			itemTable[#itemTable + 1] = {
				item = items[k].name,
				label = QBShared.Items[items[k].name]['label'],
				image = items[k].image,
			}
		end
	end
	if my_webui == nil then return end
	my_webui:SendEvent('requiredItem', { items = itemTable, toggle = bool })
end)

RegisterClientEvent('qb-inventory:client:hotbar', function(items)
	hotbarShown = not hotbarShown
	if my_webui == nil then return end
	my_webui:SendEvent('toggleHotbar', { open = hotbarShown, items = items })
end)

RegisterClientEvent('qb-inventory:client:closeInv', function()
	if my_webui == nil then return end
	my_webui:SendEvent('closeInventory')
end)

RegisterClientEvent('qb-inventory:client:updateInventory', function(items)
	if my_webui == nil then return end
	my_webui:SendEvent('updateInventory', { inventory = items })
end)

RegisterClientEvent('qb-inventory:client:ItemBox', function(itemData, type, amount)
	if my_webui == nil then return end
	my_webui:SendEvent('itemBox', { item = itemData, type = type, amount = amount })
end)

--[[ RegisterClientEvent('qb-inventory:client:useItem', function(bool, itemData)
	if my_webui == nil then return end
	my_webui:SendEvent('UseItemResponse', bool, itemData)
end) ]]

-- NUI Events

my_webui:RegisterEventHandler('SetInventoryData', function(data)
	TriggerServerEvent(
		'qb-inventory:server:SetInventoryData',
		data.fromInventory,
		data.toInventory,
		data.fromSlot,
		data.toSlot,
		data.fromAmount,
		data.toAmount
	)
end)

my_webui:RegisterEventHandler('CloseInventory', function(data)
	local name = data.name
	inv_open = false
	my_webui:SetStackOrder(0)
	my_webui:SetInputMode(0)
	if name then
		TriggerServerEvent('qb-inventory:server:closeInventory', name)
	elseif CurrentDrop then
		TriggerServerEvent('qb-inventory:server:closeInventory', CurrentDrop)
		CurrentDrop = nil
	else
		TriggerServerEvent('qb-inventory:server:closeInventory')
	end
end)

my_webui:RegisterEventHandler('PlayDropFail', function()
	--PlaySound(-1, 'Place_Prop_Fail', 'DLC_Dmod_Prop_Editor_Sounds', 0, 0, 1)
end)

my_webui:RegisterEventHandler('Notify', function(data)
	exports['qb-core']:Notify(data.message, data.type)
end)

my_webui:RegisterEventHandler('UseItem', function(data)
	TriggerServerEvent('qb-inventory:server:useItem', data.item)
end)

my_webui:RegisterEventHandler('DropItem', function(item, cb)
	TriggerCallback('server.createDrop', function(dropId)
		if dropId then
			cb(dropId)
		end
	end, item)
end)

my_webui:RegisterEventHandler('AttemptPurchase', function(data, cb)
	TriggerCallback('server.attemptPurchase', function(canPurchase)
		cb(canPurchase)
	end, data)
end)

my_webui:RegisterEventHandler('GiveItem', function(data, cb)
	local player, distance = exports['qb-core']:GetClosestPlayer()
	if player and distance < 500 then
		local playerId = player:GetID()
		TriggerCallback('server.giveItem', function(success)
			cb(success)
		end, playerId, data.item.name, data.amount)
	else
		exports['qb-core']:Notify(Lang:t('notify.nonb'), 'error')
	end
end)

-- qb-weapons

my_webui:RegisterEventHandler('GetWeaponData', function(cData, cb)
	local data = {
		WeaponData = QBShared.Items[cData.weapon],
		AttachmentData = FormatWeaponAttachments(cData.ItemData),
	}
	cb(data)
end)

my_webui:RegisterEventHandler('RemoveAttachment', function(data, cb)
	local ped = PlayerPedId()
	local WeaponData = data.WeaponData
	local allAttachments = getConfigWeaponAttachments()
	local Attachment = allAttachments[data.AttachmentData.attachment][WeaponData.name]
	exports['qb-core']:TriggerCallback('weapons:server:RemoveAttachment', function(NewAttachments)
		if NewAttachments ~= false then
			local Attachies = {}
			RemoveWeaponComponentFromPed(ped, joaat(WeaponData.name), joaat(Attachment))
			for _, v in pairs(NewAttachments) do
				for attachmentType, weapons in pairs(allAttachments) do
					local componentHash = weapons[WeaponData.name]
					if componentHash and v.component == componentHash then
						local label = QBShared.Items[attachmentType] and QBShared.Items[attachmentType].label
							or 'Unknown'
						Attachies[#Attachies + 1] = {
							attachment = attachmentType,
							label = label,
						}
					end
				end
			end
			local DJATA = {
				Attachments = Attachies,
				WeaponData = WeaponData,
			}
			cb(DJATA)
		else
			RemoveWeaponComponentFromPed(ped, joaat(WeaponData.name), joaat(Attachment))
		end
	end, data.AttachmentData, WeaponData)
end)

RegisterClientEvent('qb-inventory:client:openInventory', function(items, other)
	inv_open = true
	my_webui:SetInputMode(1)
	my_webui:SendEvent('openInventory', { inventory = items, slots = Config.MaxSlots, maxweight = Config.MaxWeight, other = other })
end)

-- Vending

for _, model in pairs(Config.VendingObjects) do
	exports['qb-target']:AddTargetModel(model, {
		options = {
			{
				type = 'server',
				event = 'qb-inventory:server:openVending',
				icon = 'cash-register',
				label = Lang:t('menu.vending'),
			},
		},
		distance = 1000
	})
end

-- Open UI
Input.BindKey(Config.Keybinds.Open, function()
	if inv_open then
		my_webui:SendEvent('closeInventory')
	else
		TriggerServerEvent('qb-inventory:server:openInventory')
	end
end)

Input.BindKey(Config.Keybinds.Hotbar, function()
	TriggerServerEvent('qb-inventory:server:toggleHotbar')
end)

-- Commands
--[[
Input.Register('Inventory', Config.Keybinds.Open)
Input.Register('Hotbar', Config.Keybinds.Hotbar)

Input.Bind('Inventory', InputEvent.Pressed, function()
	TriggerServerEvent('qb-inventory:server:openInventory')
	Input.SetInputEnabled(false)
end)

Input.Bind('Hotbar', InputEvent.Pressed, function()
	if Input.IsMouseEnabled() then return end
	TriggerServerEvent('qb-inventory:server:toggleHotbar')
end)

Input.Subscribe('KeyPress', function(key_name)
	if Input.IsMouseEnabled() then return end
	local index
	if key_name == 'One' then
		index = 1
	elseif key_name == 'Two' then
		index = 2
	elseif key_name == 'Three' then
		index = 3
	elseif key_name == 'Four' then
		index = 4
	elseif key_name == 'Five' then
		index = 5
	end

	if index then
		local itemData = player_data.items[index]
		if not itemData then
			return false
		end
		Events.Call('qb-inventory:client:closeInv')
		TriggerServerEvent('qb-inventory:server:useItem', itemData)
	end
end)
 ]]
