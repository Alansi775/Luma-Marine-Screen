import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import 'playback_providers.dart';

part 'playlist_player_controller.g.dart';

/// Owns the current video's [VideoPlayerController] and keeps it pointed
/// at the active playlist, looping forever (video 1 → 2 → … → N → 1 → …).
///
/// Uses the official `video_player` package rather than a general-purpose
/// media library: flutter-pi (the production target) has its own
/// first-party GStreamer-backed implementation of `video_player`'s
/// platform interface built in — no plugin registration needed, just the
/// right GStreamer packages installed on the device (see
/// frontend/README.md). `video_player` also has official macOS and web
/// implementations, so the same code path covers every platform this app
/// touches.
///
/// `video_player` needs a fresh [VideoPlayerController] per video (unlike
/// a single long-lived player object), so the controller instance itself
/// is this provider's state — the UI rebuilds when it changes.
///
/// Deliberately does *not* switch videos just because the resolved
/// file-path list changed shape — "future playlist changes must not
/// interrupt playback unnecessarily": if the currently-playing file is
/// still present anywhere in the new list, playback continues
/// uninterrupted and only the *next* advance uses the updated order.
@Riverpod(keepAlive: true)
class PlaylistPlayerController extends _$PlaylistPlayerController {
  List<String> _queue = [];
  String? _currentPath;

  @override
  VideoPlayerController? build() {
    ref.onDispose(() {
      state?.dispose();
    });

    ref.listen(resolvedPlaylistFilePathsProvider, (previous, next) {
      next.whenData(_onQueueChanged);
    });

    return null;
  }

  Future<void> _onQueueChanged(List<String> paths) async {
    _queue = paths;
    if (_queue.isEmpty) {
      _currentPath = null;
      await state?.pause();
      return;
    }
    if (_currentPath == null || !_queue.contains(_currentPath)) {
      await _playAt(0);
    }
  }

  Future<void> _playNext() async {
    if (_queue.isEmpty) return;
    final currentIndex = _currentPath == null ? -1 : _queue.indexOf(_currentPath!);
    await _playAt((currentIndex + 1) % _queue.length);
  }

  Future<void> _playAt(int index) async {
    final path = _queue[index];
    _currentPath = path;

    final isNetworkUrl = path.startsWith('http://') || path.startsWith('https://');
    final controller = isNetworkUrl
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));

    controller.addListener(() {
      if (controller.value.isCompleted) _playNext();
    });

    final previous = state;
    await controller.initialize();
    await controller.play();
    state = controller;
    await previous?.dispose();
  }
}
