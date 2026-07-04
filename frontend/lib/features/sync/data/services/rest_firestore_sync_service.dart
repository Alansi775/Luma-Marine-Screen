import 'dart:async';
import 'dart:convert';
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
/// Genuinely event-driven, not polling: holds one persistent connection
/// to Realtime Database's Server-Sent-Events stream (see
/// backend/README.md's "Realtime Database: why it exists") and reacts
/// within about a second of any admin change. A long-interval
/// reconciliation poll runs underneath purely as a safety net for a
/// missed signal (e.g. during a reconnect) — it is not the primary
/// mechanism.
class RestFirestoreSyncService extends SyncService {
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

  static const _safetyNetInterval = Duration(minutes: 3);
  static const _reconnectDelay = Duration(seconds: 3);

  final AppDatabase _db;
  final AppDirectories _directories;
  final AppLogger _logger;
  final PlaylistLocalDataSource _dataSource;
  final _dio = Dio();
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _activityController = StreamController<SyncActivity?>.broadcast();
  Timer? _safetyNetTimer;
  bool _isSyncing = false;
  bool _disposed = false;

  String get _projectId => DefaultFirebaseOptions.currentPlatform.projectId;
  String get _apiKey => DefaultFirebaseOptions.currentPlatform.apiKey;
  String get _bucket => DefaultFirebaseOptions.currentPlatform.storageBucket!;
  String get _firestoreBase =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';
  String get _signalUrl =>
      '${DefaultFirebaseOptions.databaseUrl}/deviceSignals/${FirestorePaths.defaultDeviceId}/updatedAt.json';

  @override
  bool get isAvailable => true;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Stream<SyncActivity?> get activityStream => _activityController.stream;

  @override
  void dispose() {
    _disposed = true;
    _safetyNetTimer?.cancel();
  }

  void _start() {
    unawaited(_poll());
    unawaited(_listenForSignal());
    _safetyNetTimer = Timer.periodic(_safetyNetInterval, (_) => _poll());
  }

  /// Holds one persistent connection to the Realtime Database signal path
  /// and triggers an immediate [_poll] on every change event. Reconnects
  /// automatically (with a short delay) if the connection drops — normal
  /// on a device that can be offline for extended periods.
  Future<void> _listenForSignal() async {
    while (!_disposed) {
      try {
        final response = await _dio.get<ResponseBody>(
          _signalUrl,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        );
        var buffer = '';
        await for (final chunk in response.data!.stream) {
          buffer += utf8.decode(chunk, allowMalformed: true);
          var boundary = buffer.indexOf('\n\n');
          while (boundary != -1) {
            final rawEvent = buffer.substring(0, boundary);
            buffer = buffer.substring(boundary + 2);
            if (rawEvent.startsWith('event: put') || rawEvent.startsWith('event: patch')) {
              unawaited(_poll());
            }
            boundary = buffer.indexOf('\n\n');
          }
        }
      } catch (e, st) {
        _logger.warning('Realtime signal connection dropped, reconnecting', error: e, stackTrace: st);
      }
      if (_disposed) return;
      await Future.delayed(_reconnectDelay);
    }
  }

  Future<void> _poll() async {
    // A single poll (specifically, downloading a large video) can easily
    // take far longer than it takes for another signal to arrive.
    // Without this guard, an admin making several quick changes would
    // start a new, competing download on top of one still in progress,
    // and neither would ever finish.
    if (_isSyncing) return;
    _isSyncing = true;
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
      // either way, leave local data untouched and retry next signal/tick,
      // so whatever's already cached keeps playing uninterrupted.
      _logger.warning('Sync pass failed, will retry', error: e, stackTrace: st);
      _statusController.add(SyncStatus.error);
    } finally {
      _activityController.add(null);
      _isSyncing = false;
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
    _activityController.add(const SyncActivity(kind: SyncActivityKind.downloading, progress: 0));
    final tempPath = '$localPath.part';
    await _dio.download(
      downloadUrl,
      tempPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          _activityController.add(SyncActivity(
            kind: SyncActivityKind.downloading,
            progress: received / total,
          ));
        }
      },
    );
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
    final orphaned = cachedVideos.where((v) => !activeVideoIds.contains(v.id)).toList();
    if (orphaned.isEmpty) return;

    _activityController.add(const SyncActivity(kind: SyncActivityKind.removing));
    for (final video in orphaned) {
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
