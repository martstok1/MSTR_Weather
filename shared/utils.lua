-- Shared utility functions for MSTR_Weather

MSTR = MSTR or {}
MSTR.Utils = MSTR.Utils or {}

local Utils = MSTR.Utils
local PREFIX = '[MSTR_Weather]'

function Utils.Debug(message)
    if Config and Config.Debug then
        print(('%s[DEBUG] %s'):format(PREFIX, tostring(message)))
    end
end

function Utils.Info(message)
    print(('%s %s'):format(PREFIX, tostring(message)))
end

function Utils.Warn(message)
    print(('%s[WARNING] %s'):format(PREFIX, tostring(message)))
end

function Utils.IsValidNumber(value, min, max)
    if type(value) ~= 'number' or type(min) ~= 'number' or type(max) ~= 'number' then
        return false
    end

    if value ~= value or value == math.huge or value == -math.huge then
        return false
    end

    return value >= min and value <= max
end

-- GetGameTimer is a wrapping millisecond counter. Use differences, not absolute
-- deadlines, so long-running servers/clients survive a counter wrap.
function Utils.ElapsedMs(now, thenTimer)
    return (now - thenTimer) % 4294967296
end

function Utils.IsValidInteger(value, min, max)
    return Utils.IsValidNumber(value, min, max) and value % 1 == 0
end

function Utils.IsValidBoolean(value)
    return type(value) == 'boolean'
end

function Utils.NormalizeWeatherType(value)
    if type(value) ~= 'string' then
        return nil
    end

    local normalized = string.upper(value)
    if not MSTR.Constants
        or not MSTR.Constants.WeatherTypeLookup
        or not MSTR.Constants.WeatherTypeLookup[normalized] then
        return nil
    end

    return normalized
end

function Utils.IsValidWeatherType(value)
    return Utils.NormalizeWeatherType(value) ~= nil
end

function Utils.ParseBoolean(value)
    if value == true or value == false then
        return value
    end

    if type(value) ~= 'string' then
        return nil
    end

    local normalized = string.lower(value)
    if normalized == 'true' or normalized == '1' then
        return true
    end

    if normalized == 'false' or normalized == '0' then
        return false
    end

    return nil
end

function Utils.ParseTimeString(value)
    if type(value) ~= 'string' then
        return nil, nil
    end

    local hourText, minuteText = value:match('^(%d%d?):(%d%d?)$')
    if not hourText or not minuteText then
        return nil, nil
    end

    local hour = tonumber(hourText)
    local minute = tonumber(minuteText)

    if not Utils.IsValidInteger(hour, 0, 23) or not Utils.IsValidInteger(minute, 0, 59) then
        return nil, nil
    end

    return hour, minute
end

function Utils.FormatTime(hour, minute)
    if not Utils.IsValidInteger(hour, 0, 23) or not Utils.IsValidInteger(minute, 0, 59) then
        return nil
    end

    return string.format('%02d:%02d', hour, minute)
end

function Utils.WrapMinutes(minutes)
    if not Utils.IsValidNumber(minutes, -math.huge, math.huge) then
        return 0.0
    end

    local wrapped = minutes % 1440.0
    if wrapped < 0 then
        wrapped = wrapped + 1440.0
    end

    return wrapped
end

-- Normalize the owner-editable values used by phases 1-5 before either side
-- starts. Bad defaults must never reach GlobalState or a clock native.
function Utils.ValidateConfig()
    local function group(name)
        if type(Config[name]) ~= 'table' then
            Utils.Warn('Invalid/missing Config.' .. name .. '; using defaults')
            Config[name] = {}
        end
        return Config[name]
    end

    local function number(t, key, fallback, minimum, maximum, integer)
        local valid = integer and Utils.IsValidInteger(t[key], minimum, maximum)
            or (not integer and Utils.IsValidNumber(t[key], minimum, maximum))
        if not valid then
            Utils.Warn('Invalid config value ' .. key .. '; using ' .. tostring(fallback))
            t[key] = fallback
        end
    end

    local function boolean(t, key, fallback)
        if not Utils.IsValidBoolean(t[key]) then
            Utils.Warn('Invalid config boolean ' .. key .. '; using ' .. tostring(fallback))
            t[key] = fallback
        end
    end

    boolean(Config, 'Debug', false)
    local general = group('General')
    if general.Locale ~= 'nl' and general.Locale ~= 'en' then general.Locale = 'nl' end
    local commands = { DebugCommand = 'mstrdebug', WeatherCommand = 'mstrweather',
        TimeCommand = 'mstrtime', BlackoutCommand = 'mstrblackout', MenuCommand = 'mstrmenu' }
    local seen, invalidCommands = {}, false
    for key in pairs(commands) do
        local value = general[key]
        if type(value) ~= 'string' or not value:match('^[%w_-]+$') then
            invalidCommands = true
        elseif seen[value:lower()] then
            invalidCommands = true
        else
            seen[value:lower()] = true
        end
    end
    if invalidCommands then
        Utils.Warn('Invalid/duplicate command names; using default command names')
        for key, value in pairs(commands) do general[key] = value end
    end

    local permissions = group('Permissions')
    if type(permissions.Admin) ~= 'string' or permissions.Admin:match('^%s*$') then
        permissions.Admin = 'mstr.weather.admin'
    end
    if type(permissions.SuperAdmin) ~= 'string' or permissions.SuperAdmin:match('^%s*$')
        or permissions.SuperAdmin == permissions.Admin then
        permissions.SuperAdmin = 'mstr.weather.superadmin'
    end
    if permissions.SuperAdmin == permissions.Admin then
        error('Admin and SuperAdmin ACE must be different')
    end
    local weather = group('Weather')
    weather.Default = Utils.NormalizeWeatherType(weather.Default) or 'CLEAR'
    number(weather, 'TransitionDuration', 30, 0, 300, false)
    boolean(weather, 'AllowInstantChange', true)
    boolean(weather, 'EnableSnowTrails', true)

    local dynamic = group('DynamicWeather')
    boolean(dynamic, 'Enabled', true)
    number(dynamic, 'MinIntervalMinutes', 0.1, 0.1, 1440, false)
    number(dynamic, 'MaxIntervalMinutes', 1440, dynamic.MinIntervalMinutes, 1440, false)
    number(dynamic, 'IntervalMinutes', math.max(dynamic.MinIntervalMinutes,
        math.min(15, dynamic.MaxIntervalMinutes)), dynamic.MinIntervalMinutes, dynamic.MaxIntervalMinutes, false)

    local time = group('Time')
    number(time, 'DefaultHour', 12, 0, 23, true)
    number(time, 'DefaultMinute', 0, 0, 59, true)
    boolean(time, 'Frozen', false)
    number(time, 'MinCycleSpeed', 0, 0, 100, false)
    number(time, 'MaxCycleSpeed', math.max(10, time.MinCycleSpeed), time.MinCycleSpeed, 100, false)
    number(time, 'CycleSpeed', math.max(time.MinCycleSpeed, math.min(2, time.MaxCycleSpeed)),
        time.MinCycleSpeed, time.MaxCycleSpeed, false)
    number(time, 'CorrectionIntervalSeconds', 60, 10, 3600, false)
    number(time, 'ClientTickMs', 250, 50, 1000, true)

    local blackout = group('Blackout')
    boolean(blackout, 'Default', false)
    boolean(blackout, 'AffectVehicles', false)
    local persistence = group('Persistence')
    boolean(persistence, 'Enabled', true)
    number(persistence, 'DebounceMs', 1500, 0, 30000, true)
    -- The save path must be a JSON file inside data/, never code/config or an
    -- absolute path. Custom nested directories must already exist.
    if type(persistence.File) ~= 'string'
        or not persistence.File:match('^data/[%w_/%.-]+%.json$')
        or persistence.File:find('..', 1, true)
        or persistence.File:find('/./', 1, true)
        or persistence.File:find('//', 1, true)
        or persistence.File:lower() == 'data/admin.json' then
        Utils.Warn('Invalid persistence path; using data/state.json')
        persistence.File = 'data/state.json'
    end
end

Utils.ValidateConfig()

function Utils.MinutesToClock(minutes)
    local wrapped = Utils.WrapMinutes(minutes)
    local wholeMinutes = math.floor(wrapped)
    local hour = math.floor(wholeMinutes / 60)
    local minute = wholeMinutes % 60
    local second = math.floor((wrapped - wholeMinutes) * 60.0)

    if second < 0 then
        second = 0
    elseif second > 59 then
        second = 59
    end

    return hour, minute, second
end
