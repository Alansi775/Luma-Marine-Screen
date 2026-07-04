/// Where the sync engine's status lives — see the various implementations
/// under features/sync/data/services/ for which one runs on which
/// platform/availability combination.
enum SyncStatus { idle, checking, syncing, upToDate, error }

abstract class SyncService {
  /// Whether a sync backend (native SDK or REST fallback) is active. Sync
  /// is impossible without it, but playback must not care either way.
  bool get isAvailable;

  Stream<SyncStatus> get statusStream;

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
