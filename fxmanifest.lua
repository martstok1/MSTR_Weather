--[[
  Project: MSTR_Weather
  Author: Martstok
  Copyright (c) 2026 Martstok. All rights reserved.

  This resource is original work unless otherwise stated.

  Third-party code, libraries and assets remain subject to their
  respective licenses and copyright notices.
]]

fx_version 'cerulean'
game 'gta5'

author 'Martstok'
description 'Modern Weather and Time Management for FiveM'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/locales.lua'
}

server_scripts {
    'server/permissions.lua',
    'server/requests.lua',
    'server/logging.lua',
    'server/persistence.lua',
    'server/state.lua',
    'server/weather_engine.lua',
    'server/time_engine.lua',
    'server/admin.lua',
    'server/nui.lua',
    'server/server.lua'
}

client_scripts {
    'client/weather.lua',
    'client/time.lua',
    'client/blackout.lua',
    'client/settings.lua',
    'client/nui.lua',
    'client/client.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/theme.js',
    'web/locales.js',
    'web/branding.js',
    'web/logs.js',
    'images/default.svg',
    'images/*.png',
    'images/*.webp',
    'web/icons.js',
    'web/controls.js',
    'web/app.js'
}
