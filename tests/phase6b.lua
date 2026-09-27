-- Standalone mocked tests; also runs all 16 core regressions.
local runtime = dofile('tests/phase1_5.lua')
local passed = 0
local function test(name, fn)
    fn(); passed = passed + 1; print('PASS ' .. name)
end
local function rights(view, weather, time, dynamic, blackout)
    return { view = view == true, weather = weather == true, time = time == true,
        dynamic = dynamic == true, blackout = blackout == true }
end
local function action(r, player, name, payload)
    r.advance(501)
    r.env.source = player
    r.emit('mstr_weather:server:uiAction', 10, name, payload or {})
    return r.events[#r.events].payload
end
local function owner()
    return runtime({ ace = function(player, permission)
        return player == 1 and permission == 'mstr.weather.superadmin'
    end })
end

test('superadmin is ACE-only; legacy admin has ordinary controls, never management', function()
    local r = runtime(); r.ace = true
    local p = r.env.MSTR.Permissions
    assert(p.Can(2, 'weather') and not p.Can(2, 'manage'))
    local result = action(r, 2, 'panel')
    assert(not result.ok and result.reason == 'forbidden' and not result.panel)
    assert(not result.snapshot.permissions.manage)
    r.super = 1
    assert(p.Can(2, 'manage'))
    r.super = false
    assert(not p.Can(2, 'manage'))
end)

test('rights persist; granular commands cannot bypass delegation or revocation', function()
    local r = owner(); local m = r.env.MSTR
    assert(m.Admin.UpdateUser(1, 'fivem:2', 'Tester', rights(true, true), 0))
    assert(m.Permissions.Can(2, 'weather') and not m.Permissions.Can(2, 'time'))
    r.commands.mstrtime(2, { '18:00' }); assert(m.TimeEngine.GetCurrentClock().hour == 12)
    r.commands.mstrweather(2, { 'dynamic', 'false' }); assert(m.State.GetDynamicWeather())
    r.commands.mstrblackout(2, { 'true' }); assert(not m.State.GetBlackout())
    r.commands.mstrweather(2, { 'RAIN', 'instant' }); assert(m.State.GetWeather() == 'RAIN')
    local saved = r.encoded[r.files['data/admin.json']]
    local reboot = runtime({ files = { ['data/admin.json'] = 'stored' }, decoded = { stored = saved } })
    assert(reboot.env.MSTR.Permissions.Can(2, 'weather'))
    assert(m.Admin.UpdateUser(1, 'fivem:2', 'Tester', rights(), 1))
    assert(not m.Permissions.Can(2, 'view'))
    r.env.source = 2; r.emit('mstr_weather:server:uiSnapshot', 1)
    assert(r.events[#r.events].payload.allowed == false)
end)

test('explicit all-false defeats legacy ACE; aliases cannot undo a revoke', function()
    local license = 'license:' .. string.rep('a', 40)
    local r = runtime({ identifiers = { [2] = { 'fivem:2', license } } })
    r.super = true
    assert(r.env.MSTR.Admin.UpdateUser(1, 'fivem:2', 'Tester', rights(), 0))
    assert(r.env.MSTR.Admin.UpdateUser(1, license, 'Alias', rights(true, true, true, true, true), 1))
    r.super = false; r.ace = true
    assert(not r.env.MSTR.Permissions.Can(2, 'view'))
end)

test('no self escalation, forged rights, unsupported identity or invalid version overwrite', function()
    local r = owner(); local m = r.env.MSTR
    assert(not m.Admin.UpdateUser(2, 'fivem:2', 'Me', rights(true, true), 0))
    local forged = rights(true); forged.manage = true
    assert(not m.Admin.UpdateUser(1, 'fivem:2', 'Me', forged, 0))
    assert(not m.Admin.UpdateUser(1, 'ip:127.0.0.1', 'Me', rights(true), 0))
    assert(not m.Admin.UpdateUser(1, 'fivem:2', 'bad\nname', rights(true), 0))
    assert(m.Admin.UpdateUser(1, 'fivem:2', 'Good', rights(true), 0))
    local ok, reason = m.Admin.UpdateUser(1, 'fivem:2', 'Stale', rights(true, true), 0)
    assert(not ok and reason == 'conflict' and m.Admin.GetUser('fivem:2').name == 'Good')
end)

test('all mutation endpoints validate and call the existing engines', function()
    local r = owner(); local m = r.env.MSTR
    assert(not action(r, 2, 'weather', { weather = 'RAIN', instant = true }).ok)
    assert(not action(r, 1, 'weather', { weather = 'INVALID', instant = true }).ok)
    assert(not action(r, 1, 'weather', { weather = 'RAIN', instant = 'false' }).ok)
    assert(action(r, 1, 'weather', { weather = 'RAIN', instant = false }).ok)
    local busy = action(r, 1, 'weather', { weather = 'CLEAR', instant = false })
    assert(not busy.ok and busy.reason == 'transitioning')
    assert(action(r, 1, 'weather', { weather = 'CLEAR', instant = true }).ok)
    assert(action(r, 1, 'time', { hour = 8, minute = 30 }).ok)
    assert(not action(r, 1, 'time', { hour = 24, minute = 0 }).ok)
    assert(not action(r, 1, 'freeze', { value = 'false' }).ok)
    assert(action(r, 1, 'freeze', { value = true }).ok and m.State.GetTimeFrozen())
    assert(not action(r, 1, 'scale', { value = math.huge }).ok)
    assert(action(r, 1, 'scale', { value = 0.5 }).ok)
    assert(action(r, 1, 'dynamic', { value = false }).ok and not m.State.GetDynamicWeather())
    assert(action(r, 1, 'blackout', { value = true }).ok and m.State.GetBlackout())
    assert(not action(r, 1, 'blackout', { value = 0 }).ok)
    assert(not action(r, 1, 'invented', {}).ok)
end)

test('settings validate, reset countdown, publish visual settings and persist independently', function()
    local r = owner(); local m = r.env.MSTR
    local s = m.Admin.GetSettings()
    s.dynamicIntervalMinutes = 0.2; s.snowTrails = false; s.affectVehicles = true
    s.persistenceEnabled = false; s.transitionSeconds = 5; s.instantAllowed = false
    assert(m.Admin.UpdateSettings(1, s, 0))
    assert(m.WeatherEngine.GetNextDynamicChangeSeconds() == 12)
    assert(r.env.GlobalState['mstr:settings'].snowTrails == false)
    assert(r.env.GlobalState['mstr:settings'].affectVehicles == true)
    local saved = r.encoded[r.files['data/admin.json']]
    local reboot = runtime({ files = { ['data/admin.json'] = 'stored' }, decoded = { stored = saved } })
    assert(reboot.env.Config.Persistence.Enabled == false and reboot.env.Config.Weather.TransitionDuration == 5)
    assert(not action(r, 1, 'weather', { weather = 'RAIN', instant = true }).ok)
    s = m.Admin.GetSettings(); s.dynamicIntervalMinutes = 0
    assert(not m.Admin.UpdateSettings(1, s, 1))
    s = m.Admin.GetSettings(); s.snowTrails = 'false'
    assert(not m.Admin.UpdateSettings(1, s, 1))
    s = m.Admin.GetSettings(); s.persistenceEnabled = true
    m.TimeEngine.SetTime(17, 45)
    assert(m.Admin.UpdateSettings(1, s, 1))
    r.advance(2000)
    assert(r.encoded[r.files['data/state.json']].time.hour == 17)
end)

test('snow and vehicle setting updates apply without weather restart', function()
    local r = runtime(); r.clients(); local m = r.env.MSTR
    m.ClientWeather.ApplySync({ currentWeather = 'SNOW', targetWeather = 'SNOW', transitionDuration = 0, transitionElapsed = 0 })
    assert(r.natives.SetForceVehicleTrails[1])
    r.env.GlobalState['mstr:blackout'] = true
    r.emit('mstr:settings', 'global', 'mstr:settings', { snowTrails = false, affectVehicles = true })
    assert(not r.natives.SetForceVehicleTrails[1] and not r.natives.SetForcePedFootstepsTracks[1])
    assert(r.natives.SetArtificialLightsStateAffectsVehicles[1] and r.natives.ForceSnowPass[1])
end)

test('corrupt primary never restores old permissions from backup; writes fail closed', function()
    local old = { version = 1, revision = 1, users = { ['fivem:2'] = { name = 'Old', rights = rights(true, true) } }, settings = {} }
    local r = runtime({ files = { ['data/admin.json'] = 'broken', ['data/admin.json.bak'] = 'old' }, decoded = { old = old } })
    r.ace = true
    assert(r.env.MSTR.Admin.IsLocked() and not r.env.MSTR.Permissions.Can(2, 'view'))
    r.super = true; assert(r.env.MSTR.Permissions.Can(1, 'manage'))
    assert(not r.env.MSTR.Admin.UpdateUser(1, 'fivem:2', 'Me', rights(true), 0))
    local missing = runtime({ files = { ['data/admin.json.bak'] = 'old' }, decoded = { old = old } })
    missing.ace = true
    assert(missing.env.MSTR.Admin.IsLocked() and not missing.env.MSTR.Permissions.Can(2, 'view'))
    local fail = owner(); fail.failWrites = true
    assert(not fail.env.MSTR.Admin.UpdateUser(1, 'fivem:2', 'Me', rights(true), 0))
    assert(not fail.env.MSTR.Admin.GetUser('fivem:2'))
    fail.failWrites = false
    local save = fail.env.SaveResourceFile
    fail.env.SaveResourceFile = function(resource, path, raw)
        if path == 'data/admin.json' then fail.files[path] = 'partial'; return false end
        return save(resource, path, raw)
    end
    assert(not fail.env.MSTR.Admin.UpdateUser(1, 'fivem:2', 'Me', rights(true), 0))
    assert(fail.env.MSTR.Admin.IsLocked() and not fail.env.MSTR.Permissions.Can(2, 'view'))
end)

test('panel privacy, event throttle and request validation', function()
    local r = owner()
    local denied = action(r, 2, 'panel')
    assert(not denied.panel and not denied.snapshot.state)
    local allowed = action(r, 1, 'panel')
    assert(allowed.panel.online[1].identifier == 'fivem:1')
    r.env.source = 1
    r.emit('mstr_weather:server:uiAction', 11, 'panel', {})
    assert(r.events[#r.events].payload.reason == 'rate')
    local count = #r.events
    r.emit('mstr_weather:server:uiAction', {}, 'panel', {})
    assert(#r.events == count)
end)

test('NUI action callback completes once on response, timeout or close; local spoof rejected', function()
    local r = owner(); r.load('client/nui.lua')
    r.callbacks.ready({}, function() end); r.commands.mstrmenu()
    local responses = {}
    r.callbacks.action({ action = 'panel', payload = {} }, function(p) responses[#responses + 1] = p end)
    r.env.source = 3
    r.emit('mstr_weather:client:uiAction', { requestId = 1, ok = true })
    assert(#responses == 0)
    r.env.source = 65535
    r.emit('mstr_weather:client:uiAction', { requestId = 1, ok = true })
    assert(#responses == 1 and responses[1].ok)
    r.callbacks.action({ action = 'panel', payload = {} }, function(p) responses[#responses + 1] = p end)
    r.callbacks.close({}, function() end)
    assert(#responses == 2 and responses[2].reason == 'closed')
    r.advance(10000); assert(#responses == 2)
    r.commands.mstrmenu()
    r.env.source = 65535
    r.emit('mstr_weather:client:uiSnapshot', { requestId = r.lastRequest.id, allowed = true, state = { time = {} }, settings = {} })
    r.callbacks.action({ action = 'panel', payload = {} }, function(p) responses[#responses + 1] = p end)
    r.advance(8000)
    r.emit('mstr_weather:client:uiSnapshot', { requestId = r.lastRequest.id, allowed = true, state = { time = {} }, settings = {} })
    r.advance(2000)
    assert(#responses == 3 and responses[3].reason == 'timeout')
end)

print(('All %d Phase 6B checks passed (plus 16 core checks).'):format(passed))
