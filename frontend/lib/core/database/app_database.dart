import 'package:drift/drift.dart';

import 'tables/playlist_entries_table.dart';
import 'tables/videos_table.dart';

part 'app_database.g.dart';

/// Schema only — deliberately has no platform-specific imports (no
/// `dart:io`, no `drift/native.dart`) so this file compiles everywhere,
/// including Flutter Web. Platform-specific executor construction lives
/// in `app_database_connection.dart` (native vs web, via `drift_flutter`,
/// which handles that split internally) and in test files that only ever
/// run natively.
@DriftDatabase(tables: [PlaylistEntries, Videos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
