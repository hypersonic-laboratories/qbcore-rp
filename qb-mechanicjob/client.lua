local function actorComponentsToTable(actor, componentClass)
    local ok, components = pcall(function()
        return actor:K2_GetComponentsByClass(componentClass)
    end)
    if not ok or not components then
        return {}
    end
    if type(components) == 'table' then
        return components
    end

    local converted, result = pcall(function()
        return components:ToTable()
    end)
    return converted and result or {}
end

local function objectName(object)
    local ok, name = pcall(function()
        return object:GetName()
    end)
    return ok and tostring(name) or tostring(object)
end

local function configEntry(entries, key)
    for _, entry in ipairs(entries) do
        if entry.key == key then
            return entry
        end
    end
end

local function collectRims(vehicle)
    local byName = {}
    if vehicle and UE.UPrimitiveComponent then
        for _, component in ipairs(actorComponentsToTable(vehicle, UE.UPrimitiveComponent)) do
            byName[objectName(component)] = component
        end
    end

    local rims = {}
    for _, rim in ipairs(Config.RimComponents) do
        if byName[rim.key] then
            rims[#rims + 1] = rim
        end
    end
    return rims
end

local openRimMenu
local activeRims = {}

local function openColorMenu(rimKey, rimLabel)
    local menu = {
        {
            header = rimLabel,
            txt = 'Choose a rim paint color',
            icon = 'palette',
            isMenuHeader = true,
        },
    }

    for _, color in ipairs(Config.RimColors) do
        menu[#menu + 1] = {
            header = color.label,
            txt = 'Apply this color',
            icon = 'paint-bucket',
            params = {
                event = 'qb-mechanicjob:client:selectRimColor',
                args = { rimKey = rimKey, colorKey = color.key },
            },
        }
    end

    menu[#menu + 1] = {
        header = 'Back',
        icon = 'arrow-left',
        params = { event = 'qb-mechanicjob:client:backToRims' },
    }
    exports['qb-menu']:openMenu(menu)
end

openRimMenu = function(rims)
    activeRims = rims

    local menu = {
        {
            header = 'Rim Paint',
            txt = 'Choose which rims to paint',
            icon = 'disc-3',
            isMenuHeader = true,
        },
    }

    if #rims > 1 then
        menu[#menu + 1] = {
            header = 'All Rims',
            txt = ('Paint all %d detected rims'):format(#rims),
            icon = 'circle-dot',
            params = {
                event = 'qb-mechanicjob:client:selectRim',
                args = { rimKey = 'all', rimLabel = 'All Rims' },
            },
        }
    end

    for _, rim in ipairs(rims) do
        menu[#menu + 1] = {
            header = rim.label,
            txt = rim.key,
            icon = 'circle',
            params = {
                event = 'qb-mechanicjob:client:selectRim',
                args = { rimKey = rim.key, rimLabel = rim.label },
            },
        }
    end

    menu[#menu + 1] = {
        header = 'Close',
        icon = 'x',
        params = { event = 'qb-menu:client:closeMenu' },
    }
    exports['qb-menu']:openMenu(menu)
end

RegisterClientEvent('qb-mechanicjob:client:selectRim', function(data)
    if data and data.rimKey and data.rimLabel then
        openColorMenu(data.rimKey, data.rimLabel)
    end
end)

RegisterClientEvent('qb-mechanicjob:client:backToRims', function()
    if #activeRims > 0 then
        openRimMenu(activeRims)
    end
end)

RegisterClientEvent('qb-mechanicjob:client:selectRimColor', function(data)
    if data and data.rimKey and data.colorKey then
        TriggerServerEvent('qb-mechanicjob:server:applyRimPaint', data.rimKey, data.colorKey)
    end
end)

local function openRimPaintMenu(vehicle)
    Timer.SetTimeout(function()
        if not vehicle then
            exports['qb-core']:Notify('Vehicle is not available', 'error')
            return
        end

        local rims = collectRims(vehicle)
        if #rims == 0 then
            exports['qb-core']:Notify('No paintable rims found on the closest vehicle', 'error')
            return
        end
        openRimMenu(rims)
    end, 150)
end

RegisterClientEvent('qb-mechanicjob:client:openRimPaintMenu', function(vehicle)
    openRimPaintMenu(vehicle)
end)

local function applyRimPaint(vehicle, rimKey, colorKey, attempt)
    local color = configEntry(Config.RimColors, colorKey)
    if not vehicle or not color then
        return
    end

    local targets = {}
    for _, component in ipairs(actorComponentsToTable(vehicle, UE.UPrimitiveComponent)) do
        local componentName = objectName(component)
        if (rimKey == 'all' and configEntry(Config.RimComponents, componentName)) or componentName == rimKey then
            targets[#targets + 1] = component
        end
    end

    if #targets == 0 and attempt < 10 then
        Timer.SetTimeout(function()
            applyRimPaint(vehicle, rimKey, colorKey, attempt + 1)
        end, 100)
        return
    end

    local paintColor = LinearColor(color.r, color.g, color.b, color.a)
    for _, rimComponent in ipairs(targets) do
        pcall(function()
            local sourceMaterial = rimComponent:GetMaterial(0)
            local rimMaterial = rimComponent:CreateDynamicMaterialInstance(0, sourceMaterial, 'RimPaint_' .. color.key)
            rimMaterial:SetVectorParameterValue('Paint Color', paintColor)
            rimComponent:SetMaterial(0, rimMaterial)
        end)
    end
end

RegisterClientEvent('qb-mechanicjob:client:applyRimPaint', function(vehicle, rimKey, colorKey)
    applyRimPaint(vehicle, rimKey, colorKey, 1)
end)
