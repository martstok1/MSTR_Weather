MSTR.ClientRegions={}
local R=MSTR.ClientRegions
local packet,received={regions={},effects={fallbackTemperature=20}},0
local global,globalAt=nil,0
local current,candidate,candidateAt,lastKey=nil,nil,0,nil
local generation,running=0,false
local shownTemperature,temperatureAt=nil,0
local function copy(p) local out={};for k,v in pairs(p) do out[k]=v end;return out end
local function advance(p,at)
    p=copy(p)
    local rate=p.cycle and p.clockRate or 1
    p.transitionElapsed=math.min(p.transitionDuration,p.transitionElapsed+MSTR.Utils.ElapsedMs(GetGameTimer(),at)/1000*rate)
    if p.previousTemperature and p.targetTemperature then
        local f=p.transitionDuration>0 and p.transitionElapsed/p.transitionDuration or 1
        p.temperature=p.previousTemperature+(p.targetTemperature-p.previousTemperature)*f
    end
    if p.transitionDuration<=0 or p.transitionElapsed>=p.transitionDuration then
        p.currentWeather=p.targetWeather;p.transitionDuration=0;p.transitionElapsed=0
    end
    return p
end
local function selected()
    for _,r in ipairs(packet.regions) do if r.id==current then return r end end
end
local function provider()
    local r=selected()
    if r then return advance(r.weather,received) end
    return global and advance(global,globalAt) or {currentWeather='CLEAR',targetWeather='CLEAR',transitionDuration=0,transitionElapsed=0}
end
local function apply(border,force)
    if not global then return end
    local r=selected()
    local key=r and r.id..':'..packet.revision..':'..r.signature or 'global'
    if force or key~=lastKey then
        lastKey=key
        MSTR.ClientWeather.Route(provider,border and (r and r.transitionSeconds or 10) or nil,true)
    end
end
function R.Global(p)
    if type(p)~='table' or not MSTR.Utils.IsValidWeatherType(p.currentWeather)
        or not MSTR.Utils.IsValidWeatherType(p.targetWeather) then return end
    global,globalAt=p,GetGameTimer()
    if not current then apply(false,true) end
end
function R.Environment()
    local p=provider();local r=selected()
    local target=p.temperature or packet.effects.fallbackTemperature or 20
    local now=GetGameTimer()
    if not shownTemperature then shownTemperature=target else
        local elapsed=MSTR.Utils.ElapsedMs(now,temperatureAt)/1000
        shownTemperature=shownTemperature+(target-shownTemperature)*(1-math.exp(-elapsed/math.max(1,r and r.transitionSeconds or 10)))
    end
    temperatureAt=now
    return shownTemperature,packet.effects,r and r.name or false,p.targetWeather
end
local function tick()
    local pos=GetEntityCoords(PlayerPedId())
    local found=nil
    -- Bounding boxes reject distant areas before point-in-polygon work.
    for _,r in ipairs(packet.regions) do
        local b=r.bounds
        if pos.x>=b.minX and pos.x<=b.maxX and pos.y>=b.minY and pos.y<=b.maxY
            and MSTR.Geometry.Contains(r.points,pos) then found=r.id;break end
    end
    local old=selected()
    if old and found~=current and MSTR.Geometry.Distance(old.points,pos)<3 then found=current end
    if found~=current then
        if found~=candidate then candidate,candidateAt=found,GetGameTimer() end
        if MSTR.Utils.ElapsedMs(GetGameTimer(),candidateAt)>=750 then
            current=found;candidate=nil;apply(true,true)
        end
    else candidate=nil;candidateAt=GetGameTimer();apply(false,false) end
end
RegisterNetEvent('mstr_weather:client:regions',function(value)
    if source~=65535 or type(value)~='table' or type(value.regions)~='table' or type(value.effects)~='table' then return end
    local old=selected();local oldId=current;local oldRevision=packet.revision
    packet,received=value,GetGameTimer()
    table.sort(packet.regions,function(a,b) return a.id<b.id end)
    for _,r in ipairs(packet.regions) do
        local b={minX=math.huge,maxX=-math.huge,minY=math.huge,maxY=-math.huge}
        for _,p in ipairs(r.points) do b.minX=math.min(b.minX,p.x);b.maxX=math.max(b.maxX,p.x);b.minY=math.min(b.minY,p.y);b.maxY=math.max(b.maxY,p.y) end
        r.bounds=b
    end
    if oldId and not selected() then current=nil;apply(true,true)
    elseif current then apply(old~=nil and oldRevision~=packet.revision,value.force==true) end
    if MSTR.Temperature then MSTR.Temperature.Configure(value.effects) end
    if not running and #packet.regions>0 then
        running=true;generation=generation+1;local token=generation
        CreateThread(function()
            while generation==token and #packet.regions>0 do tick();Wait(500) end
            running=false
        end)
    end
end)

-- Read-only editor coordinate helper. It cannot mutate server state.
RegisterNUICallback('position',function(_,cb)
    local p=GetEntityCoords(PlayerPedId());cb({x=p.x,y=p.y})
end)
