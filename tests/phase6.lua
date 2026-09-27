-- Runs the 16 core regressions first, then the read-only NUI security/lifecycle checks.
local runtime = dofile('tests/phase1_5.lua')
local passed = 0
local function test(name, f)
    f()
    passed = passed + 1
    print('PASS ' .. name)
end

test('server: ACE per refresh, malformed ids, throttle, drop cleanup, no writes', function()
    local r = runtime(); r.env.source = 7
    local endpoint = 'mstr_weather:server:uiSnapshot'
    r.emit(endpoint, {})
    assert(#r.events == 0)
    r.emit(endpoint, 1)
    assert(r.events[1].payload.allowed == false and r.events[1].payload.state == nil)
    r.ace = true
    r.emit(endpoint, 2); assert(#r.events == 1)
    r.advance(1000); r.emit(endpoint, 2)
    local p = r.events[2].payload
    assert(p.allowed and p.state.blackout == false and p.settings.persistenceEnabled)
    assert(p.state.time.second > 0 and p.requestId == 2)
    r.ace = false; r.advance(1000); r.emit(endpoint, 3)
    assert(r.events[3].payload.allowed == false)
    r.emit('playerDropped'); r.emit(endpoint, 4)
    assert(#r.events == 4 and #r.writes == 0)
end)

local function client()
    local r = runtime()
    r.load('client/nui.lua')
    r.env.source = 65535
    return r
end
local function reply(r, id)
    r.emit('mstr_weather:client:uiSnapshot', {
        requestId = id, allowed = true, state = { time = {} }, settings = {}
    })
end

test('client: ready handshake, correlated replies, close and stale reply rejection', function()
    local r = client()
    r.commands.mstrmenu()
    assert(not r.focus and not r.lastRequest)
    r.callbacks.ready({}, function(p) assert(p.ok) end)
    r.advance(2000)
    local id = r.lastRequest.id
    reply(r, id + 1); assert(not r.focus)
    r.env.source = 1; reply(r, id); assert(not r.focus)
    r.env.source = 65535; reply(r, id); assert(r.focus)
    r.callbacks.close({}, function(p) assert(p.ok) end)
    assert(not r.focus and r.message.action == 'close')
    reply(r, id); assert(not r.focus)
    local count = r.requests
    r.advance(6000); assert(r.requests == count)
end)

test('client: revoked ACE and resource stop release focus', function()
    local r = client(); r.callbacks.ready({}, function() end)
    r.commands.mstrmenu(); reply(r, r.lastRequest.id); assert(r.focus)
    r.advance(2000)
    r.emit('mstr_weather:client:uiSnapshot', { requestId = r.lastRequest.id, allowed = false })
    assert(not r.focus)
    r.commands.mstrmenu(); reply(r, r.lastRequest.id); assert(r.focus)
    r.emit('onClientResourceStop', 'MSTR_Weather'); assert(not r.focus)
end)

test('client: unavailable NUI/server timeout and fast reopen use one polling loop', function()
    local r = client()
    r.commands.mstrmenu(); r.advance(10000); assert(not r.focus and not r.lastRequest)
    r.callbacks.ready({}, function() end)
    r.commands.mstrmenu(); local old = r.lastRequest.id
    r.commands.mstrmenu(); r.commands.mstrmenu()
    reply(r, old); assert(not r.focus)
    reply(r, r.lastRequest.id); assert(r.focus)
    local count = r.requests
    r.advance(2000); assert(r.requests == count + 1)
    r.advance(8000); assert(not r.focus)
end)

print(('All %d Phase 6 checks passed (plus 16 core checks).'):format(passed))
