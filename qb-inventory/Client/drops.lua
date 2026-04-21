local Lang = require('Shared/locales/en')
local heldDrop = nil
CurrentDropActor = nil
CurrentDrop = nil

-- Functions

--[[ function GetDrops()
	exports['qb-core']:TriggerCallback("qb-inventory:server:GetCurrentDrops", function(drops)
		if drops then
			for k, v in pairs(drops) do
				local bag = v.entityId
				AddTargetEntity(bag, {
					options = {
						{
							icon = "backpack",
							label = Lang:t("menu.o_bag"),
							action = function()
								TriggerServerEvent("qb-inventory:server:openDrop", k)
								CurrentDrop = dropId
								CurrentDropActor = bag
							end,
						},
					},
					distance = 1000,
				})
			end
		end
	end)
end ]]

-- Events

RegisterClientEvent('qb-inventory:client:openDrop', function(data)
	CurrentDrop = data.dropId
	TriggerServerEvent('qb-inventory:server:openDrop', data.dropId)
end)

RegisterClientEvent('qb-inventory:client:holdDrop', function(dropId)
	exports['qb-core']:DrawText('Press [G] to drop Bag', 'right')
	heldDrop = dropId
end)

-- KeyPress

Input.BindKey('G', function()
	if not heldDrop then return end
	exports['qb-core']:HideText()
	TriggerServerEvent('qb-inventory:server:updateDrop', heldDrop)
	heldDrop = nil
end)
