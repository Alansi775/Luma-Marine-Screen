import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Detects when flutter-pi's native platform thread has permanently
/// wedged and force-restarts the whole process so systemd can bring up a
/// fresh one.
///
/// Confirmed via a live `gdb` backtrace on-device (2026-07-05): a
/// GStreamer VAAPI buffer-pool bug can leave a decoder thread spinning
/// forever inside `gst_buffer_pool_acquire_buffer` while holding a pad
/// lock. When our own stall-recovery then calls `gstplayer_destroy` to
/// tear down that pipeline, it blocks forever waiting for that same lock
/// — and because flutter-pi dispatches *every* platform channel message
/// through that one thread, this doesn't just kill one video, it
/// permanently wedges the channel that all future `initialize()`/
/// `dispose()` calls need too. No Dart-side `Future.timeout` can recover
/// from this: the awaited call is abandoned, but the underlying native
/// call keeps blocking that thread forever regardless.
///
/// The only way out is external: notice the platform thread stopped
/// responding at all, then kill the process outright (`exit()` runs in
/// the Dart VM directly, bypassing the wedged engine thread entirely) so
/// the `flutter-pi.service` systemd unit's `Restart=always` brings up a
/// clean instance in a couple of seconds — turning an unbounded, silent
/// freeze into a bounded, automatic ~30s recovery.
void startPlatformThreadWatchdog(AppLogger logger) {
  if (!Platform.isLinux) return;

  const channel = MethodChannel('pano/heartbeat_probe');
  const pingInterval = Duration(seconds: 10);
  const pingTimeout = Duration(seconds: 12);
  const missesBeforeRestart = 2;

  var consecutiveMisses = 0;
  Timer.periodic(pingInterval, (_) async {
    try {
      // No handler is registered for this channel anywhere — the only
      // way to get any reply (even a "not implemented" one) is for the
      // native platform thread to actually process the message. A
      // `MissingPluginException` is a successful heartbeat.
      await channel.invokeMethod('ping').timeout(pingTimeout);
      consecutiveMisses = 0;
    } on MissingPluginException {
      consecutiveMisses = 0;
    } on TimeoutException {
      consecutiveMisses++;
      logger.error('Platform thread heartbeat missed ($consecutiveMisses/$missesBeforeRestart)');
      if (consecutiveMisses >= missesBeforeRestart) {
        logger.error('Platform thread appears permanently wedged — restarting process');
        exit(1);
      }
    }
  });
}
