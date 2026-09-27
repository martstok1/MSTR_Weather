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
    if type(minutes) ~= 'number' then
        return 0.0
    end

    local wrapped = minutes % 1440.0
    if wrapped < 0 then
        wrapped = wrapped + 1440.0
    end

    return wrapped
end

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
