-- Server-authoritative Time Engine for MSTR_Weather
-- Phase 3
-- The server keeps a canonical anchor. Clients progress time locally between syncs.

MSTR = MSTR or {}
MSTR.TimeEngine = MSTR.TimeEngine or {}

local TimeEngine = MSTR.TimeEngine

local initialized = false
local correctionStarted = false
local anchorMinutes = 0.0
local anchorTimer = 0
local frozen = false
local scale = 1.0

local function Rebase(minutes)
    anchorMinutes = MSTR.Utils.WrapMinutes(minutes)
    anchorTimer = GetGameTimer()
end

local function CommitStateTime(minutes)
    local hour, minute = MSTR.Utils.MinutesToClock(minutes)
    return MSTR.State.SetTime(hour, minute)
end

function TimeEngine.Initialize()
    local stateTime = MSTR.State.GetTime()
    anchorMinutes = (stateTime.hour * 60) + stateTime.minute
    anchorTimer = GetGameTimer()
    frozen = MSTR.State.GetTimeFrozen()
    scale = MSTR.State.GetTimeScale()

    if not MSTR.Utils.IsValidNumber(scale, Config.Time.MinCycleSpeed, Config.Time.MaxCycleSpeed) then
        scale = Config.Time.CycleSpeed
        MSTR.State.SetTimeScale(scale)
    end

    initialized = true
    MSTR.Utils.Debug('Time engine initialized')
end

function TimeEngine.GetCurrentMinutes()
    if not initialized then
        return MSTR.Utils.WrapMinutes((Config.Time.DefaultHour * 60) + Config.Time.DefaultMinute)
    end

    if frozen or scale == 0 then
        return MSTR.Utils.WrapMinutes(anchorMinutes)
    end

    local elapsedSeconds = math.max(0, GetGameTimer() - anchorTimer) / 1000.0
    local progressedMinutes = elapsedSeconds * (scale / 60.0)

    return MSTR.Utils.WrapMinutes(anchorMinutes + progressedMinutes)
end

function TimeEngine.GetCurrentClock()
    local hour, minute, second = MSTR.Utils.MinutesToClock(TimeEngine.GetCurrentMinutes())
    return {
        hour = hour,
        minute = minute,
        second = second
    }
end

function TimeEngine.GetSyncPayload()
    return {
        minutes = TimeEngine.GetCurrentMinutes(),
        frozen = frozen,
        scale = scale
    }
end

function TimeEngine.SyncPlayer(source)
    local playerSource = tonumber(source)
    if not playerSource or playerSource <= 0 then
        return
    end

    TriggerClientEvent('mstr_weather:client:timeSync', playerSource, TimeEngine.GetSyncPayload())
end

function TimeEngine.BroadcastSync()
    TriggerClientEvent('mstr_weather:client:timeSync', -1, TimeEngine.GetSyncPayload())
end

function TimeEngine.SetTime(hour, minute)
    if not MSTR.Utils.IsValidInteger(hour, 0, 23) or not MSTR.Utils.IsValidInteger(minute, 0, 59) then
        return false
    end

    Rebase((hour * 60) + minute)
    MSTR.State.SetTime(hour, minute)
    TimeEngine.BroadcastSync()

    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('time changed')
    end

    MSTR.Utils.Debug(('Time set to %02d:%02d'):format(hour, minute))
    return true
end

function TimeEngine.SetTimeScale(newScale)
    if not MSTR.Utils.IsValidNumber(newScale, Config.Time.MinCycleSpeed, Config.Time.MaxCycleSpeed) then
        return false
    end

    local currentMinutes = TimeEngine.GetCurrentMinutes()
    Rebase(currentMinutes)
    scale = newScale

    if not MSTR.State.SetTimeScale(newScale) then
        return false
    end

    CommitStateTime(currentMinutes)
    TimeEngine.BroadcastSync()

    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('time scale changed')
    end

    MSTR.Utils.Debug(('Time scale set to %s'):format(tostring(newScale)))
    return true
end

function TimeEngine.SetTimeFrozen(shouldFreeze)
    if not MSTR.Utils.IsValidBoolean(shouldFreeze) then
        return false
    end

    local currentMinutes = TimeEngine.GetCurrentMinutes()
    Rebase(currentMinutes)
    frozen = shouldFreeze

    if not MSTR.State.SetTimeFrozen(shouldFreeze) then
        return false
    end

    CommitStateTime(currentMinutes)
    TimeEngine.BroadcastSync()

    if MSTR.Persistence then
        MSTR.Persistence.MarkDirty('time frozen changed')
    end

    MSTR.Utils.Debug(('Time frozen set to %s'):format(tostring(shouldFreeze)))
    return true
end

function TimeEngine.StartCorrectionScheduler()
    if correctionStarted then
        return
    end

    correctionStarted = true

    CreateThread(function()
        while true do
            local intervalSeconds = tonumber(Config.Time.CorrectionIntervalSeconds) or 60
            if intervalSeconds < 10 then
                intervalSeconds = 10
            end

            Wait(math.floor(intervalSeconds * 1000))

            local currentMinutes = TimeEngine.GetCurrentMinutes()
            CommitStateTime(currentMinutes)
            TimeEngine.BroadcastSync()
            MSTR.Utils.Debug('Periodic time correction broadcast')
        end
    end)

    MSTR.Utils.Debug('Time correction scheduler started')
end
