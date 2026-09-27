local runtime = dofile('tests/phase1_5.lua')
local r = runtime(); r.super = true
local m = r.env.MSTR
local settings = m.Admin.GetSettings()
assert(settings.locale == 'nl')
settings.locale = 'de'; assert(not m.Admin.UpdateSettings(1, settings, 0))
settings.locale = 'en'; r.super = false
assert(not m.Admin.UpdateSettings(1, settings, 0))
r.super = true
assert(m.Admin.UpdateSettings(1, settings, 0))
assert(r.env.Config.General.Locale == 'en' and r.env.GlobalState['mstr:settings'].locale == 'en')
local saved = r.encoded[r.files['data/admin.json']]
local reboot = runtime({ files = { ['data/admin.json'] = 'saved' }, decoded = { saved = saved } })
assert(reboot.env.Config.General.Locale == 'en')
local old = m.Admin.GetSettings(); old.locale = nil
local migrated = runtime({ files = { ['data/admin.json'] = 'old' }, decoded = { old = { version = 1, revision = 2, users = {}, settings = old } } })
assert(not migrated.env.MSTR.Admin.IsLocked() and migrated.env.MSTR.Admin.GetSettings().locale == 'nl')
r.env.source = 1; r.emit('mstr_weather:server:uiSnapshot', 1)
local snapshot = r.events[#r.events].payload
assert(snapshot.locale == 'en' and snapshot.settings.transitionSeconds == nil and snapshot.settings.persistenceEnabled == nil)
assert(snapshot.settings.instantAllowed ~= nil)
assert(m.Locale.Translate('Blackout set to true') == 'Blackout set to true')
r.env.Config.General.Locale = 'nl'
assert(m.Locale.Translate('Blackout set to true') == 'Stroomuitval ingesteld op aan')
assert(m.Locale.Translate('Weather change accepted: RAIN (instant)') == 'Weerwijziging geaccepteerd: Regen (direct)')
assert(m.Locale.Translate('Scale must be between 0 and 10.') == 'Snelheid moet tussen 0 en 10 liggen.')
assert(m.Locale.Translate('Time set to 08:30') == 'Tijd ingesteld op 08:30')
r.clients()
assert(m.ClientWeather.ApplySync({ currentWeather = 'CLEAR', targetWeather = 'HALLOWEEN', transitionDuration = 0, transitionElapsed = 0 }))
assert(r.natives.SetWeatherTypeNowPersist[1] == 'HALLOWEEN' and r.natives.SetRainLevel[1] == -1.0)
assert(m.ClientWeather.ApplySync({ currentWeather = 'HALLOWEEN', targetWeather = 'CLEAR', transitionDuration = 0, transitionElapsed = 0 }))
assert(r.natives.SetRainLevel[1] == 0.0)
print('PASS global locale validation/permissions/persistence/migration, snapshot privacy, command translations, Halloween native routing and precipitation cleanup')
