-- Phase 6A: focus/lifecycle and read-only transport, never environment authority.
local ready, wanted = false, false
local generation, sequence, pending = 0, 0, nil
local lastResponse = 0
local actionSequence, actionPending = 0, nil

local function Close()
    if actionPending then
        actionPending.cb({ ok = false, reason = 'closed' })
        actionPending = nil
    end
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

RegisterNUICallback('action', function(data, cb)
    if not wanted or type(data) ~= 'table' or type(data.action) ~= 'string'
        or #data.action > 24 or type(data.payload) ~= 'table' then
        cb({ ok = false, reason = 'closed' }); return
    end
    if actionPending then cb({ ok = false, reason = 'busy' }); return end
    actionSequence = actionSequence % 2147483647 + 1
    local request = { id = actionSequence, cb = cb }
    actionPending = request
    TriggerServerEvent('mstr_weather:server:uiAction', request.id, data.action, data.payload)
    CreateThread(function()
        Wait(10000)
        if actionPending == request then
            actionPending = nil
            cb({ ok = false, reason = 'timeout' })
        end
    end)
end)

RegisterNetEvent('mstr_weather:client:uiAction', function(payload)
    if source ~= 65535 or type(payload) ~= 'table' or not actionPending
        or actionPending.id ~= payload.requestId then return end
    local cb = actionPending.cb
    actionPending = nil
    cb(payload)
    if payload.snapshot and payload.snapshot.allowed == false then Close() end
end)

RegisterNetEvent('mstr_weather:client:uiSnapshot', function(payload)
    if source ~= 65535 then return end
    if not wanted or type(payload) ~= 'table' or payload.requestId ~= pending then return end
    pending = nil
    if payload.allowed ~= true then
        if payload.locale == 'nl' or payload.locale == 'en' then Config.General.Locale = payload.locale end
        Close()
        MSTR.Utils.Info(MSTR.Locale.Translate('No access to the menu (permission required).'))
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
                MSTR.Utils.Warn(MSTR.Locale.Translate('Menu closed: no server response or NUI not ready. Try again.'))
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
