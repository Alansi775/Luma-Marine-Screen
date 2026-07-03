import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../platform/app_directories.dart';

/// Builds the platform-appropriate [QueryExecutor] for [AppDatabase].
///
/// `drift_flutter`'s `driftDatabase` picks the right backend internally
/// (native sqlite3 vs a WASM+IndexedDB backend on web) via its own
/// conditional exports, so this function is safe to call from code that
/// must compile on every platform this app targets — no platform split
/// needed here.
///
/// The web backend requires `sqlite3.wasm` and `drift_worker.dart.js` in
/// `web/` (see frontend/README.md) and is only used for fast UI preview
/// during development — it is not a deployment target.
QueryExecutor openAppDatabaseConnection(AppDirectories directories) {
  return driftDatabase(
    name: 'luma_marine',
    native: DriftNativeOptions(
      databasePath: () async => directories.databaseFilePath,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
