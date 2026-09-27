-- Main client entry point for MSTR_Weather

print('[MSTR_Weather] Client starting...')

if not Config or not MSTR or not MSTR.ClientWeather or not MSTR.ClientTime or not MSTR.ClientBlackout then
    error('[MSTR_Weather] Client modules were not loaded in the expected order')
end

local requestedInitialSync = false

local function RequestInitialSync()
    if requestedInitialSync then
        return
    end

    requestedInitialSync = true

    CreateThread(function()
        Wait(500)
        while not MSTR.ClientWeather.IsSynced() or not MSTR.ClientTime.IsSynced() do
            TriggerServerEvent('mstr_weather:server:requestSync')
            Wait(2000)
        end
    end)
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RequestInitialSync()
    end
end)

-- Client scripts are normally already running when this file executes, but this
-- also covers unusual resource-start ordering during development.
RequestInitialSync()

print('[MSTR_Weather] Client started successfully')
