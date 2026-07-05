import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/di/core_providers.dart';
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
  /// flutter-pi's GStreamer pipeline setup occasionally deadlocks during
  /// preroll for reasons outside this app's control (a native race
  /// confirmed to happen independent of resolution or hardware vs.
  /// software decode). A stuck pipeline never throws — it just never
  /// finishes initializing — so the only way to detect it is a timeout.
  /// Two attempts before giving up on a video: transient enough that a
  /// clean retry usually succeeds, without stalling the whole playlist
  /// for minutes on a video that's genuinely broken.
  static const _initializeTimeout = Duration(seconds: 8);
  static const _maxAttemptsPerVideo = 2;

  List<String> _queue = [];
  String? _currentPath;
  bool _advancing = false;

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
    _advancing = false;

    // Dispose the outgoing controller *before* creating the next one:
    // flutter-pi's GStreamer/VAAPI decode session is a limited shared
    // resource, so briefly having two controllers alive at once makes the
    // new one hang on its first frame waiting for hardware the old one is
    // still holding.
    final previous = state;
    state = null;
    await previous?.dispose();

    final logger = ref.read(appLoggerProvider);

    for (var attempt = 1; attempt <= _maxAttemptsPerVideo; attempt++) {
      final isNetworkUrl = path.startsWith('http://') || path.startsWith('https://');
      final controller = isNetworkUrl
          ? VideoPlayerController.networkUrl(Uri.parse(path))
          : VideoPlayerController.file(File(path));

      controller.addListener(() {
        if (_advancing || !controller.value.isInitialized) return;
        // Exact position == duration is unreliable — the platform's last
        // position update often lands a few hundred milliseconds short of
        // the true end, so isCompleted alone can just never become true
        // and the playlist stalls forever on the last video. A small
        // tolerance catches "effectively finished" the same way.
        final remaining = controller.value.duration - controller.value.position;
        if (controller.value.isCompleted || remaining <= const Duration(milliseconds: 300)) {
          _advancing = true;
          _playNext();
        }
      });

      try {
        await controller.initialize().timeout(_initializeTimeout);
        await controller.play();
        state = controller;
        return;
      } on TimeoutException {
        logger.warning(
          'Video failed to start within ${_initializeTimeout.inSeconds}s '
          '(attempt $attempt/$_maxAttemptsPerVideo), retrying: $path',
        );
        unawaited(controller.dispose());
      }
    }

    logger.error('Giving up on "$path" after $_maxAttemptsPerVideo failed attempts, skipping to next video');
    if (_currentPath == path) {
      await _playNext();
    }
  }
}
