Jobs = {}

Job = {}
Job.__index = Job

local function getVehicleAsset(vehicleName)
    local vehicleInfo = SharedVehicles[vehicleName]
    return vehicleInfo and vehicleInfo.asset_name or vehicleName
end

local function getVehicleSpawnCoords(spawn)
    local zOffset = Config.VehicleSpawnZOffset or 0
    return Vector(spawn.X, spawn.Y, spawn.Z - zOffset)
end

local function spawnJobVehicle(depot, vehicleAsset, plate)
    local vehicle = HVehicle(getVehicleSpawnCoords(depot.vehicleSpawn), Rotator(0, depot.vehicleHeading or 0, 0), vehicleAsset)
    if not vehicle then
        return nil
    end

    if vehicle.SetFuel then
        vehicle:SetFuel(100.0)
    end
    if plate and vehicle.SetPlate then
        vehicle:SetPlate(plate)
    end

    return vehicle
end

function Job.new(Courier, DepotInfo)
    local self = setmetatable({}, Job)

    -- Setup Job instance
    self.DeliveryId = GenerateId(6, 'mixed')
    self.Courier = Courier
    self.Depot = DepotInfo
    self.CurrentStop = 1
    self.MaxStops = math.random(Config.Stops.Minimum, Config.Stops.Maximum)
    self:CreateDeliveryVehicle()
    self:CreateRoute()

    Jobs[self.DeliveryId] = self
    return self
end

function Job:CreateDeliveryVehicle()
    local vehicleName = Config.Vehicles[math.random(1, #Config.Vehicles)] or 'bp_deliverytruck'
    local vehicleAsset = getVehicleAsset(vehicleName)
    local plate = (Config.VehiclePlatePrefix or 'D-') .. self.DeliveryId
    local newVehicle = spawnJobVehicle(self.Depot, vehicleAsset, plate)
    if not newVehicle then
        return nil
    end

    self.Vehicle = newVehicle

    -- Add pickup box target option
    TriggerClientEvent(self.Courier, 'qb-deliveryjob:client:setupVehicleTarget', newVehicle, self.DeliveryId)

    return self.Vehicle
end

function Job:CreateDeliveryProp()
    local Pawn = GetPlayerPawn(self.Courier)
    if not Pawn then
        return
    end
    if self.Prop and self.Prop:IsValid() then
        DeleteEntity(self.Prop)
    end

    local PawnCoords = GetEntityCoords(Pawn)
    self.Prop = StaticMesh(PawnCoords, Rotator(), Config.Prop.Mesh)

    -- Attach box to hand
    local Mesh = Pawn:GetCharacterBaseMesh()
    local Attached = AttachActorToComponent(self.Prop.Object, Mesh, Vector(0, -50, 0), Rotator(), 'hand_r')
    self.Prop:SetActorScale3D(Vector(0.3, 0.3, 0.3))
    local PlayAnims = UE.FHelixPlayAnimParams()
    PlayAnims.bIgnoreMovementInput = false
    PlayAnims.LoopCount = -1
    PlayAnims.AnimSlotName = 'UpperBody'
    --Animation.Play(Pawn, Config.Prop.HoldingAnimation, PlayAnims)

    return self.Prop
end

function Job:CreateRoute()
    local Route = {}
    local PlayerPawn = GetPlayerPawn(self.Courier)
    local PawnLocation = GetEntityCoords(PlayerPawn)

    -- Randomly select route locations
    local closestLocation, closestDistance = nil, math.huge
    for _, v in pairs(Config.Locations) do
        if math.random(0, 100) % 2 == 0 then
            Route[#Route + 1] = v
            local currentDist = PawnLocation:Dist(v)
            if not closestLocation or currentDist < closestDistance then
                closestLocation = v
                closestDistance = currentDist
            end
        end
        if #Route == self.MaxStops then
            break
        end
    end
    -- Regenerate if Route isn't big enough
    if #Route < Config.Stops.Minimum or #Route < self.MaxStops then
        return self:CreateRoute()
    end

    -- Sort route by closest from closest start point
    table.sort(Route, function(a, b)
        local aDist = closestLocation:Dist(a)
        local bDist = closestLocation:Dist(b)
        return aDist < bDist
    end)

    self.Route = Route

    return self.Route
end

function Job:DeliverPackage()
    local Pawn = GetPlayerPawn(self.Courier)
    local PawnCoords = GetEntityCoords(Pawn)
    if self.CurrentStop > self.MaxStops then
        return false
    end
    if PawnCoords:Dist(self.Route[self.CurrentStop]) > 1000 then
        return false
    end
    self.CurrentStop = self.CurrentStop + 1

    DeleteEntity(self.Prop)

    return true
end

function Job:Payout()
    local amount = math.random(Config.Payout.Minimum, Config.Payout.Maximum)
    local completedRoute = self.CurrentStop > self.MaxStops
    -- Decrease amount if route is incomplete
    if not completedRoute and self.CurrentStop == 1 then
        amount = 0
    elseif not completedRoute then
        amount = math.floor(amount * 0.3)
    end

    local Player = exports['qb-core']:GetPlayer(self.Courier)
    if not Player then
        return
    end
    local Success = Player.AddMoney('bank', amount, 'delivery-job-payout')
    if not Success then
        return
    end

    exports['qb-core']:NotifyPlayer(self.Courier, completedRoute and Lang.t('success.paid', { Amount = amount }) or Lang.t('success.incomplete_paid', { Amount = amount }), 'success')

    return true
end

function Job:Cleanup()
    if self.Prop and self.Prop:IsValid() then
        DeleteEntity(self.Prop)
    end
    if self.Vehicle and self.Vehicle:IsValid() then
        DeleteVehicle(self.Vehicle)
    end
end
