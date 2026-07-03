# Luma Marine — Frontend

The Flutter application. Runs on macOS during development and on Ubuntu Server
(x86_64) via [flutter-pi](https://github.com/ardera/flutter-pi) in production.

## Running locally

```
flutter run -d macos
```

## Architecture

Feature-first Clean Architecture. See `lib/`:

- `core/` — cross-cutting infrastructure: logging, local app-data directories,
  the drift database, Firebase bootstrap, device identity, error types.
- `theme/` — the white/black/grey design system and the 06:00/18:00
  light/dark schedule (`ThemeSchedule`).
- `routing/` — `go_router` setup.
- `shared/` — generic reusable widgets not tied to a single feature.
- `features/<name>/{domain,data,presentation}` — one folder per feature.
  `playback` is the only fully real feature this pass; `sync` and
  `diagnostics` are thin stubs proving the pattern extends cleanly to the
  future sync engine and remote diagnostics.

All cross-cutting singletons (logger, directories, database, Firebase
availability) are resolved once in `bootstrap.dart` before `runApp`, then
injected into Riverpod via `ProviderScope(overrides: ...)` — see that file
for the exact ordering and why it matters.

## Firebase

No real Firebase project is configured yet. `lib/core/firebase/firebase_options.dart`
is a placeholder — once a project exists, regenerate it from this directory:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

That requires an interactive `firebase login`, so it can't be automated here.
Until then, `FirebaseBootstrapper` will fail to connect and the app runs in
offline-only mode, which is also its normal behavior on a yacht with no
internet — see `backend/README.md` for a known risk around Firebase on Linux.

## Branding

`assets/icon/logo.png` is a **draft** asset — converted and padded from a
non-transparent JPEG. Replace it with the real square (ideally
transparent-background) logo when available, then regenerate app icons:

```
dart run flutter_launcher_icons
```

There's no native splash screen config: `flutter_native_splash` only supports
Android/iOS/Web, and flutter-pi has no OS-level splash surface to hook into
before Dart runs anyway. `lib/shared/widgets/bootstrap_screen.dart` is the
real splash — shown in-app while `bootstrap()` finishes its async setup.

## Testing

```
flutter analyze
flutter test
```

`flutter build linux` (the production target) cannot be compiled on macOS —
it requires a Linux toolchain (CMake, Ninja, GTK dev headers). Validate it on
a Linux host, container, or CI before deploying to a physical device.
