import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/app_directories.dart';
import '../../domain/services/sync_service.dart';
import 'firestore_sync_service.dart';
import 'rest_firestore_sync_service.dart';

SyncService createSyncService({
  required AppLogger logger,
  required bool firebaseAvailable,
  required AppDatabase database,
  required AppDirectories directories,
}) {
  if (firebaseAvailable) {
    return FirestoreSyncService(database: database, directories: directories, logger: logger);
  }
  // Native Firebase SDK unavailable — always true on Linux (see
  // backend/README.md), occasionally true elsewhere on transient init
  // failure. Falls back to a REST-polling engine that doesn't need the
  // native SDK at all, rather than giving up on syncing entirely.
  return RestFirestoreSyncService(database: database, directories: directories, logger: logger);
}
