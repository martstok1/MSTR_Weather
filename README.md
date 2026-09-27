<img width="1185" height="821" alt="Screenshot_7" src="https://github.com/user-attachments/assets/c335da62-2575-4b3f-b372-f9cf3b7db8a0" />


# MSTR_Weather

**Standalone weather and time management for FiveM · v1.0.0 · Martstok**

Manage weather, time and blackout from a single menu. MSTR_Weather synchronizes the environment through the server and provides separate permissions per administrator, Dutch and English menu text, and personal menu colors.

## Features

- Fifteen weather types, with instant changes or smooth transitions.
- Dynamic weather with a configurable interval and weighted, logical follow-up transitions.
- Set, freeze, resume, speed up or slow down time.
- Blackout with configurable impact on vehicle lighting.
- Automatic persistence of environment state, admin settings and access permissions.
- Superadmin panel with per-user permissions and a shared server language.
- Personal themes plus configurable server name and logo.
- Bounded action log for superadmins.
- Server-side permission checks, input validation and request rate limits.

No ESX, QBCore, ox_lib, database or external web service is required. The interface is included locally; no build step is needed.

## Installation

1. Download or clone this repository.
2. Place the resource as `MSTR_Weather` inside your resources folder. `fxmanifest.lua` must be directly inside that folder, not inside an additional subfolder.
3. Keep the `data/` folder and make sure FXServer can write to it.
4. Disable other weather and time synchronization resources, including any modules inside admin or framework resources.
5. Configure your superadmin permissions as described below.
6. Add the following to your loaded `resources.cfg`:

```cfg
ensure MSTR_Weather
```

Make sure your server configuration actually executes `permissions.cfg` and `resources.cfg`, with permissions loaded before the resource starts. Then start the server and open `/mstrmenu` in-game, or use `mstrmenu` in F8.

The resource does not automatically modify external configuration files.

## Access and superadmin

Add the following to your loaded `permissions.cfg`:

```cfg
add_ace identifier.fivem:YOUR_FIVEM_ID mstr.weather.superadmin allow
```

Replace `YOUR_FIVEM_ID` with the numeric part of your own `fivem:` identifier. Only grant this ACE to the intended account. Existing broad ACE rules or group permissions may also grant access.

| Access | Capabilities |
| --- | --- |
| No permissions | Receives the synchronized environment but cannot use the admin menu |
| Delegated user | Only the explicitly enabled sections |
| `mstr.weather.admin` | Regular controls, without the superadmin panel or logs |
| `mstr.weather.superadmin` | Full control, admin settings, user permissions and logs |

As a superadmin, add an online player through **Management**, or manually enter a `fivem:123456` identifier or a lowercase `license:` followed by 40 hexadecimal characters. Set permissions per user for menu access, weather, time, dynamic weather and blackout.

**Menu access** is required for all other regular permissions. A saved user rule takes precedence over the normal admin ACE. Disabling all permissions revokes regular access. Multiple saved identifiers belonging to the same player are combined restrictively.

Superadmin permissions can only be granted through ACE and never through the menu. A superadmin keeps those permissions regardless of regular user permission settings. Up to 256 user rules can be stored.

## Controls

Open the menu with `/mstrmenu`. Close it with Escape, the close button, or the same command.

| Section | Usage |
| --- | --- |
| Dashboard | Overview of the current environment |
| Weather | Select weather type, transition mode and control dynamic weather |
| Time | Control time, freeze state and time scale |
| Settings | Customize personal menu colors |
| Management | Shared settings and user permissions; superadmin only |
| Logs | Action history; superadmin only |

While the menu is open, it receives current server data approximately every two seconds. The displayed clock is a snapshot; the in-game clock continues locally based on server settings.

During a smooth weather transition, a second smooth transition is rejected. An instant change can interrupt the current transition when instant changes are allowed.

Dynamic weather selects its next step from `Config.Weather.Transitions`. The numbers are relative weights. Snow and Halloween are not automatically selected from normal weather in the default configuration. Disable dynamic weather if you want to keep a manually selected weather type active.

Supported types: `EXTRASUNNY`, `CLEAR`, `CLOUDS`, `SMOG`, `FOGGY`, `OVERCAST`, `RAIN`, `THUNDER`, `CLEARING`, `NEUTRAL`, `SNOW`, `SNOWLIGHT`, `BLIZZARD`, `XMAS` and `HALLOWEEN`.

## Configuration

Change startup settings in [config.lua](config.lua) and restart the resource.

| Configuration | Default / meaning |
| --- | --- |
| `General.Locale` | `nl`; supports `nl` and `en` |
| `General.MenuCommand` | `mstrmenu` |
| `Weather.Default` | `CLEAR` |
| `Weather.TransitionDuration` | 30 seconds |
| `Weather.AllowInstantChange` | Instant changes allowed |
| `Weather.EnableSnowTrails` | Snow trails enabled |
| `DynamicWeather.Enabled` | Enabled |
| `DynamicWeather.IntervalMinutes` | 15 minutes |
| `Time.DefaultHour / DefaultMinute` | 12:00 |
| `Time.CycleSpeed` | 2; two in-game seconds per real second |
| `Time.Frozen` | Disabled |
| `Blackout.Default` | Disabled |
| `Blackout.AffectVehicles` | Disabled |
| `Persistence.Enabled` | Enabled |
| `Logging.MaxEntries` | 200; configurable from 10 to 1000 |
| `Debug` | Disabled |

**Saved data takes precedence over startup defaults.** The superadmin can save transition duration, instant-change permission, dynamic weather interval, snow trails, vehicle-light impact, environment persistence and server language through **Management**. These settings are stored in `data/admin.json`. The saved environment state is stored separately in `data/state.json`.

A changed transition duration applies from the next transition. A changed dynamic weather interval starts a new countdown. Enabling environment persistence saves the current state; disabling it does not remove existing files.

### Language and appearance

**Management → Server language** selects Dutch or English for everyone. Open menus follow the change on the next update. The language is not a personal preference.

Under **Settings → Your appearance**, each administrator can choose a theme or custom colors. This preference is stored locally in the NUI browser. Clearing cache or using another computer can reset the preference.

Configure your branding in `config.lua`:

```lua
Config.Branding = {
    Name = 'My server',
    Logo = 'images/mylogo.png',
    ShowName = true
}
```

Place your PNG or WEBP file in `images/`. Use a simple filename containing letters, numbers, hyphens or underscores, with a lowercase extension. The default logo is `images/default.svg`. A missing or invalid logo falls back to the default logo. Set `ShowName = false` to hide the name.

### Optional commands

Only the menu command is enabled by default. To enable optional commands, replace `false` in `Config.General` with the corresponding command name:

| Config field | Name | Examples |
| --- | --- | --- |
| `WeatherCommand` | `mstrweather` | `/mstrweather RAIN smooth`, `/mstrweather CLEAR instant`, `/mstrweather dynamic false` |
| `TimeCommand` | `mstrtime` | `/mstrtime 18:30`, `/mstrtime freeze true`, `/mstrtime scale 2` |
| `BlackoutCommand` | `mstrblackout` | `/mstrblackout true` |
| `DebugCommand` | `mstrdebug` | Read-only current status |

Use explicit `false` to disable an optional command; a missing field may be filled by configuration validation. These commands work in-game and use the same permission checks as the menu. Visible command feedback uses `chat:addMessage` and requires a compatible chat resource.

Commands and menu actions share a limit of one request per player every 500 ms. Commands sent too quickly are ignored. The status command has a separate limit and is independent of `Config.Debug`.

## Storage, backups and updates

| File | Contents |
| --- | --- |
| `data/state.json` | Weather, time, dynamic weather, blackout, freeze state and time scale |
| `data/state.json.bak` | Previous valid environment state |
| `data/admin.json` | Shared admin settings and user permissions |
| `data/admin.json.bak` | Previous admin state |

These files are created during runtime and should not be committed to Git. Preserve them when updating:

1. Stop the resource normally.
2. Make a backup outside the resource of `config.lua`, custom logos and all JSON and backup files listed above.
3. Update the resource files and reapply your custom configuration values.
4. Keep or restore the runtime files in `data/`.
5. Start the resource again.

Writes are batched and read back for verification. On a normal stop, the current environment is saved. A crash may lose changes made since the last successful save. Seconds, transition progress and elapsed offline time are not stored. During a transition, the target weather is saved and applied immediately after restart.

If the environment state is invalid, the resource tries the backup and then the defaults. **Admin permissions intentionally do not use automatic backup restore** because an old backup could restore revoked permissions. Corrupted admin storage blocks regular access and admin writes. The superadmin can still inspect the system. Stop the resource, inspect the primary and backup files, and deliberately restore a valid version.

Do not simply delete `admin.json` and its backup: if both files are missing, defaults and regular ACE permissions apply again. See [data/README.md](data/README.md).

## Logging

The superadmin can view ADMIN and SYSTEM actions with timestamp, source, player/identifier where applicable, and old/new values. Logs are stored in memory only, are bounded, and disappear after a resource or server restart. There is no database or file archive for logs.

## Troubleshooting

| Problem | Check |
| --- | --- |
| Menu does not open | Resource is started, command name is correct, and effective ACE or user permissions are present |
| Management or Logs is missing | Your account needs the superadmin ACE |
| Config change appears to be ignored | Saved admin settings or environment state take precedence |
| Weather or time jumps back | Check whether another resource or dynamic weather is changing the environment |
| Change is rejected | Check permissions, active transition, input and request rate limit |
| Storage warning or locked management | Check server console, write permissions and JSON files; follow the recovery instructions above |
| Logo does not appear | Check file path, filename, extension and whether the file is included |

For support, include F8 and server messages, resource version and clear reproduction steps. Do not share player identifiers or admin files publicly.

## Version status

Version **1.0.0** was finalized at the owner's request after approved in-game checks through Phase 8. Synchronization with a second player had previously been confirmed.

**Release TODO:** the full multiplayer final verification for this exact release has been postponed: synchronization with two real clients, late join during a transition and simultaneous control by two admins. These checks have not been marked as passed. No fixed CPU or resmon value is guaranteed.

Development tests and phase documentation have been removed from the product version; earlier versions remain available in Git history. This version does not provide public developer exports, zones, per-routing-bucket weather or real-world weather.

## Author

**Martstok** · MSTR_Weather

Copyright © 2026 Martstok. All rights reserved.
