import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/env.dart';
import 'app_directories.dart';

/// Default [AppDirectories] for native platforms (Linux production,
/// macOS development): resolves a fixed, overridable directory tree
/// rather than depending on a platform-channel plugin (see
/// [AppDirectories]'s doc comment for why not `path_provider`).
///
/// Production (Linux/flutter-pi): `/var/lib/luma-marine`, expected to be
/// provisioned (created + chowned) by the device's deployment scripts
/// before the app is launched — that provisioning is an ops concern, not
/// this class's responsibility.
///
/// Local dev (macOS): `~/Library/Application Support/luma-marine`.
///
/// Either can be overridden via the `LUMA_APP_DATA_DIR` environment variable.
class DefaultAppDirectories implements AppDirectories {
  String _rootPath = _resolvePreferredPath();
  bool _isReady = false;

  @override
  String get appDataDirectoryPath => _rootPath;

  @override
  String get videosDirectoryPath => p.join(_rootPath, 'videos');

  @override
  String get logsDirectoryPath => p.join(_rootPath, 'logs');

  @override
  String get databaseFilePath => p.join(_rootPath, 'luma_marine.db');

  @override
  bool get isReady => _isReady;

  @override
  Future<void> ensureCreated() async {
    _isReady = await _tryCreateAll(_rootPath);
    if (_isReady) return;

    // Fall back to a temp directory so the app can still run (with data
    // that won't survive a reboot) rather than crash outright.
    final fallback = p.join(Directory.systemTemp.path, 'luma-marine');
    if (await _tryCreateAll(fallback)) {
      _rootPath = fallback;
      _isReady = true;
    }
  }

  Future<bool> _tryCreateAll(String root) async {
    try {
      for (final dir in [root, p.join(root, 'videos'), p.join(root, 'logs')]) {
        await Directory(dir).create(recursive: true);
      }
      return true;
    } on FileSystemException {
      return false;
    }
  }

  static String _resolvePreferredPath() {
    final override = Env.appDataDirOverride;
    if (override != null) return override;

    if (Platform.isLinux) return '/var/lib/luma-marine';
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '.';
      return p.join(home, 'Library', 'Application Support', 'luma-marine');
    }
    throw UnsupportedError('Luma Marine only targets Linux (production) and macOS (development).');
  }
}
