-- Resource-local JSON persistence for MSTR_Weather
-- Phase 5: Blackout + Persistence

MSTR = MSTR or {}
MSTR.Persistence = MSTR.Persistence or {}

local Persistence = MSTR.Persistence

local initialized = false
local saveGeneration = 0
local resourceName = GetCurrentResourceName()

local function GetFilePath()
    local configured = Config.Persistence and Config.Persistence.File or 'data/state.json'

    if type(configured) ~= 'string' or configured == ''
        or configured:find('..', 1, true)
        or configured:sub(1, 1) == '@'
        or configured:sub(1, 1) == '/'
        or configured:sub(1, 1) == '\\' then
        MSTR.Utils.Warn('Invalid persistence file path; using data/state.json')
        return 'data/state.json'
    end

    return configured
end

local function DecodeJson(raw)
    if type(raw) ~= 'string' or raw == '' then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end

    return decoded
end

local function ValidateLoadedState(data)
    local restored = {}
    local validFields = 0

    if MSTR.Utils.IsValidWeatherType(data.weather) then
        restored.weather = MSTR.Utils.NormalizeWeatherType(data.weather)
        validFields = validFields + 1
    elseif data.weather ~= nil then
        MSTR.Utils.Warn('Ignored invalid persisted weather value')
    end

    if MSTR.Utils.IsValidBoolean(data.dynamicWeather) then
        restored.dynamicWeather = data.dynamicWeather
        validFields = validFields + 1
    elseif data.dynamicWeather ~= nil then
        MSTR.Utils.Warn('Ignored invalid persisted Dynamic Weather value')
    end

    if MSTR.Utils.IsValidBoolean(data.blackout) then
        restored.blackout = data.blackout
        validFields = validFields + 1
    elseif data.blackout ~= nil then
        MSTR.Utils.Warn('Ignored invalid persisted blackout value')
    end

    if MSTR.Utils.IsValidBoolean(data.timeFrozen) then
        restored.timeFrozen = data.timeFrozen
        validFields = validFields + 1
    elseif data.timeFrozen ~= nil then
        MSTR.Utils.Warn('Ignored invalid persisted timeFrozen value')
    end

    if MSTR.Utils.IsValidNumber(data.timeScale, Config.Time.MinCycleSpeed, Config.Time.MaxCycleSpeed) then
        restored.timeScale = data.timeScale
        validFields = validFields + 1
    elseif data.timeScale ~= nil then
        MSTR.Utils.Warn('Ignored invalid persisted timeScale value')
    end

    -- Current format uses a nested time object. Flat fields are accepted only
    -- for backwards compatibility with early development builds.
    local time = type(data.time) == 'table' and data.time or nil
    local hour = time and time.hour or data.timeHour
    local minute = time and time.minute or data.timeMinute

    if MSTR.Utils.IsValidInteger(hour, 0, 23) and MSTR.Utils.IsValidInteger(minute, 0, 59) then
        restored.time = { hour = hour, minute = minute }
        validFields = validFields + 1
    elseif hour ~= nil or minute ~= nil then
        MSTR.Utils.Warn('Ignored invalid persisted time value')
    end

    if validFields == 0 then
        return nil
    end

    return restored
end

function Persistence.LoadState()
    if not Config.Persistence or Config.Persistence.Enabled ~= true then
        return nil
    end

    local path = GetFilePath()
    local raw = LoadResourceFile(resourceName, path)

    if raw == nil then
        MSTR.Utils.Debug(('No persistence file found at %s; using config defaults'):format(path))
        return nil
    end

    local decoded = DecodeJson(raw)
    if not decoded then
        MSTR.Utils.Warn(('Persistence file %s is invalid JSON; using valid config defaults'):format(path))
        return nil
    end

    local restored = ValidateLoadedState(decoded)
    if not restored then
        MSTR.Utils.Debug(('Persistence file %s contains no usable state; using config defaults'):format(path))
        return nil
    end

    MSTR.Utils.Debug(('Loaded persisted state from %s'):format(path))
    return restored
end

local function BuildSaveData()
    local snapshot = MSTR.State.GetSnapshot()
    local clock = snapshot.time

    -- Persist the resolved live time, not the last periodic GlobalState correction.
    if MSTR.TimeEngine and MSTR.TimeEngine.GetCurrentClock then
        local resolved = MSTR.TimeEngine.GetCurrentClock()
        if type(resolved) == 'table'
            and MSTR.Utils.IsValidInteger(resolved.hour, 0, 23)
            and MSTR.Utils.IsValidInteger(resolved.minute, 0, 59) then
            clock = {
                hour = resolved.hour,
                minute = resolved.minute
            }
        end
    end

    return {
        version = 1,
        weather = snapshot.weather,
        dynamicWeather = snapshot.dynamicWeather,
        blackout = snapshot.blackout,
        timeFrozen = snapshot.timeFrozen,
        timeScale = snapshot.timeScale,
        time = {
            hour = clock.hour,
            minute = clock.minute
        }
    }
end

function Persistence.SaveState(reason)
    if not Config.Persistence or Config.Persistence.Enabled ~= true then
        return false
    end

    if not MSTR.State then
        return false
    end

    local data = BuildSaveData()
    local ok, encoded = pcall(json.encode, data)

    if not ok or type(encoded) ~= 'string' or encoded == '' then
        MSTR.Utils.Warn('Failed to encode persistence state')
        return false
    end

    local path = GetFilePath()
    local saved = SaveResourceFile(resourceName, path, encoded, #encoded)

    if saved ~= true and saved ~= 1 then
        MSTR.Utils.Warn(('Failed to save state to %s'):format(path))
        return false
    end

    MSTR.Utils.Debug(('Persisted state to %s%s'):format(
        path,
        reason and (' (' .. tostring(reason) .. ')') or ''
    ))

    return true
end

function Persistence.MarkDirty(reason)
    if not initialized or not Config.Persistence or Config.Persistence.Enabled ~= true then
        return
    end

    saveGeneration = saveGeneration + 1
    local generation = saveGeneration
    local debounceMs = tonumber(Config.Persistence.DebounceMs) or 1500

    if debounceMs < 0 then
        debounceMs = 0
    elseif debounceMs > 30000 then
        debounceMs = 30000
    end

    CreateThread(function()
        Wait(math.floor(debounceMs))

        if generation ~= saveGeneration then
            return
        end

        Persistence.SaveState(reason or 'state changed')
    end)
end

function Persistence.Initialize()
    if not Config.Persistence or Config.Persistence.Enabled ~= true then
        MSTR.Utils.Debug('Persistence disabled by config')
        initialized = false
        return nil
    end

    local restored = Persistence.LoadState()
    initialized = true
    MSTR.Utils.Debug('Persistence initialized')
    return restored
end

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource ~= resourceName or not initialized then
        return
    end

    -- Flush the latest resolved state once on a clean resource stop.
    Persistence.SaveState('resource stop')
end)
