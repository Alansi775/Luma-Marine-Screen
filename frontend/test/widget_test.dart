import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_marine/app.dart';
import 'package:luma_marine/core/database/app_database.dart';
import 'package:luma_marine/core/di/core_providers.dart';
import 'package:luma_marine/core/logging/app_logger.dart';
import 'package:luma_marine/core/platform/app_directories.dart';

class _FakeLogger implements AppLogger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void info(String message) {}
  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  Future<void> attachFileSink(Directory logDirectory) async {}
}

class _FakeDirectories implements AppDirectories {
  final _root = Directory.systemTemp;
  @override
  Directory get appDataDirectory => _root;
  @override
  Directory get videosDirectory => _root;
  @override
  Directory get logsDirectory => _root;
  @override
  File get databaseFile => File('${_root.path}/luma_marine_test.db');
  @override
  bool get isReady => true;
  @override
  Future<void> ensureCreated() async {}
}

void main() {
  testWidgets('App boots to the now-playing route without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLoggerProvider.overrideWithValue(_FakeLogger()),
          appDirectoriesProvider.overrideWithValue(_FakeDirectories()),
          appDatabaseProvider.overrideWithValue(AppDatabase.inMemory()),
          firebaseAvailableProvider.overrideWithValue(false),
        ],
        child: const LumaMarineApp(),
      ),
    );

    await tester.pump();

    expect(find.text('No videos synced yet.\nWaiting for the playlist to sync.'), findsOneWidget);

    // Tear the tree down within the test body (rather than relying on
    // testWidgets' implicit teardown) so the drift stream's dispose-time
    // zero-duration timer and ThemeSchedule's periodic timer both fire
    // before the test framework asserts no timers are left pending.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
