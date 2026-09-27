-- Run from the repository root: lua5.4 tests/phase1_5.lua
-- Pure Lua regression checks with mocked Cfx natives, events, disk and JSON.
-- These cannot verify GTA rendering, real network latency or filesystem writes.
local passed = 0
local function check(name, test)
    local ok, err = pcall(test)
    if not ok then error(name .. ': ' .. tostring(err), 0) end
    passed = passed + 1
    print('PASS ' .. name)
end

local function runtime(options)
    options = options or {}
    local r = { now = options.now or 0, tasks = {}, events = {}, handlers = {}, commands = {},
        natives = {}, logs = {}, files = options.files or {}, writes = {}, encoded = {}, serial = 0 }
    local e = setmetatable({}, { __index = _G })
    r.env = e
    e._G = e
    e.GlobalState = {}
    e.print = function(message) table.insert(r.logs, message) end
    e.GetCurrentResourceName = function() return 'MSTR_Weather' end
    e.GetGameTimer = function() return (r.now + 2147483648) % 4294967296 - 2147483648 end
    e.GetHashKey = function(value) return value end
    e.IsPlayerAceAllowed = function() return r.ace or false end
    local function resume(task)
        local ok, delay = coroutine.resume(task.co)
        assert(ok, delay)
        if coroutine.status(task.co) ~= 'dead' then
            assert(type(delay) == 'number' and delay > 0, 'invalid/busy wait')
            task.due = r.now + delay
            table.insert(r.tasks, task)
        end
    end
    e.CreateThread = function(f) resume({ co = coroutine.create(f) }) end
    e.Wait = coroutine.yield
    function r.advance(ms)
        local finish = r.now + ms
        local iterations = 0
        while true do
            local index, due
            for i, task in ipairs(r.tasks) do
                if task.due <= finish and (not due or task.due < due) then index, due = i, task.due end
            end
            if not index then break end
            iterations = iterations + 1
            assert(iterations < 100000, 'scheduler did not settle')
            r.now = due
            resume(table.remove(r.tasks, index))
        end
        r.now = finish
    end
    e.TriggerClientEvent = function(name, target, payload)
        table.insert(r.events, { name = name, target = target, payload = payload })
    end
    e.TriggerServerEvent = function(name) r.requests = (r.requests or 0) + 1 end
    e.RegisterNetEvent = function(name, f) r.handlers[name] = { f } end
    e.AddEventHandler = function(name, f)
        r.handlers[name] = r.handlers[name] or {}
        table.insert(r.handlers[name], f)
    end
    e.AddStateBagChangeHandler = function(key, _, f) r.handlers[key] = { f } end
    e.RegisterCommand = function(name, f) r.commands[name] = f end
    r.callbacks = {}
    e.RegisterNUICallback = function(name, f) r.callbacks[name] = f end
    e.SetNuiFocus = function(keyboard, mouse) r.focus = keyboard or mouse end
    e.SendNUIMessage = function(message) r.message = message end
    e.TriggerServerEvent = function(name, id)
        r.requests = (r.requests or 0) + 1
        r.lastRequest = { name = name, id = id }
    end
    function r.emit(name, ...)
        for _, f in ipairs(r.handlers[name] or {}) do f(...) end
    end
    e.LoadResourceFile = function(_, path) return r.files[path] end
    e.SaveResourceFile = function(_, path, value)
        table.insert(r.writes, path)
        if r.failWrites then return false end
        r.files[path] = value
        return true
    end
    e.json = {
        encode = function(data)
            r.serial = r.serial + 1
            local key = 'encoded-' .. r.serial
            r.encoded[key] = data
            return key
        end,
        decode = function(raw)
            if r.encoded[raw] then return r.encoded[raw] end
            if options.decoded and options.decoded[raw] then return options.decoded[raw] end
            error('mock malformed JSON')
        end
    }
    for _, name in ipairs({ 'SetWeatherTypeNowPersist', 'SetWeatherTypeTransition', 'ForceSnowPass',
        'SetForceVehicleTrails', 'SetForcePedFootstepsTracks', 'SetRainLevel', 'SetWeatherOwnedByNetwork',
        'ClearOverrideWeather', 'ClearWeatherTypePersist', 'NetworkOverrideClockTime',
        'NetworkClearClockTimeOverride', 'SetArtificialLightsState', 'SetArtificialLightsStateAffectsVehicles' }) do
        e[name] = function(...) r.natives[name] = { ... } end
    end
    function r.load(path) assert(loadfile(path, 't', e))() end
    local manifest = {}
    local me = setmetatable({ shared_scripts = function(paths) manifest.shared = paths end,
        server_scripts = function(paths) manifest.server = paths end,
        client_scripts = function(paths) manifest.client = paths end },
        { __index = function() return function() end end })
    assert(loadfile('fxmanifest.lua', 't', me))()
    for _, path in ipairs(manifest.shared) do
        r.load(path)
        if path == 'config.lua' and options.configure then options.configure(e.Config) end
    end
    for _, path in ipairs(manifest.server) do r.load(path) end
    function r.clients() for _, path in ipairs(manifest.client) do r.load(path) end end
    function r.weatherEvents()
        local count = 0
        for _, event in ipairs(r.events) do
            if event.name == 'mstr_weather:client:weatherSync' then count = count + 1 end
        end
        return count
    end
    return r
end

check('manifest boot, ACE booleans/numbers and unauthorized commands', function()
    local r = runtime()
    local m = r.env.MSTR
    for _, value in ipairs({ true, 1, false, 0 }) do
        r.ace = value
        assert(m.Permissions.HasAdminPermission(1) == (value == true or value == 1))
    end
    r.ace = false
    r.commands.mstrweather(1, { 'RAIN', 'instant' })
    r.commands.mstrtime(1, { '18:30' })
    r.commands.mstrblackout(1, { 'true' })
    assert(m.State.GetWeather() == 'CLEAR' and not m.State.GetBlackout())
    assert(m.TimeEngine.GetCurrentClock().hour == 12)
    assert(#r.writes == 0)
    r.ace = true
    r.commands.mstrblackout(1, { 'true' })
    assert(m.State.GetBlackout())
    r.commands.mstrblackout(1, { 'false' })
    assert(not m.State.GetBlackout())
end)

check('invalid commands rejected and debug read-only', function()
    local r = runtime(); r.ace = true
    r.commands.mstrweather(1, { 'NOPE' })
    r.commands.mstrweather(1, { 'RAIN', 'NOPE' })
    r.commands.mstrweather(1, { 'dynamic', 'maybe' })
    r.commands.mstrtime(1, { '24:00' })
    r.commands.mstrtime(1, { 'freeze', 'maybe' })
    r.commands.mstrtime(1, { 'scale', '11' })
    r.commands.mstrblackout(1, { 'maybe' })
    r.commands.mstrdebug(1)
    r.advance(2000)
    assert(#r.writes == 0 and r.weatherEvents() == 0)
end)

check('late join receives existing blend; busy smooth leaves it unchanged', function()
    local r = runtime(); local m = r.env.MSTR
    assert(m.WeatherEngine.SetWeather('RAIN', false))
    r.advance(15000)
    m.WeatherEngine.SyncPlayer(2)
    local p = r.events[#r.events].payload
    assert(p.currentWeather == 'CLEAR' and p.targetWeather == 'RAIN')
    assert(p.transitionDuration == 30 and p.transitionElapsed == 15)
    local before = r.weatherEvents()
    local ok, reason = m.WeatherEngine.SetWeather('CLOUDS', false)
    assert(not ok and reason == 'transitioning' and r.weatherEvents() == before)
    r.load('client/weather.lua')
    assert(m.ClientWeather.ApplySync(p))
    assert(r.natives.SetWeatherTypeTransition[3] == 0.5)
    assert(not r.natives.SetWeatherTypeNowPersist, 'late join reset to old weather')
    r.advance(15000)
    assert(m.State.GetWeather() == 'RAIN' and not m.WeatherEngine.IsTransitioning())
    assert(r.natives.SetWeatherTypeNowPersist[1] == 'RAIN')
end)

check('instant cancels stale server and client transition completion', function()
    local r = runtime(); local m = r.env.MSTR
    r.load('client/weather.lua')
    m.WeatherEngine.SetWeather('RAIN', false)
    m.ClientWeather.ApplySync(r.events[#r.events].payload)
    r.advance(5000)
    m.WeatherEngine.SetWeather('EXTRASUNNY', true)
    m.ClientWeather.ApplySync(r.events[#r.events].payload)
    r.advance(30000)
    assert(m.State.GetWeather() == 'EXTRASUNNY')
    assert(r.natives.SetWeatherTypeNowPersist[1] == 'EXTRASUNNY')
end)

check('safe fallback and weighted choices including invalid weights', function()
    local r = runtime(); local m = r.env.MSTR; local c = r.env.Config
    c.Weather.Transitions = {}
    assert(m.WeatherEngine.GetNextWeatherType('FOGGY') == 'CLOUDS')
    assert(m.WeatherEngine.GetNextWeatherType('THUNDER') == 'RAIN')
    assert(m.WeatherEngine.GetNextWeatherType('XMAS') == 'SNOWLIGHT')
    c.Weather.Transitions.CLEAR = { CLOUDS = 70, EXTRASUNNY = 30, RAIN = math.huge, THUNDER = 0/0 }
    math.randomseed(42)
    local clouds = 0
    for _ = 1, 100000 do
        local nextWeather = m.WeatherEngine.GetNextWeatherType('CLEAR')
        assert(nextWeather == 'CLOUDS' or nextWeather == 'EXTRASUNNY')
        if nextWeather == 'CLOUDS' then clouds = clouds + 1 end
    end
    assert(clouds > 68500 and clouds < 71500)
end)

check('disabled scheduler exits; toggles do not duplicate automatic cycles', function()
    local r = runtime({ configure = function(c) c.DynamicWeather.IntervalMinutes = 0.1 end })
    local m = r.env.MSTR
    m.WeatherEngine.SetDynamicWeather(false)
    r.advance(2000)
    assert(#r.tasks == 1, 'only time correction should remain')
    for _ = 1, 5 do m.WeatherEngine.SetDynamicWeather(true); m.WeatherEngine.SetDynamicWeather(false) end
    m.WeatherEngine.SetDynamicWeather(true)
    r.advance(6000)
    assert(r.weatherEvents() == 1)
    r.advance(6000)
    assert(r.weatherEvents() == 1, 'automatic transition stacked')
    m.WeatherEngine.SetDynamicWeather(false)
    r.advance(30000)
    assert(r.weatherEvents() == 2, 'only active transition completion expected')
end)

check('time wrap, backwards set, freeze/resume, scales, live snapshot', function()
    local r = runtime(); local m = r.env.MSTR
    m.TimeEngine.SetTime(23, 59); r.advance(60000)
    assert(m.TimeEngine.GetCurrentClock().hour == 0 and m.TimeEngine.GetCurrentClock().minute == 1)
    m.TimeEngine.SetTimeFrozen(true); local minutes = m.TimeEngine.GetCurrentMinutes(); r.advance(60000)
    assert(m.TimeEngine.GetCurrentMinutes() == minutes)
    m.TimeEngine.SetTimeFrozen(false); r.advance(30000)
    assert(math.abs(m.TimeEngine.GetCurrentMinutes() - minutes - 1) < 0.00001)
    m.TimeEngine.SetTime(18, 0); m.TimeEngine.SetTime(8, 0)
    assert(m.TimeEngine.GetCurrentClock().hour == 8)
    for _, speed in ipairs({ 0, 0.5, 1, 2, 10 }) do
        m.TimeEngine.SetTime(12, 0); m.TimeEngine.SetTimeScale(speed); r.advance(60000)
        assert(math.abs(m.TimeEngine.GetCurrentMinutes() - 720 - speed) < 0.00001)
    end
    m.TimeEngine.SetTime(12, 0); r.advance(10000)
    assert(m.State.GetSnapshot().time.minute == 1)
    assert(not m.TimeEngine.SetTimeScale(0/0) and not m.TimeEngine.SetTimeScale(11))
    assert(not m.TimeEngine.SetTimeFrozen('false') and not m.TimeEngine.SetTime(24, 0))
end)

check('game timer wrap does not stall weather or time', function()
    local r = runtime({ now = 2147480000 })
    local m = r.env.MSTR
    m.WeatherEngine.SetWeather('RAIN', false); r.advance(15000)
    assert(math.abs(m.WeatherEngine.GetTransitionRemainingSeconds() - 15) < 0.001)
    assert(m.TimeEngine.GetCurrentClock().second == 30)
    assert(m.Utils.ElapsedMs(20, 4294967290) == 26)
end)

check('config invalid defaults, path and duplicate commands normalized', function()
    local r = runtime({ configure = function(c)
        c.Time.DefaultHour = 99; c.Time.CycleSpeed = math.huge
        c.Time.MinCycleSpeed = 9; c.Time.MaxCycleSpeed = -1
        c.Time.DefaultMinute = 0/0; c.Blackout.Default = 'false'
        c.Persistence.File = 'config.lua'; c.DynamicWeather.IntervalMinutes = math.huge
        c.General.TimeCommand = c.General.WeatherCommand
    end })
    local c = r.env.Config
    assert(c.Time.DefaultHour == 12 and c.Time.DefaultMinute == 0 and c.Time.CycleSpeed == 9)
    assert(c.Time.MaxCycleSpeed == 10 and c.Blackout.Default == false)
    assert(c.Persistence.File == 'data/state.json' and c.General.TimeCommand == 'mstrtime')
    assert(c.DynamicWeather.IntervalMinutes == 15)
end)

check('persistence preserves false, validates fields and recovers backup', function()
    local valid = { version = 1, weather = 'RAIN', blackout = false, dynamicWeather = false,
        timeFrozen = false, timeScale = 2, time = { hour = 8, minute = 30 } }
    local r = runtime({ files = { ['data/state.json'] = 'broken', ['data/state.json.bak'] = 'valid' },
        decoded = { valid = valid } })
    local m = r.env.MSTR
    assert(m.State.GetWeather() == 'RAIN' and m.State.GetDynamicWeather() == false)
    assert(m.State.GetBlackout() == false and m.State.GetTimeFrozen() == false)
    assert(m.TimeEngine.GetCurrentClock().hour == 8)
    local bad = runtime({ files = { ['data/state.json'] = 'partial' }, decoded = {
        partial = { weather = 'INVALID', blackout = 'false', timeScale = 999, time = { hour = 99, minute = 1 }, dynamicWeather = false }
    } })
    assert(bad.env.MSTR.State.GetWeather() == 'CLEAR' and not bad.env.MSTR.State.GetDynamicWeather())
    assert(bad.env.MSTR.TimeEngine.GetCurrentClock().hour == 12)
    local future = runtime({ files = { ['data/state.json'] = 'future' }, decoded = { future = { version = 99, weather = 'RAIN' } } })
    assert(future.env.MSTR.State.GetWeather() == 'CLEAR')
end)

check('one debounce worker saves target weather and live time; clean stop flush', function()
    local r = runtime(); local m = r.env.MSTR
    m.WeatherEngine.SetWeather('RAIN', false)
    for _ = 1, 100 do m.Persistence.MarkDirty('burst') end
    assert(#r.tasks == 4, 'time + dynamic + transition + one save worker')
    r.advance(1000); m.Persistence.MarkDirty('later mutation'); r.advance(1000)
    assert(#r.writes == 0)
    r.advance(500)
    assert(#r.writes == 2)
    local saved = r.encoded[r.files['data/state.json']]
    assert(saved.weather == 'RAIN' and saved.blackout == false)
    m.TimeEngine.SetTime(17, 45)
    r.emit('onResourceStop', 'MSTR_Weather')
    saved = r.encoded[r.files['data/state.json']]
    assert(saved.time.hour == 17 and saved.time.minute == 45)
end)

check('write retries bounded; backups retain last successful state', function()
    local r = runtime(); local m = r.env.MSTR
    m.Persistence.SaveState('baseline')
    local previous = r.files['data/state.json']
    r.failWrites = true
    m.WeatherEngine.SetWeather('RAIN', true); r.advance(12000)
    assert(#r.writes == 5, 'initial two writes plus three failed backup writes')
    assert(r.files['data/state.json'] == previous)
    r.failWrites = false
    m.Persistence.MarkDirty('retry after recovery'); r.advance(1500)
    assert(r.files['data/state.json.bak'] == previous)
    assert(r.encoded[r.files['data/state.json']].weather == 'RAIN')
end)

check('snow/rain/blackout apply and resource-stop cleanup', function()
    local r = runtime(); r.clients(); local m = r.env.MSTR
    local function weather(w)
        assert(m.ClientWeather.ApplySync({ currentWeather = w, targetWeather = w, transitionDuration = 0, transitionElapsed = 0 }))
    end
    weather('SNOW'); assert(r.natives.ForceSnowPass[1] and r.natives.SetForceVehicleTrails[1])
    weather('RAIN'); assert(not r.natives.ForceSnowPass[1] and r.natives.SetRainLevel[1] == -1)
    weather('CLEAR'); assert(not r.natives.SetForcePedFootstepsTracks[1] and r.natives.SetRainLevel[1] == 0)
    r.env.Config.Blackout.AffectVehicles = true
    r.emit('mstr:blackout', 'global', 'mstr:blackout', true)
    assert(r.natives.SetArtificialLightsState[1] and r.natives.SetArtificialLightsStateAffectsVehicles[1])
    r.emit('onClientResourceStop', 'MSTR_Weather')
    assert(not r.natives.ForceSnowPass[1] and r.natives.SetRainLevel[1] == -1)
    assert(not r.natives.SetArtificialLightsState[1] and r.natives.NetworkClearClockTimeOverride)
end)

check('client sync retries until both engines ready; bad payloads rejected', function()
    local r = runtime(); r.clients(); local m = r.env.MSTR
    r.advance(2500); assert(r.requests == 2)
    assert(not m.ClientTime.ApplySync({ minutes = math.huge, scale = 2, frozen = false }))
    assert(not m.ClientWeather.ApplySync({ currentWeather = 'CLEAR', targetWeather = 'RAIN', transitionDuration = 0/0, transitionElapsed = 0 }))
    m.ClientTime.ApplySync({ minutes = 720, scale = 2, frozen = false })
    m.ClientWeather.ApplySync({ currentWeather = 'CLEAR', targetWeather = 'CLEAR', transitionDuration = 0, transitionElapsed = 0 })
    r.advance(5000); assert(r.requests == 2)
end)

check('sync endpoint is throttled and player-drop removes throttle', function()
    local r = runtime(); r.env.source = 7
    r.emit('mstr_weather:server:requestSync'); assert(#r.events == 2)
    r.emit('mstr_weather:server:requestSync'); assert(#r.events == 2)
    r.emit('playerDropped'); r.emit('mstr_weather:server:requestSync'); assert(#r.events == 4)
end)

check('disabled persistence never writes', function()
    local r = runtime({ configure = function(c) c.Persistence.Enabled = false end })
    r.env.MSTR.TimeEngine.SetTime(18, 0)
    r.advance(5000); r.emit('onResourceStop', 'MSTR_Weather')
    assert(#r.writes == 0)
end)

print(('All %d mocked regression checks passed. FiveM ingame validation is still required.'):format(passed))

-- Also reused by the Phase 6 tests; no runtime resource dependency.
return runtime
