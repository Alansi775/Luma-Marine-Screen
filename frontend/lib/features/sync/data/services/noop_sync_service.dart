import '../../../../core/logging/app_logger.dart';
import '../../domain/services/sync_service.dart';

/// Placeholder [SyncService]: logs and reports idle, never touches the
/// network. Exists so the rest of the app can depend on [SyncService]
/// today; swapping in the real Firestore-backed engine later means
/// changing one provider (see routing/diagnostics wiring), not any
/// caller.
class NoopSyncService extends SyncService {
  NoopSyncService(this._logger, {required this.isAvailable}) {
    _logger.info('Sync engine not yet implemented; running local-only.');
  }

  final AppLogger _logger;

  @override
  final bool isAvailable;

  @override
  Stream<SyncStatus> get statusStream => Stream.value(SyncStatus.idle);

  @override
  Future<void> checkForUpdates() async {
    _logger.debug('checkForUpdates() called on NoopSyncService — no-op.');
  }
}
