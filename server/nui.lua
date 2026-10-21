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
    panel = 'manage', settings = 'manage', user = 'manage', logs = 'manage', v2 = 'manage'
}

local function Perform(player, action, p)
    local right = actionRights[action]
    if not right then return false, 'invalid' end
    if not MSTR.Permissions.Can(player, right) then return false, 'forbidden' end
    if type(p) ~= 'table' then return false, 'invalid' end
    local actor = { player = player, origin = 'nui' }
    if action=='v2' then
        if type(p.op)~='string' or #p.op>16 then return false,'invalid' end
        if p.raw~=nil and (type(p.raw)~='string' or #p.raw>262144) then return false,'invalid' end
        local ok,result,locked
        if p.kind=='all' and p.op=='list' then
            local _,cycles,cycleLocked=MSTR.Cycles.Request(player,'list',nil,nil,nil,true)
            local _,regions=MSTR.Regions.Request(player,'list')
            return true,nil,nil,nil,{kind='all',cycles={document=cycles,locked=cycleLocked},regions=regions}
        end
        if p.kind=='cycles' then
            ok,result,locked=MSTR.Cycles.Request(player,p.op,p.revision,p.id,p.raw,true)
            if ok then
                local _,document,isLocked=MSTR.Cycles.Request(player,'list',nil,nil,nil,true)
                return true,nil,nil,nil,{kind='cycles',document=document,locked=isLocked}
            end
        elseif p.kind=='regions' then
            ok,result=MSTR.Regions.Request(player,p.op,p.revision,p.id,p.raw)
            if ok then result.kind='regions';return true,nil,nil,nil,result end
        else return false,'invalid' end
        return false,result
    end
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
        if MSTR.Cycles.IsActive() then
            if p.stopCycle~=true then return false,'cycle_active' end
            local ok,reason=MSTR.Cycles.Request(player,'stop',p.cycleRevision,'confirm',nil,true)
            if not ok then return false,reason end
        end
        local ok,reason=MSTR.WeatherEngine.SetWeather(p.weather, p.instant, actor)
        if ok then MSTR.WeatherEngine.SetDynamicWeather(false,actor) end
        return ok,reason
    elseif action == 'time' then
        return MSTR.TimeEngine.SetTime(p.hour, p.minute, actor)
    elseif action == 'scale' then
        return MSTR.TimeEngine.SetTimeScale(p.value, actor)
    elseif action == 'freeze' then
        return MSTR.TimeEngine.SetTimeFrozen(p.value, actor)
    elseif action == 'dynamic' then
        if type(p.value)~='boolean' then return false,'invalid' end
        if MSTR.Cycles.IsActive() then
            if p.stopCycle~=true then return false,'cycle_active' end
            local ok,reason=MSTR.Cycles.Request(player,'stop',p.cycleRevision,'confirm',nil,true)
            if not ok then return false,reason end
        end
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
    local ok, reason, panel, logs, v2 = Perform(player, action, payload)
    if ok and (action == 'user' or action == 'settings') then panel = MSTR.Admin.GetPanel(player) end
    TriggerClientEvent('mstr_weather:client:uiAction', player, {
        requestId = requestId, ok = ok == true, reason = reason or (not ok and 'invalid' or nil),
        panel = panel, logs = logs, v2 = v2, snapshot = Snapshot(player)
    })
end)

AddEventHandler('playerDropped', function()
    lastSnapshot[source], lastRateReply[source] = nil, nil
end)
