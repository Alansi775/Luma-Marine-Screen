import 'package:meta/meta.dart';

/// An admin-managed, named playlist (mirrors `playlists/{playlistId}` —
/// see backend/schema/firestore-schema.md). Distinct from the local,
/// playback-side `PlaylistEntry` (features/playback), which only ever
/// reflects whichever one of these is currently active.
@immutable
class AdminPlaylist {
  const AdminPlaylist({required this.id, required this.name, this.scheduledStart});

  final String id;
  final String name;

  /// `"HH:mm"`, optional. Not yet consumed by the sync engine — see
  /// backend/schema/firestore-schema.md's "known gaps".
  final String? scheduledStart;
}
