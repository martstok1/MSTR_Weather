-- Resource-local JSON persistence for MSTR_Weather
-- Validated environment storage with backup recovery.

MSTR = MSTR or {}
MSTR.Persistence = MSTR.Persistence or {}

local Persistence = MSTR.Persistence

local initialized = false
local ready = false
local saveGeneration = 0
local workerRunning = false
local lastMutationAt = 0
local lastGoodRaw = nil
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
    if type(raw) ~= 'string' or raw == '' or #raw > 262144 then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end

    return decoded
end

local function ValidateLoadedState(data)
    -- No version is accepted for early development files; reject future formats.
    if data.version ~= nil and data.version ~= 1 then
        MSTR.Utils.Warn('Unsupported persistence version; trying backup/defaults')
        return nil
    end
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
    for _, candidate in ipairs({ path, path .. '.bak' }) do
        local raw = LoadResourceFile(resourceName, candidate)
        if raw ~= nil then
            local decoded = DecodeJson(raw)
            local restored = decoded and ValidateLoadedState(decoded) or nil
            if restored then
                lastGoodRaw = raw
                if candidate ~= path then
                    MSTR.Utils.Warn('Recovered persistence from ' .. candidate)
                end
                return restored
            end
            MSTR.Utils.Warn('Invalid/empty persistence file ' .. candidate .. '; trying backup/defaults')
        end
    end
    return nil
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
        -- Accepted transitions restore at their destination after a restart.
        -- Intermediate blend/timer state is intentionally not persisted.
        weather = snapshot.weatherTransition.active and snapshot.weatherTransition.target or snapshot.weather,
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

    if not ready or not MSTR.State then
        return false
    end

    local data = BuildSaveData()
    local ok, encoded = pcall(json.encode, data)

    if not ok or type(encoded) ~= 'string' or encoded == '' then
        MSTR.Utils.Warn('Failed to encode persistence state')
        return false
    end

    local path = GetFilePath()
    -- Keep the previous known-good state before replacing the primary file.
    -- On the first save, seed the backup with the new valid state instead.
    local backup = lastGoodRaw or encoded
    local backupSaved = SaveResourceFile(resourceName, path .. '.bak', backup, #backup)
    if (backupSaved ~= true and backupSaved ~= 1) or LoadResourceFile(resourceName, path .. '.bak') ~= backup then
        MSTR.Utils.Warn('Failed to write persistence backup; keeping primary untouched')
        return false
    end
    local saved = SaveResourceFile(resourceName, path, encoded, #encoded)

    if (saved ~= true and saved ~= 1) or LoadResourceFile(resourceName, path) ~= encoded then
        MSTR.Utils.Warn(('Failed to save state to %s'):format(path))
        return false
    end
    lastGoodRaw = encoded

    MSTR.Utils.Debug(('Persisted state to %s%s'):format(
        path,
        reason and (' (' .. tostring(reason) .. ')') or ''
    ))

    return true
end

function Persistence.MarkDirty(reason)
    if not ready or not initialized or not Config.Persistence or Config.Persistence.Enabled ~= true then
        return
    end

    saveGeneration = saveGeneration + 1
    lastMutationAt = GetGameTimer()
    if workerRunning then return end
    workerRunning = true
    local debounceMs = tonumber(Config.Persistence.DebounceMs) or 1500

    if debounceMs < 0 then
        debounceMs = 0
    elseif debounceMs > 30000 then
        debounceMs = 30000
    end

    CreateThread(function()
        local attempts = 0
        while ready do
            local remaining = debounceMs - MSTR.Utils.ElapsedMs(GetGameTimer(), lastMutationAt)
            if remaining > 0 then
                Wait(math.floor(remaining))
            else
                local generation = saveGeneration
                if Persistence.SaveState(reason or 'state changed') then
                    if generation == saveGeneration then break end
                    attempts = 0
                else
                    attempts = attempts + 1
                    if attempts >= 3 then
                        MSTR.Utils.Warn('Persistence failed after 3 attempts; next mutation/clean stop will retry')
                        break
                    end
                    Wait(5000)
                end
            end
        end
        workerRunning = false
    end)
end

function Persistence.SetReady()
    ready = initialized
end

function Persistence.SetEnabled(enabled)
    Config.Persistence.Enabled = enabled == true
    if enabled then
        initialized, ready = true, true
        -- Enabling saves live state; it must never load an old saved clock/weather.
        Persistence.MarkDirty('persistence enabled')
    else
        ready = false
    end
end

function Persistence.Initialize()
    ready = false
    lastGoodRaw = nil
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
    if stoppedResource ~= resourceName or not ready then
        return
    end

    -- Flush the latest resolved state once on a clean resource stop.
    Persistence.SaveState('resource stop')
    ready = false
end)
