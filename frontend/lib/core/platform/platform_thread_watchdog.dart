/// Starts the liveness-heartbeat watchdog on the right platform target.
/// `dart:io`'s `Platform` throws on web the moment any property is
/// read (not just "reports false" — it's unimplemented there), so
/// gating this with a runtime `Platform.isLinux` check crashed the
/// whole app during `bootstrap()` on Flutter Web. Same conditional-
/// export shape as `video_player_registration.dart` for the same
/// reason: the `_web.dart` variant never touches `dart:io` at all.
library;

export 'platform_thread_watchdog_io.dart'
    if (dart.library.js_interop) 'platform_thread_watchdog_web.dart';
