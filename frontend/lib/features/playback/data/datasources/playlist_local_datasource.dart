import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// Thin wrapper around the drift `PlaylistEntries` table. Kept separate
/// from `LocalPlaylistRepository` so the repository deals only in domain
/// entities, never in generated drift row types.
class PlaylistLocalDataSource {
  PlaylistLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<PlaylistEntryRow>> watchAll() {
    return (_db.select(_db.playlistEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<List<PlaylistEntryRow>> getAll() {
    return (_db.select(_db.playlistEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<void> replaceAll(List<PlaylistEntriesCompanion> entries) {
    return _db.transaction(() async {
      await _db.delete(_db.playlistEntries).go();
      await _db.batch((batch) => batch.insertAll(_db.playlistEntries, entries));
    });
  }
}
