import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/bootstrap_screen.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/sync_activity_badge.dart';
import '../providers/playback_providers.dart';
import '../providers/playlist_player_controller.dart';

/// The signage player. Loops through the local playlist forever; falls
/// back to [BootstrapScreen] whenever there's nothing downloaded yet to
/// play (first boot, empty playlist, or between syncs).
///
/// Long-pressing anywhere on this screen — whatever it's currently
/// showing — opens the hidden admin sign-in. There's no visible button;
/// this is a public display.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPaths = ref.watch(resolvedPlaylistFilePathsProvider);

    return AppScaffold(
      body: GestureDetector(
        onLongPress: () => context.push(AppRoutes.adminLogin),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: resolvedPaths.when(
                loading: () => const BootstrapScreen(),
                error: (error, stackTrace) => EmptyState(
                  icon: Icons.error_outline,
                  message: 'Unable to load the playlist.\n$error',
                ),
                data: (paths) => paths.isEmpty
                    ? const EmptyState(
                        icon: Icons.playlist_play,
                        message: 'No videos synced yet.\nWaiting for the playlist to sync.',
                      )
                    : const _VideoPlayerView(),
              ),
            ),
            // Small, non-blocking — never covers the video underneath.
            const Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(child: SyncActivityBadge()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Split out so the native video player is only ever constructed once
/// there's actually something to play — not on every app boot, and not
/// when the playlist happens to be empty (e.g. in tests).
class _VideoPlayerView extends ConsumerWidget {
  const _VideoPlayerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(playlistPlayerControllerProvider);
    if (controller == null || !controller.value.isInitialized) {
      return const BootstrapScreen();
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
