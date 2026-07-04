import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/services/sync_service_factory.dart';
import '../../domain/services/sync_service.dart';

part 'sync_providers.g.dart';

/// `keepAlive` matters here beyond the usual reason: constructing this
/// provider is what starts the real sync engine's Firestore listener (see
/// `FirestoreSyncService`) — it must be watched from somewhere at app
/// startup (see `app.dart`), not just lazily from the diagnostics screen.
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final service = createSyncService(
    logger: ref.watch(appLoggerProvider),
    firebaseAvailable: ref.watch(firebaseAvailableProvider),
    database: ref.watch(appDatabaseProvider),
    directories: ref.watch(appDirectoriesProvider),
  );
  ref.onDispose(service.dispose);
  return service;
}
