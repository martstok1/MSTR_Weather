-- Phase 6A: focus/lifecycle and read-only transport, never environment authority.
local ready, wanted = false, false
local generation, sequence, pending = 0, 0, nil
local lastResponse = 0

local function Close()
    wanted, pending = false, nil
    generation = generation + 1
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function Request()
    sequence = sequence % 2147483647 + 1
    pending = sequence
    TriggerServerEvent('mstr_weather:server:uiSnapshot', sequence)
end

RegisterNUICallback('ready', function(_, cb)
    ready = true
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    Close()
    cb({ ok = true })
end)

RegisterNetEvent('mstr_weather:client:uiSnapshot', function(payload)
    if source ~= 65535 then return end
    if not wanted or type(payload) ~= 'table' or payload.requestId ~= pending then return end
    pending = nil
    if payload.allowed ~= true then
        Close()
        MSTR.Utils.Info('Geen toegang tot het menu (ACE vereist).')
        return
    end
    if type(payload.state) ~= 'table' or type(payload.state.time) ~= 'table'
        or type(payload.settings) ~= 'table' then return end

    lastResponse = GetGameTimer()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'snapshot', payload = payload })
end)

RegisterCommand(Config.General.MenuCommand, function()
    if wanted then Close(); return end
    wanted = true
    generation = generation + 1
    local current = generation
    lastResponse = GetGameTimer()
    CreateThread(function()
        while wanted and generation == current do
            if MSTR.Utils.ElapsedMs(GetGameTimer(), lastResponse) >= 10000 then
                Close()
                MSTR.Utils.Warn('Menu gesloten: geen serverantwoord of NUI niet gereed. Probeer opnieuw.')
                return
            end
            if ready and not pending then Request() end
            Wait(2000)
        end
    end)
end, false)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Close() end
end)
