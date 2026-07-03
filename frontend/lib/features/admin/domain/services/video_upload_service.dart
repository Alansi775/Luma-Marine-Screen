import 'dart:typed_data';

/// Uploads a video picked from the admin's device to the shared catalog
/// and appends it to the default screen's playlist (see
/// backend/schema/firestore-schema.md). The real sync engine
/// (features/sync) then picks up the change and downloads it to any
/// device watching that playlist.
abstract class VideoUploadService {
  /// Throws [NetworkException] (see core/errors/app_exception.dart) if
  /// the upload fails or Firebase is unavailable.
  Future<void> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    void Function(double progress)? onProgress,
  });
}
