// PLACEHOLDER FIREBASE CONFIGURATION — DO NOT SHIP THESE VALUES.
//
// Once a real Firebase project exists, regenerate this file by running,
// from `frontend/`:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command requires an interactive `firebase login` and project
// selection, so it can't be run non-interactively — a human has to do it.
//
// Until then, `FirebaseBootstrapper` will attempt to initialize with these
// dummy values, fail, and the app will continue running in offline-only
// mode (see core/firebase/firebase_bootstrapper.dart).

import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (Platform.isMacOS) return macos;
    // Speculative: FlutterFire has no official Linux desktop platform
    // implementation as of this writing (see backend/README.md). Firebase
    // calls on Linux will likely throw at runtime rather than fail the
    // build — FirebaseBootstrapper handles that gracefully.
    if (Platform.isLinux) return linux;
    throw UnsupportedError(
      'DefaultFirebaseOptions has not been configured for this platform.',
    );
  }

  static const macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.lumamarine.signage',
  );

  static const linux = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
  );
}
