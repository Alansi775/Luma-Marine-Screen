import '../../../../core/database/app_database.dart';
import '../../domain/entities/playlist_entry.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/playlist_local_datasource.dart';

/// Drift-backed [PlaylistRepository]. Returns an empty playlist until the
/// future sync engine populates the table — this pass wires the pattern,
/// not the sync logic itself.
class LocalPlaylistRepository implements PlaylistRepository {
  LocalPlaylistRepository(AppDatabase db) : _dataSource = PlaylistLocalDataSource(db);

  final PlaylistLocalDataSource _dataSource;

  @override
  Stream<List<PlaylistEntry>> watchActivePlaylist() {
    return _dataSource.watchAll().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<PlaylistEntry>> getActivePlaylist() async {
    final rows = await _dataSource.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> replacePlaylist(List<PlaylistEntry> entries) {
    return _dataSource.replaceAll(entries.map(_toCompanion).toList());
  }

  PlaylistEntry _toEntity(PlaylistEntryRow row) => PlaylistEntry(
        id: row.id,
        videoId: row.videoId,
        sortOrder: row.sortOrder,
      );

  PlaylistEntriesCompanion _toCompanion(PlaylistEntry entry) => PlaylistEntriesCompanion.insert(
        id: entry.id,
        videoId: entry.videoId,
        sortOrder: entry.sortOrder,
      );
}
