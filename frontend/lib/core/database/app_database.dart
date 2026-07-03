import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables/playlist_entries_table.dart';
import 'tables/videos_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [PlaylistEntries, Videos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens (creating if necessary) the on-disk database at [file].
  factory AppDatabase.file(File file) =>
      AppDatabase(NativeDatabase.createInBackground(file));

  /// In-memory database used as a last-resort fallback when the on-disk
  /// database can't be opened (e.g. permissions) — playback should still
  /// run, even if sync state won't survive a reboot in that scenario.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
