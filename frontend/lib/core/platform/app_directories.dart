import 'dart:io';

/// Resolves where the app stores its persistent data.
///
/// Deliberately not backed by `path_provider`: its Linux implementation
/// depends on platform-channel plugin registration, which is a risk area
/// under flutter-pi's minimal plugin support. Implementations resolve
/// paths directly instead, so this is the one seam to change if the
/// resolution strategy ever needs to differ (e.g. a config file instead
/// of an environment variable).
abstract class AppDirectories {
  /// Root directory for all app data.
  Directory get appDataDirectory;

  /// Where downloaded playlist videos are cached.
  Directory get videosDirectory;

  /// Where rotating log files are written.
  Directory get logsDirectory;

  /// Path to the local sqlite database file.
  File get databaseFile;

  /// Creates all required directories if missing.
  ///
  /// Must never throw: on an embedded device, a failure here (e.g. bad
  /// permissions) should be logged, not crash startup. Callers can check
  /// [isReady] afterwards.
  Future<void> ensureCreated();

  /// Whether [ensureCreated] succeeded in creating a writable data directory.
  bool get isReady;
}
