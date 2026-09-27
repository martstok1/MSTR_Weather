-- Server-authoritative Weather Engine for MSTR_Weather
-- Weather transitions and weighted dynamic weather scheduling.

MSTR = MSTR or {}
MSTR.WeatherEngine = MSTR.WeatherEngine or {}

local WeatherEngine = MSTR.WeatherEngine

local schedulerStarted = false
local transitionSerial = 0
local activeTransition = nil
local dynamicTimer = nil
local schedulerGeneration = 0

local function GetWeightedChoice(weights)
    if type(weights) ~= 'table' then
        return nil
    end

    local totalWeight = 0.0

    for weatherType, weight in pairs(weights) do
        if MSTR.Utils.IsValidWeatherType(weatherType) and MSTR.Utils.IsValidNumber(weight, 0.000001, 1000000) then
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local cumulative = 0.0

    for weatherType, weight in pairs(weights) do
        if MSTR.Utils.IsValidWeatherType(weatherType) and MSTR.Utils.IsValidNumber(weight, 0.000001, 1000000) then
            cumulative = cumulative + weight

            if roll <= cumulative then
                return MSTR.Utils.NormalizeWeatherType(weatherType)
            end
        end
    end

    return nil
end

local function GetTransitionDuration()
    local duration = tonumber(Config.Weather.TransitionDuration) or 30

    if duration < 0 then
        duration = 0
    elseif duration > 300 then
        duration = 300
    end

    return duration
end

local function GetDynamicIntervalMs()
    local minutes = tonumber(Config.DynamicWeather.IntervalMinutes) or 15
    local minimum = tonumber(Config.DynamicWeather.MinIntervalMinutes) or 0.1
    local maximum = tonumber(Config.DynamicWeather.MaxIntervalMinutes) or 1440

    if minimum <= 0 then
        minimum = 0.1
    end

    if maximum < minimum then
        maximum = minimum
    end

    if minutes < minimum then
        minutes = minimum
    elseif minutes > maximum then
        minutes = maximum
    end

    return math.max(1000, math.floor(minutes * 60000))
end

local function ResetDynamicTimer(reason)
    if not MSTR.State.GetDynamicWeather() then
        dynamicTimer = nil
        return
    end

    dynamicTimer = { started = GetGameTimer(), interval = GetDynamicIntervalMs() }

    if reason then
        MSTR.Utils.Debug(('Dynamic weather timer reset (%s)'):format(reason))
    end
end

local function BroadcastWeather(currentWeather, targetWeather, duration)
    TriggerClientEvent('mstr_weather:client:weatherSync', -1, {
        currentWeather = currentWeather,
        targetWeather = targetWeather,
        transitionDuration = duration,
        transitionElapsed = 0
    })
end

local function CompleteTransition(serial, targetWeather)
    if serial ~= transitionSerial or not activeTransition then
        return
    end

    local previous = MSTR.State.GetWeather()
    if not MSTR.State.SetWeather(targetWeather) then
        MSTR.Utils.Warn(('Failed to commit weather transition target %s'):format(tostring(targetWeather)))
        return
    end

    activeTransition = nil
    MSTR.State.SetWeatherTransition(false, nil, 0)
    BroadcastWeather(targetWeather, targetWeather, 0)

    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('weather transition completed')
    end

    MSTR.Utils.Debug(('Weather transition completed: %s'):format(targetWeather))
    MSTR.Logging.Record('transition', previous, targetWeather, { origin = 'transition' })
end

function WeatherEngine.Initialize()
    math.randomseed(os.time() + GetGameTimer())

    local currentWeather = MSTR.State.GetWeather()

    if not MSTR.Utils.IsValidWeatherType(currentWeather) then
        MSTR.State.SetWeather(Config.Weather.Default)
    end

    -- A resource restart starts with a clean transition state.
    MSTR.State.SetWeatherTransition(false, nil, 0)
    activeTransition = nil
    transitionSerial = 0
    dynamicTimer = nil

    MSTR.Utils.Debug('Weather engine initialized')
end

function WeatherEngine.IsTransitioning()
    return activeTransition ~= nil
end

-- A missing/broken graph must not suddenly turn fog into a thunderstorm.
local SAFE_NEXT = {
    EXTRASUNNY = 'CLEAR', CLEAR = 'CLOUDS', CLOUDS = 'CLEAR',
    SMOG = 'CLOUDS', FOGGY = 'CLOUDS', OVERCAST = 'CLOUDS',
    RAIN = 'CLEARING', THUNDER = 'RAIN', CLEARING = 'CLOUDS',
    NEUTRAL = 'CLEAR', SNOW = 'SNOWLIGHT', BLIZZARD = 'SNOW',
    SNOWLIGHT = 'CLEARING', XMAS = 'SNOWLIGHT', HALLOWEEN = 'FOGGY'
}

function WeatherEngine.GetNextWeatherType(currentWeather)
    local normalized = MSTR.Utils.NormalizeWeatherType(currentWeather)

    if not normalized then
        return MSTR.Utils.NormalizeWeatherType(Config.Weather.Default) or 'CLEAR'
    end

    local transitions = Config.Weather.Transitions
    local transitionMap = type(transitions) == 'table' and transitions[normalized] or nil
    local selected = GetWeightedChoice(transitionMap)

    if selected then
        return selected
    end

    MSTR.Utils.Warn(('No usable transition graph entry for %s; using safe fallback')
        :format(normalized))

    return SAFE_NEXT[normalized] or 'CLEAR'
end

function WeatherEngine.SetWeather(weatherType, instant, actor)
    local targetWeather = MSTR.Utils.NormalizeWeatherType(weatherType)

    if not targetWeather then
        MSTR.Utils.Debug(('Rejected invalid weather type: %s'):format(tostring(weatherType)))
        return false
    end

    local currentWeather = MSTR.State.GetWeather()
    local useInstant = instant == true and Config.Weather.AllowInstantChange == true
    local previous = { weather = currentWeather, target = activeTransition and activeTransition.target or currentWeather }

    -- A third weather cannot be represented by the current two-weather blend.
    -- Keep the active blend intact; admins can explicitly interrupt with instant.
    if activeTransition and not useInstant and GetTransitionDuration() > 0 then
        return false, 'transitioning'
    end

    transitionSerial = transitionSerial + 1
    local serial = transitionSerial

    if useInstant or GetTransitionDuration() <= 0 then
        activeTransition = nil
        MSTR.State.SetWeatherTransition(false, nil, 0)

        if not MSTR.State.SetWeather(targetWeather) then
            return false
        end

        BroadcastWeather(targetWeather, targetWeather, 0)
        ResetDynamicTimer('weather changed')

        if MSTR.Persistence then
            MSTR.Persistence.MarkDirty('weather changed')
        end

        MSTR.Utils.Debug(('Weather set instantly: %s'):format(targetWeather))
        MSTR.Logging.Record('weather', previous, { weather = targetWeather, mode = 'instant', duration = 0 }, actor)
        return true
    end

    if currentWeather == targetWeather and not activeTransition then
        BroadcastWeather(currentWeather, currentWeather, 0)
        ResetDynamicTimer('weather unchanged')
        MSTR.Logging.Record('weather', previous, { weather = targetWeather, mode = 'unchanged', duration = 0 }, actor)
        return true
    end

    local duration = GetTransitionDuration()

    activeTransition = {
        serial = serial,
        from = currentWeather,
        target = targetWeather,
        startTimer = GetGameTimer(),
        durationMs = math.floor(duration * 1000)
    }

    if not MSTR.State.SetWeatherTransition(true, targetWeather, duration) then
        activeTransition = nil
        return false
    end

    BroadcastWeather(currentWeather, targetWeather, duration)
    ResetDynamicTimer('weather transition started')
    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('weather transition accepted')
    end

    MSTR.Utils.Debug(('Weather transition started: %s -> %s (%ss)')
        :format(currentWeather, targetWeather, tostring(duration)))
    MSTR.Logging.Record('weather', previous, { weather = targetWeather, mode = 'smooth', duration = duration }, actor)

    CreateThread(function()
        Wait(math.floor(duration * 1000))
        CompleteTransition(serial, targetWeather)
    end)

    return true
end

function WeatherEngine.SetDynamicWeather(enabled, actor)
    if not MSTR.Utils.IsValidBoolean(enabled) then
        return false
    end

    local previous = MSTR.State.GetDynamicWeather()
    if not MSTR.State.SetDynamicWeather(enabled) then
        return false
    end

    if enabled then
        ResetDynamicTimer('dynamic weather enabled')
        WeatherEngine.StartScheduler()
    else
        dynamicTimer = nil
        schedulerGeneration = schedulerGeneration + 1
        schedulerStarted = false
        MSTR.Utils.Debug('Dynamic weather disabled; current weather left unchanged')
    end

    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('dynamic weather changed')
    end

    if previous ~= enabled then MSTR.Logging.Record('dynamic', previous, enabled, actor) end
    return true
end

function WeatherEngine.GetTransitionRemainingSeconds()
    if not activeTransition then
        return 0
    end

    local elapsedMs = MSTR.Utils.ElapsedMs(GetGameTimer(), activeTransition.startTimer)
    local remainingMs = activeTransition.durationMs - elapsedMs

    if remainingMs <= 0 then
        return 0
    end

    return remainingMs / 1000.0
end

function WeatherEngine.SettingsChanged()
    ResetDynamicTimer('interval settings changed')
end

function WeatherEngine.GetNextDynamicChangeSeconds()
    if not MSTR.State.GetDynamicWeather() or not dynamicTimer then
        return nil
    end

    local remainingMs = dynamicTimer.interval - MSTR.Utils.ElapsedMs(GetGameTimer(), dynamicTimer.started)

    if remainingMs <= 0 then
        return 0
    end

    return remainingMs / 1000.0
end

function WeatherEngine.SyncPlayer(source)
    local playerSource = tonumber(source)

    if not playerSource or playerSource <= 0 then
        return
    end

    if activeTransition then
        local remaining = WeatherEngine.GetTransitionRemainingSeconds()

        if remaining <= 0 then
            CompleteTransition(activeTransition.serial, activeTransition.target)
        else
            TriggerClientEvent('mstr_weather:client:weatherSync', playerSource, {
                currentWeather = MSTR.State.GetWeather(),
                targetWeather = activeTransition.target,
                transitionDuration = activeTransition.durationMs / 1000.0,
                transitionElapsed = (activeTransition.durationMs / 1000.0) - remaining
            })
            return
        end
    end

    local currentWeather = MSTR.State.GetWeather()

    TriggerClientEvent('mstr_weather:client:weatherSync', playerSource, {
        currentWeather = currentWeather,
        targetWeather = currentWeather,
        transitionDuration = 0,
        transitionElapsed = 0
    })
end

function WeatherEngine.RunDynamicCycle()
    if not MSTR.State.GetDynamicWeather() then
        return false, 'disabled'
    end

    if WeatherEngine.IsTransitioning() then
        return false, 'transitioning'
    end

    local currentWeather = MSTR.State.GetWeather()
    local nextWeather = WeatherEngine.GetNextWeatherType(currentWeather)

    if not nextWeather then
        ResetDynamicTimer('no weather selected')
        return false, 'no_selection'
    end

    if nextWeather == currentWeather then
        ResetDynamicTimer('same weather selected')
        MSTR.Utils.Debug(('Dynamic weather kept current weather: %s'):format(currentWeather))
        return true, 'unchanged'
    end

    local success = WeatherEngine.SetWeather(nextWeather, false, { origin = 'dynamic' })

    if not success then
        ResetDynamicTimer('weather change failed')
        return false, 'failed'
    end

    MSTR.Utils.Debug(('Dynamic weather selected: %s -> %s')
        :format(currentWeather, nextWeather))

    return true, nextWeather
end

function WeatherEngine.StartScheduler()
    if schedulerStarted or not MSTR.State.GetDynamicWeather() then
        return
    end

    schedulerStarted = true
    schedulerGeneration = schedulerGeneration + 1
    local generation = schedulerGeneration

    if MSTR.State.GetDynamicWeather() then
        ResetDynamicTimer('scheduler started')
    end

    CreateThread(function()
        while generation == schedulerGeneration and MSTR.State.GetDynamicWeather() do
            Wait(1000)
            if generation ~= schedulerGeneration or not MSTR.State.GetDynamicWeather() then
                return
            end

            if not dynamicTimer then
                ResetDynamicTimer('scheduler resumed')
            elseif WeatherEngine.GetNextDynamicChangeSeconds() <= 0 then
                if WeatherEngine.IsTransitioning() then
                    -- Never stack automatic transitions. If a transition is still
                    -- active when the interval expires, wait a fresh interval.
                    ResetDynamicTimer('transition still active')
                else
                    WeatherEngine.RunDynamicCycle()
                end
            end
        end
    end)

    MSTR.Utils.Debug('Dynamic weather scheduler started')
end
