/// Where the sync engine's status lives — see the various implementations
/// under features/sync/data/services/ for which one runs on which
/// platform/availability combination.
enum SyncStatus { idle, checking, syncing, upToDate, error }

/// What the sync engine is doing right now, for the signage screen's
/// small non-blocking indicator (see shared/widgets/sync_activity_badge.dart).
/// Null (see [SyncService.activityStream]) means nothing is happening.
enum SyncActivityKind { downloading, removing }

class SyncActivity {
  const SyncActivity({required this.kind, this.progress});

  final SyncActivityKind kind;

  /// 0.0-1.0, or null if indeterminate (e.g. a removal, which has no
  /// meaningful progress fraction).
  final double? progress;
}

abstract class SyncService {
  /// Whether a sync backend (native SDK or REST fallback) is active. Sync
  /// is impossible without it, but playback must not care either way.
  bool get isAvailable;

  Stream<SyncStatus> get statusStream;

  /// Emits the currently in-progress activity, or null when idle.
  /// Defaults to permanently idle — only implementations that actually
  /// download/remove files in a way worth surfacing to the viewer
  /// override this.
  Stream<SyncActivity?> get activityStream => Stream.value(null);

  /// Triggers an immediate check for playlist/video changes, outside the
  /// implementation's normal cadence (listener push or poll timer).
  Future<void> checkForUpdates();

  /// Releases any resources (timers, subscriptions) held by this
  /// service. Implementations that are meant to live for the whole app
  /// lifetime (the common case) can leave this a no-op in production —
  /// it mainly matters for tests, where a `ProviderContainer` disposal
  /// must not leave e.g. a polling `Timer` pending.
  void dispose() {}
}
