import 'package:meta/meta.dart';

/// A single slot in the device's active playlist, referencing a video in
/// the shared catalog by id. Mirrors a document under
/// `devices/{deviceId}/playlist/{entryId}` — see
/// backend/schema/firestore-schema.md.
@immutable
class PlaylistEntry {
  const PlaylistEntry({
    required this.id,
    required this.videoId,
    required this.sortOrder,
  });

  final String id;
  final String videoId;
  final int sortOrder;
}
