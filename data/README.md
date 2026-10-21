# Runtime storage

## V2 configuration

`cycles.json` stores cycle definitions, revision and global active ID.
`regions.json` stores regional weather, effect settings and revision. Both have a
`.bak` containing the previous valid configuration after a subsequent successful
save. A first save has no previous configuration to back up. All runtime JSON files
are ignored by Git. Keep both configurations together to preserve cycle references.

V2 saves are immediate and read back before publishing the new configuration.
Failed writes keep the previous live configuration, but can leave a partial primary
file on disk; inspect it before restart. Invalid/missing primary storage with a
backup present locks editing, without automatically restoring old activation.
Repair deliberately while stopped. A corrupt region file also blocks cycle deletion
because the service cannot prove the cycle is unused.

Storage is independent of ordinary environment persistence. `state.json` and
`admin.json` keep their existing formats. Cycle definition schema 1 remains readable
with 20 °C; editor saves use schema 2. The cycle container remains schema 1. Region
storage uses schema 1. Old `cycle_import.json` files are no longer read.

See [V2 usage and rollback](../Instructions/V2_GEBRUIK.md).

This folder must remain present and writable by FXServer.

`state.json`, `state.json.bak`, `admin.json` and `admin.json.bak` are created automatically during runtime and are ignored by Git. Do not share these files with other servers: admin storage contains player identifiers and permissions.

Before updating the resource, stop it normally and create a backup outside the resource of all environment, admin, cycle and region files and their backups. Keep the backup until the new code has been confirmed to work correctly.

## Environment

`state.json` stores weather, dynamic weather, blackout, freeze state, time scale and whole hours/minutes. During a transition, the target weather is stored and applied immediately after restart. Seconds, transition progress and elapsed offline time are not saved.

If the primary file is missing or invalid, the resource attempts to load a valid backup and then falls back to defaults. Writes are batched and verified by reading them back. Failed environment writes are retried up to three times, with a single warning message. A normal stop saves the current environment. A crash may lose changes made since the last successful write.

To reset only the environment: stop the resource, create a backup and delete both `state.json` and `state.json.bak`. Deleting only the primary file may cause the backup to be loaded. Admin settings remain in effect.

## Administration and permissions

`admin.json` stores shared settings, server language and user permissions, even when environment persistence is disabled. These settings take precedence over the corresponding configuration defaults.

Corrupted admin storage, or a missing primary file while a backup exists, blocks regular access and admin write operations. Superadmins can still view the system. **There is no automatic backup restore:** this could restore permissions that were previously revoked. Stop the resource and deliberately restore a known-good version.

Do not simply delete both admin files, as defaults and regular ACE permissions will apply again. Keep backups outside the resource.
