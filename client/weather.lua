-- Client weather application. The server owns the from/target/progress state.
MSTR = MSTR or {}
MSTR.ClientWeather = MSTR.ClientWeather or {}

local ClientWeather = MSTR.ClientWeather
local applySerial = 0
local synced = false
local snowApplied = nil
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
    if not from or not target
        or not MSTR.Utils.IsValidNumber(duration, 0, 300)
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
        SetWeatherTypeTransition(fromHash, targetHash, progress + 0.0)
        ApplySnowEffects(progress < 0.5 and from or target)
    end
    ApplyProgress(elapsed / duration)

    CreateThread(function()
        while serial == applySerial do
            local seconds = elapsed + MSTR.Utils.ElapsedMs(GetGameTimer(), anchor) / 1000.0
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
    ClientWeather.ApplySync(payload)
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    applySerial = applySerial + 1
    synced = false
    ForceSnowPass(false)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    SetRainLevel(-1.0)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherOwnedByNetwork(true)
end)
