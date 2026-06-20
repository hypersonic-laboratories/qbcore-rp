-- Add or change (a) method(s) in the QBCore.Functions table
local function SetMethod(methodName, handler)
    if type(methodName) ~= 'string' then
        return false, 'invalid_method_name'
    end
    if QBCore.Functions[methodName] ~= nil then
        return false, 'method_exists'
    end
    QBCore.Functions[methodName] = handler
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'SetMethod', SetMethod)

-- Add or change (a) field(s) in the QBCore table
local function SetField(fieldName, data)
    if type(fieldName) ~= 'string' then
        return false, 'invalid_field_name'
    end
    if QBCore[fieldName] ~= nil then
        return false, 'field_exists'
    end
    QBCore[fieldName] = data
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'SetField', SetField)

-- Single add job function which should only be used if you planning on adding a single job
local function AddJob(jobName, job)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end
    if QBCore.Shared.Jobs[jobName] then
        return false, 'job_exists'
    end
    QBCore.Shared.Jobs[jobName] = job
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Jobs', jobName, job)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'AddJob', AddJob)

-- Multiple Add Jobs
local function AddJobs(jobs)
    for key, value in pairs(jobs) do
        if type(key) ~= 'string' then
            return false, 'invalid_job_name', value
        end
        if QBCore.Shared.Jobs[key] then
            return false, 'job_exists', value
        end
    end
    for key, value in pairs(jobs) do
        QBCore.Shared.Jobs[key] = value
    end
    BroadcastEvent('QBCore:Client:OnSharedUpdateMultiple', 'Jobs', jobs)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success', nil
end
exports('qb-core', 'AddJobs', AddJobs)

-- Single Remove Job
local function RemoveJob(jobName)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end
    if not QBCore.Shared.Jobs[jobName] then
        return false, 'job_not_exists'
    end
    QBCore.Shared.Jobs[jobName] = nil
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Jobs', jobName, nil)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'RemoveJob', RemoveJob)

-- Single Update Job
local function UpdateJob(jobName, job)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end
    if not QBCore.Shared.Jobs[jobName] then
        return false, 'job_not_exists'
    end
    QBCore.Shared.Jobs[jobName] = job
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Jobs', jobName, job)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'UpdateJob', UpdateJob)

-- Single add item
local function AddItem(itemName, item)
    if type(itemName) ~= 'string' then
        return false, 'invalid_item_name'
    end
    if QBCore.Shared.Items[itemName] then
        return false, 'item_exists'
    end
    QBCore.Shared.Items[itemName] = item
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Items', itemName, item)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'AddItem', AddItem)

-- Single update item
local function UpdateItem(itemName, item)
    if type(itemName) ~= 'string' then
        return false, 'invalid_item_name'
    end
    if not QBCore.Shared.Items[itemName] then
        return false, 'item_not_exists'
    end
    QBCore.Shared.Items[itemName] = item
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Items', itemName, item)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'UpdateItem', UpdateItem)

-- Multiple Add Items
local function AddItems(items)
    for key, value in pairs(items) do
        if type(key) ~= 'string' then
            return false, 'invalid_item_name', value
        end
        if QBCore.Shared.Items[key] then
            return false, 'item_exists', value
        end
    end
    for key, value in pairs(items) do
        QBCore.Shared.Items[key] = value
    end
    BroadcastEvent('QBCore:Client:OnSharedUpdateMultiple', 'Items', items)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success', nil
end
exports('qb-core', 'AddItems', AddItems)

-- Single Remove Item
local function RemoveItem(itemName)
    if type(itemName) ~= 'string' then
        return false, 'invalid_item_name'
    end
    if not QBCore.Shared.Items[itemName] then
        return false, 'item_not_exists'
    end
    QBCore.Shared.Items[itemName] = nil
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Items', itemName, nil)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'RemoveItem', RemoveItem)

-- Single Add Gang
local function AddGang(gangName, gang)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end
    if QBCore.Shared.Gangs[gangName] then
        return false, 'gang_exists'
    end
    QBCore.Shared.Gangs[gangName] = gang
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Gangs', gangName, gang)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'AddGang', AddGang)

-- Multiple Add Gangs
local function AddGangs(gangs)
    for key, value in pairs(gangs) do
        if type(key) ~= 'string' then
            return false, 'invalid_gang_name', value
        end
        if QBCore.Shared.Gangs[key] then
            return false, 'gang_exists', value
        end
    end
    for key, value in pairs(gangs) do
        QBCore.Shared.Gangs[key] = value
    end
    BroadcastEvent('QBCore:Client:OnSharedUpdateMultiple', 'Gangs', gangs)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success', nil
end
exports('qb-core', 'AddGangs', AddGangs)

-- Single Remove Gang
local function RemoveGang(gangName)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end
    if not QBCore.Shared.Gangs[gangName] then
        return false, 'gang_not_exists'
    end
    QBCore.Shared.Gangs[gangName] = nil
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Gangs', gangName, nil)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'RemoveGang', RemoveGang)

-- Single Update Gang
local function UpdateGang(gangName, gang)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end
    if not QBCore.Shared.Gangs[gangName] then
        return false, 'gang_not_exists'
    end
    QBCore.Shared.Gangs[gangName] = gang
    BroadcastEvent('QBCore:Client:OnSharedUpdate', 'Gangs', gangName, gang)
    TriggerLocalServerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end
exports('qb-core', 'UpdateGang', UpdateGang)

local function AddPlayerField(source, fieldName, data)
    local player = QBCore.Players[source]
    if not player then
        return false
    end
    return player:AddField(fieldName, data)
end
exports('qb-core', 'AddPlayerField', AddPlayerField)
