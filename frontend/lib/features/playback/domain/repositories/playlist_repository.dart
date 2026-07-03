import '../entities/playlist_entry.dart';

/// Source of truth for the device's active playlist. Always backed by
/// local storage — the future sync engine writes to this via
/// [replacePlaylist] when Firestore reports a change; playback never
/// talks to Firestore directly.
abstract class PlaylistRepository {
  /// Emits the active playlist, in [PlaylistEntry.sortOrder] order,
  /// whenever it changes.
  Stream<List<PlaylistEntry>> watchActivePlaylist();

  Future<List<PlaylistEntry>> getActivePlaylist();

  /// Atomically replaces the playlist. This is the future sync engine's
  /// write path — not called by anything in this pass.
  Future<void> replacePlaylist(List<PlaylistEntry> entries);
}
