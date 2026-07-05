import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/realtime/device_change_signal.dart';
import '../../data/repositories/firebase_playlist_management_repository.dart';
import '../../data/services/firebase_video_upload_service.dart';
import '../../domain/entities/admin_playlist.dart';
import '../../domain/entities/playlist_video_item.dart';
import '../../domain/repositories/playlist_management_repository.dart';
import '../../domain/services/video_upload_service.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
DeviceChangeSignal deviceChangeSignal(Ref ref) => DeviceChangeSignal(FirebaseDatabase.instance);

@Riverpod(keepAlive: true)
VideoUploadService videoUploadService(Ref ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return UnavailableVideoUploadService();
  return FirebaseVideoUploadService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    ref.watch(deviceChangeSignalProvider),
  );
}

@Riverpod(keepAlive: true)
PlaylistManagementRepository playlistManagementRepository(Ref ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return UnavailablePlaylistManagementRepository();
  return FirebasePlaylistManagementRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    ref.watch(deviceChangeSignalProvider),
  );
}

@riverpod
Stream<List<AdminPlaylist>> adminPlaylists(Ref ref) =>
    ref.watch(playlistManagementRepositoryProvider).watchPlaylists();

@riverpod
Stream<List<PlaylistVideoItem>> playlistEntries(Ref ref, String playlistId) =>
    ref.watch(playlistManagementRepositoryProvider).watchPlaylistEntries(playlistId);

@riverpod
Stream<String?> activePlaylistId(Ref ref) =>
    ref.watch(playlistManagementRepositoryProvider).watchActivePlaylistId();
