import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/realtime/device_change_signal.dart';
import '../../domain/entities/admin_playlist.dart';
import '../../domain/entities/playlist_video_item.dart';
import '../../domain/repositories/playlist_management_repository.dart';

class FirebasePlaylistManagementRepository implements PlaylistManagementRepository {
  FirebasePlaylistManagementRepository(this._firestore, this._storage, this._changeSignal);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final DeviceChangeSignal _changeSignal;

  CollectionReference<Map<String, dynamic>> get _playlists => _firestore.collection('playlists');

  DocumentReference<Map<String, dynamic>> get _defaultDevice =>
      _firestore.collection('devices').doc(FirestorePaths.defaultDeviceId);

  Future<void> _notifyDevice() => _changeSignal.notifyChanged(FirestorePaths.defaultDeviceId);

  @override
  Stream<List<AdminPlaylist>> watchPlaylists() {
    return _playlists.orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs.map(_toAdminPlaylist).toList(),
        );
  }

  @override
  Future<String> createPlaylist(String name) async {
    try {
      final doc = await _playlists.add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'scheduledStart': null,
      });
      return doc.id;
    } catch (e) {
      throw NetworkException('Liste oluşturulamadı', cause: e);
    }
  }

  @override
  Future<void> renamePlaylist(String playlistId, String name) async {
    try {
      await _playlists.doc(playlistId).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw NetworkException('Liste yeniden adlandırılamadı', cause: e);
    }
  }

  @override
  Future<void> setPlaylistSchedule(String playlistId, String? scheduledStart) async {
    try {
      await _playlists.doc(playlistId).update({
        'scheduledStart': scheduledStart,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw NetworkException('Liste zamanlaması güncellenemedi', cause: e);
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    try {
      final entries = await _playlists.doc(playlistId).collection('entries').get();
      final videoIds = entries.docs.map((e) => e.data()['videoId'] as String).toList();

      final batch = _firestore.batch();
      for (final entry in entries.docs) {
        batch.delete(entry.reference);
      }
      batch.delete(_playlists.doc(playlistId));
      await batch.commit();

      final device = await _defaultDevice.get();
      if (device.data()?['activePlaylistId'] == playlistId) {
        await _defaultDevice.set({'activePlaylistId': null}, SetOptions(merge: true));
      }
      for (final videoId in videoIds) {
        await _deleteVideoIfOrphaned(videoId);
      }
      await _notifyDevice();
    } catch (e) {
      throw NetworkException('Liste silinemedi', cause: e);
    }
  }

  @override
  Stream<List<PlaylistVideoItem>> watchPlaylistEntries(String playlistId) {
    return _playlists
        .doc(playlistId)
        .collection('entries')
        .orderBy('sortOrder')
        .snapshots()
        .asyncMap((snapshot) async {
      final items = <PlaylistVideoItem>[];
      for (final entryDoc in snapshot.docs) {
        final entryData = entryDoc.data();
        final videoId = entryData['videoId'] as String;
        final videoDoc = await _firestore.collection(FirestorePaths.videos).doc(videoId).get();
        final videoData = videoDoc.data();
        items.add(PlaylistVideoItem(
          entryId: entryDoc.id,
          videoId: videoId,
          sortOrder: entryData['sortOrder'] as int,
          name: (videoData?['name'] as String?) ?? '(deleted video)',
          durationSeconds: videoData?['durationSeconds'] as int?,
          storagePath: videoData?['storagePath'] as String?,
          thumbnailPath: videoData?['thumbnailPath'] as String?,
          uploadedAt: (videoData?['createdAt'] as Timestamp?)?.toDate(),
        ));
      }
      return items;
    });
  }

  @override
  Future<void> removeVideoFromPlaylist({
    required String playlistId,
    required String entryId,
    required String videoId,
  }) async {
    try {
      await _playlists.doc(playlistId).collection('entries').doc(entryId).delete();
      await _deleteVideoIfOrphaned(videoId);
      await _notifyDevice();
    } catch (e) {
      throw NetworkException('Video listeden kaldırılamadı', cause: e);
    }
  }

  /// Deletes a video's catalog doc and Storage file once nothing
  /// references it anymore. Checked by scanning every playlist's entries
  /// rather than a collection-group query, since that would need a
  /// manually-enabled Firestore index this project doesn't have — fine at
  /// this scale (a handful of playlists), and avoids a query that would
  /// silently return nothing until that index exists.
  Future<void> _deleteVideoIfOrphaned(String videoId) async {
    final playlists = await _playlists.get();
    for (final playlist in playlists.docs) {
      final stillUsed = await playlist.reference.collection('entries').where('videoId', isEqualTo: videoId).limit(1).get();
      if (stillUsed.docs.isNotEmpty) return;
    }

    final videoDoc = await _firestore.collection(FirestorePaths.videos).doc(videoId).get();
    final storagePath = videoDoc.data()?['storagePath'] as String?;
    final thumbnailPath = videoDoc.data()?['thumbnailPath'] as String?;
    for (final path in [storagePath, thumbnailPath]) {
      if (path == null) continue;
      try {
        await _storage.ref(path).delete();
      } on FirebaseException catch (e) {
        // Already gone (e.g. a previous delete partially succeeded, or the
        // thumbnail-generation function never got to run) — still remove
        // the catalog doc below rather than leaving it stuck.
        if (e.code != 'object-not-found') rethrow;
      }
    }
    await videoDoc.reference.delete();
  }

  @override
  Future<void> moveVideoToPlaylist({
    required String fromPlaylistId,
    required String entryId,
    required String videoId,
    required String toPlaylistId,
  }) async {
    try {
      final targetEntries = _playlists.doc(toPlaylistId).collection('entries');
      final last = await targetEntries.orderBy('sortOrder', descending: true).limit(1).get();
      final nextOrder = last.docs.isEmpty ? 0 : (last.docs.first.data()['sortOrder'] as int) + 1;

      final batch = _firestore.batch();
      batch.delete(_playlists.doc(fromPlaylistId).collection('entries').doc(entryId));
      batch.set(targetEntries.doc(), {
        'videoId': videoId,
        'sortOrder': nextOrder,
        'addedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await _notifyDevice();
    } catch (e) {
      throw NetworkException('Video taşınamadı', cause: e);
    }
  }

  @override
  Future<void> reorderEntries(String playlistId, List<String> orderedEntryIds) async {
    try {
      final batch = _firestore.batch();
      final entries = _playlists.doc(playlistId).collection('entries');
      for (var i = 0; i < orderedEntryIds.length; i++) {
        batch.update(entries.doc(orderedEntryIds[i]), {'sortOrder': i});
      }
      await batch.commit();
      await _notifyDevice();
    } catch (e) {
      throw NetworkException('Liste sıralaması değiştirilemedi', cause: e);
    }
  }

  @override
  Future<void> renameVideo(String videoId, String name) async {
    try {
      await _firestore.collection(FirestorePaths.videos).doc(videoId).update({'name': name});
      await _notifyDevice();
    } catch (e) {
      throw NetworkException('Video yeniden adlandırılamadı', cause: e);
    }
  }

  @override
  Stream<String?> watchActivePlaylistId() {
    return _defaultDevice.snapshots().map((doc) => doc.data()?['activePlaylistId'] as String?);
  }

  @override
  Future<void> setActivePlaylist(String? playlistId) async {
    try {
      await _defaultDevice.set({'activePlaylistId': playlistId}, SetOptions(merge: true));
      await _notifyDevice();
    } catch (e) {
      throw NetworkException('Aktif liste ayarlanamadı', cause: e);
    }
  }

  AdminPlaylist _toAdminPlaylist(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AdminPlaylist(
      id: doc.id,
      name: data['name'] as String? ?? '(unnamed)',
      scheduledStart: data['scheduledStart'] as String?,
    );
  }
}

/// Used when Firebase failed to initialize.
class UnavailablePlaylistManagementRepository implements PlaylistManagementRepository {
  Never _unavailable() => throw const NetworkException('Firebase şu anda kullanılamıyor.');

  @override
  Stream<List<AdminPlaylist>> watchPlaylists() => Stream.value(const []);
  @override
  Future<String> createPlaylist(String name) async => _unavailable();
  @override
  Future<void> renamePlaylist(String playlistId, String name) async => _unavailable();
  @override
  Future<void> setPlaylistSchedule(String playlistId, String? scheduledStart) async => _unavailable();
  @override
  Future<void> deletePlaylist(String playlistId) async => _unavailable();
  @override
  Stream<List<PlaylistVideoItem>> watchPlaylistEntries(String playlistId) => Stream.value(const []);
  @override
  Future<void> removeVideoFromPlaylist({
    required String playlistId,
    required String entryId,
    required String videoId,
  }) async =>
      _unavailable();
  @override
  Future<void> moveVideoToPlaylist({
    required String fromPlaylistId,
    required String entryId,
    required String videoId,
    required String toPlaylistId,
  }) async =>
      _unavailable();
  @override
  Future<void> reorderEntries(String playlistId, List<String> orderedEntryIds) async => _unavailable();
  @override
  Future<void> renameVideo(String videoId, String name) async => _unavailable();
  @override
  Stream<String?> watchActivePlaylistId() => Stream.value(null);
  @override
  Future<void> setActivePlaylist(String? playlistId) async => _unavailable();
}
