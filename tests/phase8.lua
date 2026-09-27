local runtime = dofile('tests/phase1_5.lua')
local passed = 0
local function test(name, fn) fn(); passed = passed + 1; print('PASS ' .. name) end
local function action(r, player, id, name, payload)
    r.env.source = player
    r.emit('mstr_weather:server:uiAction', id, name, payload or {})
end

test('disabled owner commands remain disabled, including bad config fallback', function()
    local r = runtime({ productionConfig = true })
    assert(not r.commands.mstrweather and not r.commands.mstrtime and not r.commands.mstrblackout)
    assert(r.commands.mstrdebug and r.env.Config.Branding.Logo == 'images/myLogo.png')
    local bad = runtime({ productionConfig = true, configure = function(c) c.General.DebugCommand = 'bad name' end })
    assert(not bad.commands.mstrweather and bad.commands.mstrdebug)
end)

test('weather/time events require server origin; server payloads still synchronize', function()
    local r = runtime(); r.clients(); local m = r.env.MSTR
    local weather = { currentWeather = 'CLEAR', targetWeather = 'RAIN', transitionDuration = 0, transitionElapsed = 0 }
    local time = { minutes = 300, frozen = true, scale = 2 }
    r.env.source = 4
    r.emit('mstr_weather:client:weatherSync', weather); r.emit('mstr_weather:client:timeSync', time)
    assert(not m.ClientWeather.IsSynced() and not m.ClientTime.IsSynced())
    r.env.source = 65535
    r.emit('mstr_weather:client:weatherSync', weather); r.emit('mstr_weather:client:timeSync', time)
    assert(m.ClientWeather.IsSynced() and m.ClientTime.GetCurrentMinutes() == 300)
    assert(r.natives.SetWeatherTypeNowPersist[1] == 'RAIN')
    assert(not m.Utils.IsValidWeatherType(string.rep('a', 10000)))
end)

test('10,000 mixed requests cannot bypass command/NUI mutation limit', function()
    local r = runtime(); r.super = true
    r.commands.mstrweather(1, { 'RAIN', 'instant' })
    for i = 1, 10000 do
        r.commands.mstrweather(1, { 'CLEAR', 'instant' })
        action(r, 1, i, 'weather', { weather = 'CLEAR', instant = true })
    end
    assert(r.env.MSTR.State.GetWeather() == 'RAIN')
    local count = 0
    for _, e in ipairs(r.events) do if e.name == 'mstr_weather:client:uiAction' then count = count + 1 end end
    assert(count == 1, 'rate feedback must also be bounded')
    r.advance(500)
    action(r, 1, 10001, 'weather', { weather = 'CLEAR', instant = true })
    assert(r.env.MSTR.State.GetWeather() == 'CLEAR')
    r.commands.mstrtime(1, { '03:00' }); assert(r.env.MSTR.TimeEngine.GetCurrentClock().hour ~= 3)
    r.env.source = 1; r.emit('playerDropped')
    r.commands.mstrtime(1, { '03:00' }); assert(r.env.MSTR.TimeEngine.GetCurrentClock().hour == 3)
    print('MEASURE burst: 20001 mutation attempts; 1 accepted before 500 ms; 1 rate reply')
end)

test('gate handles timer wrap, player isolation, malformed sources and requests', function()
    local r = runtime({ now = 4294967200 }); local gate = r.env.MSTR.Requests
    assert(gate.Allow(1) and gate.Allow(2) and not gate.Allow(1))
    r.advance(500); assert(gate.Allow(1))
    for _, id in ipairs({ 0, -1, 1.5, math.huge, '1', {} }) do assert(not gate.Allow(id)) end
    local count = #r.events
    r.env.source = 0; r.emit('mstr_weather:server:requestSync')
    r.env.source = -1; r.emit('mstr_weather:server:requestSync')
    action(r, 1, {}, 'logs', {}); action(r, 1, 1, string.rep('a', 25), {})
    assert(#r.events == count)
end)

test('unauthorized actions and forged identity never expose logs/admin data or write state', function()
    local r = runtime()
    for _, name in ipairs({ 'weather', 'time', 'freeze', 'scale', 'dynamic', 'blackout', 'panel', 'logs', 'settings', 'user' }) do
        r.advance(500)
        action(r, 2, 1, name, { player = 1, manage = true, value = true, weather = 'RAIN', instant = true })
        local result = r.events[#r.events].payload
        assert(not result.ok and not result.panel and not result.logs and not result.snapshot.state)
    end
    assert(#r.writes == 0 and r.env.MSTR.State.GetWeather() == 'CLEAR')
end)

test('silent primary corruption cannot replace last good persistence backup', function()
    local r = runtime(); local m = r.env.MSTR
    assert(m.Persistence.SaveState('seed'))
    local good = r.files['data/state.json']
    local save = r.env.SaveResourceFile
    r.env.SaveResourceFile = function(resource, path, raw, size)
        if path == 'data/state.json' then r.files[path] = 'partial'; return true end
        return save(resource, path, raw, size)
    end
    assert(not m.Persistence.SaveState('bad1')); assert(not m.Persistence.SaveState('bad2'))
    assert(r.files['data/state.json.bak'] == good)
    local main = r.files['data/state.json']
    r.env.SaveResourceFile = function(_, path) r.files[path] = 'partial'; return true end
    assert(not m.Persistence.SaveState('bad backup'))
    assert(r.files['data/state.json'] == main)
end)

test('admin backup verification prevents primary overwrite; storage caps reject oversized data', function()
    local r = runtime(); r.super = true; local m = r.env.MSTR
    local rights = { view = true, weather = true, time = false, dynamic = false, blackout = false }
    assert(m.Admin.UpdateUser(1, 'fivem:2', 'Tester', rights, 0))
    local main = r.files['data/admin.json']
    r.env.SaveResourceFile = function(_, path) r.files[path] = 'partial'; return true end
    assert(not m.Admin.UpdateUser(1, 'fivem:2', 'Changed', rights, 1))
    assert(r.files['data/admin.json'] == main and m.Admin.GetRevision() == 1)
    local large = runtime({ files = { ['data/state.json'] = string.rep('x', 262145) } })
    assert(large.env.MSTR.State.GetWeather() == 'CLEAR')
end)

test('idle and transition task/event counts settle; menu polling stops on close', function()
    local r = runtime({ configure = function(c) c.DynamicWeather.Enabled = false end })
    assert(#r.tasks == 1, 'only time correction runs on an idle server')
    r.advance(60000)
    assert(#r.events == 1 and #r.writes == 0 and #r.tasks == 1)
    r.env.MSTR.WeatherEngine.SetWeather('RAIN', false)
    assert(#r.tasks == 3, 'one correction, one transition, one save worker')
    r.advance(32000); assert(#r.tasks == 1)
    r.load('client/nui.lua'); r.callbacks.ready({}, function() end); r.commands.mstrmenu()
    local start = r.requests or 0
    for _ = 1, 30 do
        r.env.source = 65535
        r.emit('mstr_weather:client:uiSnapshot', { requestId = r.lastRequest.id, allowed = true, state = { time = {} }, settings = {} })
        r.advance(2000)
    end
    assert(r.requests - start == 30)
    r.commands.mstrmenu(); local closed = r.requests
    r.advance(60000); assert(r.requests == closed and #r.tasks == 1)
    print('MEASURE idle server 60 s: 1 correction, 0 writes; open menu 60 s: 30 requests; closed menu 60 s: 0 requests')
end)

test('stable client applies clock at configured rate without weather polling', function()
    local r = runtime({ configure = function(c) c.DynamicWeather.Enabled = false end })
    r.clients(); r.env.source = 65535
    r.emit('mstr_weather:client:weatherSync', { currentWeather = 'CLEAR', targetWeather = 'CLEAR', transitionDuration = 0, transitionElapsed = 0 })
    r.emit('mstr_weather:client:timeSync', { minutes = 720, frozen = false, scale = 2 })
    r.advance(1000)
    local ticks, weatherCalls = 0, 0
    local clock, weather = r.env.NetworkOverrideClockTime, r.env.SetWeatherTypeNowPersist
    r.env.NetworkOverrideClockTime = function(...) ticks = ticks + 1; clock(...) end
    r.env.SetWeatherTypeNowPersist = function(...) weatherCalls = weatherCalls + 1; weather(...) end
    r.advance(60000)
    assert(ticks == 240 and weatherCalls == 0 and not r.requests)
    print('MEASURE stable client 60 s: 240 clock-native calls, 0 weather reapplications, 0 resync requests')
end)

print(('All %d Phase 8 checks passed (plus 16 core regressions).'):format(passed))
