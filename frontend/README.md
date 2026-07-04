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
  - `playback` — the video player itself (`video_player`), reading from the
    local drift-backed playlist/video cache. Never touches the network.
  - `sync` — three implementations selected automatically per platform:
    `FirestoreSyncService` (native Firebase SDK, realtime — macOS),
    `RestFirestoreSyncService` (Linux — no native SDK, so plain HTTPS +
    a Realtime Database push signal instead of polling; see backend/README.md),
    `WebSyncService` (streams from Storage URLs directly, no local caching).
  - `auth` — Firebase Authentication (email/password) gating the admin flow.
  - `admin` — playlist management: create/rename/delete playlists, upload
    videos into a specific playlist, reorder/move/rename videos, pick which
    playlist is live.
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

Uses the **official `video_player` package** — not a general-purpose media
library like `media_kit`. flutter-pi (the production target) has its own
first-party GStreamer-backed implementation of `video_player`'s platform
interface built into the engine itself; there's no plugin to register, no
extra Dart-side setup. `video_player` also has official macOS
(`video_player_avfoundation`) and web (`video_player_web`) implementations,
so the same widget code runs on every platform this app targets.

**Deployment requirement:** the target device needs GStreamer installed
before video will play under flutter-pi:

```
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly \
  gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-alsa
```

(Do not use `media_kit`/`media_kit_video` here — they implement the
*standard* Flutter plugin registration mechanism, which flutter-pi does not
support for third-party plugins. Confirmed in production: it throws
`MissingPluginException` on `VideoOutputManager.Create` at runtime.)

Each video gets its own `VideoPlayerController` (this package's design, not
ours) — the controller instance is the player provider's state, and the UI
rebuilds when it changes between videos. The controller is only constructed
once there's an actual video to play — not on every app boot — so an empty
playlist (fresh install, or in tests) never touches the platform video
implementation at all.

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
- `WebSyncService` streams videos directly from their Storage URL instead of
  caching locally (no local disk to speak of in a browser tab) — so the full
  upload → sync → playback loop *does* work in the web preview, just without
  offline caching.
- Device identity is a fresh UUID per session, not persisted.

## Testing

```
flutter analyze
flutter test
```

`flutter build linux` (the production target) cannot be compiled on macOS —
it requires a Linux toolchain (CMake, Ninja, GTK dev headers). Validate it on
a Linux host, container, or CI before deploying to a physical device.
