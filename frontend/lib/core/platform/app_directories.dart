/// Resolves where the app stores its persistent data.
///
/// Exposes plain path strings rather than `dart:io` `File`/`Directory`
/// types so this interface (and everything that depends on it) stays
/// compilable on every platform this app touches, including Flutter Web
/// for fast UI preview during development — `dart:io` doesn't exist
/// there. Implementations still use `dart:io` internally where real file
/// I/O is possible; see `default_app_directories.dart`, which picks the
/// right implementation per platform via a conditional export.
abstract class AppDirectories {
  /// Root directory for all app data.
  String get appDataDirectoryPath;

  /// Where downloaded playlist videos are cached.
  String get videosDirectoryPath;

  /// Where rotating log files are written.
  String get logsDirectoryPath;

  /// Path to the local sqlite database file.
  String get databaseFilePath;

  /// Creates all required directories if missing.
  ///
  /// Must never throw: on an embedded device, a failure here (e.g. bad
  /// permissions) should be logged, not crash startup. Callers can check
  /// [isReady] afterwards.
  Future<void> ensureCreated();

  /// Whether [ensureCreated] succeeded in creating a writable data directory.
  bool get isReady;
}
