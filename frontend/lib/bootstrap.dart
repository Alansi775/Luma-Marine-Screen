import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/database/app_database.dart';
import 'core/di/core_providers.dart';
import 'core/firebase/firebase_bootstrapper.dart';
import 'core/logging/file_logger.dart';
import 'core/platform/default_app_directories.dart';

/// Ordered async setup, run once before `runApp`. Order matters: the
/// logger's file sink and the database file both need directories
/// resolved first, so the logger starts console-only and is upgraded
/// once directories are ready — see [FileLogger.consoleOnly].
///
/// Every step here degrades gracefully instead of throwing: a failure in
/// any one of these must not prevent the app from at least attempting to
/// play back whatever's already cached on disk.
Future<List<Override>> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = FileLogger.consoleOnly();
  logger.info('Luma Marine starting');

  final directories = DefaultAppDirectories();
  await directories.ensureCreated();
  if (!directories.isReady) {
    logger.error('Could not create a writable app data directory');
  }
  await logger.attachFileSink(directories.logsDirectory);

  final database = await _openDatabaseSafely(directories, logger);

  final firebaseAvailable = await FirebaseBootstrapper(logger).init();

  return [
    appLoggerProvider.overrideWithValue(logger),
    appDirectoriesProvider.overrideWithValue(directories),
    appDatabaseProvider.overrideWithValue(database),
    firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
  ];
}

Future<AppDatabase> _openDatabaseSafely(
  DefaultAppDirectories directories,
  FileLogger logger,
) async {
  try {
    final db = AppDatabase.file(directories.databaseFile);
    // Force a trivial query so an unreadable/corrupt file fails fast,
    // here, rather than on the first screen that happens to query it.
    await db.customSelect('select 1').get();
    return db;
  } catch (e, stackTrace) {
    logger.error(
      'Failed to open on-disk database, falling back to in-memory (sync state will not survive a reboot)',
      error: e,
      stackTrace: stackTrace,
    );
    return AppDatabase.inMemory();
  }
}
