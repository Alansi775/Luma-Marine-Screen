# Firestore schema

Device-scoped from day one, even though only one device exists today —
this is what makes multi-display/device-registration (a named future
requirement) additive rather than a rewrite.

## Collections

### `videos/{videoId}`

Shared catalog — not duplicated per playlist, so the same video can appear in
multiple playlists without re-uploading or re-describing it.

| Field             | Type      | Notes                                  |
|-------------------|-----------|-----------------------------------------|
| `name`            | string    | Admin-facing display name, renamable — defaults to the uploaded filename |
| `storagePath`     | string    | Object path in Firebase Storage         |
| `checksum`        | string    | Used to detect changed files, skip re-downloads |
| `sizeBytes`       | number    |                                          |
| `durationSeconds` | number    | Not populated yet — see known gaps below |
| `createdAt`       | timestamp |                                          |

Storage layout: `videos/{videoId}.{ext}`, referenced by the matching document.

### `playlists/{playlistId}`

An admin-managed, named collection of videos. Multiple playlists can exist;
exactly one is "active" per device at a time (see `devices/{deviceId}`).

| Field           | Type      | Notes                                          |
|-----------------|-----------|--------------------------------------------------|
| `name`          | string    | Admin-facing, renamable                          |
| `createdAt`     | timestamp |                                                   |
| `updatedAt`     | timestamp |                                                   |
| `scheduledStart`| string?   | Optional `"HH:mm"` (24h, local device time). Not yet consumed by the sync engine — see known gaps below. |

### `playlists/{playlistId}/entries/{entryId}`

| Field       | Type      | Notes                                          |
|-------------|-----------|--------------------------------------------------|
| `videoId`   | string    | References `videos/{videoId}`                    |
| `sortOrder` | number    | Explicit ordering (not list position — must survive out-of-order sync updates) |
| `addedAt`   | timestamp |                                                    |

A video can be moved between playlists (delete the entry in one, create it in
another) without touching the shared `videos/{videoId}` document.

### `devices/{deviceId}`

| Field             | Type      | Notes                                    |
|-------------------|-----------|--------------------------------------------|
| `name`            | string    | Human-readable label, e.g. "Salon Display" |
| `activePlaylistId`| string?   | Which playlist is currently on air. Null/missing = nothing plays. |
| `createdAt`       | timestamp |                                            |
| `lastSeenAt`      | timestamp | Updated by the future sync engine's heartbeat |
| `appVersion`      | string    |                                            |
| `status`          | string    | Home for future device health monitoring  |

The sync engine watches this document for `activePlaylistId`, then watches
that playlist's `entries` subcollection. Mirrored locally in the
`playlist_entries` + `videos` drift tables
(`frontend/lib/core/database/tables/`) — only the *active* playlist's
contents are ever synced locally, not every playlist that exists.

## Known gaps (called out explicitly, not silently dropped)

- **Time-based scheduling** (`scheduledStart`): the field exists so the
  schema doesn't need to change shape later, but the sync engine doesn't
  read it yet — switching the active playlist is manual
  (`devices/{deviceId}.activePlaylistId`) only.
- **Video duration**: not auto-extracted at upload time; `durationSeconds`
  stays unset until a future pass adds client-side probing.
- **Video thumbnails**: not generated; the admin UI shows a generic icon
  per video rather than a real frame preview.

## Documented, not yet created

- `devices/{deviceId}/health/{logId}` — device health monitoring
- `devices/{deviceId}/commands/{commandId}` — command-queue pattern for
  remote reboot, brightness, and volume control (a device polls or
  listens for pending commands and marks them processed)
