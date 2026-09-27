-- Shared command/NUI mutation gate. No background thread, cleared on disconnect.
MSTR.Requests = {}
local lastAction, lastDebug = {}, {}
function MSTR.Requests.Allow(player, readOnly)
    if not MSTR.Utils.IsValidInteger(player, 1, 2147483647) then return false end
    local bucket = readOnly and lastDebug or lastAction
    local now = GetGameTimer()
    if bucket[player] and MSTR.Utils.ElapsedMs(now, bucket[player]) < 500 then return false end
    bucket[player] = now
    return true
end
AddEventHandler('playerDropped', function()
    lastAction[source], lastDebug[source] = nil, nil
end)
