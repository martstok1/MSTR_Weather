-- Global cycle service. Disk commit precedes publication; no client-owned clock.
MSTR.Cycles = {}
local Cycles = MSTR.Cycles
local FILE, LIMIT = 'data/cycles.json', 262144
local document = { version=1, revision=0, active=false, cycles={} }
local handles, lastGood, locked, ready = {}, nil, false, false
local generation, running, lastSignature = 0, false, nil

local function Fields(t, keys)
    if type(t) ~= 'table' or getmetatable(t) ~= nil then return false end
    for key in pairs(t) do if not keys[key] then return false end end
    return true
end
local function Id(id)
    return type(id)=='string' and #id>=1 and #id<=40 and id:match('^[a-z0-9_-]+$') ~= nil
end
local function Copy(value)
    if type(value)~='table' then return value end
    local result={};for k,v in pairs(value) do result[k]=Copy(v) end;return result
end
local function Validate(value)
    if not Fields(value,{version=true,revision=true,active=true,cycles=true})
        or value.version~=1 or not MSTR.Utils.IsValidInteger(value.revision,0,2147483646)
        or type(value.cycles)~='table' or getmetatable(value.cycles)~=nil then return nil end
    local result,count={},0
    for id, definition in pairs(value.cycles) do
        count=count+1
        if count>32 or not Id(id) then return nil end
        local compiled=MSTR.CycleModel.Compile(definition)
        if not compiled then return nil end
        result[id]=compiled
    end
    if value.active~=false and (not Id(value.active) or not result[value.active]) then return nil end
    return result
end

-- Bound JSON nesting before decoding, including quoted braces and escaped quotes.
local function Decode(raw)
    if type(raw)~='string' or #raw==0 or #raw>LIMIT then return nil end
    local depth,quoted,escape=0,false,false
    for i=1,#raw do
        local c=raw:sub(i,i)
        if quoted then
            if escape then escape=false elseif c=='\\' then escape=true elseif c=='"' then quoted=false end
        elseif c=='"' then quoted=true
        elseif c=='{' or c=='[' then depth=depth+1;if depth>8 then return nil end
        elseif c=='}' or c==']' then depth=depth-1;if depth<0 then return nil end end
    end
    if quoted or depth~=0 then return nil end
    local ok,value=pcall(json.decode,raw)
    if ok then return value end
end
local function Write(path, raw)
    local ok,result=pcall(SaveResourceFile,GetCurrentResourceName(),path,raw,#raw)
    return ok and (result==true or result==1)
        and LoadResourceFile(GetCurrentResourceName(),path)==raw
end
local function Commit(nextDocument)
    local compiled=Validate(nextDocument)
    if not compiled then return false,'invalid' end
    local ok,raw=pcall(json.encode,nextDocument)
    if not ok or type(raw)~='string' or #raw>LIMIT then return false,'invalid' end
    if lastGood and not Write(FILE..'.bak',lastGood) then
        MSTR.Utils.Warn('Cycle backup write failed; live configuration unchanged')
        return false,'storage'
    end
    if not Write(FILE,raw) then
        -- Preserve the last good backup, never promote a partial primary write.
        MSTR.Utils.Warn('Cycle write failed; live configuration unchanged; inspect cycles.json before restart')
        return false,'storage'
    end
    document,handles,lastGood=nextDocument,compiled,raw
    return true
end

function Cycles.IsActive() return ready and document.active~=false end
function Cycles.GetStatus()
    return { active=Cycles.IsActive() and document.active or false,
        revision=document.revision, locked=locked }
end
function Cycles.GetPayload()
    if not Cycles.IsActive() then return nil end
    local result=MSTR.CycleModel.Resolve(handles[document.active],MSTR.TimeEngine.GetCurrentMinutes()*60)
    local clock=MSTR.TimeEngine.GetSyncPayload()
    return { cycle=true, currentWeather=result.previousWeather, targetWeather=result.weather,
        transitionDuration=result.transitionGameSeconds,
        transitionElapsed=math.min(result.elapsedGameSeconds,result.transitionGameSeconds),
        clockRate=clock.frozen and 0 or clock.scale },result
end
function Cycles.Refresh(force)
    if not Cycles.IsActive() then return end
    local payload,result=Cycles.GetPayload()
    local signature=document.active..':'..document.revision..':'..result.index..':'..tostring(result.transitioning)
    if force or signature~=lastSignature then
        lastSignature=signature
        MSTR.WeatherEngine.ApplyCycle(payload,result)
    end
end
local function StartScheduler()
    if running or not Cycles.IsActive() then return end
    running=true;generation=generation+1
    local token=generation
    CreateThread(function()
        while token==generation and Cycles.IsActive() do
            Cycles.Refresh(false)
            local payload,result=Cycles.GetPayload()
            local seconds=result.remainingGameSeconds
            if result.transitioning then seconds=math.min(seconds,payload.transitionDuration-payload.transitionElapsed) end
            local delay=payload.clockRate>0 and math.max(50,math.min(1000,math.ceil(seconds/payload.clockRate*1000))) or 1000
            Wait(delay)
        end
    end)
end
local function ApplyMode(wasActive)
    if Cycles.IsActive() then
        MSTR.WeatherEngine.SuspendAutomaticWeather()
        Cycles.Refresh(true)
        StartScheduler()
    else
        generation=generation+1;running=false;lastSignature=nil
        if wasActive then MSTR.WeatherEngine.EndCycle() end
    end
end
function Cycles.Initialize()
    if ready then return end
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local backup=LoadResourceFile(GetCurrentResourceName(),FILE..'.bak')
    if raw~=nil then
        local value=Decode(raw);local compiled=value and Validate(value)
        if compiled then document,handles,lastGood=value,compiled,raw else locked=true end
    elseif backup~=nil then locked=true end
    ready=true
    if locked then MSTR.Utils.Warn('Invalid cycle storage: cycle editing locked, no automatic backup restore; v1 environment retained') end
    ApplyMode(false)
end

-- One entrypoint for temporary command and future NUI. Never trust actor/source in data.
function Cycles.Request(player, action, revision, id, raw)
    if not MSTR.Permissions.IsSuperAdmin(player) then return false,'forbidden' end
    if not MSTR.Requests.Allow(player) then return false,'rate' end
    if action=='list' then return true,Copy(document),locked end
    if locked then return false,'locked' end
    if not MSTR.Utils.IsValidInteger(revision,0,2147483645) or revision~=document.revision then
        return false,'revision'
    end
    local nextDocument=Copy(document)
    if action=='import' then
        if not Id(id) then return false,'invalid' end
        local definition=Decode(raw or LoadResourceFile(GetCurrentResourceName(),'data/cycle_import.json'))
        if not definition or not MSTR.CycleModel.Compile(definition) then return false,'invalid' end
        nextDocument.cycles[id]=definition
    elseif action=='activate' then
        if not Id(id) or not nextDocument.cycles[id] then return false,'invalid' end
        nextDocument.active=id
    elseif action=='delete' then
        if not Id(id) or not nextDocument.cycles[id] then return false,'invalid' end
        if nextDocument.active==id then return false,'in_use' end
        nextDocument.cycles[id]=nil
    elseif action=='stop' then
        if id~='confirm' then return false,'confirm' end
        nextDocument.active=false
    else return false,'invalid' end
    nextDocument.revision=nextDocument.revision+1
    local wasActive=Cycles.IsActive()
    local previous={ revision=document.revision, active=document.active }
    local ok,reason=Commit(nextDocument)
    if not ok then return false,reason end
    ApplyMode(wasActive)
    MSTR.Logging.Record('cycle_'..action,previous,{ revision=document.revision, active=document.active, id=id },
        {player=player,origin='command'})
    return true,Cycles.GetStatus()
end

-- Deliberately no network mutation event in this phase. Import is a fixed local file.
RegisterCommand('mstrcycle',function(player,args)
    if not MSTR.Utils.IsValidInteger(player,1,2147483647) then return end
    local action=args[1] or 'list'
    local raw
    local ok,result,isLocked=Cycles.Request(player,action,tonumber(args[3]),args[2],raw)
    local nl=Config.General.Locale=='nl'
    local reasons={
        forbidden={'Geen hoofdadminrechten.','Superadmin permission required.'},
        rate={'Wacht even tussen verzoeken.','Wait between requests.'},
        locked={'Cyclusopslag beschadigd; herstel het bestand met de resource gestopt.','Cycle storage damaged; repair while resource is stopped.'},
        revision={'Verouderde revisie. Gebruik /mstrcycle list.','Stale revision. Use /mstrcycle list.'},
        invalid={'Ongeldige invoer of importbestand. Zie het Fase 2-testplan.','Invalid input or import file. See the Phase 2 test plan.'},
        storage={'Opslaan mislukt. Actieve toestand behouden.','Save failed. Live state retained.'},
        in_use={'Stop de cyclus eerst.','Stop the cycle first.'},
        confirm={'Gebruik /mstrcycle stop confirm <revisie>.','Use /mstrcycle stop confirm <revision>.'}
    }
    local message
    if ok then
        message=(nl and 'Revisie: ' or 'Revision: ')..result.revision..' | '..(nl and 'Actief: ' or 'Active: ')..tostring(result.active)
        if action=='list' then
            local ids={};for key in pairs(result.cycles) do ids[#ids+1]=key end;table.sort(ids)
            message=message..' | '..table.concat(ids,', ')..(isLocked and ' | LOCKED' or '')
        end
    else local pair=reasons[result] or reasons.invalid;message=pair[nl and 1 or 2] end
    TriggerClientEvent('chat:addMessage',player,{args={'MSTR_Weather',message}})
end,false)
