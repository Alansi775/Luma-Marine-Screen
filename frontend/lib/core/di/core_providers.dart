import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../logging/app_logger.dart';
import '../platform/app_directories.dart';

part 'core_providers.g.dart';

/// Infrastructure singletons resolved once in `bootstrap()` before
/// `runApp`, then injected via `ProviderScope(overrides: [...])` with
/// `overrideWithValue`. Declaring them here (rather than as plain global
/// variables) keeps every consumer going through Riverpod, so tests can
/// override them too. The bodies below should never run in practice —
/// if one does, `bootstrap()` failed to provide an override.

@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) =>
    throw UnimplementedError('appLoggerProvider must be overridden in bootstrap()');

@Riverpod(keepAlive: true)
AppDirectories appDirectories(Ref ref) =>
    throw UnimplementedError('appDirectoriesProvider must be overridden in bootstrap()');

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) =>
    throw UnimplementedError('appDatabaseProvider must be overridden in bootstrap()');

@Riverpod(keepAlive: true)
bool firebaseAvailable(Ref ref) =>
    throw UnimplementedError('firebaseAvailableProvider must be overridden in bootstrap()');
