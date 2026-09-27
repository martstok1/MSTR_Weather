-- Client blackout application for MSTR_Weather
-- Reads server-owned GlobalState and applies GTA lighting natives locally.

MSTR = MSTR or {}
MSTR.ClientBlackout = MSTR.ClientBlackout or {}

local ClientBlackout = MSTR.ClientBlackout
local appliedState = nil

function ClientBlackout.Apply(enabled)
    if not MSTR.Utils.IsValidBoolean(enabled) then
        return false
    end

    SetArtificialLightsState(enabled)
    SetArtificialLightsStateAffectsVehicles(Config.Blackout.AffectVehicles == true)
    appliedState = enabled

    MSTR.Utils.Debug(('Client blackout applied: %s (affectVehicles=%s)')
        :format(tostring(enabled), tostring(Config.Blackout.AffectVehicles == true)))

    return true
end

AddStateBagChangeHandler('mstr:blackout', 'global', function(_, _, value)
    if MSTR.Utils.IsValidBoolean(value) and value ~= appliedState then
        ClientBlackout.Apply(value)
    end
end)

CreateThread(function()
    -- GlobalState can be unavailable on the very first client tick. Wait briefly
    -- and then apply the current replicated value as initial state.
    Wait(500)

    local value = GlobalState['mstr:blackout']
    if not MSTR.Utils.IsValidBoolean(value) then
        value = Config.Blackout.Default == true
    end

    ClientBlackout.Apply(value)
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    SetArtificialLightsState(false)
    SetArtificialLightsStateAffectsVehicles(false)
end)
