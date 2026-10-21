-- Visual effects only. Never changes health, thirst, clothing or other resources.
MSTR.Temperature={}
local T=MSTR.Temperature
local settings,running,temperature,heat,cold=nil,false,20,0,0
local modifierName=GetCurrentResourceName()..'_heat_v2'
local modifierIndex,prepared,blocked=nil,false,false
local function release()
    if modifierIndex and GetTimecycleModifierIndex()==modifierIndex then ClearTimecycleModifier() end
end
local function prepare()
    if prepared then return end;prepared=true
    -- Resolve supported variable names from this game build, without editing vanilla modifiers.
    local available={}
    for i=0,GetTimecycleVarCount()-1 do available[GetTimecycleVarNameByIndex(i)]=true end
    local vars={heat_haze=1.0,heat_haze_scale=0.5,heat_haze_speed=1.0,heat_haze_intensity=1.0,
        heat_haze_min_intensity=0.2,heat_haze_max_intensity=1.0,heat_haze_scroll_speed=0.1}
    local any=false;for name in pairs(vars) do if available[name] then any=true end end
    if not any then MSTR.Utils.Warn('Heat haze variables unavailable in this game build');return end
    local index=CreateTimecycleModifier(modifierName)
    if index==-1 then MSTR.Utils.Warn('Cannot create heat haze modifier');return end
    modifierIndex=index
    for name,value in pairs(vars) do if available[name] then SetTimecycleModifierVar(modifierName,name,value,value) end end
end
function T.Get() return temperature end
function T.Configure(value)
    settings=value
    if not value.heat then blocked=false end
    if running or (not value.heat and not value.cold and heat==0 and cold==0) then return end
    running=true
    CreateThread(function()
        while settings and (settings.heat or settings.cold or heat>0 or cold>0) do
            local target=MSTR.ClientRegions.Environment()
            local step=0.25/math.max(1,settings.fadeSeconds)
            temperature=temperature+(target-temperature)*math.min(1,step*4)
            local h=settings.heat and math.min(1,math.max(0,(temperature-settings.heatThreshold)/10))*settings.intensity or 0
            local c=settings.cold and math.min(1,math.max(0,(settings.coldThreshold-temperature)/10))*settings.intensity or 0
            heat=heat+(h-heat)*math.min(1,step*4);cold=cold+(c-cold)*math.min(1,step*4)
            if heat<0.001 then heat=0 end;if cold<0.001 then cold=0 end
            if heat>0 and not blocked then
                prepare()
                if modifierIndex then
                    local active=GetTimecycleModifierIndex()
                    if active==-1 then SetTimecycleModifier(modifierName)
                    elseif active~=modifierIndex then blocked=true end
                    if not blocked then SetTimecycleModifierStrength(heat) end
                end
            elseif heat==0 then release() end
            SendNUIMessage({action='temperature',cold=cold,temperature=temperature})
            Wait(250)
        end
        release();SendNUIMessage({action='temperature',cold=0,temperature=temperature});running=false
    end)
end
AddEventHandler('onClientResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    release()
    if modifierIndex then RemoveTimecycleModifier(modifierName) end
    SendNUIMessage({action='temperature',cold=0})
end)
