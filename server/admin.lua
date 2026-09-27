-- Server-only settings and delegated rights; independent of environment persistence.
MSTR.Admin = {}
local Admin = MSTR.Admin
local path = 'data/admin.json'
local data = { version = 1, revision = 0, users = {}, settings = {} }
local locked, lastRaw = false, nil
local rights = { view = true, weather = true, time = true, dynamic = true, blackout = true }

local function ExactKeys(value, keys)
    if type(value) ~= 'table' then return false end
    for key in pairs(value) do if not keys[key] then return false end end
    return true
end

function Admin.ValidIdentifier(value)
    if type(value) ~= 'string' or #value > 64 then return false end
    return value:match('^fivem:%d+$') ~= nil
        or (value:match('^license:[0-9a-f]+$') ~= nil and #value == 48)
end

function Admin.ValidRights(value)
    if not ExactKeys(value, rights) then return false end
    for key in pairs(rights) do if type(value[key]) ~= 'boolean' then return false end end
    return true
end

function Admin.IsLocked() return locked end
function Admin.GetUser(identifier) return data.users[identifier] end
function Admin.GetRevision() return data.revision end

function Admin.GetSettings()
    return {
        locale = Config.General.Locale,
        transitionSeconds = Config.Weather.TransitionDuration,
        instantAllowed = Config.Weather.AllowInstantChange,
        snowTrails = Config.Weather.EnableSnowTrails,
        dynamicIntervalMinutes = Config.DynamicWeather.IntervalMinutes,
        affectVehicles = Config.Blackout.AffectVehicles,
        persistenceEnabled = Config.Persistence.Enabled
    }
end

local function ValidSettings(s)
    local keys = { locale = true, transitionSeconds = true, instantAllowed = true, snowTrails = true,
        dynamicIntervalMinutes = true, affectVehicles = true, persistenceEnabled = true }
    return ExactKeys(s, keys)
        and (s.locale == 'nl' or s.locale == 'en')
        and MSTR.Utils.IsValidNumber(s.transitionSeconds, 0, 300)
        and MSTR.Utils.IsValidNumber(s.dynamicIntervalMinutes, Config.DynamicWeather.MinIntervalMinutes, Config.DynamicWeather.MaxIntervalMinutes)
        and type(s.instantAllowed) == 'boolean' and type(s.snowTrails) == 'boolean'
        and type(s.affectVehicles) == 'boolean' and type(s.persistenceEnabled) == 'boolean'
end

local function ApplySettings(s, runtime)
    Config.General.Locale = s.locale
    local intervalChanged = Config.DynamicWeather.IntervalMinutes ~= s.dynamicIntervalMinutes
    local persistenceChanged = Config.Persistence.Enabled ~= s.persistenceEnabled
    Config.Weather.TransitionDuration = s.transitionSeconds
    Config.Weather.AllowInstantChange = s.instantAllowed
    Config.Weather.EnableSnowTrails = s.snowTrails
    Config.DynamicWeather.IntervalMinutes = s.dynamicIntervalMinutes
    Config.Blackout.AffectVehicles = s.affectVehicles
    Config.Persistence.Enabled = s.persistenceEnabled
    if runtime then
        if intervalChanged then MSTR.WeatherEngine.SettingsChanged() end
        if persistenceChanged then MSTR.Persistence.SetEnabled(s.persistenceEnabled) end
        MSTR.State.PublishSettings()
    end
end

local function ValidName(name)
    return type(name) == 'string' and #name > 0 and #name <= 80 and not name:find('%c')
end

local function Decode(raw)
    if type(raw) ~= 'string' or #raw > 262144 then return nil end
    local ok, value = pcall(json.decode, raw)
    if not ok or not ExactKeys(value, { version = true, revision = true, users = true, settings = true })
        or value.version ~= 1 or not MSTR.Utils.IsValidInteger(value.revision, 0, 2147483646)
        or type(value.users) ~= 'table' or type(value.settings) ~= 'table' then return nil end
    -- Upgrade old six-field settings in memory without changing existing grants.
    if next(value.settings) and value.settings.locale == nil then value.settings.locale = Config.General.Locale end
    if next(value.settings) and not ValidSettings(value.settings) then return nil end
    local count = 0
    for identifier, user in pairs(value.users) do
        count = count + 1
        if count > 256 or not Admin.ValidIdentifier(identifier)
            or not ExactKeys(user, { name = true, rights = true })
            or not ValidName(user.name) or not Admin.ValidRights(user.rights) then return nil end
    end
    return value
end

function Admin.Initialize()
    local raw = LoadResourceFile(GetCurrentResourceName(), path)
    if raw == nil then
        if LoadResourceFile(GetCurrentResourceName(), path .. '.bak') ~= nil then
            locked = true
            MSTR.Utils.Warn('admin.json missing while backup exists: access locked; restore manually.')
        end
        return
    end
    local decoded = Decode(raw)
    if not decoded then
        locked = true
        MSTR.Utils.Warn('admin.json invalid: delegated/legacy access and admin writes blocked. Restore manually; no automatic rights rollback.')
        return
    end
    data, lastRaw = decoded, raw
    if next(data.settings) then ApplySettings(data.settings, false) end
end

local function Save(candidate)
    local ok, raw = pcall(json.encode, candidate)
    if not ok or type(raw) ~= 'string' or #raw > 262144 then return false, 'storage' end
    local resource = GetCurrentResourceName()
    local backup = lastRaw or json.encode(data)
    local saved = SaveResourceFile(resource, path .. '.bak', backup, #backup)
    if saved ~= true and saved ~= 1 then return false, 'storage' end
    saved = SaveResourceFile(resource, path, raw, #raw)
    if (saved ~= true and saved ~= 1) or LoadResourceFile(resource, path) ~= raw then
        locked = true -- A partial primary write must never silently grant stale rights.
        MSTR.Utils.Warn('admin.json write failed: access locked until file repaired and resource restarted')
        return false, 'storage'
    end
    data, lastRaw = candidate, raw
    return true
end

function Admin.UpdateSettings(player, settings, revision)
    if not MSTR.Permissions.IsSuperAdmin(player) then return false, 'forbidden' end
    if locked then return false, 'storage' end
    if revision ~= data.revision then return false, 'conflict' end
    if not ValidSettings(settings) then return false, 'invalid' end
    local candidate = { version = 1, revision = data.revision + 1, users = data.users, settings = settings }
    local previous = Admin.GetSettings()
    local ok, reason = Save(candidate)
    if ok then
        ApplySettings(settings, true)
        MSTR.Logging.Record('settings', previous, settings, { player = player, origin = 'nui' })
    end
    return ok, reason
end

function Admin.UpdateUser(player, identifier, name, permissions, revision)
    if not MSTR.Permissions.IsSuperAdmin(player) then return false, 'forbidden' end
    if locked then return false, 'storage' end
    if revision ~= data.revision then return false, 'conflict' end
    if not Admin.ValidIdentifier(identifier) or not ValidName(name) or not Admin.ValidRights(permissions) then
        return false, 'invalid'
    end
    local users, count = {}, 0
    for id, user in pairs(data.users) do users[id] = user; count = count + 1 end
    if not users[identifier] and count >= 256 then return false, 'limit' end
    -- Retain explicit all-false entries: deleting them could restore legacy ACE access.
    local previous = { identifier = identifier, user = data.users[identifier] }
    users[identifier] = { name = name, rights = permissions }
    local ok, reason = Save({ version = 1, revision = data.revision + 1, users = users, settings = data.settings })
    if ok then MSTR.Logging.Record('user', previous, { identifier = identifier, user = users[identifier] }, { player = player, origin = 'nui' }) end
    return ok, reason
end

function Admin.GetPanel(player)
    if not MSTR.Permissions.IsSuperAdmin(player) then return nil end
    local users, online = {}, {}
    for id, user in pairs(data.users) do
        users[#users + 1] = { identifier = id, name = user.name, rights = user.rights }
    end
    table.sort(users, function(a, b) return a.identifier < b.identifier end)
    for _, id in ipairs(GetPlayers()) do
        local identifier = MSTR.Permissions.GetIdentity(tonumber(id))
        if identifier and #online < 256 then
            online[#online + 1] = { identifier = identifier, source = tonumber(id),
                name = (GetPlayerName(id) or 'Speler'):gsub('%c', ''):sub(1, 80),
                superadmin = MSTR.Permissions.IsSuperAdmin(tonumber(id)) }
        end
    end
    return { revision = data.revision, users = users, online = online, locked = locked,
        settings = Admin.GetSettings(), minInterval = Config.DynamicWeather.MinIntervalMinutes,
        maxInterval = Config.DynamicWeather.MaxIntervalMinutes }
end
