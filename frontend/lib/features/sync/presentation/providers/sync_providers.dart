import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/services/noop_sync_service.dart';
import '../../domain/services/sync_service.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) => NoopSyncService(
      ref.watch(appLoggerProvider),
      isAvailable: ref.watch(firebaseAvailableProvider),
    );
