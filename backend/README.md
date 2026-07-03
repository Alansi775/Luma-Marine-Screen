# Luma Marine — Backend

Firebase configuration, security rules, and schema documentation only —
**no application code lives here**. All Dart/Flutter code is in `../frontend`.

## Contents

- `firebase.json` / `.firebaserc` — point the Firebase CLI at this project's
  rules files. `.firebaserc` has a placeholder project id; replace it once a
  real Firebase project exists.
- `firestore.rules`, `storage.rules` — default-deny. There's no device
  authentication mechanism yet, so open rules would let any device read or
  write any other device's data. Each file has a commented sketch of the
  intended future shape.
- `schema/firestore-schema.md` — the intended Firestore collection layout.

## Setting up a real Firebase project

1. Create the project in the Firebase console.
2. Update `.firebaserc` with the real project id.
3. From `../frontend`, run `flutterfire configure` (requires an interactive
   `firebase login`) to regenerate `firebase_options.dart` with real values.
4. Deploy rules: `firebase deploy --only firestore:rules,storage:rules` from
   this directory.

## Known risk: FlutterFire has no official Linux desktop support

`firebase_core`, `cloud_firestore`, and `firebase_storage` are federated
plugins with no official Linux platform implementation as of this writing.
The production target for Luma Marine is `flutter build linux` running under
flutter-pi — macOS (used for day-to-day development) is officially
supported, so this gap is easy to miss until deployment.

Expected failure mode: Firebase calls throw at runtime on Linux (e.g.
`MissingPluginException`) rather than failing the build. The frontend
already handles this gracefully — `FirebaseBootstrapper`
(`frontend/lib/core/firebase/firebase_bootstrapper.dart`) treats Firebase as
best-effort and the app runs fully offline without it.

This is fine for the current pass (no sync engine exists yet), but it's a
real constraint on the future sync engine: if Linux support is confirmed
broken, the fix is a REST-based Firestore/Storage client (both have plain
HTTPS APIs) behind the same `SyncService`/`PlaylistRepository` interfaces —
no other layer needs to change. Verify this on an actual Linux build before
building the real sync engine on top of the official SDKs.
