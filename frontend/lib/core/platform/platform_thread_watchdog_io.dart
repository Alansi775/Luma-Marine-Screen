import 'dart:async';
import 'dart:io';

/// Writes a liveness heartbeat file for an external, out-of-process
/// watchdog to monitor — see `deploy/pano-watchdog.sh`.
///
/// Confirmed via a live `gdb` backtrace on-device (2026-07-05): a
/// GStreamer VAAPI buffer-pool bug can leave a decoder thread spinning
/// forever inside `gst_buffer_pool_acquire_buffer` while holding a pad
/// lock. When our own stall-recovery then calls `gstplayer_destroy` to
/// tear down that pipeline, it blocks forever waiting for that same
/// lock — and flutter-pi serializes *all* platform channel traffic
/// through that single native thread, so this doesn't just kill one
/// video, it wedges the channel every future `initialize()`/`dispose()`
/// call needs too.
///
/// The first attempt at this watchdog used a `MethodChannel` heartbeat
/// from Dart, on the theory that a plain round-trip would prove the
/// native thread was still alive. That was wrong: a second gdb capture
/// during a real wedge showed the Dart **UI isolate itself** blocked
/// inside `flutterpi_post_platform_task_with_time`'s mutex — the exact
/// call `MethodChannel.invokeMethod` has to make just to *submit* a
/// message, before any `Future`/timeout machinery ever gets involved.
/// The heartbeat wasn't an independent probe; it was one more thing
/// contending for the same wedged lock, so it hung right alongside
/// everything else and never fired its own timeout.
///
/// This version never touches a platform channel at all. `dart:io`
/// file writes go straight through the VM's own I/O thread pool with
/// no engine/platform-thread involvement whatsoever, so they keep
/// working even while the native side is completely deadlocked. An
/// external script (not part of this app, so it can't be wedged by
/// anything happening inside it) watches the file's mtime and kills the
/// process if it goes stale, letting `flutter-pi.service`'s
/// `Restart=always` bring up a clean instance.
void startPlatformThreadWatchdog() {
  if (!Platform.isLinux) return;

  // Reuses flutter-pi.service's own RuntimeDirectory (XDG_RUNTIME_DIR)
  // rather than a hardcoded path, so this stays correct if that ever
  // changes. Falls back to /tmp for a plain `flutter-pi` run outside
  // systemd (e.g. manual on-device debugging).
  final runtimeDir = Platform.environment['XDG_RUNTIME_DIR'] ?? '/tmp';
  final heartbeatFile = File('$runtimeDir/pano-heartbeat');
  const interval = Duration(seconds: 5);

  Timer.periodic(interval, (_) {
    heartbeatFile.writeAsStringSync(DateTime.now().toIso8601String());
  });
}
