import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'playback_providers.dart';

part 'playlist_player_controller.g.dart';

/// Owns the single [Player] instance and keeps it pointed at the active
/// playlist, looping forever (video 1 → 2 → … → N → 1 → …).
///
/// Deliberately does *not* restart playback just because the resolved
/// file-path list changed shape — "future playlist changes must not
/// interrupt playback unnecessarily": if the currently-playing file is
/// still present anywhere in the new list, playback continues
/// uninterrupted and only the *next* advance uses the updated order.
/// Playback only jumps immediately if the current file was removed, or
/// nothing has played yet.
@Riverpod(keepAlive: true)
class PlaylistPlayerController extends _$PlaylistPlayerController {
  late final Player _player;
  List<String> _queue = [];
  String? _currentPath;
  StreamSubscription<bool>? _completedSubscription;

  @override
  VideoController build() {
    _player = Player();
    final controller = VideoController(_player);

    if (kIsWeb) {
      // Chrome (and other browsers) block autoplay with sound until the
      // user has interacted with the page — without this, playback opens
      // but silently never actually starts, appearing "frozen" on the
      // first frame. Not an issue on the real target platforms
      // (Linux/macOS via media_kit's native backend), so only mute here.
      unawaited(_player.setVolume(0));
    }

    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed) _playNext();
    });

    ref.onDispose(() {
      _completedSubscription?.cancel();
      _player.dispose();
    });

    ref.listen(resolvedPlaylistFilePathsProvider, (previous, next) {
      next.whenData(_onQueueChanged);
    });

    return controller;
  }

  void _onQueueChanged(List<String> paths) {
    _queue = paths;
    if (_queue.isEmpty) {
      _currentPath = null;
      _player.stop();
      return;
    }
    if (_currentPath == null || !_queue.contains(_currentPath)) {
      _playAt(0);
    }
  }

  void _playNext() {
    if (_queue.isEmpty) return;
    final currentIndex = _currentPath == null ? -1 : _queue.indexOf(_currentPath!);
    _playAt((currentIndex + 1) % _queue.length);
  }

  void _playAt(int index) {
    final path = _queue[index];
    _currentPath = path;
    _player.open(Media(path));
  }
}
