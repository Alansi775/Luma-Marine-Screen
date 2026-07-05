import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/database/app_database_opener.dart';
import 'core/di/core_providers.dart';
import 'core/firebase/firebase_bootstrapper.dart';
import 'core/logging/platform_logger.dart';
import 'core/platform/default_app_directories.dart';
import 'core/platform/platform_thread_watchdog.dart';
import 'core/platform/video_player_registration.dart';

/// Ordered async setup, run once before `runApp`. Order matters: the
/// logger's file sink and the database file both need directories
/// resolved first, so the logger starts console-only and is upgraded
/// once directories are ready — see [PlatformLogger.consoleOnly].
///
/// Every step here degrades gracefully instead of throwing: a failure in
/// any one of these must not prevent the app from at least attempting to
/// play back whatever's already cached on disk.
Future<List<Override>> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerVideoPlayerPlatform();

  final logger = PlatformLogger.consoleOnly();
  logger.info('PANO starting');
  startPlatformThreadWatchdog();

  final directories = DefaultAppDirectories();
  await directories.ensureCreated();
  if (!directories.isReady) {
    logger.error('Could not create a writable app data directory');
  }
  await logger.attachFileSink(directories.logsDirectoryPath);

  final database = await openAppDatabase(directories, logger);

  final firebaseAvailable = await FirebaseBootstrapper(logger).init();

  return [
    appLoggerProvider.overrideWithValue(logger),
    appDirectoriesProvider.overrideWithValue(directories),
    appDatabaseProvider.overrideWithValue(database),
    firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
  ];
}
