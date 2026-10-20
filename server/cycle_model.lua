-- Pure cycle validation and clock resolution. No events, timers or state writes.
-- Author: Martstok. Copyright (c) 2026 Martstok. All rights reserved.
MSTR = MSTR or {}
MSTR.CycleModel = {}
local Model = MSTR.CycleModel
local DAY = 86400
local compiled = setmetatable({}, { __mode = 'k' })

local function number(value, minimum, maximum)
    return MSTR.Utils.IsValidNumber(value, minimum, maximum)
end

local function fields(value, allowed)
    if type(value) ~= 'table' or getmetatable(value) ~= nil then return false end
    for key in pairs(value) do
        if not allowed[key] then return false end
    end
    return true
end

-- Percentages support two decimal places; integer basis points total exactly 10000.
-- Transition duration is in GAME seconds and belongs to the start of its block.
function Model.Compile(input)
    if not fields(input, { version=true, name=true, startMinute=true, blocks=true }) then
        return nil, 'schema'
    end
    if input.version ~= 1 then return nil, 'version' end
    if type(input.name) ~= 'string' or #input.name > 80 or not input.name:find('%S')
        or input.name:find('%c') then return nil, 'name' end
    if not MSTR.Utils.IsValidInteger(input.startMinute, 0, 1439) then
        return nil, 'startMinute'
    end
    if type(input.blocks) ~= 'table' or getmetatable(input.blocks) ~= nil then
        return nil, 'blocks'
    end
    local count = 0
    for key in pairs(input.blocks) do
        if not MSTR.Utils.IsValidInteger(key, 1, 24) then return nil, 'blocks' end
        count = count + 1
    end
    if count < 1 or count > 24 then return nil, 'blocks' end
    local total, blocks = 0, {}
    for i = 1, count do
        local block = input.blocks[i]
        if not fields(block, { weather=true, percent=true, transitionGameSeconds=true }) then
            return nil, 'block', i
        end
        local weather = MSTR.Utils.NormalizeWeatherType(block.weather)
        if not weather then return nil, 'weather', i end
        if not number(block.percent, 0.01, 100) then return nil, 'percent', i end
        local units = math.floor(block.percent * 100 + 0.5)
        if math.abs(block.percent * 100 - units) > 0.0000001 then
            return nil, 'precision', i
        end
        local duration = units * DAY / 10000
        if not number(block.transitionGameSeconds, 0, duration) then
            return nil, 'transition', i
        end
        blocks[i] = { weather=weather, start=total * DAY / 10000,
            duration=duration, transition=block.transitionGameSeconds }
        total = total + units
    end
    if total ~= 10000 then return nil, 'total' end
    -- Opaque handle prevents callers changing the validated internal model.
    local handle = {}
    compiled[handle] = { name=input.name, start=input.startMinute * 60, blocks=blocks }
    return handle
end

-- gameSeconds is the canonical server clock (0 <= seconds < 86400).
-- Resolve does not advance time: a frozen clock yields the same result.
function Model.Resolve(handle, gameSeconds)
    local cycle = compiled[handle]
    if not cycle then return nil, 'cycle' end
    if not number(gameSeconds, 0, DAY) or gameSeconds == DAY then return nil, 'clock' end
    local offset = (gameSeconds - cycle.start) % DAY
    for index, block in ipairs(cycle.blocks) do
        if offset < block.start + block.duration then
            local elapsed = offset - block.start
            local previous = cycle.blocks[index == 1 and #cycle.blocks or index - 1]
            local progress = block.transition == 0 and 1 or math.min(1, elapsed / block.transition)
            return { index=index, weather=block.weather, previousWeather=previous.weather,
                elapsedGameSeconds=elapsed, remainingGameSeconds=block.duration-elapsed,
                transitionProgress=progress, transitionGameSeconds=block.transition,
                transitioning=progress < 1 and previous.weather ~= block.weather,
                startGameSeconds=(cycle.start+block.start) % DAY,
                endGameSeconds=(cycle.start+block.start+block.duration) % DAY }
        end
    end
end
