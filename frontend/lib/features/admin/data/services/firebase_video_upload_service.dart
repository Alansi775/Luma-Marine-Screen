import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/realtime/device_change_signal.dart';
import '../../domain/services/video_upload_service.dart';

class FirebaseVideoUploadService implements VideoUploadService {
  FirebaseVideoUploadService(this._firestore, this._storage, this._changeSignal);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final DeviceChangeSignal _changeSignal;

  @override
  Future<void> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    required String playlistId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final videoId = const Uuid().v4();
      final extension = fileName.contains('.') ? fileName.split('.').last : 'mp4';
      final storagePath = '${FirestorePaths.videos}/$videoId.$extension';
      final checksum = md5.convert(bytes).toString();
      final displayName = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      final uploadTask = _storage.ref(storagePath).putData(
            bytes,
            SettableMetadata(contentType: 'video/$extension'),
          );
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
      await uploadTask;

      await _firestore.collection(FirestorePaths.videos).doc(videoId).set({
        'name': displayName,
        'storagePath': storagePath,
        'checksum': checksum,
        'sizeBytes': bytes.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _appendToPlaylist(playlistId, videoId);
    } catch (e) {
      throw NetworkException('Video upload failed', cause: e);
    }
  }

  Future<void> _appendToPlaylist(String playlistId, String videoId) async {
    final entries = _firestore.collection('playlists').doc(playlistId).collection('entries');
    final last = await entries.orderBy('sortOrder', descending: true).limit(1).get();
    final nextOrder = last.docs.isEmpty ? 0 : (last.docs.first.data()['sortOrder'] as int) + 1;

    await entries.add({
      'videoId': videoId,
      'sortOrder': nextOrder,
      'addedAt': FieldValue.serverTimestamp(),
    });
    await _changeSignal.notifyChanged(FirestorePaths.defaultDeviceId);
  }
}

/// Used when Firebase failed to initialize.
class UnavailableVideoUploadService implements VideoUploadService {
  @override
  Future<void> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    required String playlistId,
    void Function(double progress)? onProgress,
  }) async {
    throw const NetworkException('Firebase is unavailable, cannot upload right now.');
  }
}
