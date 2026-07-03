import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/services/video_upload_service.dart';

class FirebaseVideoUploadService implements VideoUploadService {
  FirebaseVideoUploadService(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<void> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final videoId = const Uuid().v4();
      final extension = fileName.contains('.') ? fileName.split('.').last : 'mp4';
      final storagePath = '${FirestorePaths.videos}/$videoId.$extension';
      final checksum = md5.convert(bytes).toString();

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
        'storagePath': storagePath,
        'checksum': checksum,
        'sizeBytes': bytes.length,
      });

      await _appendToDefaultPlaylist(videoId);
    } catch (e) {
      throw NetworkException('Video upload failed', cause: e);
    }
  }

  Future<void> _appendToDefaultPlaylist(String videoId) async {
    final playlist = _firestore.collection(
      FirestorePaths.devicePlaylist(FirestorePaths.defaultDeviceId),
    );
    final last = await playlist.orderBy('sortOrder', descending: true).limit(1).get();
    final nextOrder = last.docs.isEmpty ? 0 : (last.docs.first.data()['sortOrder'] as int) + 1;

    await playlist.add({
      'videoId': videoId,
      'sortOrder': nextOrder,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Used when Firebase failed to initialize.
class UnavailableVideoUploadService implements VideoUploadService {
  @override
  Future<void> uploadVideo({
    required Uint8List bytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    throw const NetworkException('Firebase is unavailable, cannot upload right now.');
  }
}
