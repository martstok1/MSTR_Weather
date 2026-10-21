-- The server chooses every regional environment. Clients only choose their location.
MSTR.Regions={}
local R,S=MSTR.Regions,MSTR.V2Storage
local store,started,signature=nil,false,nil
local weighted={}
local defaults={version=1,revision=0,regions={},effects={heat=false,cold=false,
    heatThreshold=32,coldThreshold=0,intensity=0.35,fadeSeconds=15,fallbackTemperature=20}}
local function effects(v)
    return S.Fields(v,{heat=true,cold=true,heatThreshold=true,coldThreshold=true,intensity=true,fadeSeconds=true,fallbackTemperature=true})
        and type(v.heat)=='boolean' and type(v.cold)=='boolean'
        and MSTR.Utils.IsValidNumber(v.heatThreshold,-49,60) and MSTR.Utils.IsValidNumber(v.coldThreshold,-50,59)
        and v.heatThreshold>v.coldThreshold and MSTR.Utils.IsValidNumber(v.intensity,0,1)
        and MSTR.Utils.IsValidNumber(v.fadeSeconds,1,120) and MSTR.Utils.IsValidNumber(v.fallbackTemperature,-50,60)
end
local function region(v)
    if not S.Fields(v,{name=true,points=true,mode=true,weather=true,cycle=true,temperature=true,
        transitionSeconds=true,intervalMinutes=true,weights=true,enabled=true}) then return false end
    if type(v.name)~='string' or #v.name>80 or not v.name:find('%S') or v.name:find('%c')
        or type(v.enabled)~='boolean' or not MSTR.Geometry.Validate(v.points)
        or not MSTR.Utils.IsValidNumber(v.temperature,-50,60)
        or not MSTR.Utils.IsValidNumber(v.transitionSeconds,1,120)
        or not MSTR.Utils.IsValidNumber(v.intervalMinutes,0.1,1440)
        or not MSTR.Utils.IsValidWeatherType(v.weather) or type(v.cycle)~='string' or #v.cycle>40
        or not S.Fields(v.weights,MSTR.Constants.WeatherTypeLookup) then return false end
    local sum=0;for _,w in pairs(v.weights) do
        if not MSTR.Utils.IsValidNumber(w,0,1000000) then return false end;sum=sum+w
    end
    return v.mode=='static' or (v.mode=='weighted' and sum>0)
        or (v.mode=='cycle' and S.Id(v.cycle) and MSTR.Cycles.Exists(v.cycle))
end
local function valid(v)
    if not S.Fields(v,{version=true,revision=true,regions=true,effects=true}) or v.version~=1
        or not MSTR.Utils.IsValidInteger(v.revision,0,2147483646)
        or type(v.regions)~='table' or getmetatable(v.regions) or not effects(v.effects) then return false end
    local ids={}
    for id,value in pairs(v.regions) do
        if not S.Id(id) or not region(value) then return false end
        ids[#ids+1]=id;if #ids>32 then return false end
    end
    for i=1,#ids do for j=i+1,#ids do
        if MSTR.Geometry.Overlap(v.regions[ids[i]].points,v.regions[ids[j]].points) then return false end
    end end
    return true
end
function R.UsesCycle(id)
    if not store then return false end
    -- Broken region storage cannot prove a cycle is unreferenced.
    if store.locked then return true end
    for _,v in pairs(store.value.regions) do if v.mode=='cycle' and v.cycle==id then return true end end
    return false
end
local function choose(weights)
    local total=0;for _,w in pairs(weights) do total=total+w end
    local roll=math.random()*total;local last
    for w,n in pairs(weights) do if n>0 then last=w;roll=roll-n;if roll<=0 then return w end end end
    return last
end
local function payload(v,id)
    local clock=MSTR.TimeEngine.GetSyncPayload()
    if v.mode=='cycle' then
        local r=MSTR.Cycles.Resolve(v.cycle)
        if not r then return nil end
        return {cycle=true,currentWeather=r.previousWeather,targetWeather=r.weather,
            transitionDuration=r.transitionGameSeconds,transitionElapsed=math.min(r.elapsedGameSeconds,r.transitionGameSeconds),
            clockRate=clock.frozen and 0 or clock.scale,previousTemperature=r.previousTemperature,
            targetTemperature=r.targetTemperature,temperature=r.temperature},r.index..':'..tostring(r.transitioning)
    end
    if v.mode=='weighted' then
        local w=weighted[id];local now=GetGameTimer()
        if not w then w={from=v.weather,to=v.weather,start=now,serial=0};weighted[id]=w end
        if MSTR.Utils.ElapsedMs(now,w.start)>=math.max(v.intervalMinutes*60000,v.transitionSeconds*1000) then
            w.from,w.to,w.start,w.serial=w.to,choose(v.weights),now,w.serial+1
        end
        return {currentWeather=w.from,targetWeather=w.to,transitionDuration=v.transitionSeconds,
            transitionElapsed=math.min(v.transitionSeconds,MSTR.Utils.ElapsedMs(now,w.start)/1000),temperature=v.temperature},w.serial
    end
    return {currentWeather=v.weather,targetWeather=v.weather,transitionDuration=0,transitionElapsed=0,temperature=v.temperature},0
end
function R.Refresh(force,player)
    if not store then return end
    local packet={revision=store.value.revision,regions={},effects=store.value.effects,force=force==true}
    local parts={tostring(packet.revision)}
    local ids={};for id,v in pairs(store.value.regions) do if v.enabled then ids[#ids+1]=id end end;table.sort(ids)
    for _,id in ipairs(ids) do
        local v=store.value.regions[id];local p,sig=payload(v,id)
        if p then packet.regions[#packet.regions+1]={id=id,name=v.name,points=v.points,
            transitionSeconds=v.transitionSeconds,weather=p,signature=tostring(sig)}
            parts[#parts+1]=id..':'..tostring(sig)
        end
    end
    local key=table.concat(parts,'|')
    if force or key~=signature then
        if not player then signature=key end
        TriggerClientEvent('mstr_weather:client:regions',player or -1,packet)
    end
end
function R.Initialize()
    store=S.Open('data/regions.json',S.Copy(defaults),valid)
    R.Refresh(true)
end
local function scheduler()
    if started then return end
    local needed=false;for _,r in pairs(store.value.regions) do if r.enabled and r.mode~='static' then needed=true end end
    if not needed then return end
    started=true
    CreateThread(function()
        while true do
            local any=false;for _,r in pairs(store.value.regions) do if r.enabled and r.mode~='static' then any=true end end
            if not any then started=false;return end
            R.Refresh(false);Wait(250)
        end
    end)
end
function R.Start() scheduler() end
function R.Request(player,op,revision,id,raw)
    if not MSTR.Permissions.IsSuperAdmin(player) then return false,'forbidden' end
    if op=='list' then return true,{document=S.Copy(store.value),locked=store.locked} end
    if store.locked then return false,'locked' end
    if not MSTR.Utils.IsValidInteger(revision,0,2147483645) or revision~=store.value.revision then return false,'revision' end
    local next=S.Copy(store.value)
    if op=='save' then
        local v=S.Decode(raw)
        if not S.Id(id) or not v or not region(v) then return false,'invalid' end
        for key,r in pairs(next.regions) do if key~=id and MSTR.Geometry.Overlap(v.points,r.points) then return false,'overlap' end end
        next.regions[id]=v
    elseif op=='delete' then
        if not S.Id(id) or not next.regions[id] then return false,'invalid' end
        next.regions[id]=nil
    elseif op=='effects' then
        local v=S.Decode(raw);if not effects(v) then return false,'invalid' end;next.effects=v
    else return false,'invalid' end
    next.revision=next.revision+1
    local ok,reason=store:Commit(next);if not ok then return false,reason end
    if id then weighted[id]=nil end
    R.Refresh(true);scheduler()
    MSTR.Logging.Record('region_'..op,{revision=revision},{revision=next.revision,id=id},{player=player,origin='nui'})
    return true,{document=S.Copy(next),locked=false}
end
