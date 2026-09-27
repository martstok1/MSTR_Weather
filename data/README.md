# Runtime state

This directory must remain present and writable by FXServer.

`state.json` and `state.json.bak` are generated at runtime and are deliberately
excluded from Git. A fresh installation uses `config.lua` defaults.

Before updating an existing installation, stop the resource normally and back up
both files outside the resource directory. Restore them after copying/checking out
the update if you want to keep your existing environment settings.

The primary JSON stores version 1, accepted weather, dynamic mode, blackout,
freeze, scale and resolved whole game hours/minutes. If a smooth transition is
active, the target weather is saved and restored instantly after restart.
Seconds, transition progress and offline elapsed time are not persisted.

A missing/invalid primary file falls back to a valid `.bak`, then config defaults.
The backup contains the previous successful state (the first save seeds both).
Writes are debounced; failures get up to three attempts and an explicit warning.
A normal stop flushes live state. A process crash can lose changes since the last
successful save; there is no periodic disk-write loop.

To deliberately reset to config defaults: stop the resource first, then remove
both runtime files, then start it again. Removing only the primary restores backup.
