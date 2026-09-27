-- Server-authoritative Weather Engine for MSTR_Weather
-- Phase 2 + Phase 4 Dynamic Weather

MSTR = MSTR or {}
MSTR.WeatherEngine = MSTR.WeatherEngine or {}

local WeatherEngine = MSTR.WeatherEngine

local schedulerStarted = false
local transitionSerial = 0
local activeTransition = nil
local nextDynamicDecisionAt = nil

local function GetWeightedChoice(weights)
    if type(weights) ~= 'table' then
        return nil
    end

    local totalWeight = 0.0

    for weatherType, weight in pairs(weights) do
        if MSTR.Utils.IsValidWeatherType(weatherType) and type(weight) == 'number' and weight > 0 then
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local cumulative = 0.0

    for weatherType, weight in pairs(weights) do
        if MSTR.Utils.IsValidWeatherType(weatherType) and type(weight) == 'number' and weight > 0 then
            cumulative = cumulative + weight

            if roll <= cumulative then
                return weatherType
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
        nextDynamicDecisionAt = nil
        return
    end

    nextDynamicDecisionAt = GetGameTimer() + GetDynamicIntervalMs()

    if reason then
        MSTR.Utils.Debug(('Dynamic weather timer reset (%s)'):format(reason))
    end
end

local function BroadcastWeather(currentWeather, targetWeather, duration)
    TriggerClientEvent('mstr_weather:client:weatherSync', -1, {
        currentWeather = currentWeather,
        targetWeather = targetWeather,
        transitionDuration = duration
    })
end

local function CompleteTransition(serial, targetWeather)
    if serial ~= transitionSerial then
        return
    end

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
    nextDynamicDecisionAt = nil

    MSTR.Utils.Debug('Weather engine initialized')
end

function WeatherEngine.IsTransitioning()
    return activeTransition ~= nil
end

function WeatherEngine.GetRandomWeatherType()
    return GetWeightedChoice(Config.Weather.Weights) or MSTR.State.GetWeather()
end

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

    MSTR.Utils.Debug(('No usable transition graph entry for %s; using fallback weights')
        :format(normalized))

    return WeatherEngine.GetRandomWeatherType()
end

function WeatherEngine.SetWeather(weatherType, instant)
    local targetWeather = MSTR.Utils.NormalizeWeatherType(weatherType)

    if not targetWeather then
        MSTR.Utils.Debug(('Rejected invalid weather type: %s'):format(tostring(weatherType)))
        return false
    end

    local currentWeather = MSTR.State.GetWeather()
    local useInstant = instant == true and Config.Weather.AllowInstantChange == true

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
        return true
    end

    if currentWeather == targetWeather and not activeTransition then
        BroadcastWeather(currentWeather, currentWeather, 0)
        ResetDynamicTimer('weather unchanged')
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

    MSTR.Utils.Debug(('Weather transition started: %s -> %s (%ss)')
        :format(currentWeather, targetWeather, tostring(duration)))

    CreateThread(function()
        Wait(math.floor(duration * 1000))
        CompleteTransition(serial, targetWeather)
    end)

    return true
end

function WeatherEngine.SetDynamicWeather(enabled)
    if not MSTR.Utils.IsValidBoolean(enabled) then
        return false
    end

    if not MSTR.State.SetDynamicWeather(enabled) then
        return false
    end

    if enabled then
        ResetDynamicTimer('dynamic weather enabled')
    else
        nextDynamicDecisionAt = nil
        MSTR.Utils.Debug('Dynamic weather disabled; current weather left unchanged')
    end

    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('dynamic weather changed')
    end

    return true
end

function WeatherEngine.GetTransitionRemainingSeconds()
    if not activeTransition then
        return 0
    end

    local elapsedMs = GetGameTimer() - activeTransition.startTimer
    local remainingMs = activeTransition.durationMs - elapsedMs

    if remainingMs <= 0 then
        return 0
    end

    return remainingMs / 1000.0
end

function WeatherEngine.GetNextDynamicChangeSeconds()
    if not MSTR.State.GetDynamicWeather() or not nextDynamicDecisionAt then
        return nil
    end

    local remainingMs = nextDynamicDecisionAt - GetGameTimer()

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
                transitionDuration = remaining
            })
            return
        end
    end

    local currentWeather = MSTR.State.GetWeather()

    TriggerClientEvent('mstr_weather:client:weatherSync', playerSource, {
        currentWeather = currentWeather,
        targetWeather = currentWeather,
        transitionDuration = 0
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

    local success = WeatherEngine.SetWeather(nextWeather, false)

    if not success then
        ResetDynamicTimer('weather change failed')
        return false, 'failed'
    end

    MSTR.Utils.Debug(('Dynamic weather selected: %s -> %s')
        :format(currentWeather, nextWeather))

    return true, nextWeather
end

function WeatherEngine.StartScheduler()
    if schedulerStarted then
        return
    end

    schedulerStarted = true

    if MSTR.State.GetDynamicWeather() then
        ResetDynamicTimer('scheduler started')
    end

    CreateThread(function()
        while true do
            Wait(1000)

            if not MSTR.State.GetDynamicWeather() then
                nextDynamicDecisionAt = nil
            else
                if not nextDynamicDecisionAt then
                    ResetDynamicTimer('scheduler resumed')
                elseif GetGameTimer() >= nextDynamicDecisionAt then
                    if WeatherEngine.IsTransitioning() then
                        -- Never stack automatic transitions. If a transition is still
                        -- active when the interval expires, wait a fresh interval.
                        ResetDynamicTimer('transition still active')
                    else
                        WeatherEngine.RunDynamicCycle()
                    end
                end
            end
        end
    end)

    MSTR.Utils.Debug('Dynamic weather scheduler started')
end
