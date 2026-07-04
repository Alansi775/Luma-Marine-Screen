/// Registers the right `video_player` platform implementation for the
/// current compile target: on Linux (flutter-pi) the official
/// `video_player` package doesn't ship a platform implementation and
/// flutter-pi doesn't run Flutter's generated plugin registrant, so
/// nothing ever sets `VideoPlayerPlatform.instance` and every controller
/// throws `UnimplementedError: init() has not been implemented.` at
/// runtime (see `default_app_directories_io.dart` for why native vs. web
/// needs a conditional export here) — the `_io.dart` variant fixes that
/// by manually calling `FlutterpiVideoPlayer.registerWith()`, which
/// flutter-pi's own built-in GStreamer plugin expects. No-op everywhere
/// else, since Android/iOS/macOS/web already register themselves via
/// their own official federated packages.
library;

export 'video_player_registration_io.dart'
    if (dart.library.js_interop) 'video_player_registration_web.dart';
