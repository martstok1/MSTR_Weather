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

function Permissions.Initialize()
    MSTR.Utils.Debug(('Permission service initialized (admin ACE: %s)'):format(GetAdminAce()))
end
