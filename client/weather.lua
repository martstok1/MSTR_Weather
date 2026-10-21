-- Client weather application. The server owns the from/target/progress state.
MSTR = MSTR or {}
MSTR.ClientWeather = MSTR.ClientWeather or {}

local ClientWeather = MSTR.ClientWeather
local applySerial = 0
local synced = false
local snowApplied = nil
local visual,bridgeSerial,bridging=nil,0,false
local rainWeathers = { RAIN = true, THUNDER = true, CLEARING = true, NEUTRAL = true, HALLOWEEN = true }

local function ApplySnowEffects(weatherType)
    local snow = MSTR.Constants.SnowWeatherTypes[weatherType] == true
    if snowApplied == snow then return end
    -- Ground coverage is separate from trails. Both are released on exit/stop.
    ForceSnowPass(snow)
    SetForceVehicleTrails(snow and Config.Weather.EnableSnowTrails)
    SetForcePedFootstepsTracks(snow and Config.Weather.EnableSnowTrails)
    snowApplied = snow
end

local function ApplyStableWeather(weatherType)
    visual={from=weatherType,target=weatherType,progress=1}
    SetWeatherTypeNowPersist(weatherType)
    ApplySnowEffects(weatherType)
    -- Let precipitation weather choose its own level; explicitly end dry-weather
    -- rain effects. Existing puddles can still dry naturally in the game.
    SetRainLevel((rainWeathers[weatherType] or MSTR.Constants.SnowWeatherTypes[weatherType]) and -1.0 or 0.0)
end

function ClientWeather.IsSynced()
    return synced
end

function ClientWeather.RefreshSettings()
    if snowApplied == nil then return end
    SetForceVehicleTrails(snowApplied and Config.Weather.EnableSnowTrails)
    SetForcePedFootstepsTracks(snowApplied and Config.Weather.EnableSnowTrails)
end

function ClientWeather.ApplySync(payload)
    if type(payload) ~= 'table' then return false end
    local from = MSTR.Utils.NormalizeWeatherType(payload.currentWeather)
    local target = MSTR.Utils.NormalizeWeatherType(payload.targetWeather)
    local duration = payload.transitionDuration
    local elapsed = payload.transitionElapsed
    local cycle = payload.cycle == true
    local rate = 1
    if cycle then rate = payload.clockRate end
    if not from or not target
        or not MSTR.Utils.IsValidNumber(duration, 0, cycle and 86400 or 300)
        or not MSTR.Utils.IsValidNumber(rate, 0, 100)
        or not MSTR.Utils.IsValidNumber(elapsed, 0, duration) then
        MSTR.Utils.Warn('Rejected invalid client weather sync payload')
        return false
    end

    applySerial = applySerial + 1
    local serial = applySerial
    synced = true
    SetWeatherOwnedByNetwork(false)
    ClearOverrideWeather()
    ClearWeatherTypePersist()

    if duration <= 0 or elapsed >= duration or from == target then
        ApplyStableWeather(target)
        return true
    end

    local anchor = GetGameTimer()
    local fromHash, targetHash = GetHashKey(from), GetHashKey(target)
    SetRainLevel(-1.0)
    -- SetWeatherTypeTransition takes a blend fraction (0=from, 1=target).
    -- Apply the received fraction immediately: never reset a late join to from.
    local function ApplyProgress(progress)
        visual={from=from,target=target,progress=progress}
        SetWeatherTypeTransition(fromHash, targetHash, progress + 0.0)
        ApplySnowEffects(progress < 0.5 and from or target)
    end
    ApplyProgress(elapsed / duration)

    -- Frozen cycles retain their blend without a polling thread.
    if rate == 0 then return true end

    CreateThread(function()
        while serial == applySerial do
            local seconds = elapsed + MSTR.Utils.ElapsedMs(GetGameTimer(), anchor) / 1000.0 * rate
            if seconds >= duration then
                ApplyStableWeather(target)
                return
            end
            ApplyProgress(seconds / duration)
            Wait(100) -- active transitions only; no permanent weather polling
        end
    end)
    return true
end

RegisterNetEvent('mstr_weather:client:weatherSync', function(payload)
    if source ~= 65535 then return end
    if MSTR.ClientRegions then MSTR.ClientRegions.Global(payload) else ClientWeather.ApplySync(payload) end
end)

-- A GTA blend has two endpoints. Resolve an interrupted blend continuously before
-- introducing a third weather; never snap to a guessed dominant endpoint.
function ClientWeather.Route(provider,seconds,preserveBridge)
    if preserveBridge and bridging and not seconds then return end
    bridgeSerial=bridgeSerial+1
    local token=bridgeSerial
    if not visual or not seconds or seconds<=0 then bridging=false;return ClientWeather.ApplySync(provider()) end
    bridging=true
    applySerial=applySerial+1
    local initial={from=visual.from,target=visual.target,progress=visual.progress}
    CreateThread(function()
        local function segment(from,to,startProgress,endProgress,duration)
            local start=GetGameTimer()
            while token==bridgeSerial do
                local t=math.min(1,MSTR.Utils.ElapsedMs(GetGameTimer(),start)/(duration*1000))
                local progress=startProgress+(endProgress-startProgress)*t
                visual={from=from,target=to,progress=progress}
                SetWeatherTypeTransition(GetHashKey(from),GetHashKey(to),progress+0.0)
                ApplySnowEffects(progress<0.5 and from or to)
                SetRainLevel(-1.0)
                if t>=1 then return true end
                Wait(100)
            end
            return false
        end
        local part=seconds/3
        if not segment(initial.from,initial.target,initial.progress,1,part) then return end
        local p=provider()
        if not segment(initial.target,p.currentWeather,0,1,part) then return end
        local start=GetGameTimer()
        while token==bridgeSerial do
            local current=provider()
            if current.currentWeather~=p.currentWeather or current.targetWeather~=p.targetWeather then
                ClientWeather.Route(provider,seconds);return
            end
            local t=math.min(1,MSTR.Utils.ElapsedMs(GetGameTimer(),start)/(part*1000))
            local fraction=current.transitionDuration>0 and math.min(1,current.transitionElapsed/current.transitionDuration) or 1
            visual={from=p.currentWeather,target=p.targetWeather,progress=t*fraction}
            SetWeatherTypeTransition(GetHashKey(visual.from),GetHashKey(visual.target),visual.progress+0.0)
            ApplySnowEffects(visual.progress<0.5 and visual.from or visual.target)
            if t>=1 then bridging=false;ClientWeather.ApplySync(current);return end
            Wait(100)
        end
    end)
end

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    applySerial = applySerial + 1
    bridgeSerial=bridgeSerial+1
    synced = false
    ForceSnowPass(false)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    SetRainLevel(-1.0)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherOwnedByNetwork(true)
end)
