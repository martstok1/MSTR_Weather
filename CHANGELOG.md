# Changelog

## 2.0.0-rc.1 — integrated V2 test build

- Extend the existing V1 menu with Weather cycles, Regions and Temperature.
- Edit named cycles, reorder blocks, allocate exactly 100% of the game day, preview
  start/end times and configure transitions and temperatures per block.
- Replace temporary cycle commands and file import with superadmin NUI controls.
- Add regional static, weighted and cycle modes, a schematic coordinate-map editor,
  polygon/rectangle drawing, vertex/region movement and player-position helpers.
- Reuse the existing weather and time engines, including pause/speed changes;
  blend region boundaries in real seconds through the central client weather module.
- Add optional heat haze and transparent frost edges, with effect cleanup and
  precedence for other resources' timecycle effects.
- Add revisioned region/effect storage, verified writes, explicit backup recovery,
  polygon/reference validation and per-request superadmin authorization.
- Preserve V1 branding, themes, permissions, global blackout and shared NL/EN locale.

Status: owner testing pending. No new automated, browser, runtime, multiplayer or
performance tests were executed for this RC at the owner's request. Only Lua and
JavaScript syntax parsing was performed, without executing the scripts. Earlier phase
test results do not certify this build. See [the V2 guide](Instructions/V2_GEBRUIK.md).

## V2 phases 1 and 2

Pure cycle model, global execution and separate cycle storage. These development
steps remain in Git history; their temporary command workflow is superseded.

## 1.0.0

Original standalone weather/time management with NUI, permissions, themes,
NL/EN, blackout, dynamic weather, audit logs and JSON persistence.
