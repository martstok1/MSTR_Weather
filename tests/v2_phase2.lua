-- Integration tests using real engines/services and mocked Cfx, timers and JSON/disk.
local function copy(v)
    if type(v)~='table' then return v end
    local t={};for k,x in pairs(v) do t[k]=copy(x) end;return t
end
local function runtime(seed)
    local r={now=0,files=copy(seed or {}),workers={},events={},commands={},sent={},writes=0,dirty=0,logs={},allowed=true}
    local env=setmetatable({}, {__index=_G});r.env=env
    env.MSTR={};env.GlobalState={};env.print=function() end
    env.GetGameTimer=function() return r.now end
    env.GetCurrentResourceName=function() return 'MSTR_Weather' end
    env.GetPlayerIdentifiers=function() return {'fivem:123'} end
    env.GetPlayerName=function() return 'Admin' end
    env.IsPlayerAceAllowed=function(_,ace) return r.allowed and ace==env.Config.Permissions.SuperAdmin end
    env.AddEventHandler=function(name,fn) r.events[name]=fn end
    env.RegisterNetEvent=env.AddEventHandler
    env.RegisterCommand=function(name,fn) r.commands[name]=fn end
    env.TriggerClientEvent=function(name,target,data) r.sent[#r.sent+1]={name=name,target=target,data=copy(data)} end
    env.LoadResourceFile=function(_,path) return r.files[path] end
    env.SaveResourceFile=function(_,path,raw)
        r.writes=r.writes+1
        if r.fail==path then return false end
        r.files[path]=r.corrupt==path and 'broken' or raw
        return true
    end
    -- Token codec intentionally mocks JSON only; schema validation is production code.
    r.tokens={};local serial=0
    env.json={encode=function(v)
        serial=serial+1;local raw='{"token":'..serial..'}';r.tokens[raw]=copy(v);return raw
    end,decode=function(raw) assert(r.tokens[raw],'invalid JSON');return copy(r.tokens[raw]) end}
    function r.load(path) assert(loadfile(path,'t',env))() end
    local function resume(w)
        local ok,delay=coroutine.resume(w.co);assert(ok,delay)
        w.wake=coroutine.status(w.co)=='dead' and math.huge or r.now+delay
    end
    env.CreateThread=function(fn)
        local w={co=coroutine.create(fn)};r.workers[#r.workers+1]=w;resume(w)
    end
    env.Wait=function(ms) assert(ms>0);return coroutine.yield(ms) end
    function r.advance(ms)
        local target=r.now+ms
        while true do
            local nextWorker
            for _,w in ipairs(r.workers) do if w.wake<=target and (not nextWorker or w.wake<nextWorker.wake) then nextWorker=w end end
            if not nextWorker then break end
            r.now=nextWorker.wake;resume(nextWorker)
        end
        r.now=target
    end
    function r.live() local n=0;for _,w in ipairs(r.workers) do if w.wake<math.huge then n=n+1 end end;return n end
    for _,p in ipairs({'config.lua','shared/constants.lua','shared/utils.lua','server/cycle_model.lua','server/requests.lua','server/permissions.lua','server/state.lua','server/weather_engine.lua','server/time_engine.lua'}) do r.load(p) end
    env.MSTR.Admin={IsLocked=function() return false end,GetUser=function() end,ValidIdentifier=function() return true end}
    env.MSTR.Logging={Record=function(...) r.logs[#r.logs+1]={...} end}
    env.MSTR.Persistence={MarkDirty=function() r.dirty=r.dirty+1 end}
    r.load('server/cycles.lua')
    env.MSTR.State.Initialize();env.MSTR.WeatherEngine.Initialize();env.MSTR.TimeEngine.Initialize()
    r.C=env.MSTR.Cycles;r.W=env.MSTR.WeatherEngine;r.T=env.MSTR.TimeEngine;r.S=env.MSTR.State
    function r.init() r.C.Initialize() end
    function r.request(action,id,raw,revision)
        r.advance(500)
        return r.C.Request(1,action,revision or r.C.GetStatus().revision,id,raw)
    end
    function r.definition()
        return {version=1,name='Test',startMinute=0,blocks={
            {weather='CLEAR',percent=50,transitionGameSeconds=60},
            {weather='RAIN',percent=50,transitionGameSeconds=120}}}
    end
    function r.import() return r.request('import','test',env.json.encode(r.definition())) end
    return r
end
local total=0
local function test(name,fn) fn();total=total+1;print('PASS '..name) end

test('v1 starts without cycle files, writes or workers',function()
    local r=runtime();r.init();assert(not r.C.IsActive() and r.writes==0 and r.live()==0)
    assert(r.W.SetWeather('RAIN',true));assert(r.S.GetWeather()=='RAIN')
end)
test('environment persistence cannot overwrite cycle files',function()
    local r=runtime()
    for _,path in ipairs({'data/cycles.json','data/cycle_import.json','DATA/CYCLES.JSON'}) do
        r.env.Config.Persistence.File=path;r.env.MSTR.Utils.ValidateConfig()
        assert(r.env.Config.Persistence.File=='data/state.json')
    end
end)
test('authorization, shared throttle, stale revisions and reserved IDs',function()
    local r=runtime();r.init();r.allowed=false
    local ok,why=r.request('import','test',r.env.json.encode(r.definition()));assert(not ok and why=='forbidden')
    assert(r.writes==0);r.allowed=true;assert(r.import())
    ok,why=r.C.Request(1,'activate',1,'test');assert(not ok and why=='rate')
    ok,why=r.request('activate','test',nil,0);assert(not ok and why=='revision')
    ok,why=r.request('import','../bad',r.env.json.encode(r.definition()));assert(not ok and why=='invalid')
    assert(not r.C.IsActive())
end)
test('cycle owns weather; delayed legacy transition cannot overwrite it',function()
    local r=runtime();r.init();assert(r.W.SetWeather('SNOW',false));r.W.StartScheduler()
    assert(r.import());assert(r.request('activate','test'))
    assert(not r.S.GetDynamicWeather());assert(not r.W.SetWeather('THUNDER',true));assert(not r.W.SetDynamicWeather(true))
    assert(not r.W.RunDynamicCycle());r.advance(31000);assert(r.S.GetWeather()=='RAIN')
    assert(r.live()==1);r.C.Initialize();r.advance(1000);assert(r.live()==1)
end)
test('time changes resolve exact progress; freeze, zero scale and resume',function()
    local r=runtime();r.init();assert(r.import());assert(r.request('activate','test'))
    assert(r.T.SetTime(12,1));local p=r.C.GetPayload();assert(p.transitionElapsed==60)
    assert(r.T.SetTimeFrozen(true));p=r.C.GetPayload();assert(p.clockRate==0)
    r.advance(5000);assert(r.C.GetPayload().transitionElapsed==60)
    assert(r.T.SetTimeFrozen(false));assert(r.T.SetTimeScale(0));r.advance(2000)
    assert(r.C.GetPayload().transitionElapsed==60)
    assert(r.T.SetTimeScale(4));r.advance(10000);p=r.C.GetPayload();assert(p.transitionElapsed==100 and p.clockRate==4)
    assert(r.T.SetTime(0,0));assert(r.C.GetPayload().targetWeather=='CLEAR')
    assert(r.T.SetTime(23,59));r.advance(16000);assert(r.C.GetPayload().targetWeather=='CLEAR')
end)
test('late join receives current fraction and frozen rate',function()
    local r=runtime();r.init();assert(r.import());assert(r.request('activate','test'))
    r.T.SetTime(12,1);r.T.SetTimeFrozen(true);r.W.SyncPlayer(9)
    local x=r.sent[#r.sent];assert(x.target==9 and x.data.transitionElapsed==60 and x.data.clockRate==0)
end)
test('delete in use and explicit stop; static weather then weighted resumes',function()
    local r=runtime();r.init();assert(r.import());assert(r.request('activate','test'))
    local ok,why=r.request('delete','test');assert(not ok and why=='in_use')
    ok,why=r.request('stop','no');assert(not ok and why=='confirm')
    assert(r.request('stop','confirm'));r.advance(1000);assert(r.live()==0 and not r.C.IsActive())
    assert(not r.S.GetDynamicWeather());assert(r.W.SetWeather('CLEAR',true))
    assert(r.request('delete','test'));assert(r.W.SetDynamicWeather(true));assert(r.live()==1)
end)
test('failed/corrupted primary write keeps live state and last-good backup',function()
    local r=runtime();r.init();assert(r.import());local good=r.files['data/cycles.json']
    r.corrupt='data/cycles.json'
    local ok,why=r.request('activate','test');assert(not ok and why=='storage')
    assert(not r.C.IsActive() and r.C.GetStatus().revision==1 and r.files['data/cycles.json.bak']==good)
    r.corrupt=nil;assert(r.request('activate','test'));assert(r.files['data/cycles.json.bak']==good)
end)
test('backup failure leaves primary and live mode untouched',function()
    local r=runtime();r.init();assert(r.import());local good=r.files['data/cycles.json']
    r.corrupt='data/cycles.json.bak';assert(not r.request('activate','test'))
    assert(r.files['data/cycles.json']==good and not r.C.IsActive())
end)
test('corruption locks editing without silently restoring a backup',function()
    local r=runtime({['data/cycles.json']='broken',['data/cycles.json.bak']='older'})
    r.init();assert(r.C.GetStatus().locked and not r.C.IsActive() and r.writes==0)
    local ok,why=r.request('activate','test');assert(not ok and why=='locked')
    r=runtime({['data/cycles.json.bak']='older'});r.init();assert(r.C.GetStatus().locked)
end)
test('restart restores active cycle at the current clock',function()
    local r=runtime();r.init();assert(r.import());assert(r.request('activate','test'))
    local saved=r.env.json.decode(r.files['data/cycles.json'])
    local n=runtime();n.files['data/cycles.json']=n.env.json.encode(saved);n.T.SetTime(12,1);n.init()
    assert(n.C.IsActive() and n.C.GetPayload().transitionElapsed==60 and not n.S.GetDynamicWeather())
    assert(n.live()==1)
end)
test('size, depth, schema and cycle count are bounded',function()
    local r=runtime();r.init()
    assert(not r.request('import','test',string.rep('x',262145)))
    assert(not r.request('import','test',string.rep('[',9)..string.rep(']',9)))
    local d=r.definition();d.extra=true;assert(not r.request('import','test',r.env.json.encode(d)))
    for i=1,32 do assert(r.request('import','c'..i,r.env.json.encode(r.definition()))) end
    assert(not r.request('import','overflow',r.env.json.encode(r.definition())))
    assert(r.C.GetStatus().revision==32)
end)
test('no periodic disk saves or redundant stable weather broadcasts',function()
    local r=runtime();r.init();assert(r.import());assert(r.request('activate','test'))
    r.T.SetTime(14,0);local sent,writes,dirty=#r.sent,r.writes,r.dirty
    r.advance(60000);assert(#r.sent==sent and r.writes==writes and r.dirty==dirty)
end)
test('single client blend handles pause/resume and rejects local event origin',function()
    local r=runtime();local last,stable=nil,nil
    local noop=function() end
    for _,n in ipairs({'ForceSnowPass','SetForceVehicleTrails','SetForcePedFootstepsTracks','SetRainLevel','SetWeatherOwnedByNetwork','ClearOverrideWeather','ClearWeatherTypePersist'}) do r.env[n]=noop end
    r.env.GetHashKey=function(x) return x end
    r.env.SetWeatherTypeTransition=function(_,_,v) last=v end
    r.env.SetWeatherTypeNowPersist=function(x) stable=x end
    r.load('client/weather.lua')
    local p={cycle=true,currentWeather='CLEAR',targetWeather='RAIN',transitionDuration=120,transitionElapsed=60,clockRate=0}
    r.env.source=0;r.events['mstr_weather:client:weatherSync'](p);assert(last==nil)
    r.env.source=65535;r.events['mstr_weather:client:weatherSync'](p);assert(last==0.5 and r.live()==0)
    p.clockRate=2;r.events['mstr_weather:client:weatherSync'](p);r.advance(10000);assert(math.abs(last-2/3)<0.002)
    p.clockRate=0;p.transitionElapsed=80;r.events['mstr_weather:client:weatherSync'](p);r.advance(1000);assert(r.live()==0)
    p.clockRate=false;assert(not r.env.MSTR.ClientWeather.ApplySync(p))
    p.clockRate=2;r.events['mstr_weather:client:weatherSync'](p);r.advance(20000);assert(stable=='RAIN')
end)
print(('V2 phase 2: %d integration tests passed'):format(total))
