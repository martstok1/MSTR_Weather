-- Client Time Engine for MSTR_Weather
-- Progresses the clock locally from a server-authoritative anchor.

MSTR = MSTR or {}
MSTR.ClientTime = MSTR.ClientTime or {}

local ClientTime = MSTR.ClientTime

local synced = false
local anchorMinutes = 0.0
local anchorTimer = 0
local frozen = false
local scale = 1.0

function ClientTime.ApplySync(payload)
    if type(payload) ~= 'table' then
        return
    end

    local minutes = tonumber(payload.minutes)
    local newScale = tonumber(payload.scale)
    local newFrozen = payload.frozen

    if not MSTR.Utils.IsValidNumber(minutes, 0, 1440) then
        MSTR.Utils.Warn('Rejected invalid client time sync: minutes')
        return
    end

    if not MSTR.Utils.IsValidNumber(newScale, Config.Time.MinCycleSpeed, Config.Time.MaxCycleSpeed) then
        MSTR.Utils.Warn('Rejected invalid client time sync: scale')
        return
    end

    if not MSTR.Utils.IsValidBoolean(newFrozen) then
        MSTR.Utils.Warn('Rejected invalid client time sync: frozen')
        return
    end

    anchorMinutes = MSTR.Utils.WrapMinutes(minutes)
    anchorTimer = GetGameTimer()
    scale = newScale
    frozen = newFrozen
    synced = true

    MSTR.Utils.Debug(('Client time sync: minutes=%.3f scale=%s frozen=%s')
        :format(anchorMinutes, tostring(scale), tostring(frozen)))
    return true
end

function ClientTime.IsSynced()
    return synced
end

function ClientTime.GetCurrentMinutes()
    if not synced or frozen or scale == 0 then
        return MSTR.Utils.WrapMinutes(anchorMinutes)
    end

    local elapsedSeconds = MSTR.Utils.ElapsedMs(GetGameTimer(), anchorTimer) / 1000.0
    return MSTR.Utils.WrapMinutes(anchorMinutes + (elapsedSeconds * (scale / 60.0)))
end

RegisterNetEvent('mstr_weather:client:timeSync', function(payload)
    ClientTime.ApplySync(payload)
end)

CreateThread(function()
    while true do
        if synced then
            local hour, minute, second = MSTR.Utils.MinutesToClock(ClientTime.GetCurrentMinutes())
            NetworkOverrideClockTime(hour, minute, second)
            Wait(math.max(50, tonumber(Config.Time.ClientTickMs) or 250))
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    NetworkClearClockTimeOverride()
end)
