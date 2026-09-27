-- Main server entry point for MSTR_Weather
-- V1.0 development: Foundation + Weather + Time + Dynamic Weather + Blackout + Persistence

print('[MSTR_Weather] Server starting...')

if not Config then
    error('[MSTR_Weather] Config was not loaded before server/server.lua')
end

if not MSTR or not MSTR.Permissions or not MSTR.Persistence or not MSTR.State or not MSTR.WeatherEngine or not MSTR.TimeEngine then
    error('[MSTR_Weather] One or more server modules were not loaded before server/server.lua')
end

local function SendMessage(source, message)
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'MSTR_Weather', message }
    })
end

local function HasAdminPermission(source, right)
    if MSTR.Permissions.Can(source, right) then
        return true
    end

    SendMessage(source, 'You do not have permission to use this command.')
    return false
end

MSTR.Permissions.Initialize()
MSTR.Admin.Initialize()
local restoredState = MSTR.Persistence.Initialize()
MSTR.State.Initialize(restoredState)
MSTR.State.PublishSettings()
MSTR.WeatherEngine.Initialize()
MSTR.TimeEngine.Initialize()
MSTR.Persistence.SetReady()

local syncRequestTimes = {}

RegisterNetEvent('mstr_weather:server:requestSync', function()
    local playerSource = source
    local now = GetGameTimer()
    local lastRequest = syncRequestTimes[playerSource]

    if lastRequest and MSTR.Utils.ElapsedMs(now, lastRequest) < 1000 then
        return
    end

    syncRequestTimes[playerSource] = now
    MSTR.WeatherEngine.SyncPlayer(playerSource)
    MSTR.TimeEngine.SyncPlayer(playerSource)
end)

AddEventHandler('playerDropped', function()
    syncRequestTimes[source] = nil
end)

RegisterCommand(Config.General.DebugCommand or 'mstrdebug', function(source)
    if source == 0 then
        print('[MSTR_Weather] /mstrdebug can only be used in-game.')
        return
    end

    if not HasAdminPermission(source, 'view') then
        return
    end

    local snapshot = MSTR.State.GetSnapshot()
    local clock = MSTR.TimeEngine.GetCurrentClock()
    local transition = snapshot.weatherTransition
    local nextDynamicSeconds = MSTR.WeatherEngine.GetNextDynamicChangeSeconds()
    local nextDynamicText = nextDynamicSeconds and ('%ds'):format(math.ceil(nextDynamicSeconds)) or 'off'

    SendMessage(source, ('Core OK | Weather: %s | Time: %02d:%02d:%02d | Dynamic: %s | Next: %s | Transition: %s | Blackout: %s | Frozen: %s | Scale: %s')
        :format(
            tostring(snapshot.weather),
            clock.hour,
            clock.minute,
            clock.second,
            tostring(snapshot.dynamicWeather),
            nextDynamicText,
            tostring(transition.active),
            tostring(snapshot.blackout),
            tostring(snapshot.timeFrozen),
            tostring(snapshot.timeScale)
        ))
end, false)

RegisterCommand(Config.General.WeatherCommand or 'mstrweather', function(source, args)
    if source == 0 then
        print('[MSTR_Weather] /mstrweather can only be used in-game.')
        return
    end

    local right = args[1] and string.lower(args[1]) == 'dynamic' and 'dynamic' or 'weather'
    if not HasAdminPermission(source, right) then
        return
    end

    if #args < 1 then
        SendMessage(source, 'Usage: /mstrweather <weather_type> [smooth|instant] | /mstrweather dynamic <true|false>')
        return
    end

    if string.lower(args[1]) == 'dynamic' then
        local enabled = MSTR.Utils.ParseBoolean(args[2])
        if enabled == nil then
            SendMessage(source, 'Usage: /mstrweather dynamic <true|false>')
            return
        end

        if not MSTR.WeatherEngine.SetDynamicWeather(enabled) then
            SendMessage(source, 'Failed to change Dynamic Weather state.')
            return
        end

        SendMessage(source, 'Dynamic Weather set to ' .. tostring(enabled))
        return
    end

    local weatherType = MSTR.Utils.NormalizeWeatherType(args[1])
    if not weatherType then
        SendMessage(source, 'Invalid weather type.')
        return
    end

    local mode = args[2] and string.lower(args[2]) or 'smooth'
    if mode ~= 'smooth' and mode ~= 'instant' then
        SendMessage(source, 'Transition mode must be smooth or instant.')
        return
    end

    if mode == 'instant' and Config.Weather.AllowInstantChange ~= true then
        SendMessage(source, 'Instant weather changes are disabled in config.')
        return
    end

    local success, reason = MSTR.WeatherEngine.SetWeather(weatherType, mode == 'instant')
    if not success then
        if reason == 'transitioning' then
            SendMessage(source, 'A weather transition is active. Wait for completion or use instant.')
            return
        end
        SendMessage(source, 'Failed to change weather to ' .. weatherType)
        return
    end

    SendMessage(source, ('Weather change accepted: %s (%s)'):format(weatherType, mode))
end, false)

RegisterCommand(Config.General.TimeCommand or 'mstrtime', function(source, args)
    if source == 0 then
        print('[MSTR_Weather] /mstrtime can only be used in-game.')
        return
    end

    if not HasAdminPermission(source, 'time') then
        return
    end

    if #args < 1 then
        SendMessage(source, 'Usage: /mstrtime HH:MM | /mstrtime freeze <true|false> | /mstrtime scale <value>')
        return
    end

    local command = string.lower(args[1])

    if command == 'freeze' then
        local shouldFreeze = MSTR.Utils.ParseBoolean(args[2])
        if shouldFreeze == nil then
            SendMessage(source, 'Usage: /mstrtime freeze <true|false>')
            return
        end

        if not MSTR.TimeEngine.SetTimeFrozen(shouldFreeze) then
            SendMessage(source, 'Failed to change the frozen state.')
            return
        end

        SendMessage(source, 'Time frozen set to ' .. tostring(shouldFreeze))
        return
    end

    if command == 'scale' then
        local newScale = tonumber(args[2])
        if not newScale then
            SendMessage(source, ('Scale must be between %s and %s.')
                :format(tostring(Config.Time.MinCycleSpeed), tostring(Config.Time.MaxCycleSpeed)))
            return
        end

        if not MSTR.TimeEngine.SetTimeScale(newScale) then
            SendMessage(source, ('Scale must be between %s and %s.')
                :format(tostring(Config.Time.MinCycleSpeed), tostring(Config.Time.MaxCycleSpeed)))
            return
        end

        SendMessage(source, 'Time scale set to ' .. tostring(newScale))
        return
    end

    local hour, minute = MSTR.Utils.ParseTimeString(args[1])
    if hour == nil or minute == nil then
        SendMessage(source, 'Invalid time. Use HH:MM with hour 0-23 and minute 0-59.')
        return
    end

    if not MSTR.TimeEngine.SetTime(hour, minute) then
        SendMessage(source, 'Failed to set time.')
        return
    end

    SendMessage(source, ('Time set to %02d:%02d'):format(hour, minute))
end, false)


RegisterCommand(Config.General.BlackoutCommand or 'mstrblackout', function(source, args)
    if source == 0 then
        print('[MSTR_Weather] /mstrblackout can only be used in-game.')
        return
    end

    if not HasAdminPermission(source, 'blackout') then
        return
    end

    local enabled = MSTR.Utils.ParseBoolean(args[1])
    if enabled == nil then
        SendMessage(source, 'Usage: /mstrblackout <true|false>')
        return
    end

    if not MSTR.State.SetBlackout(enabled) then
        SendMessage(source, 'Failed to change blackout state.')
        return
    end

    MSTR.Persistence.MarkDirty('blackout changed')
    SendMessage(source, 'Blackout set to ' .. tostring(enabled))
end, false)

MSTR.WeatherEngine.StartScheduler()
MSTR.TimeEngine.StartCorrectionScheduler()

print('[MSTR_Weather] Server started successfully')
