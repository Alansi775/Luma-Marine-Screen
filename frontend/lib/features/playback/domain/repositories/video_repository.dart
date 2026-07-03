import '../entities/video_asset.dart';

/// Read access to the local video catalog cache. Never touches the
/// network — the future download manager is what populates
/// [VideoAsset.localFilePath]; this repository only reports what's
/// already on disk.
abstract class VideoRepository {
  Future<VideoAsset?> getById(String videoId);

  Future<bool> isDownloaded(String videoId);

  Future<String?> getLocalFilePath(String videoId);
}
