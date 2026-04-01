local interiors = {}
local nextId = 1

-- Functions

exports('qb-interior', 'DespawnInterior_C', function(id)
    if interiors[id] then
        if interiors[id].object then interiors[id].object:K2_DestroyActor() end
        if interiors[id].light then interiors[id].light:K2_DestroyActor() end
        interiors[id] = nil
    end
end)

local function CreateShell(spawn, exitXYZH, shellData, teleport)
    if not shellData.model then
        print('No model provided for interior shell')
        return
    end

    local id = nextId
    nextId = nextId + 1
    interiors[id] = {}

    local POIOffsets = {}
    POIOffsets.exit = exitXYZH
    interiors[id].POIOffsets = POIOffsets

    local spawnTransform = Transform()
    spawnTransform.Translation = Vector(spawn.X, spawn.Y, spawn.Z)

    if shellData.model then
        local house = SpawnActor(shellData.model, spawnTransform)
        interiors[id].object = house
    end

    if shellData.light then
        local light = SpawnActor(shellData.light, spawnTransform)
        interiors[id].light = light
    end

    if teleport or teleport == nil then
        Timer.SetTimeout(function()
            TriggerServerEvent(
                'qb-interior:server:teleportPlayer',
                spawn.X - POIOffsets.exit.x,
                spawn.Y - POIOffsets.exit.y,
                spawn.Z + POIOffsets.exit.z
            )
        end, 1000)
    end

    return id, POIOffsets
end

-- Housing Shells

exports('qb-interior', 'StarterAptFurn_C', function(spawn, teleport)
    local exit = { x = 0, y = 100, z = 100 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_StarterApartment_01_Interior_Furnished.BPP_Miami_StarterApartment_01_Interior_Furnished_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_ApartmentLevel1_01_Lighting.BP_ApartmentLevel1_01_Lighting_C'
    }
    local id, POIOffsets = CreateShell(spawn, exit, shellData, teleport)

    if POIOffsets then
        POIOffsets.clothes = { x = -405.08, y = 449.07, z = 93.43 }
        POIOffsets.stash = { x = 639.49, y = 467.39, z = 93.43 }
        POIOffsets.logout = { x = 239.45, y = 660.92, z = 93.43 }
        interiors[id].POIOffsets = POIOffsets
    end

    return { id, POIOffsets }
end)

exports('qb-interior', 'StarterApt_C', function(spawn)
    local exit = { x = 0, y = 100, z = 100 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_StarterApartment_01_Interior.BPP_Miami_StarterApartment_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_ApartmentLevel1_01_Lighting.BP_ApartmentLevel1_01_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'MarinaApt_C', function(spawn)
    local exit = { x = 6.58, y = 101.13, z = 108.25 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_MarinaApartment_01_Interior.BPP_Miami_MarinaApartment_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_ApartmentLevel2_Lighting.BP_ApartmentLevel2_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'ResidentialHouse_C', function(spawn)
    local exit = { x = 276.25, y = -79.29, z = 92.82 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_ResidentialHouse_Mid_01_Interior.BPP_Miami_ResidentialHouse_Mid_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_ResidentialHouse_Mid_01_Lighting.BP_Miami_ResidentialHouse_Mid_01_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'OceanDrive_C', function(spawn)
    local exit = { x = -5.28, y = 60.54, z = 93.65 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_OceanDrivePenthouse_01_Interior.BPP_Miami_OceanDrivePenthouse_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_OceanDrivePenthouse_01_Lighting.BP_Miami_OceanDrivePenthouse_01_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'VillaApt_C', function(spawn)
    local exit = { x = -5, y = 2020, z = 92 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Villa/BPP_Villa_06_Interior_B.BPP_Villa_06_Interior_B_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Villa_06_Lighting.BP_Villa_06_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

-- Garage Shells

exports('qb-interior', 'StarterGarage_C', function(spawn)
    local exit = { x = 416, y = -172, z = 107 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageStarterApartment_01_Interior.BPP_Miami_GarageStarterApartment_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageStarterApartment_01_Lighting.BP_Miami_GarageStarterApartment_01_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'MarinaGarage_C', function(spawn)
    local exit = { x = 428, y = -153, z = 107 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageMarinaApartment_01_Interior.BPP_Miami_GarageMarinaApartment_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageMarinaApartment_01_Lighting.BP_Miami_GarageMarinaApartment_01_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'ResidentialGarage_C', function(spawn)
    local exit = { x = -395.46, y = -192.80, z = 93.02 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageResidentialHouse_Mid_01_Interior.BPP_Miami_GarageResidentialHouse_Mid_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageResidentialHouse_Mid_01_Lighting.BP_Miami_GarageResidentialHouse_Mid_01_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'OceanDriveGarage_C', function(spawn)
    local exit = { x = -736, y = -323, z = 97 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BPP_Miami_GarageOceanDrivePenthouse_01_Interior.BPP_Miami_GarageOceanDrivePenthouse_01_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_Miami_GarageOceanDrivePenthouse_01_Lighting_Final.BP_Miami_GarageOceanDrivePenthouse_01_Lighting_Final_C'
    }
    return CreateShell(spawn, exit, shellData)
end)

exports('qb-interior', 'VillaGarage_C', function(spawn)
    local exit = { x = -736, y = -323, z = 97 }
    local shellData = {
        model = '/Game/Pacifica/Environment/PLA/City/Villa/BPP_GarageVilla_06_Interior.BPP_GarageVilla_06_Interior_C',
        light = '/Game/Pacifica/Environment/PLA/City/Miami/Residential/BP_GarageVilla_06_Lighting.BP_GarageVilla_06_Lighting_C'
    }
    return CreateShell(spawn, exit, shellData)
end)
