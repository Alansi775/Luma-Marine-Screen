import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/app_directories.dart';
import '../../domain/services/sync_service.dart';
import 'noop_sync_service.dart';
import 'web_sync_service.dart';

/// Web runs a real sync engine too (see [WebSyncService]) — it just
/// resolves streamable Storage URLs instead of caching files locally,
/// since there's no local disk to speak of in a browser tab.
SyncService createSyncService({
  required AppLogger logger,
  required bool firebaseAvailable,
  required AppDatabase database,
  required AppDirectories directories,
}) {
  if (!firebaseAvailable) return NoopSyncService(logger, isAvailable: false);
  return WebSyncService(database: database, logger: logger);
}
