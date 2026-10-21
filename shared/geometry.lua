-- Bounded, dependency-free polygon operations shared by validation and selection.
MSTR.Geometry = {}
local G = MSTR.Geometry
local function cross(a,b,c) return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x) end
local function on(a,b,p)
    return math.abs(cross(a,b,p)) < 0.00001 and p.x >= math.min(a.x,b.x)-0.00001
        and p.x <= math.max(a.x,b.x)+0.00001 and p.y >= math.min(a.y,b.y)-0.00001
        and p.y <= math.max(a.y,b.y)+0.00001
end
function G.Contains(points,p,strict)
    local inside=false
    for i,a in ipairs(points) do
        local b=points[i%#points+1]
        if on(a,b,p) then return not strict end
        if (a.y>p.y)~=(b.y>p.y) and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then inside=not inside end
    end
    return inside
end
function G.Distance(points,p)
    local best=math.huge
    for i,a in ipairs(points) do
        local b=points[i%#points+1];local dx,dy=b.x-a.x,b.y-a.y
        local t=math.max(0,math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/(dx*dx+dy*dy)))
        best=math.min(best,math.sqrt((p.x-a.x-t*dx)^2+(p.y-a.y-t*dy)^2))
    end
    return best
end
local function intersects(a,b,c,d,touch)
    local ab,ac,cd,ce=cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)
    if ab*ac<0 and cd*ce<0 then return true end
    return touch and (on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b))
end
function G.Validate(points)
    if type(points)~='table' or getmetatable(points) then return false end
    local n=0;for k in pairs(points) do
        if not MSTR.Utils.IsValidInteger(k,1,64) then return false end;n=n+1
    end
    if n<3 then return false end
    local area=0
    for i=1,n do
        local p=points[i]
        if type(p)~='table' or getmetatable(p) then return false end
        for k in pairs(p) do if k~='x' and k~='y' then return false end end
        if not MSTR.Utils.IsValidNumber(p.x,-10000,10000) or not MSTR.Utils.IsValidNumber(p.y,-10000,10000) then return false end
    end
    for i,a in ipairs(points) do
        local b=points[i%n+1]
        if (a.x-b.x)^2+(a.y-b.y)^2<0.01 then return false end
        area=area+a.x*b.y-b.x*a.y
        for j=i+1,n do
            if j~=i+1 and not(i==1 and j==n) and intersects(a,b,points[j],points[j%n+1],true) then return false end
        end
    end
    return math.abs(area)>2
end
function G.Overlap(a,b)
    local function area(points)
        local n=0;for i,p in ipairs(points) do local q=points[i%#points+1];n=n+p.x*q.y-q.x*p.y end;return n
    end
    local areaA,areaB=area(a),area(b)
    for _,p in ipairs(a) do if G.Contains(b,p,true) then return true end end
    for _,p in ipairs(b) do if G.Contains(a,p,true) then return true end end
    for i,p in ipairs(a) do
        local q=a[i%#a+1]
        if G.Contains(b,{x=(p.x+q.x)/2,y=(p.y+q.y)/2},true) then return true end
        for j,r in ipairs(b) do
            local s=b[j%#b+1]
            if intersects(p,q,r,s,false) then return true end
            -- Collinear shared edges: interiors on the same side overlap.
            if math.abs(cross(p,q,r))<0.00001 and math.abs(cross(p,q,s))<0.00001 then
                local dx,dy=q.x-p.x,q.y-p.y
                local dot=dx*(s.x-r.x)+dy*(s.y-r.y)
                local u=(r.x-p.x)*dx+(r.y-p.y)*dy
                local v=(s.x-p.x)*dx+(s.y-p.y)*dy
                local overlap=math.min(dx*dx+dy*dy,math.max(u,v))-math.max(0,math.min(u,v))
                if overlap>0.00001 and areaA*areaB*dot>0 then return true end
            end
        end
    end
    return false
end
