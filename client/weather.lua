-- Client Weather Engine for MSTR_Weather
-- Applies server-authoritative weather locally.

MSTR = MSTR or {}
MSTR.ClientWeather = MSTR.ClientWeather or {}

local ClientWeather = MSTR.ClientWeather
local applySerial = 0

local function ApplySnowEffects(weatherType)
    local snowEnabled = Config.Weather.EnableSnowTrails == true
        and MSTR.Constants.SnowWeatherTypes[weatherType] == true

    SetForceVehicleTrails(snowEnabled)
    SetForcePedFootstepsTracks(snowEnabled)
end

function ClientWeather.ApplySync(payload)
    if type(payload) ~= 'table' then
        return
    end

    local currentWeather = MSTR.Utils.NormalizeWeatherType(payload.currentWeather)
    local targetWeather = MSTR.Utils.NormalizeWeatherType(payload.targetWeather)
    local duration = tonumber(payload.transitionDuration) or 0

    if not currentWeather then
        currentWeather = targetWeather
    end

    if not targetWeather then
        targetWeather = currentWeather
    end

    if not currentWeather or not targetWeather then
        MSTR.Utils.Warn('Rejected invalid client weather sync payload')
        return
    end

    if duration < 0 then
        duration = 0
    elseif duration > 300 then
        duration = 300
    end

    applySerial = applySerial + 1
    local serial = applySerial

    SetWeatherOwnedByNetwork(false)

    if duration > 0 and currentWeather ~= targetWeather then
        SetWeatherTypeNowPersist(currentWeather)
        ApplySnowEffects(currentWeather)
        SetWeatherTypeOvertimePersist(targetWeather, duration + 0.0)

        CreateThread(function()
            Wait(math.floor(duration * 1000) + 250)

            if serial ~= applySerial then
                return
            end

            SetWeatherTypeNowPersist(targetWeather)
            ApplySnowEffects(targetWeather)
        end)

        MSTR.Utils.Debug(('Client weather transition: %s -> %s (%ss)')
            :format(currentWeather, targetWeather, tostring(duration)))
        return
    end

    SetWeatherTypeNowPersist(targetWeather)
    ApplySnowEffects(targetWeather)
    MSTR.Utils.Debug(('Client weather applied: %s'):format(targetWeather))
end

RegisterNetEvent('mstr_weather:client:weatherSync', function(payload)
    ClientWeather.ApplySync(payload)
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    applySerial = applySerial + 1
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherOwnedByNetwork(true)
end)
