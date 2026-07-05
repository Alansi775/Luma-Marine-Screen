import 'package:meta/meta.dart';

/// A video as it appears inside one playlist — the join of a
/// `playlists/{playlistId}/entries/{entryId}` document with its
/// referenced `videos/{videoId}` document, for admin display.
@immutable
class PlaylistVideoItem {
  const PlaylistVideoItem({
    required this.entryId,
    required this.videoId,
    required this.sortOrder,
    required this.name,
    this.durationSeconds,
    this.storagePath,
  });

  final String entryId;
  final String videoId;
  final int sortOrder;
  final String name;

  /// Not populated yet — see backend/schema/firestore-schema.md's "known gaps".
  final int? durationSeconds;

  /// Firebase Storage path (e.g. `videos/{id}.mp4`) — resolved to an
  /// actual download URL on demand by whoever needs to play or preview
  /// it (see `_VideoThumbnail` in playlist_detail_screen.dart). Null
  /// only if the underlying video doc was deleted out from under this
  /// entry.
  final String? storagePath;
}
