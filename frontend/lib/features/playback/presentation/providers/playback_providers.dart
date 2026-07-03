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
