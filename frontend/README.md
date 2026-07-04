# Luma Marine — Frontend

The Flutter application. Runs on macOS during development and on Ubuntu Server
(x86_64) via [flutter-pi](https://github.com/ardera/flutter-pi) in production.
`flutter run -d chrome` also works for fast UI iteration (see "Web preview"
below for what does and doesn't work there).

## Running locally

```
flutter run -d macos
```

## Architecture

Feature-first Clean Architecture. See `lib/`:

- `core/` — cross-cutting infrastructure: logging, local app-data directories,
  the drift database, Firebase bootstrap, device identity, error types. Several
  of these (directories, logger, device identity, database connection) have
  separate native/web implementations picked via conditional exports (e.g.
  `default_app_directories.dart`), since `dart:io` and native SQLite don't
  exist on Flutter Web.
- `theme/` — the white/black/grey design system and the 06:00/18:00
  light/dark schedule (`ThemeSchedule`).
- `routing/` — `go_router` setup: `/` (signage player), `/diagnostics`,
  `/admin/login`, `/admin` (auth-guarded).
- `shared/` — generic reusable widgets not tied to a single feature.
- `features/<name>/{domain,data,presentation}`:
  - `playback` — the video player itself (`media_kit`), reading from the
    local drift-backed playlist/video cache. Never touches the network.
  - `sync` — the real sync engine (`FirestoreSyncService`, native only):
    listens to the default screen's Firestore playlist, downloads new/changed
    videos, prunes ones no longer referenced. Web always uses the no-op
    stub — there's no local video cache to speak of in a browser tab.
  - `auth` — Firebase Authentication (email/password) gating the admin flow.
  - `admin` — the hidden upload screen: pick a video file, upload to Storage,
    write its Firestore catalog entry and playlist entry.
  - `diagnostics` — read-only status screen (device id, Firebase/sync/storage
    state).

All cross-cutting singletons (logger, directories, database, Firebase
availability) are resolved once in `bootstrap.dart` before `runApp`, then
injected into Riverpod via `ProviderScope(overrides: ...)` — see that file
for the exact ordering and why it matters.

## Admin flow

There's no visible admin button — long-press the logo on the idle/splash
screen (or anywhere on the signage view while a video is playing) to reach
`/admin/login`. Sign in with a Firebase Authentication (email/password) user;
create one via the Firebase console under Authentication → Users. Note
Firebase requires passwords to be **at least 6 characters**.

## Firebase

Configured against the `advertisingscreen` project —
`lib/core/firebase/firebase_options.dart` has real values for `web` and
`macos`, plus a `linux` case that reuses the macOS app's project-level values
(FlutterFire has no official Linux SDK — see `backend/README.md`). To
reconfigure after Firebase project changes:

```
flutterfire configure --project=advertisingscreen --platforms=web,macos,linux --out=lib/core/firebase/firebase_options.dart
```

`FirebaseBootstrapper` treats Firebase as best-effort — the app runs fully
offline without it, which is also its normal behavior on a yacht with no
internet.

## Video playback

Uses [`media_kit`](https://pub.dev/packages/media_kit) rather than the
official `video_player` plugin, which has no Linux implementation at all —
`media_kit` (backed by libmpv) is the standard choice for Flutter kiosk/signage
apps on flutter-pi. **Deployment note:** the target Ubuntu Server device needs
`libmpv` installed (`media_kit_libs_linux` bundles it for a normal `flutter
build linux`, but verify it's present/loadable in the flutter-pi runtime
environment before relying on it).

The player is only constructed once there's an actual video to play — not on
every app boot — so an empty playlist (fresh install, or in tests) never
touches the native media library at all.

## Branding

`assets/icon/LUMA_MARINE_logo_black.png` and `_white.png` are the real
transparent-background logos (dark and light wordmark). The static app icon
uses the black wordmark; the in-app splash
(`lib/shared/widgets/bootstrap_screen.dart`) picks whichever variant reads
correctly against the current theme's background. Regenerate icons with:

```
dart run flutter_launcher_icons
```

There's no native splash screen config: `flutter_native_splash` only supports
Android/iOS/Web, and flutter-pi has no OS-level splash surface to hook into
before Dart runs anyway. `bootstrap_screen.dart` is the real splash — shown
in-app while `bootstrap()` finishes its async setup, and whenever the
playlist is empty.

## Web preview

`flutter run -d chrome` works for iterating on UI, auth, and the admin upload
flow quickly (no native compile step). What's different there:

- The database uses drift's WASM backend (`sqlite3.wasm` +
  `drift_worker.dart.js` in `web/` — download matching versions from
  `simolus3/sqlite3.dart` and `simolus3/drift` GitHub releases if you upgrade
  those packages).
- The real sync engine doesn't run on web (`NoopSyncService` always) — there's
  no local video cache in a browser tab, so uploaded videos won't appear/play
  in the web preview. Use macOS to see the full upload → sync → playback loop.
- Device identity is a fresh UUID per session, not persisted.

## Testing

```
flutter analyze
flutter test
```

`flutter build linux` (the production target) cannot be compiled on macOS —
it requires a Linux toolchain (CMake, Ninja, GTK dev headers). Validate it on
a Linux host, container, or CI before deploying to a physical device.
