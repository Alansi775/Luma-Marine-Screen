import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_playlist.dart';
import '../../domain/entities/playlist_video_item.dart';
import '../../domain/repositories/playlist_management_repository.dart';

class FirebasePlaylistManagementRepository implements PlaylistManagementRepository {
  FirebasePlaylistManagementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _playlists => _firestore.collection('playlists');

  DocumentReference<Map<String, dynamic>> get _defaultDevice =>
      _firestore.collection('devices').doc(FirestorePaths.defaultDeviceId);

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
      throw NetworkException('Failed to create playlist', cause: e);
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
      throw NetworkException('Failed to rename playlist', cause: e);
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
      throw NetworkException('Failed to update playlist schedule', cause: e);
    }
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    try {
      final entries = await _playlists.doc(playlistId).collection('entries').get();
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
    } catch (e) {
      throw NetworkException('Failed to delete playlist', cause: e);
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
        ));
      }
      return items;
    });
  }

  @override
  Future<void> removeVideoFromPlaylist({required String playlistId, required String entryId}) async {
    try {
      await _playlists.doc(playlistId).collection('entries').doc(entryId).delete();
    } catch (e) {
      throw NetworkException('Failed to remove video from playlist', cause: e);
    }
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
    } catch (e) {
      throw NetworkException('Failed to move video', cause: e);
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
    } catch (e) {
      throw NetworkException('Failed to reorder playlist', cause: e);
    }
  }

  @override
  Future<void> renameVideo(String videoId, String name) async {
    try {
      await _firestore.collection(FirestorePaths.videos).doc(videoId).update({'name': name});
    } catch (e) {
      throw NetworkException('Failed to rename video', cause: e);
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
    } catch (e) {
      throw NetworkException('Failed to set active playlist', cause: e);
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
  Never _unavailable() => throw const NetworkException('Firebase is unavailable right now.');

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
  Future<void> removeVideoFromPlaylist({required String playlistId, required String entryId}) async =>
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
