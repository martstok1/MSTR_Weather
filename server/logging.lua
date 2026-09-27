-- Bounded, server-only audit history. Read access is checked again at the service.
MSTR.Logging = {}
local Logging = MSTR.Logging
local entries, sequence = {}, 0

local function Copy(value, depth)
    local kind = type(value)
    if kind == 'string' then return value:gsub('%c', ' '):sub(1, 512) end
    if kind == 'boolean' then return value end
    if kind == 'number' then return MSTR.Utils.IsValidNumber(value, -1e15, 1e15) and value or nil end
    if kind ~= 'table' or (depth or 0) >= 3 then return nil end
    local result, count = {}, 0
    for key, item in pairs(value) do
        if type(key) == 'string' and #key <= 64 then
            result[key] = Copy(item, (depth or 0) + 1)
            count = count + 1
            if count >= 16 then break end
        end
    end
    return result
end

function Logging.Record(action, oldValue, newValue, actor)
    if not Config.Logging.Enabled then return end
    sequence = sequence + 1
    local player = actor and tonumber(actor.player)
    if player and (player <= 0 or player % 1 ~= 0) then player = nil end
    local sources = { command = true, nui = true, dynamic = true, startup = true, transition = true }
    local origin = actor and actor.origin
    local entry = {
        id = sequence, timestamp = os.time(), type = player and 'ADMIN' or 'SYSTEM',
        source = sources[origin] and origin or 'engine', action = Copy(action),
        oldValue = Copy(oldValue), newValue = Copy(newValue)
    }
    if player then
        entry.player = Copy(GetPlayerName(player) or ('#' .. player))
        entry.playerId = player
        entry.identifier = MSTR.Permissions.GetIdentity(player)
    end
    entries[#entries + 1] = entry
    if #entries > Config.Logging.MaxEntries then table.remove(entries, 1) end
end

function Logging.GetPage(player, before)
    if not MSTR.Permissions.IsSuperAdmin(player) then return nil, 'forbidden' end
    if before ~= nil and not MSTR.Utils.IsValidInteger(before, 1, 9007199254740991) then return nil, 'invalid' end
    local page, more = {}, false
    for index = #entries, 1, -1 do
        local entry = entries[index]
        if before == nil or entry.id < before then
            if #page >= 50 then more = true; break end
            -- Fresh response tables: callers cannot modify the audit ring.
            page[#page + 1] = {
                id = entry.id, timestamp = entry.timestamp, type = entry.type, source = entry.source,
                player = entry.player, playerId = entry.playerId, identifier = entry.identifier,
                action = entry.action, oldValue = Copy(entry.oldValue), newValue = Copy(entry.newValue)
            }
        end
    end
    return { entries = page, nextBefore = more and page[#page].id or nil,
        enabled = Config.Logging.Enabled, limit = Config.Logging.MaxEntries }
end
