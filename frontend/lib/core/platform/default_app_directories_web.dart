import 'app_directories.dart';

/// [AppDirectories] for Flutter Web.
///
/// Web is used only for fast UI preview during development, never for
/// real deployment — a browser tab has no real filesystem to cache
/// videos in, so there's nothing meaningful to persist here. Paths are
/// nominal labels only; drift's web database backend (WASM + IndexedDB,
/// wired up in `core/database/app_database.dart`) does its own storage
/// under the hood and ignores these paths entirely.
class DefaultAppDirectories implements AppDirectories {
  @override
  String get appDataDirectoryPath => 'web';

  @override
  String get videosDirectoryPath => 'web/videos';

  @override
  String get logsDirectoryPath => 'web/logs';

  @override
  String get databaseFilePath => 'web/luma_marine.db';

  @override
  bool get isReady => true;

  @override
  Future<void> ensureCreated() async {}
}
