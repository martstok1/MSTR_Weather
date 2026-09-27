-- Phase 6A: read-only admin snapshots. No state setters or subscriptions.
local lastRequest = {}

RegisterNetEvent('mstr_weather:server:uiSnapshot', function(requestId)
    local player = source
    if not MSTR.Utils.IsValidInteger(player, 1, 2147483647)
        or not MSTR.Utils.IsValidInteger(requestId, 1, 2147483647) then return end

    local now = GetGameTimer()
    if lastRequest[player] and MSTR.Utils.ElapsedMs(now, lastRequest[player]) < 1000 then return end
    lastRequest[player] = now

    -- Check every refresh too, so revoking ACE closes an already open menu.
    if not MSTR.Permissions.HasAdminPermission(player) then
        TriggerClientEvent('mstr_weather:client:uiSnapshot', player, {
            requestId = requestId, allowed = false
        })
        return
    end

    TriggerClientEvent('mstr_weather:client:uiSnapshot', player, {
        requestId = requestId,
        allowed = true,
        state = MSTR.State.GetSnapshot(),
        transitionRemaining = MSTR.WeatherEngine.GetTransitionRemainingSeconds(),
        nextDynamicSeconds = MSTR.WeatherEngine.GetNextDynamicChangeSeconds(),
        -- Explicit public fields only; never send the whole config.
        settings = {
            transitionSeconds = Config.Weather.TransitionDuration,
            instantAllowed = Config.Weather.AllowInstantChange,
            snowTrails = Config.Weather.EnableSnowTrails,
            dynamicIntervalMinutes = Config.DynamicWeather.IntervalMinutes,
            minScale = Config.Time.MinCycleSpeed,
            maxScale = Config.Time.MaxCycleSpeed,
            affectVehicles = Config.Blackout.AffectVehicles,
            persistenceEnabled = Config.Persistence.Enabled
        }
    })
end)

AddEventHandler('playerDropped', function() lastRequest[source] = nil end)
