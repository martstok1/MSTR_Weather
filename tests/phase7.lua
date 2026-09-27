local runtime = dofile('tests/phase1_5.lua')
local r = runtime()
local m = r.env.MSTR
assert(m.Logging.GetPage(2) == nil)
r.super = true
assert(m.Logging.GetPage(1) ~= nil)
 m.Logging.Record('startup', nil, { ready = true }, { origin = 'startup' })
assert(m.WeatherEngine.SetWeather('RAIN', true, { player = 1, origin = 'nui' }))
local page = m.Logging.GetPage(1)
assert(page and #page.entries > 0 and page.entries[1].type == 'ADMIN')
assert(page.entries[1].playerId == 1 and page.entries[1].source == 'nui')
local before = page.entries[1].id
assert(m.Logging.GetPage(1, before + 1).entries[1].id == before)
assert(m.Logging.GetPage(1, 'bad') == nil)
local oldLimit = r.env.Config.Logging.MaxEntries
r.env.Config.Logging.MaxEntries = 10
for i = 1, 20 do m.Logging.Record('test', i, i + 1, { player = 1, origin = 'command' }) end
local bounded = m.Logging.GetPage(1)
assert(#bounded.entries <= 10 and bounded.limit == 10)
local copied = bounded.entries[1].newValue
bounded.entries[1].newValue = 'tampered'
assert(m.Logging.GetPage(1).entries[1].newValue == copied)
r.env.Config.Logging.MaxEntries = oldLimit
assert(m.Admin.UpdateUser(1, 'fivem:2', 'Tester', {view=true, weather=true, time=false, dynamic=false, blackout=false}, 0))
assert(m.Logging.GetPage(1).entries[1].action == 'user')
print('PASS bounded ADMIN/SYSTEM audit logging, superadmin privacy, cursor pagination and response isolation')
