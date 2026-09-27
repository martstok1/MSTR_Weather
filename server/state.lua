-- Central replicated state management for MSTR_Weather

MSTR = MSTR or {}
MSTR.State = MSTR.State or {}

local State = MSTR.State

local KEYS = {
    Weather = 'mstr:weather',
    DynamicWeather = 'mstr:dynamicWeather',
    WeatherTransitioning = 'mstr:weatherTransitioning',
    WeatherTarget = 'mstr:weatherTarget',
    WeatherTransitionDuration = 'mstr:weatherTransitionDuration',
    Blackout = 'mstr:blackout',
    TimeFrozen = 'mstr:timeFrozen',
    TimeScale = 'mstr:timeScale',
    TimeHour = 'mstr:timeHour',
    TimeMinute = 'mstr:timeMinute'
}

local function GetDefaults()
    return {
        weather = MSTR.Utils.NormalizeWeatherType(Config.Weather.Default) or 'CLEAR',
        dynamicWeather = Config.DynamicWeather.Enabled == true,
        blackout = Config.Blackout.Default == true,
        timeFrozen = Config.Time.Frozen == true,
        timeScale = Config.Time.CycleSpeed,
        time = {
            hour = Config.Time.DefaultHour,
            minute = Config.Time.DefaultMinute
        }
    }
end

function State.Initialize(restored)
    if not Config then
        error('[MSTR_Weather] Config is not loaded before State.Initialize()')
    end

    local values = GetDefaults()

    if type(restored) == 'table' then
        if MSTR.Utils.IsValidWeatherType(restored.weather) then
            values.weather = MSTR.Utils.NormalizeWeatherType(restored.weather)
        end

        if MSTR.Utils.IsValidBoolean(restored.dynamicWeather) then
            values.dynamicWeather = restored.dynamicWeather
        end

        if MSTR.Utils.IsValidBoolean(restored.blackout) then
            values.blackout = restored.blackout
        end

        if MSTR.Utils.IsValidBoolean(restored.timeFrozen) then
            values.timeFrozen = restored.timeFrozen
        end

        if MSTR.Utils.IsValidNumber(restored.timeScale, Config.Time.MinCycleSpeed, Config.Time.MaxCycleSpeed) then
            values.timeScale = restored.timeScale
        end

        if type(restored.time) == 'table'
            and MSTR.Utils.IsValidInteger(restored.time.hour, 0, 23)
            and MSTR.Utils.IsValidInteger(restored.time.minute, 0, 59) then
            values.time.hour = restored.time.hour
            values.time.minute = restored.time.minute
        end
    end

    -- Assign explicitly rather than SetDefault so a resource restart cannot keep
    -- stale GlobalState values from an older runtime instance.
    GlobalState[KEYS.Weather] = values.weather
    GlobalState[KEYS.DynamicWeather] = values.dynamicWeather
    GlobalState[KEYS.WeatherTransitioning] = false
    GlobalState[KEYS.WeatherTarget] = ''
    GlobalState[KEYS.WeatherTransitionDuration] = 0
    GlobalState[KEYS.Blackout] = values.blackout
    GlobalState[KEYS.TimeFrozen] = values.timeFrozen
    GlobalState[KEYS.TimeScale] = values.timeScale
    GlobalState[KEYS.TimeHour] = values.time.hour
    GlobalState[KEYS.TimeMinute] = values.time.minute

    MSTR.Utils.Debug('Global state initialized')
end

function State.GetWeather()
    local value = GlobalState[KEYS.Weather]
    if value == nil then
        return MSTR.Utils.NormalizeWeatherType(Config.Weather.Default) or 'CLEAR'
    end

    return value
end

function State.SetWeather(value)
    local weatherType = MSTR.Utils.NormalizeWeatherType(value)
    if not weatherType then
        return false
    end

    GlobalState[KEYS.Weather] = weatherType
    return true
end

function State.GetDynamicWeather()
    local value = GlobalState[KEYS.DynamicWeather]
    if value == nil then
        return Config.DynamicWeather.Enabled == true
    end

    return value == true
end

function State.SetDynamicWeather(enabled)
    if not MSTR.Utils.IsValidBoolean(enabled) then
        return false
    end

    GlobalState[KEYS.DynamicWeather] = enabled
    return true
end

function State.GetWeatherTransition()
    return {
        active = GlobalState[KEYS.WeatherTransitioning] == true,
        target = GlobalState[KEYS.WeatherTarget] or '',
        duration = tonumber(GlobalState[KEYS.WeatherTransitionDuration]) or 0
    }
end

function State.SetWeatherTransition(active, target, duration)
    if not MSTR.Utils.IsValidBoolean(active) then
        return false
    end

    if active then
        local normalizedTarget = MSTR.Utils.NormalizeWeatherType(target)
        if not normalizedTarget or not MSTR.Utils.IsValidNumber(duration, 0.0, 300.0) then
            return false
        end

        GlobalState[KEYS.WeatherTransitioning] = true
        GlobalState[KEYS.WeatherTarget] = normalizedTarget
        GlobalState[KEYS.WeatherTransitionDuration] = duration
        return true
    end

    GlobalState[KEYS.WeatherTransitioning] = false
    GlobalState[KEYS.WeatherTarget] = ''
    GlobalState[KEYS.WeatherTransitionDuration] = 0
    return true
end

function State.GetBlackout()
    local value = GlobalState[KEYS.Blackout]
    if value == nil then
        return Config.Blackout.Default == true
    end

    return value == true
end

function State.SetBlackout(enabled)
    if not MSTR.Utils.IsValidBoolean(enabled) then
        return false
    end

    GlobalState[KEYS.Blackout] = enabled
    return true
end

function State.GetTimeFrozen()
    local value = GlobalState[KEYS.TimeFrozen]
    if value == nil then
        return Config.Time.Frozen == true
    end

    return value == true
end

function State.SetTimeFrozen(frozen)
    if not MSTR.Utils.IsValidBoolean(frozen) then
        return false
    end

    GlobalState[KEYS.TimeFrozen] = frozen
    return true
end

function State.GetTimeScale()
    local value = tonumber(GlobalState[KEYS.TimeScale])
    if value == nil then
        return Config.Time.CycleSpeed
    end

    return value
end

function State.SetTimeScale(scale)
    if not MSTR.Utils.IsValidNumber(scale, Config.Time.MinCycleSpeed, Config.Time.MaxCycleSpeed) then
        return false
    end

    GlobalState[KEYS.TimeScale] = scale
    return true
end

function State.GetTime()
    local hour = tonumber(GlobalState[KEYS.TimeHour])
    local minute = tonumber(GlobalState[KEYS.TimeMinute])

    if not MSTR.Utils.IsValidInteger(hour, 0, 23) then
        hour = Config.Time.DefaultHour
    end

    if not MSTR.Utils.IsValidInteger(minute, 0, 59) then
        minute = Config.Time.DefaultMinute
    end

    return {
        hour = hour,
        minute = minute
    }
end

function State.SetTime(hour, minute)
    if not MSTR.Utils.IsValidInteger(hour, 0, 23) or not MSTR.Utils.IsValidInteger(minute, 0, 59) then
        return false
    end

    GlobalState[KEYS.TimeHour] = hour
    GlobalState[KEYS.TimeMinute] = minute
    return true
end

function State.GetSnapshot()
    -- GlobalState hour/minute are coarse replication values. Consumers such as
    -- debug, persistence and the later NUI need the resolved live server clock.
    local time = State.GetTime()
    if MSTR.TimeEngine and MSTR.TimeEngine.GetCurrentClock then
        time = MSTR.TimeEngine.GetCurrentClock()
    end
    return {
        weather = State.GetWeather(),
        dynamicWeather = State.GetDynamicWeather(),
        weatherTransition = State.GetWeatherTransition(),
        blackout = State.GetBlackout(),
        timeFrozen = State.GetTimeFrozen(),
        timeScale = State.GetTimeScale(),
        time = time
    }
end

function State.PublishSettings()
    GlobalState['mstr:settings'] = {
        locale = Config.General.Locale,
        snowTrails = Config.Weather.EnableSnowTrails,
        affectVehicles = Config.Blackout.AffectVehicles
    }
end
