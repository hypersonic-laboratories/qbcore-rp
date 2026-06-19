local Lang = require('locales/en')
local sharedItems = exports['qb-core']:GetShared('Items')

local carryPackage = nil
local packageCoords = nil
local onDuty = false
local registered = false
local props = {}
local registeredZones = {}
local registeredTargets = {}
local markerIds = {}
local sellPeds = {}

local function Notify(text, notifyType, length)
    exports['qb-core']:Notify(text, notifyType or 'primary', length)
end

local function AddMapMarker(coords, marker)
    local markerId = exports['qb-hud']:AddMarker(coords, {
        title = marker.label or 'Recycle Center',
        description = marker.description or '',
        icon = marker.blipIcon or marker.icon or 'recycling',
        markerType = marker.markerType or 'Store',
        color = marker.blipColor or marker.color,
    })

    if markerId then
        markerIds[#markerIds + 1] = markerId
    end
end

local function AddTargetEntity(entity, options, distance)
    if not entity then
        return
    end

    exports['qb-target']:AddTargetEntity(entity, {
        options = options,
        distance = distance or Config.TargetDistance,
    })
    registeredTargets[#registeredTargets + 1] = entity
end

local function ClearRegisteredTargets()
    for _, entity in ipairs(registeredTargets) do
        exports['qb-target']:RemoveTargetEntity(entity)
    end
    registeredTargets = {}
end

local function IsValidActor(actor)
    return actor and (not actor.IsValid or actor:IsValid())
end

local function GetRandomPackage()
    if #Config.PickupLocations == 0 then
        packageCoords = nil
        return
    end

    packageCoords = math.random(1, #Config.PickupLocations)
end

local function DropPackage()
    if IsValidActor(carryPackage) then
        DetachActor(carryPackage, {
            Location = DetachmentRule.KeepWorld,
            Rotation = DetachmentRule.KeepWorld,
        })
        DeleteEntity(carryPackage)
    end

    carryPackage = nil
end

local function PickupPackage()
    local pawn = GetPlayerPawn()
    if not pawn then
        return
    end

    local pawnCoords = GetEntityCoords(pawn)
    local package = StaticMesh(pawnCoords, Rotator(), Config.CarryPackageMesh, CollisionType.NoCollision, false)
    if not package or not package.Object then
        return
    end

    carryPackage = package.Object
    carryPackage:SetActorScale3D(Config.CarryPackageScale or Vector(0.35, 0.35, 0.35))

    local mesh = pawn:GetCharacterBaseMesh()
    if mesh then
        AttachActorToComponent(carryPackage, mesh, Config.CarryPackageOffset or Vector(-35, 0, 10), Config.CarryPackageRotation or Rotator(-95, 0, 0), 'hand_r', {
            Location = AttachmentRule.SnapToTarget,
            Rotation = AttachmentRule.SnapToTarget,
            Scale = AttachmentRule.KeepWorld,
        })
    end
end

local function ToggleDuty()
    if onDuty then
        Notify(Lang.t('text.clock_out'), 'success')
        onDuty = false
        packageCoords = nil
        return
    end

    Notify(Lang.t('text.clock_in'), 'success')
    onDuty = true
    GetRandomPackage()
end

local function PickUp(index)
    if not onDuty or carryPackage then
        return
    end

    index = tonumber(index)
    if not index or index ~= packageCoords then
        return
    end

    packageCoords = nil
    PickupPackage()
end

local function HandInPackage()
    if not carryPackage then
        return
    end

    DropPackage()
    TriggerServerEvent('qb-recyclejob:server:getItem')
    GetRandomPackage()
end

local function SellMaterials()
    TriggerCallback('qb-recyclejob:server:getPriceList', function(data)
        if data == false then
            Notify(Lang.t('error.too_far_to_sell'), 'error')
            return
        end

        if not data or #data == 0 then
            Notify(Lang.t('error.nothing_to_sell'), 'error')
            return
        end

        local menu = {
            {
                header = Lang.t('text.sell_materials'),
                isMenuHeader = true,
            },
        }

        for _, entry in ipairs(data) do
            local item = sharedItems[entry.item] or { label = entry.item, name = entry.item }
            menu[#menu + 1] = {
                header = item.label,
                txt = Lang.t('text.price', { price = entry.price }) .. ' | ' .. Lang.t('text.amount') .. ': ' .. tostring(entry.amount),
                params = {
                    event = 'qb-recyclejob:server:sellItem',
                    isServer = true,
                    args = {
                        item = entry.item,
                        amount = entry.amount,
                    },
                },
            }
        end

        exports['qb-menu']:openMenu(menu)
    end)
end

local function AddZone(name, coords, heading, label, eventName, canInteract)
    exports['qb-target']:AddBoxZone(name, coords, Config.ZoneLength, Config.ZoneWidth, {
        name = name,
        heading = heading or 0.0,
        minZ = coords.Z - 120,
        maxZ = coords.Z + 180,
        debug = false,
        distance = Config.TargetDistance,
    }, {
        {
            type = 'client',
            event = eventName,
            label = label,
            icon = 'box',
            canInteract = canInteract,
        },
    })

    registeredZones[#registeredZones + 1] = name
end

local function CreateLocationMarker()
    if not Config.DutyLocation or not Config.DutyLocation.coords then
        return
    end

    local marker = Config.Marker or {}
    AddMapMarker(Config.DutyLocation.coords, marker)
end

local function SetupPeds()
    if not Config.SellMaterials or #sellPeds > 0 then
        return
    end

    TriggerCallback('getPeds', function(jobPeds)
        if not registered then
            return
        end

        for i = 1, #jobPeds do
            local ped = jobPeds[i].npc
            sellPeds[#sellPeds + 1] = ped
            AddTargetEntity(ped, {
                {
                    type = 'client',
                    event = 'qb-recyclejob:client:sellMaterials',
                    icon = 'dollar-sign',
                    label = Lang.t('text.sell_materials'),
                },
            })
        end
    end)
end

local function CreatePickupProps()
    for k, location in ipairs(Config.PickupLocations) do
        local objectData = Config.WarehouseObjects[location.model] or Config.WarehouseObjects[1]
        local mesh = StaticMesh(location.loc, Rotator(0, location.heading or 0, 0), objectData.mesh or Config.PickupPackageMesh, CollisionType.Normal, true)

        if mesh and mesh.Object then
            local actor = mesh.Object
            props[k] = actor

            if objectData.scale then
                actor:SetActorScale3D(objectData.scale)
            end

            AddTargetEntity(actor, {
                {
                    type = 'client',
                    event = 'qb-recyclejob:client:pickUp',
                    label = Lang.t('text.get_package'),
                    icon = 'package',
                    packageIndex = k,
                    canInteract = function()
                        return onDuty and not carryPackage and packageCoords == k
                    end,
                },
            })
        end
    end
end

local function RegisterRecycleJob()
    if registered then
        return
    end

    registered = true
    CreateLocationMarker()
    SetupPeds()
    CreatePickupProps()

    AddZone('qb_recycle_duty', Config.DutyLocation.coords, Config.DutyLocation.heading, Lang.t('text.toggle_duty'), 'qb-recyclejob:client:toggleDuty')
    AddZone('qb_recycle_drop', Config.DropLocation.coords, Config.DropLocation.heading, Lang.t('text.hand_in_package'), 'qb-recyclejob:client:handInPackage', function()
        return carryPackage ~= nil
    end)
end

local function UnregisterRecycleJob()
    ClearRegisteredTargets()

    for _, zoneName in ipairs(registeredZones) do
        exports['qb-target']:RemoveZone(zoneName)
    end
    registeredZones = {}

    for _, actor in pairs(props) do
        if IsValidActor(actor) then
            DeleteEntity(actor)
        end
    end
    props = {}

    for _, markerId in ipairs(markerIds) do
        exports['qb-hud']:RemoveMarker(markerId)
    end
    markerIds = {}

    sellPeds = {}

    if carryPackage then
        DropPackage()
    end

    packageCoords = nil
    onDuty = false
    registered = false
end

RegisterClientEvent('QBCore:Client:OnPlayerLoaded', function()
    RegisterRecycleJob()
end)

RegisterClientEvent('QBCore:Client:OnPlayerUnload', function()
    UnregisterRecycleJob()
end)

RegisterClientEvent('qb-recyclejob:client:toggleDuty', ToggleDuty)
RegisterClientEvent('qb-recyclejob:client:handInPackage', HandInPackage)
RegisterClientEvent('qb-recyclejob:client:sellMaterials', SellMaterials)

RegisterClientEvent('qb-recyclejob:client:pickUp', function(data)
    PickUp(data and data.packageIndex)
end)

function onShutdown()
    UnregisterRecycleJob()
end
