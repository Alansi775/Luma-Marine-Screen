import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/firebase/firebase_options.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/app_directories.dart';
import '../../../playback/data/datasources/playlist_local_datasource.dart';
import '../../domain/services/sync_service.dart';

/// Fallback sync engine for when the native Firebase SDK isn't available
/// — always true on Linux (FlutterFire has no official Linux
/// implementation, see backend/README.md), occasionally true elsewhere
/// on transient init failure. Talks to Firestore and Storage over their
/// plain HTTPS REST APIs instead, which need nothing beyond a project id
/// and API key — no native plugin required.
///
/// This device only ever *reads* playlist/video data and *downloads*
/// files (never signs in — the admin uploads from their own machine), and
/// our security rules allow public read on exactly those paths, so no
/// auth token is needed here at all.
///
/// Trades realtime push for periodic polling, a fine trade for a
/// signage playlist (near-real-time is enough) and far simpler than
/// implementing Firestore's gRPC-based Listen RPC over plain REST.
class RestFirestoreSyncService implements SyncService {
  RestFirestoreSyncService({
    required AppDatabase database,
    required AppDirectories directories,
    required AppLogger logger,
  })  : _dataSource = PlaylistLocalDataSource(database),
        _db = database,
        _directories = directories,
        _logger = logger {
    _start();
  }

  static const _pollInterval = Duration(seconds: 15);

  final AppDatabase _db;
  final AppDirectories _directories;
  final AppLogger _logger;
  final PlaylistLocalDataSource _dataSource;
  final _dio = Dio();
  final _statusController = StreamController<SyncStatus>.broadcast();
  Timer? _pollTimer;

  String get _projectId => DefaultFirebaseOptions.currentPlatform.projectId;
  String get _apiKey => DefaultFirebaseOptions.currentPlatform.apiKey;
  String get _bucket => DefaultFirebaseOptions.currentPlatform.storageBucket!;
  String get _firestoreBase =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  @override
  bool get isAvailable => true;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  void dispose() {
    _pollTimer?.cancel();
  }

  void _start() {
    unawaited(_poll());
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    _statusController.add(SyncStatus.checking);
    try {
      final activePlaylistId = await _fetchActivePlaylistId();
      if (activePlaylistId == null) {
        await _dataSource.replaceAll(const []);
        _statusController.add(SyncStatus.upToDate);
        return;
      }

      _statusController.add(SyncStatus.syncing);
      final rawEntries = await _fetchEntries(activePlaylistId);
      rawEntries.sort((a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int));

      final entries = <PlaylistEntriesCompanion>[];
      final activeVideoIds = <String>{};
      for (final entry in rawEntries) {
        final videoId = entry['videoId'] as String;
        await _ensureVideoDownloaded(videoId);
        activeVideoIds.add(videoId);
        entries.add(PlaylistEntriesCompanion.insert(
          id: entry['id'] as String,
          videoId: videoId,
          sortOrder: entry['sortOrder'] as int,
        ));
      }

      await _dataSource.replaceAll(entries);
      await _pruneOrphanedVideos(activeVideoIds);
      _statusController.add(SyncStatus.upToDate);
    } catch (e, st) {
      // Covers both "genuinely offline" and "Firestore/Storage down" —
      // either way, leave local data untouched and retry next tick, so
      // whatever's already cached keeps playing uninterrupted.
      _logger.warning('Poll failed, will retry', error: e, stackTrace: st);
      _statusController.add(SyncStatus.error);
    }
  }

  Future<String?> _fetchActivePlaylistId() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_firestoreBase/devices/${FirestorePaths.defaultDeviceId}',
      queryParameters: {'key': _apiKey},
    );
    final fields = response.data?['fields'] as Map<String, dynamic>?;
    return _stringField(fields, 'activePlaylistId');
  }

  Future<List<Map<String, dynamic>>> _fetchEntries(String playlistId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_firestoreBase/playlists/$playlistId/entries',
      queryParameters: {'key': _apiKey},
    );
    final documents = response.data?['documents'] as List<dynamic>? ?? [];
    return documents.map((doc) {
      final map = doc as Map<String, dynamic>;
      final fields = map['fields'] as Map<String, dynamic>;
      final name = map['name'] as String;
      return {
        'id': name.split('/').last,
        'videoId': _stringField(fields, 'videoId'),
        'sortOrder': _intField(fields, 'sortOrder') ?? 0,
      };
    }).toList();
  }

  Future<void> _ensureVideoDownloaded(String videoId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_firestoreBase/videos/$videoId',
      queryParameters: {'key': _apiKey},
    );
    final fields = response.data?['fields'] as Map<String, dynamic>?;
    final storagePath = _stringField(fields, 'storagePath');
    if (storagePath == null) {
      _logger.warning('Playlist references missing video catalog entry: $videoId');
      return;
    }
    final checksum = _stringField(fields, 'checksum');
    final sizeBytes = _intField(fields, 'sizeBytes');

    final existing =
        await (_db.select(_db.videos)..where((t) => t.id.equals(videoId))).getSingleOrNull();

    final upToDate = existing != null &&
        existing.checksum == checksum &&
        existing.localFilePath != null &&
        await File(existing.localFilePath!).exists();
    if (upToDate) return;

    final extension = storagePath.contains('.') ? storagePath.split('.').last : 'mp4';
    final localPath = p.join(_directories.videosDirectoryPath, '$videoId.$extension');
    final encodedPath = Uri.encodeComponent(storagePath);
    final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/$encodedPath?alt=media';

    _logger.info('Downloading video $videoId');
    final tempPath = '$localPath.part';
    await _dio.download(downloadUrl, tempPath);
    await File(tempPath).rename(localPath);

    await _db.into(_db.videos).insertOnConflictUpdate(VideosCompanion.insert(
          id: videoId,
          storagePath: storagePath,
          checksum: Value(checksum),
          sizeBytes: Value(sizeBytes),
          localFilePath: Value(localPath),
          downloadedAt: Value(DateTime.now()),
        ));
  }

  Future<void> _pruneOrphanedVideos(Set<String> activeVideoIds) async {
    final cachedVideos = await _db.select(_db.videos).get();
    for (final video in cachedVideos) {
      if (activeVideoIds.contains(video.id)) continue;
      if (video.localFilePath != null) {
        final file = File(video.localFilePath!);
        if (await file.exists()) {
          try {
            await file.delete();
          } on FileSystemException catch (e) {
            _logger.warning('Failed to delete orphaned video file', error: e);
          }
        }
      }
      await (_db.delete(_db.videos)..where((t) => t.id.equals(video.id))).go();
    }
  }

  String? _stringField(Map<String, dynamic>? fields, String key) =>
      (fields?[key] as Map?)?['stringValue'] as String?;

  int? _intField(Map<String, dynamic>? fields, String key) {
    final raw = (fields?[key] as Map?)?['integerValue'];
    return raw == null ? null : int.tryParse(raw.toString());
  }

  @override
  Future<void> checkForUpdates() => _poll();
}
