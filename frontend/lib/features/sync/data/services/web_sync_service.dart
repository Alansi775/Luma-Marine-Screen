import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../playback/data/datasources/playlist_local_datasource.dart';
import '../../domain/services/sync_service.dart';

/// Web's sync engine. Same reactive shape as [FirestoreSyncService], but
/// there's no local disk to cache videos on in a browser tab — instead of
/// downloading, it resolves each video's Firebase Storage download URL
/// directly and stores *that* in the local (IndexedDB-backed, WASM
/// sqlite) `localFilePath` column. Nothing downstream needs to know the
/// difference: `media_kit`'s `Media()` plays a network URL exactly like a
/// local file path, and `resolvedPlaylistFilePathsProvider` just treats
/// it as "the string to hand the player."
///
/// This means web reflects live playback for real (not just admin CRUD)
/// without needing a Linux/macOS build — useful since this app's actual
/// video-caching guarantees (offline playback, never re-downloading
/// unchanged files) are meaningless in a browser tab anyway.
class WebSyncService implements SyncService {
  WebSyncService({required AppDatabase database, required AppLogger logger})
      : _dataSource = PlaylistLocalDataSource(database),
        _db = database,
        _logger = logger {
    _start();
  }

  final AppDatabase _db;
  final AppLogger _logger;
  final PlaylistLocalDataSource _dataSource;
  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _entriesSubscription;
  String? _activePlaylistId;

  @override
  bool get isAvailable => true;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void _start() {
    _statusController.add(SyncStatus.checking);
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
      unawaited(_dataSource.replaceAll(const []));
      return;
    }

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
    _statusController.add(SyncStatus.syncing);
    try {
      final entries = <PlaylistEntriesCompanion>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final videoId = data['videoId'] as String;
        final sortOrder = data['sortOrder'] as int;

        await _ensureVideoUrlResolved(videoId);
        entries.add(PlaylistEntriesCompanion.insert(id: doc.id, videoId: videoId, sortOrder: sortOrder));
      }

      await _dataSource.replaceAll(entries);
      _statusController.add(SyncStatus.upToDate);
    } catch (e, st) {
      _logger.error('Sync pass failed', error: e, stackTrace: st);
      _statusController.add(SyncStatus.error);
    }
  }

  Future<void> _ensureVideoUrlResolved(String videoId) async {
    final existing =
        await (_db.select(_db.videos)..where((t) => t.id.equals(videoId))).getSingleOrNull();
    if (existing?.localFilePath != null) return;

    final videoDoc = await FirebaseFirestore.instance.collection(FirestorePaths.videos).doc(videoId).get();
    if (!videoDoc.exists) {
      _logger.warning('Playlist references missing video catalog entry: $videoId');
      return;
    }
    final data = videoDoc.data()!;
    final storagePath = data['storagePath'] as String;
    final checksum = data['checksum'] as String?;
    final sizeBytes = data['sizeBytes'] as int?;

    final url = await FirebaseStorage.instance.ref(storagePath).getDownloadURL();

    await _db.into(_db.videos).insertOnConflictUpdate(VideosCompanion.insert(
          id: videoId,
          storagePath: storagePath,
          checksum: Value(checksum),
          sizeBytes: Value(sizeBytes),
          localFilePath: Value(url),
          downloadedAt: Value(DateTime.now()),
        ));
  }

  @override
  Future<void> checkForUpdates() async {}
}
