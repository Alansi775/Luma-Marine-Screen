# Luma Marine

Digital signage system for marine (yacht) display screens. The device boots directly into
a Flutter application (via [flutter-pi](https://github.com/ardera/flutter-pi) on headless
Ubuntu Server, no desktop environment) and loops a locally-cached video playlist. Firebase
(Firestore + Storage) is used only to synchronize playlist/video changes in the background —
playback always reads from local disk and must survive extended offline periods.

## Repository layout

```
Luma Marine/
├── frontend/   Flutter application (all Dart code, assets, platform projects)
└── backend/    Firebase configuration, security rules, schema docs (no application code)
```

Everything Flutter-related belongs in `frontend/`. Everything Firebase/infrastructure-related
belongs in `backend/`. Do not mix the two.

## Development workflow

- **Day-to-day development** happens on macOS: `cd frontend && flutter run -d macos`.
- **Production target** is Linux x86_64 via `flutter build linux`, deployed to the device and
  launched by `flutter-pi`. This build **cannot be compiled on macOS** — it requires a Linux
  toolchain (CMake, Ninja, GTK dev headers), available only on a Linux host, container, or CI.
  Validate Linux builds there before deploying to a physical device.

See [`frontend/README.md`](frontend/README.md) and [`backend/README.md`](backend/README.md)
for details specific to each half of the project.
