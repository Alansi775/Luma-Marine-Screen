/// Where the future sync engine's status lives. Not implemented this
/// pass — see [NoopSyncService] — but declaring the interface now means
/// the diagnostics screen and playback feature can depend on it without
/// waiting for the real implementation.
enum SyncStatus { idle, checking, syncing, upToDate, error }

abstract class SyncService {
  /// Whether Firebase was reachable at startup. Sync is impossible
  /// without it, but playback must not care either way.
  bool get isAvailable;

  Stream<SyncStatus> get statusStream;

  /// Triggers a check for playlist/video changes. No-op until the real
  /// sync engine (Firestore listeners + download manager) exists.
  Future<void> checkForUpdates();
}
