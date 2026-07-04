import 'dart:io';

import 'package:flutterpi_gstreamer_video_player/flutterpi_gstreamer_video_player.dart';

/// flutter-pi has no official `video_player` platform package to
/// auto-register itself, so this is the one Linux-specific line the
/// upstream flutter-pi maintainer's own bridge package requires.
/// macOS keeps using `video_player_avfoundation`'s normal auto-registration.
void registerVideoPlayerPlatform() {
  if (Platform.isLinux) {
    FlutterpiVideoPlayer.registerWith();
  }
}
