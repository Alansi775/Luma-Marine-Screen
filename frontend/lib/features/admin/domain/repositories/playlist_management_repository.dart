import '../entities/admin_playlist.dart';
import '../entities/playlist_video_item.dart';

/// Everything the admin panel needs to manage playlists and their videos.
/// All of these write directly to Firestore — the sync engine
/// (features/sync) is what turns "active playlist changed" or "active
/// playlist's entries changed" into an actual local download + playback
/// update on the device.
abstract class PlaylistManagementRepository {
  Stream<List<AdminPlaylist>> watchPlaylists();

  /// Returns the new playlist's id.
  Future<String> createPlaylist(String name);

  Future<void> renamePlaylist(String playlistId, String name);

  Future<void> setPlaylistSchedule(String playlistId, String? scheduledStart);

  /// Also deletes the playlist's entries, and clears
  /// `devices/{deviceId}.activePlaylistId` if this was the active one —
  /// Firestore doesn't cascade-delete subcollections on its own.
  Future<void> deletePlaylist(String playlistId);

  Stream<List<PlaylistVideoItem>> watchPlaylistEntries(String playlistId);

  Future<void> removeVideoFromPlaylist({required String playlistId, required String entryId});

  Future<void> moveVideoToPlaylist({
    required String fromPlaylistId,
    required String entryId,
    required String videoId,
    required String toPlaylistId,
  });

  Future<void> reorderEntries(String playlistId, List<String> orderedEntryIds);

  Future<void> renameVideo(String videoId, String name);

  Stream<String?> watchActivePlaylistId();

  Future<void> setActivePlaylist(String? playlistId);
}
