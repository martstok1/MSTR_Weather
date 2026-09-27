-- Permission management for MSTR_Weather

MSTR = MSTR or {}
MSTR.Permissions = MSTR.Permissions or {}

local Permissions = MSTR.Permissions
local DEFAULT_ADMIN_ACE = 'mstr.weather.admin'

local function GetAdminAce()
    if Config and Config.Permissions and type(Config.Permissions.Admin) == 'string' and Config.Permissions.Admin ~= '' then
        return Config.Permissions.Admin
    end

    return DEFAULT_ADMIN_ACE
end

function Permissions.HasPermission(source, permission)
    local playerSource = tonumber(source)

    if not playerSource or playerSource <= 0 then
        MSTR.Utils.Debug(('Invalid player source for ACE check: %s'):format(tostring(source)))
        return false
    end

    if type(permission) ~= 'string' or permission == '' then
        MSTR.Utils.Debug('Invalid ACE permission provided')
        return false
    end

    -- Some Cfx runtime paths return 1/0 instead of a literal Lua boolean.
    local aceResult = IsPlayerAceAllowed(playerSource, permission)
    local allowed = aceResult == true or aceResult == 1

    MSTR.Utils.Debug(('ACE check: source=%s permission=%s allowed=%s')
        :format(playerSource, permission, tostring(allowed)))

    return allowed
end

function Permissions.HasAdminPermission(source)
    return Permissions.HasPermission(source, GetAdminAce())
end

function Permissions.IsSuperAdmin(source)
    return Permissions.HasPermission(source, Config.Permissions.SuperAdmin)
end

function Permissions.GetIdentity(source)
    local fallback
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if MSTR.Admin.ValidIdentifier(id) then
            if id:sub(1, 6) == 'fivem:' then return id end
            fallback = id
        end
    end
    return fallback
end

function Permissions.Can(source, right)
    local ordinary = { view = true, weather = true, time = true, dynamic = true, blackout = true }
    if not ordinary[right] and right ~= 'manage' then return false end
    if Permissions.IsSuperAdmin(source) then return true end
    if right == 'manage' or MSTR.Admin.IsLocked() then return false end
    -- Explicit user entries override legacy access. Multiple matching identifiers
    -- are intersected, so an old alias can never bypass an explicit revocation.
    local explicit, allowed = false, true
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        local user = MSTR.Admin.GetUser(id)
        if user then
            explicit = true
            allowed = allowed and user.rights.view == true and user.rights[right] == true
        end
    end
    if explicit then return allowed end
    return Permissions.HasAdminPermission(source)
end

function Permissions.GetCapabilities(source)
    local result = {}
    for _, right in ipairs({ 'view', 'weather', 'time', 'dynamic', 'blackout', 'manage' }) do
        result[right] = Permissions.Can(source, right)
    end
    return result
end

function Permissions.Initialize()
    MSTR.Utils.Debug(('Permission service initialized (admin ACE: %s)'):format(GetAdminAce()))
end
