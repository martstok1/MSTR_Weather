# Runtime storage

This folder must remain present and writable by FXServer.

`state.json`, `state.json.bak`, `admin.json` and `admin.json.bak` are created automatically during runtime and are ignored by Git. Do not share these files with other servers: admin storage contains player identifiers and permissions.

Before updating the resource, stop it normally and create a backup outside the resource of all four files. Keep the backup until the new code has been confirmed to work correctly.

## Environment

`state.json` stores weather, dynamic weather, blackout, freeze state, time scale and whole hours/minutes. During a transition, the target weather is stored and applied immediately after restart. Seconds, transition progress and elapsed offline time are not saved.

If the primary file is missing or invalid, the resource attempts to load a valid backup and then falls back to defaults. Writes are batched and verified by reading them back. Failed environment writes are retried up to three times, with a single warning message. A normal stop saves the current environment. A crash may lose changes made since the last successful write.

To reset only the environment: stop the resource, create a backup and delete both `state.json` and `state.json.bak`. Deleting only the primary file may cause the backup to be loaded. Admin settings remain in effect.

## Administration and permissions

`admin.json` stores shared settings, server language and user permissions, even when environment persistence is disabled. These settings take precedence over the corresponding configuration defaults.

Corrupted admin storage, or a missing primary file while a backup exists, blocks regular access and admin write operations. Superadmins can still view the system. **There is no automatic backup restore:** this could restore permissions that were previously revoked. Stop the resource and deliberately restore a known-good version.

Do not simply delete both admin files, as defaults and regular ACE permissions will apply again. Keep backups outside the resource.