import 'package:drift/native.dart';

import '../logging/app_logger.dart';
import '../platform/app_directories.dart';
import 'app_database.dart';
import 'app_database_connection.dart';

/// Opens the on-disk database, falling back to an in-memory one if that
/// fails (e.g. permissions) — playback must keep working even if sync
/// state won't survive a reboot in that scenario.
Future<AppDatabase> openAppDatabase(AppDirectories directories, AppLogger logger) async {
  try {
    final db = AppDatabase(openAppDatabaseConnection(directories));
    // Force a trivial query so an unreadable/corrupt file fails fast,
    // here, rather than on the first screen that happens to query it.
    await db.customSelect('select 1').get();
    return db;
  } catch (e, stackTrace) {
    logger.error(
      'Failed to open on-disk database, falling back to in-memory (sync state will not survive a reboot)',
      error: e,
      stackTrace: stackTrace,
    );
    return AppDatabase(NativeDatabase.memory());
  }
}
