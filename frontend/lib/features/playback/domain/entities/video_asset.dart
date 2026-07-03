import 'package:meta/meta.dart';

/// A video from the shared catalog (mirrors `videos/{videoId}` in
/// Firestore), plus whatever is known about its local cache state.
/// [localFilePath] is null until the (future) download manager has
/// fetched it — playback only ever reads from [localFilePath], never
/// [storagePath] directly.
///
/// Deliberately a plain path string rather than a `dart:io` `File`:
/// domain entities shouldn't depend on platform/framework types, and
/// this keeps the whole playback feature compilable on Flutter Web too
/// (used for UI preview during development).
@immutable
class VideoAsset {
  const VideoAsset({
    required this.id,
    required this.storagePath,
    this.checksum,
    this.localFilePath,
  });

  final String id;
  final String storagePath;
  final String? checksum;
  final String? localFilePath;

  bool get isDownloaded => localFilePath != null;
}
