-- Shared constants for MSTR_Weather

MSTR = MSTR or {}
MSTR.Constants = MSTR.Constants or {}

local Constants = MSTR.Constants

Constants.WeatherTypes = {
    'EXTRASUNNY',
    'CLEAR',
    'CLOUDS',
    'SMOG',
    'FOGGY',
    'OVERCAST',
    'RAIN',
    'THUNDER',
    'CLEARING',
    'NEUTRAL',
    'SNOW',
    'BLIZZARD',
    'SNOWLIGHT',
    'XMAS',
    'HALLOWEEN'
}

Constants.WeatherTypeLookup = {}
for _, weatherType in ipairs(Constants.WeatherTypes) do
    Constants.WeatherTypeLookup[weatherType] = true
end

Constants.SnowWeatherTypes = {
    SNOW = true,
    BLIZZARD = true,
    SNOWLIGHT = true,
    XMAS = true
}
