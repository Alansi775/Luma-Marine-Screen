import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/bootstrap_screen.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/playback_providers.dart';

/// Placeholder for the eventual video player. This pass proves the
/// wiring (local playlist -> screen) end to end; the actual player
/// (video_player/media_kit, transition handling, looping) is future work.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(activePlaylistProvider);

    return AppScaffold(
      body: playlist.when(
        loading: () => const BootstrapScreen(),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          message: 'Unable to load the playlist.\n$error',
        ),
        data: (entries) => entries.isEmpty
            ? const EmptyState(
                icon: Icons.playlist_play,
                message: 'No videos synced yet.\nWaiting for the playlist to sync.',
              )
            : _PlaylistPlaceholder(entryCount: entries.length),
      ),
    );
  }
}

class _PlaylistPlaceholder extends StatelessWidget {
  const _PlaylistPlaceholder({required this.entryCount});

  final int entryCount;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.movie_outlined,
      message: '$entryCount video(s) in the playlist.\nPlayback is not implemented yet.',
    );
  }
}
