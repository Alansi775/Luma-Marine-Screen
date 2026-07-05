import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/app_directories.dart';
import '../../../playback/data/datasources/playlist_local_datasource.dart';
import '../../domain/services/sync_service.dart';

/// Real sync engine, native platforms only (see `sync_service_factory.dart`
/// — web keeps using [NoopSyncService], since there's no local video cache
/// to speak of in a browser tab).
///
/// Two-level reactive pipeline: watches the default device's
/// `activePlaylistId` (see backend/schema/firestore-schema.md), and
/// re-subscribes to that playlist's `entries` subcollection whenever it
/// changes. On every entries change, downloads any videos not already
/// cached locally (skipping ones whose checksum matches what's already
/// on disk — "never redownload unchanged files"), then replaces the
/// local playlist table. Local video files no longer referenced are
/// pruned to bound disk usage.
class FirestoreSyncService extends SyncService {
  FirestoreSyncService({
    required AppDatabase database,
    required AppDirectories directories,
    required AppLogger logger,
  })  : _dataSource = PlaylistLocalDataSource(database),
        _db = database,
        _directories = directories,
        _logger = logger {
    _start();
  }

  final AppDatabase _db;
  final AppDirectories _directories;
  final AppLogger _logger;
  final PlaylistLocalDataSource _dataSource;
  final _dio = Dio();
  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _entriesSubscription;
  String? _activePlaylistId;
  bool _isSyncing = false;

  @override
  bool get isAvailable => true;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void _start() {
    _statusController.add(SyncStatus.checking);
    // Kept alive for the app's lifetime; there's nothing to cancel this for.
    FirebaseFirestore.instance
        .collection('devices')
        .doc(FirestorePaths.defaultDeviceId)
        .snapshots()
        .listen(_onDeviceSnapshot, onError: (Object e, StackTrace st) {
      _logger.warning('Device listener failed, will retry on next change', error: e, stackTrace: st);
      _statusController.add(SyncStatus.error);
    });
  }

  void _onDeviceSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final activePlaylistId = snapshot.data()?['activePlaylistId'] as String?;
    if (activePlaylistId == _activePlaylistId) return;

    _activePlaylistId = activePlaylistId;
    _entriesSubscription?.cancel();

    if (activePlaylistId == null) {
      _logger.info('No active playlist set; clearing local playlist');
      unawaited(_replaceLocalPlaylist(const [], const {}));
      return;
    }

    _logger.info('Active playlist changed to $activePlaylistId');
    _entriesSubscription = FirebaseFirestore.instance
        .collection('playlists')
        .doc(activePlaylistId)
        .collection('entries')
        .orderBy('sortOrder')
        .snapshots()
        .listen(_onPlaylistSnapshot, onError: (Object e, StackTrace st) {
      _logger.warning('Playlist listener failed, will retry on next change', error: e, stackTrace: st);
      _statusController.add(SyncStatus.error);
    });
  }

  Future<void> _onPlaylistSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    // See rest_firestore_sync_service.dart's identical guard: a single
    // pass (downloading a large video) can take far longer than it
    // takes for another snapshot to arrive (e.g. on reconnect), so this
    // stops two passes from downloading the same file concurrently.
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);
    try {
      final entries = <PlaylistEntriesCompanion>[];
      final activeVideoIds = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final videoId = data['videoId'] as String;
        final sortOrder = data['sortOrder'] as int;

        await _ensureVideoDownloaded(videoId);
        activeVideoIds.add(videoId);
        entries.add(PlaylistEntriesCompanion.insert(id: doc.id, videoId: videoId, sortOrder: sortOrder));
      }

      await _replaceLocalPlaylist(entries, activeVideoIds);
      _statusController.add(SyncStatus.upToDate);
    } catch (e, st) {
      _logger.error('Sync pass failed', error: e, stackTrace: st);
      _statusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _replaceLocalPlaylist(
    List<PlaylistEntriesCompanion> entries,
    Set<String> activeVideoIds,
  ) async {
    await _dataSource.replaceAll(entries);
    await _pruneOrphanedVideos(activeVideoIds);
  }

  Future<void> _ensureVideoDownloaded(String videoId) async {
    final videoDoc = await FirebaseFirestore.instance.collection(FirestorePaths.videos).doc(videoId).get();
    if (!videoDoc.exists) {
      _logger.warning('Playlist references missing video catalog entry: $videoId');
      return;
    }
    final data = videoDoc.data()!;
    final storagePath = data['storagePath'] as String;
    final checksum = data['checksum'] as String?;
    final sizeBytes = data['sizeBytes'] as int?;
    // `playbackPath` is written by the processUploadedVideo Cloud Function
    // only when the original exceeds this device's decode envelope (see
    // backend/functions/index.js) — a separate, resized copy for this
    // device to actually play. The original at `storagePath` is never
    // modified, so it's still what admin/catalog code deals in.
    final playbackPath = data['playbackPath'] as String?;
    final downloadPath = playbackPath ?? storagePath;

    final existing =
        await (_db.select(_db.videos)..where((t) => t.id.equals(videoId))).getSingleOrNull();

    final upToDate = existing != null &&
        existing.checksum == checksum &&
        existing.localFilePath != null &&
        await File(existing.localFilePath!).exists();
    if (upToDate) return;

    final extension = downloadPath.contains('.') ? downloadPath.split('.').last : 'mp4';
    final localPath = p.join(_directories.videosDirectoryPath, '$videoId.$extension');

    _logger.info('Downloading video $videoId');
    final url = await FirebaseStorage.instance.ref(downloadPath).getDownloadURL();
    final tempPath = '$localPath.part';
    await _dio.download(url, tempPath);
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

  @override
  Future<void> checkForUpdates() async {
    // The realtime Firestore listener already covers this; kept to
    // satisfy the interface for a future manual "sync now" action.
  }
}
