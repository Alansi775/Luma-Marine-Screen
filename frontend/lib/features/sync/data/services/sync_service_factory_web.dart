import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/app_directories.dart';
import '../../domain/services/sync_service.dart';
import 'noop_sync_service.dart';

/// Web never runs the real sync engine — there's no local video cache to
/// speak of in a browser tab (see `default_app_directories_web.dart`).
SyncService createSyncService({
  required AppLogger logger,
  required bool firebaseAvailable,
  required AppDatabase database,
  required AppDirectories directories,
}) {
  return NoopSyncService(logger, isAvailable: firebaseAvailable);
}
