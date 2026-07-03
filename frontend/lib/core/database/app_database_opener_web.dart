import '../logging/app_logger.dart';
import '../platform/app_directories.dart';
import 'app_database.dart';
import 'app_database_connection.dart';

/// Opens the web database. drift's WASM backend already degrades
/// gracefully across storage implementations (OPFS, IndexedDB, in-memory)
/// on its own, so there's no separate fallback layer needed here — this
/// exists mainly to log if even that fails.
Future<AppDatabase> openAppDatabase(AppDirectories directories, AppLogger logger) async {
  final db = AppDatabase(openAppDatabaseConnection(directories));
  try {
    await db.customSelect('select 1').get();
  } catch (e, stackTrace) {
    logger.error('Web database failed to initialize', error: e, stackTrace: stackTrace);
  }
  return db;
}
