/// No-op on web: there's no native platform thread to wedge (the
/// signage device runs on flutter-pi/Linux only — see
/// `platform_thread_watchdog_io.dart`), and `dart:io`'s `Platform` is
/// entirely unavailable on web, not just "not Linux" — even reading
/// `Platform.isLinux` throws there, which is why this needs its own
/// conditional-export variant rather than a runtime check.
void startPlatformThreadWatchdog() {}
