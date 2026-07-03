import 'dart:io';

import 'package:meta/meta.dart';

/// A video from the shared catalog (mirrors `videos/{videoId}` in
/// Firestore), plus whatever is known about its local cache state.
/// [localFile] is null until the (future) download manager has fetched
/// it — playback only ever reads from [localFile], never [storagePath]
/// directly.
@immutable
class VideoAsset {
  const VideoAsset({
    required this.id,
    required this.storagePath,
    this.checksum,
    this.localFile,
  });

  final String id;
  final String storagePath;
  final String? checksum;
  final File? localFile;

  bool get isDownloaded => localFile != null;
}
