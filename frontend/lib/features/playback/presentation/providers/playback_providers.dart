import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/repositories/local_playlist_repository.dart';
import '../../data/repositories/local_video_repository.dart';
import '../../domain/entities/playlist_entry.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/video_repository.dart';

part 'playback_providers.g.dart';

/// Single swap point: if the local implementation is ever replaced (it
/// won't be — "local" is the whole point — but repositories exist so
/// other layers depend on interfaces, not drift), only this line changes.
@Riverpod(keepAlive: true)
PlaylistRepository playlistRepository(Ref ref) =>
    LocalPlaylistRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
VideoRepository videoRepository(Ref ref) =>
    LocalVideoRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<PlaylistEntry>> activePlaylist(Ref ref) {
  return ref.watch(playlistRepositoryProvider).watchActivePlaylist();
}

/// The active playlist, resolved down to local file paths ready to hand
/// to the player — entries whose video hasn't finished downloading yet
/// are skipped rather than shown as a gap or error, since the sync
/// engine will re-emit once the download completes.
@riverpod
Stream<List<String>> resolvedPlaylistFilePaths(Ref ref) {
  final playlistRepository = ref.watch(playlistRepositoryProvider);
  final videoRepository = ref.watch(videoRepositoryProvider);
  return playlistRepository.watchActivePlaylist().asyncMap((entries) async {
    final paths = <String>[];
    for (final entry in entries) {
      final path = await videoRepository.getLocalFilePath(entry.videoId);
      if (path != null) paths.add(path);
    }
    return paths;
  });
}
