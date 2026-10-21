-- Independent versioned configuration storage. Never restore old activation automatically.
MSTR.V2Storage = {}
local S=MSTR.V2Storage
function S.Copy(v)
    if type(v)~='table' then return v end
    local out={};for k,x in pairs(v) do out[k]=S.Copy(x) end;return out
end
function S.Decode(raw)
    if type(raw)~='string' or #raw==0 or #raw>262144 then return nil end
    local depth,quoted,escaped=0,false,false
    for i=1,#raw do
        local c=raw:sub(i,i)
        if quoted then
            if escaped then escaped=false elseif c=='\\' then escaped=true elseif c=='"' then quoted=false end
        elseif c=='"' then quoted=true
        elseif c=='{' or c=='[' then depth=depth+1;if depth>10 then return nil end
        elseif c=='}' or c==']' then depth=depth-1;if depth<0 then return nil end end
    end
    if depth~=0 or quoted then return nil end
    local ok,v=pcall(json.decode,raw);if ok then return v end
end
function S.Fields(v,keys)
    if type(v)~='table' or getmetatable(v) then return false end
    for k in pairs(v) do if not keys[k] then return false end end;return true
end
function S.Id(v) return type(v)=='string' and #v>0 and #v<=40 and v:match('^[a-z0-9_-]+$')~=nil end
function S.Open(path,default,validate)
    local raw=LoadResourceFile(GetCurrentResourceName(),path)
    local value=raw and S.Decode(raw)
    local locked=raw~=nil and not(value and validate(value))
    if raw==nil and LoadResourceFile(GetCurrentResourceName(),path..'.bak')~=nil then locked=true end
    local store={value=not locked and value or default,locked=locked,last=not locked and raw or nil}
    if locked then MSTR.Utils.Warn(path..' invalid; editing locked, no automatic backup restore') end
    local function write(file,data)
        local ok,r=pcall(SaveResourceFile,GetCurrentResourceName(),file,data,#data)
        return ok and (r==true or r==1) and LoadResourceFile(GetCurrentResourceName(),file)==data
    end
    function store:Commit(v)
        if self.locked then return false,'locked' end
        if not validate(v) then return false,'invalid' end
        local ok,data=pcall(json.encode,v)
        if not ok or #data>262144 then return false,'invalid' end
        if self.last and not write(path..'.bak',self.last) then return false,'storage' end
        if not write(path,data) then MSTR.Utils.Warn(path..' write failed; live configuration retained');return false,'storage' end
        self.value,self.last=v,data;return true
    end
    return store
end
