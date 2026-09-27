-- NUI transport: authorization/validation on every request, engines own mutations.
local lastSnapshot, lastRateReply = {}, {}
local function Snapshot(player)
    local permissions = MSTR.Permissions.GetCapabilities(player)
    if not permissions.view then return { allowed = false, locale = Config.General.Locale } end
    -- Only control constraints belong in ordinary snapshots; full settings are headadmin-only.
    local settings = { minScale = Config.Time.MinCycleSpeed, maxScale = Config.Time.MaxCycleSpeed,
        instantAllowed = Config.Weather.AllowInstantChange }
    return {
        allowed = true, locale = Config.General.Locale, permissions = permissions, state = MSTR.State.GetSnapshot(),
        transitionRemaining = MSTR.WeatherEngine.GetTransitionRemainingSeconds(),
        nextDynamicSeconds = MSTR.WeatherEngine.GetNextDynamicChangeSeconds(),
        settings = settings, weatherTypes = MSTR.Constants.WeatherTypes,
        branding = { name = Config.Branding.Name, logo = Config.Branding.Logo, showName = Config.Branding.ShowName }
    }
end

local function ValidRequest(player, id)
    return MSTR.Utils.IsValidInteger(player, 1, 2147483647)
        and MSTR.Utils.IsValidInteger(id, 1, 2147483647)
end

RegisterNetEvent('mstr_weather:server:uiSnapshot', function(requestId)
    local player, now = source, GetGameTimer()
    if not ValidRequest(player, requestId) then return end
    if lastSnapshot[player] and MSTR.Utils.ElapsedMs(now, lastSnapshot[player]) < 1000 then return end
    lastSnapshot[player] = now
    local payload = Snapshot(player)
    payload.requestId = requestId
    TriggerClientEvent('mstr_weather:client:uiSnapshot', player, payload)
end)

local actionRights = {
    weather = 'weather', time = 'time', freeze = 'time', scale = 'time',
    dynamic = 'dynamic', blackout = 'blackout',
    panel = 'manage', settings = 'manage', user = 'manage', logs = 'manage'
}

local function Perform(player, action, p)
    local right = actionRights[action]
    if not right then return false, 'invalid' end
    if not MSTR.Permissions.Can(player, right) then return false, 'forbidden' end
    if type(p) ~= 'table' then return false, 'invalid' end
    local actor = { player = player, origin = 'nui' }
    if action == 'logs' then
        local page, reason = MSTR.Logging.GetPage(player, p.before)
        return page ~= nil, reason, nil, page
    end
    if action == 'panel' then return true, nil, MSTR.Admin.GetPanel(player) end
    if action == 'settings' then
        return MSTR.Admin.UpdateSettings(player, p.settings, p.revision)
    elseif action == 'user' then
        return MSTR.Admin.UpdateUser(player, p.identifier, p.name, p.rights, p.revision)
    elseif action == 'weather' then
        if not MSTR.Utils.IsValidWeatherType(p.weather) or type(p.instant) ~= 'boolean' then return false, 'invalid' end
        if p.instant and not Config.Weather.AllowInstantChange then return false, 'instant_disabled' end
        return MSTR.WeatherEngine.SetWeather(p.weather, p.instant, actor)
    elseif action == 'time' then
        return MSTR.TimeEngine.SetTime(p.hour, p.minute, actor)
    elseif action == 'scale' then
        return MSTR.TimeEngine.SetTimeScale(p.value, actor)
    elseif action == 'freeze' then
        return MSTR.TimeEngine.SetTimeFrozen(p.value, actor)
    elseif action == 'dynamic' then
        return MSTR.WeatherEngine.SetDynamicWeather(p.value, actor)
    elseif action == 'blackout' then
        if not MSTR.State.SetBlackout(p.value, actor) then return false, 'invalid' end
        MSTR.Persistence.MarkDirty('NUI blackout')
        return true
    end
    return false, 'invalid'
end

RegisterNetEvent('mstr_weather:server:uiAction', function(requestId, action, payload)
    local player, now = source, GetGameTimer()
    if not ValidRequest(player, requestId) or type(action) ~= 'string' or #action > 24 then return end
    if not MSTR.Requests.Allow(player) then
        if not lastRateReply[player] or MSTR.Utils.ElapsedMs(now, lastRateReply[player]) >= 500 then
            lastRateReply[player] = now
            TriggerClientEvent('mstr_weather:client:uiAction', player, { requestId = requestId, ok = false, reason = 'rate' })
        end
        return
    end
    local ok, reason, panel, logs = Perform(player, action, payload)
    if ok and (action == 'user' or action == 'settings') then panel = MSTR.Admin.GetPanel(player) end
    TriggerClientEvent('mstr_weather:client:uiAction', player, {
        requestId = requestId, ok = ok == true, reason = reason or (not ok and 'invalid' or nil),
        panel = panel, logs = logs, snapshot = Snapshot(player)
    })
end)

AddEventHandler('playerDropped', function()
    lastSnapshot[source], lastRateReply[source] = nil, nil
end)
