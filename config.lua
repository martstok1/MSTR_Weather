-- MSTR_Weather configuration
-- V1.0 development: Foundation + Weather + Time + Dynamic Weather + Blackout + Persistence

Config = {}

-- Enables detailed console logging. /mstrdebug works independently of this value.
Config.Debug = false

Config.General = {
    -- Development/admin commands used while V1.0 is being built.
    DebugCommand = 'mstrdebug',
    WeatherCommand = 'mstrweather',
    TimeCommand = 'mstrtime',
    BlackoutCommand = 'mstrblackout',
    MenuCommand = 'mstrmenu'
}

Config.Branding = {
    Name = 'MSTR Weather',
    Logo = 'images/logo.png',
    ShowName = true
}

Config.Permissions = {
    Admin = 'mstr.weather.admin', -- legacy access to ordinary weather/time controls
    SuperAdmin = 'mstr.weather.superadmin' -- assign to your own identifier in permissions.cfg
}

Config.Weather = {
    Default = 'CLEAR',

    -- Markov-style transition graph used by Dynamic Weather.
    -- Values are relative weights and are applied as true weighted random choices.
    -- Special weather such as snow/Halloween is not entered from normal weather,
    -- but if it is selected manually Dynamic Weather can transition out logically.
    Transitions = {
        EXTRASUNNY = {
            CLEAR = 85,
            CLOUDS = 15
        },

        CLEAR = {
            EXTRASUNNY = 20,
            CLOUDS = 55,
            SMOG = 10,
            FOGGY = 10,
            NEUTRAL = 5
        },

        CLOUDS = {
            CLEAR = 20,
            OVERCAST = 40,
            FOGGY = 10,
            SMOG = 5,
            CLEARING = 25
        },

        SMOG = {
            CLEAR = 60,
            CLOUDS = 30,
            FOGGY = 10
        },

        FOGGY = {
            CLOUDS = 50,
            CLEAR = 30,
            OVERCAST = 20
        },

        OVERCAST = {
            CLOUDS = 10,
            RAIN = 55,
            THUNDER = 10,
            CLEARING = 25
        },

        RAIN = {
            THUNDER = 15,
            OVERCAST = 20,
            CLEARING = 50,
            CLOUDS = 15
        },

        THUNDER = {
            RAIN = 65,
            OVERCAST = 15,
            CLEARING = 20
        },

        CLEARING = {
            CLEAR = 50,
            CLOUDS = 35,
            EXTRASUNNY = 15
        },

        NEUTRAL = {
            CLEAR = 65,
            CLOUDS = 35
        },

        SNOW = {
            SNOWLIGHT = 50,
            BLIZZARD = 10,
            CLEARING = 40
        },

        SNOWLIGHT = {
            SNOW = 20,
            CLEARING = 60,
            CLOUDS = 20
        },

        BLIZZARD = {
            SNOW = 55,
            SNOWLIGHT = 35,
            CLEARING = 10
        },

        XMAS = {
            SNOWLIGHT = 60,
            SNOW = 20,
            CLEARING = 20
        },

        HALLOWEEN = {
            FOGGY = 50,
            CLOUDS = 30,
            CLEAR = 20
        }
    },

    -- Missing/invalid graph entries use a safe per-weather fallback in the engine.
    TransitionDuration = 30, -- seconds
    AllowInstantChange = true,
    EnableSnowTrails = true
}

Config.DynamicWeather = {
    Enabled = true,

    -- Minutes between automatic weather decisions.
    -- For development testing you can temporarily use e.g. 0.1 (= 6 seconds).
    IntervalMinutes = 15,

    -- Safety bounds for the scheduler.
    MinIntervalMinutes = 0.1,
    MaxIntervalMinutes = 1440
}

Config.Time = {
    DefaultHour = 12,
    DefaultMinute = 0,
    Frozen = false,

    -- Real-time multiplier. 2.0 means the in-game clock advances twice as fast as real time.
    CycleSpeed = 2.0,
    MinCycleSpeed = 0.0,
    MaxCycleSpeed = 10.0,

    -- Server correction broadcast. This does NOT update GlobalState every second.
    CorrectionIntervalSeconds = 60,

    -- How often the client applies the locally calculated clock.
    ClientTickMs = 250
}

Config.Blackout = {
    Default = false,
    AffectVehicles = false
}

Config.Persistence = {
    Enabled = true,
    File = 'data/state.json',

    -- Multiple state changes in quick succession are batched into one write.
    DebounceMs = 1500
}
