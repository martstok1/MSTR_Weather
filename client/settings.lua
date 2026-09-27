-- Visual settings replicated through the existing central server state service.
local function Apply(settings)
    if type(settings) ~= 'table' or type(settings.snowTrails) ~= 'boolean'
        or type(settings.affectVehicles) ~= 'boolean' then return end
    Config.Weather.EnableSnowTrails = settings.snowTrails
    if settings.locale == 'nl' or settings.locale == 'en' then Config.General.Locale = settings.locale end
    Config.Blackout.AffectVehicles = settings.affectVehicles
    MSTR.ClientWeather.RefreshSettings()
    local blackout = GlobalState['mstr:blackout']
    if type(blackout) == 'boolean' then MSTR.ClientBlackout.Apply(blackout) end
end

AddStateBagChangeHandler('mstr:settings', 'global', function(_, _, value) Apply(value) end)
CreateThread(function() Wait(500); Apply(GlobalState['mstr:settings']) end)
