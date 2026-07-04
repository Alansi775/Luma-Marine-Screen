# Luma Marine — Backend

Firebase configuration, security rules, and schema documentation only —
**no application code lives here**. All Dart/Flutter code is in `../frontend`.

Live project: `advertisingscreen` (Blaze plan).

## Contents

- `firebase.json` / `.firebaserc` — point the Firebase CLI at this project's
  rules files.
- `firestore.rules` — video catalog + playlists: public read, admin-only
  write (see "Security model" below).
- `storage.rules` — video files: public read, admin-only write.
- `database.rules.json` — Realtime Database: used *only* as a lightweight
  change-notification signal for the Linux sync engine (see "Realtime
  Database: why it exists" below) — not for storing real data.
- `schema/firestore-schema.md` — the Firestore collection layout (playlists,
  videos, devices).

## Security model

A single admin account (Firebase Authentication, email/password) manages
everything. Devices don't have their own credentials yet — see
`schema/firestore-schema.md`'s "documented, not yet created" section for
future per-device registration. Until then:

- **Reads are public** on the video catalog, playlists, and the RTDB
  change-signal — acceptable since this is non-sensitive signage content,
  not private data.
- **Writes require being signed in** as the admin (`request.auth != null` /
  `auth != null`), which today means "any authenticated user," since only
  the admin account exists.

Tighten this once real per-device authentication exists.

## Known risk: FlutterFire has no official Linux desktop support

`firebase_core`, `cloud_firestore`, `firebase_storage`, and `firebase_auth`
are federated plugins with no official Linux platform implementation.
Confirmed in production: on the Linux/flutter-pi target,
`Firebase.initializeApp()` throws
`PlatformException(channel-error, ... FirebaseCoreHostApi.initializeCore ...)`
— macOS (day-to-day dev) is officially supported, so this is easy to miss
until deployment.

The frontend handles this by design: `FirebaseBootstrapper`
(`frontend/lib/core/firebase/firebase_bootstrapper.dart`) treats Firebase
as best-effort and never lets a failed init block startup. More
importantly, **the sync engine has two implementations selected
automatically** (`frontend/lib/features/sync/data/services/sync_service_factory_io.dart`):

- `FirestoreSyncService` — used when the native SDK initializes (macOS).
  Realtime, via the SDK's own Firestore listeners.
- `RestFirestoreSyncService` — used when it doesn't (Linux, always). Talks
  to Firestore and Storage over their plain HTTPS REST APIs instead — no
  native plugin, no auth needed (this device only ever reads public data
  and downloads files, never signs in).

## Realtime Database: why it exists

Firestore's REST API has no realtime "listen" — that requires the gRPC
`Listen` RPC, which isn't practical to hand-roll in Dart. But polling on a
timer means either wasted requests (short interval) or slow reaction to
admin changes (long interval) — and a slow video download can take many
times longer than a short poll interval, which caused real bugs (see git
history on `rest_firestore_sync_service.dart`).

Instead, Realtime Database is used purely as a push notification:

- Path: `deviceSignals/{deviceId}/updatedAt` — a single server timestamp,
  nothing else. It is **not** a data store; Firestore remains the source
  of truth for playlists/videos.
- The admin app (`frontend/lib/core/realtime/device_change_signal.dart`)
  touches this path after every mutation that could affect what's playing
  (upload, delete, reorder, move, set-active-playlist).
- The Linux sync engine holds one persistent HTTP connection to this path
  using Realtime Database's Server-Sent-Events streaming endpoint
  (`Accept: text/event-stream`) and reacts within about a second of any
  change — genuinely event-driven, not fast polling. A long-interval
  (multi-minute) reconciliation poll still runs underneath as a safety net
  in case a signal is missed (e.g. during a reconnect), not as the primary
  mechanism.
- macOS doesn't need any of this — the native Firestore SDK's listeners are
  already realtime.

## Setting up a real Firebase project (for reference — already done for `advertisingscreen`)

1. Create the project in the Firebase console, upgrade to Blaze.
2. From `../frontend`, run
   `flutterfire configure --project=<id> --platforms=web,macos,linux --out=lib/core/firebase/firebase_options.dart`
   (requires an interactive `firebase login`).
3. Enable Authentication (email/password), Firestore, Storage, and
   Realtime Database in the console/CLI (`firebase init database` for the
   latter — the CLI's `database:instances:create` only works for
   *additional* instances after a default one exists).
4. Deploy rules: `firebase deploy --only firestore:rules,storage,database`
   from this directory.
