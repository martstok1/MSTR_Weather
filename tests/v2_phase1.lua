-- Run from resource root: lua5.4 tests/v2_phase1.lua
dofile('config.lua')
dofile('shared/constants.lua')
dofile('shared/utils.lua')
dofile('server/cycle_model.lua')
local model = MSTR.CycleModel
local passed = 0
local function test(name, fn)
    fn()
    passed = passed + 1
    print('PASS ' .. name)
end
local function fixture()
    return { version=1, name='Dagcyclus', startMinute=360, blocks={
        {weather='clear',percent=25,transitionGameSeconds=60},
        {weather='RAIN',percent=75,transitionGameSeconds=120} } }
end
local function reject(edit, reason)
    local value=fixture(); edit(value)
    local result, errorCode=model.Compile(value)
    assert(result==nil and errorCode==reason, tostring(errorCode))
end
test('boundaries, previous day and midnight', function()
    local c=assert(model.Compile(fixture()))
    assert(model.Resolve(c,21600).index==1)
    assert(model.Resolve(c,43199.99).index==1)
    assert(model.Resolve(c,43200).index==2)
    assert(model.Resolve(c,0).index==2)
    assert(model.Resolve(c,21599).index==2)
end)
test('transition is inside block and resolves skipped time directly', function()
    local c=assert(model.Compile(fixture()))
    local x=model.Resolve(c,21630)
    assert(x.transitionProgress==0.5 and x.previousWeather=='RAIN')
    assert(x.remainingGameSeconds==21570 and x.weather=='CLEAR')
    assert(model.Resolve(c,21660).transitionProgress==1)
    assert(model.Resolve(c,43320).transitionProgress==1)
    assert(model.Resolve(c,21630).transitionProgress==0.5)
end)
test('exact decimal percentages and total', function()
    local f=fixture(); f.blocks[1].percent=33.33;f.blocks[2].percent=66.67
    assert(model.Compile(f))
    reject(function(x) x.blocks[2].percent=74.99 end,'total')
    reject(function(x) x.blocks[1].percent=25.001 end,'precision')
end)
test('zero/full-duration transitions and one-block cycle', function()
    local f=fixture(); f.blocks={{weather='CLEAR',percent=100,transitionGameSeconds=86400}}
    local c=assert(model.Compile(f));assert(not model.Resolve(c,21600).transitioning)
    f=fixture();f.blocks[1].transitionGameSeconds=0
    assert(model.Resolve(assert(model.Compile(f)),21600).transitionProgress==1)
    f.blocks[1].transitionGameSeconds=21600;assert(model.Compile(f))
    reject(function(x) x.blocks[1].transitionGameSeconds=21601 end,'transition')
end)
test('malformed, sparse and oversized arrays', function()
    assert(not model.Compile(false))
    reject(function(x) x.blocks={} end,'blocks')
    reject(function(x) x.blocks[2]=nil;x.blocks[3]={} end,'block')
    reject(function(x) x.blocks[25]={} end,'blocks')
    reject(function(x) x.blocks.extra={} end,'blocks')
    reject(function(x) x.blocks[1].extra=true end,'block')
    reject(function(x) x.extra=true end,'schema')
end)
test('strict names, schema version, clock and weather', function()
    reject(function(x) x.version=2 end,'version')
    reject(function(x) x.name='  ' end,'name')
    reject(function(x) x.name=string.rep('a',81) end,'name')
    reject(function(x) x.startMinute=1440 end,'startMinute')
    reject(function(x) x.blocks[1].weather='NOT_WEATHER' end,'weather')
    local c=assert(model.Compile(fixture()))
    for _,v in ipairs({-1,86400,math.huge,'12',false}) do assert(not model.Resolve(c,v)) end
    assert(not model.Resolve(c,0/0)); assert(not model.Resolve({},0))
end)
test('nonfinite and invalid numeric data rejected', function()
    for _,v in ipairs({0/0,math.huge,-1,0,'25',false}) do
        reject(function(x) x.blocks[1].percent=v end,'percent')
    end
    reject(function(x) x.blocks[1].transitionGameSeconds=0/0 end,'transition')
end)
test('compiled data isolated from callers', function()
    local f=fixture();local c=assert(model.Compile(f))
    f.blocks[1].weather='THUNDER';c.blocks={}
    local resolved=model.Resolve(c,21600);resolved.weather='SNOW'
    assert(model.Resolve(c,21600).weather=='CLEAR')
end)
test('all day positions covered with bounded progress', function()
    local c=assert(model.Compile(fixture()))
    for t=0,86399 do
        local x=assert(model.Resolve(c,t))
        assert(x.remainingGameSeconds>0 and x.transitionProgress>=0 and x.transitionProgress<=1)
    end
end)
print(('V2 phase 1: %d tests passed'):format(passed))
