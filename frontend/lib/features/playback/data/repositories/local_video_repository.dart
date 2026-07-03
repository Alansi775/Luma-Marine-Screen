import '../../../../core/database/app_database.dart';
import '../../domain/entities/video_asset.dart';
import '../../domain/repositories/video_repository.dart';

/// Drift-backed [VideoRepository]. Reports only what's already cached
/// locally — populating the catalog and downloading files is the future
/// sync/download engine's job, out of scope for this pass.
class LocalVideoRepository implements VideoRepository {
  LocalVideoRepository(this._db);

  final AppDatabase _db;

  @override
  Future<VideoAsset?> getById(String videoId) async {
    final row = await (_db.select(_db.videos)..where((t) => t.id.equals(videoId)))
        .getSingleOrNull();
    if (row == null) return null;
    return VideoAsset(
      id: row.id,
      storagePath: row.storagePath,
      checksum: row.checksum,
      localFilePath: row.localFilePath,
    );
  }

  @override
  Future<bool> isDownloaded(String videoId) async {
    final asset = await getById(videoId);
    return asset?.isDownloaded ?? false;
  }

  @override
  Future<String?> getLocalFilePath(String videoId) async {
    final asset = await getById(videoId);
    return asset?.localFilePath;
  }
}
