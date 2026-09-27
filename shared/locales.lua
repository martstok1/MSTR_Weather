-- Player-facing command feedback. Command names/arguments remain stable API tokens.
MSTR = MSTR or {}
MSTR.Locale = {}
local entries = {
    { 'You do not have permission to use this command.', 'Je hebt geen toestemming voor dit commando.' },
    { 'Usage: /mstrweather <weather_type> [smooth|instant] | /mstrweather dynamic <true|false>', 'Gebruik: /mstrweather <weertype> [smooth|instant] | /mstrweather dynamic <true|false>' },
    { 'Usage: /mstrweather dynamic <true|false>', 'Gebruik: /mstrweather dynamic <true|false>' },
    { 'Failed to change Dynamic Weather state.', 'Dynamisch weer wijzigen is mislukt.' },
    { 'Dynamic Weather set to %s', 'Dynamisch weer ingesteld op %s' },
    { 'Invalid weather type.', 'Ongeldig weertype.' },
    { 'Transition mode must be smooth or instant.', 'Gebruik smooth of instant als overgangstype.' },
    { 'Instant weather changes are disabled in config.', 'Directe weerwijzigingen zijn uitgeschakeld.' },
    { 'A weather transition is active. Wait for completion or use instant.', 'Er loopt een weerovergang. Wacht tot deze klaar is of gebruik instant.' },
    { 'Failed to change weather to %s', 'Weer wijzigen naar %s is mislukt' },
    { 'Weather change accepted: %s (%s)', 'Weerwijziging geaccepteerd: %s (%s)' },
    { 'Usage: /mstrtime HH:MM | /mstrtime freeze <true|false> | /mstrtime scale <value>', 'Gebruik: /mstrtime UU:MM | /mstrtime freeze <true|false> | /mstrtime scale <waarde>' },
    { 'Usage: /mstrtime freeze <true|false>', 'Gebruik: /mstrtime freeze <true|false>' },
    { 'Failed to change the frozen state.', 'Bevriezen of hervatten van de tijd is mislukt.' },
    { 'Time frozen set to %s', 'Tijd bevroren ingesteld op %s' },
    { 'Scale must be between %s and %s.', 'Snelheid moet tussen %s en %s liggen.' },
    { 'Time scale set to %s', 'Tijdsnelheid ingesteld op %s' },
    { 'Invalid time. Use HH:MM with hour 0-23 and minute 0-59.', 'Ongeldige tijd. Gebruik UU:MM met uur 0–23 en minuut 0–59.' },
    { 'Failed to set time.', 'Tijd instellen is mislukt.' },
    { 'Time set to %s', 'Tijd ingesteld op %s' },
    { 'Usage: /mstrblackout <true|false>', 'Gebruik: /mstrblackout <true|false>' },
    { 'Failed to change blackout state.', 'Stroomuitval wijzigen is mislukt.' },
    { 'Blackout set to %s', 'Stroomuitval ingesteld op %s' },
    { 'Core OK | Weather: %s | Time: %s | Dynamic: %s | Next: %s | Transition: %s | Blackout: %s | Frozen: %s | Scale: %s', 'Kern OK | Weer: %s | Tijd: %s | Dynamisch: %s | Volgende: %s | Overgang: %s | Stroomuitval: %s | Bevroren: %s | Snelheid: %s' },
    { 'No access to the menu (permission required).', 'Geen toegang tot het menu (toestemming vereist).' },
    { 'Menu closed: no server response or NUI not ready. Try again.', 'Menu gesloten: geen serverantwoord of NUI niet gereed. Probeer opnieuw.' }
}
local names = { ['true'] = 'aan', ['false'] = 'uit', off = 'uit', smooth = 'geleidelijk', instant = 'direct',
    CLEAR = 'Helder', EXTRASUNNY = 'Zonnig', CLOUDS = 'Wolken', OVERCAST = 'Zwaarbewolkt',
    RAIN = 'Regen', THUNDER = 'Onweer', SMOG = 'Smog', FOGGY = 'Mist', CLEARING = 'Opklaringen',
    NEUTRAL = 'Neutraal', SNOW = 'Sneeuw', SNOWLIGHT = 'Lichte sneeuw', BLIZZARD = 'Sneeuwstorm', XMAS = 'Kerstsneeuw', HALLOWEEN = 'Halloween' }
local function Escape(s) return (s:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')) end
for _, entry in ipairs(entries) do
    local pattern, position, count = '^', 1, 0
    while true do
        local start = entry[1]:find('%s', position, true)
        if not start then pattern = pattern .. Escape(entry[1]:sub(position)) .. '$'; break end
        pattern = pattern .. Escape(entry[1]:sub(position, start - 1)) .. '(.-)'
        position, count = start + 2, count + 1
    end
    entry.pattern, entry.count = pattern, count
end
function MSTR.Locale.Translate(message)
    if Config.General.Locale == 'en' then return message end
    for _, entry in ipairs(entries) do
        if entry.count == 0 then
            if message == entry[1] then return entry[2] end
        else
            local values = { message:match(entry.pattern) }
            if #values == entry.count then
                for i, value in ipairs(values) do values[i] = names[value] or value end
                return entry[2]:format(table.unpack(values))
            end
        end
    end
    return message
end
