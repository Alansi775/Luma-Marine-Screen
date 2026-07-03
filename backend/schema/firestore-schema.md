# Firestore schema

Device-scoped from day one, even though only one device exists today —
this is what makes multi-display/device-registration (a named future
requirement) additive rather than a rewrite.

## Collections

### `videos/{videoId}`

Shared catalog — not duplicated per device, so the same video can appear in
multiple devices' playlists without re-uploading or re-describing it.

| Field             | Type      | Notes                                  |
|-------------------|-----------|-----------------------------------------|
| `storagePath`     | string    | Object path in Firebase Storage         |
| `checksum`        | string    | Used to detect changed files, skip re-downloads |
| `sizeBytes`       | number    |                                          |
| `durationSeconds` | number    |                                          |

Storage layout: `videos/{videoId}.mp4`, referenced by the matching document.

### `devices/{deviceId}`

| Field        | Type      | Notes                                    |
|--------------|-----------|-------------------------------------------|
| `name`       | string    | Human-readable label, e.g. "Salon Display" |
| `createdAt`  | timestamp |                                            |
| `lastSeenAt` | timestamp | Updated by the future sync engine's heartbeat |
| `appVersion` | string    |                                            |
| `status`     | string    | Home for future device health monitoring  |

### `devices/{deviceId}/playlist/{entryId}`

The active playlist for one device.

| Field       | Type      | Notes                                          |
|-------------|-----------|--------------------------------------------------|
| `videoId`   | string    | References `videos/{videoId}`                    |
| `sortOrder` | number    | Explicit ordering (not list position — must survive out-of-order sync updates) |
| `addedAt`   | timestamp |                                                    |

Mirrored locally in the `playlist_entries` drift table
(`frontend/lib/core/database/tables/playlist_entries_table.dart`).

## Documented, not yet created

These collections are named here so the schema doesn't need to change
shape when the corresponding features are built — only new documents
start appearing.

- `devices/{deviceId}/health/{logId}` — device health monitoring
- `devices/{deviceId}/commands/{commandId}` — command-queue pattern for
  remote reboot, brightness, and volume control (a device polls or
  listens for pending commands and marks them processed)
