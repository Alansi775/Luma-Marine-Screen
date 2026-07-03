import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/services/firebase_video_upload_service.dart';
import '../../domain/services/video_upload_service.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
VideoUploadService videoUploadService(Ref ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return UnavailableVideoUploadService();
  return FirebaseVideoUploadService(FirebaseFirestore.instance, FirebaseStorage.instance);
}
