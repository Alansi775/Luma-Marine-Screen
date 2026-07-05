import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/logging/app_logger.dart';
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
  static const _disposeTimeout = Duration(seconds: 5);
  static const _maxAttemptsPerVideo = 2;

  /// How often to check whether a "playing" video's position is actually
  /// moving. flutter-pi's `play()` call has been confirmed to report
  /// success back to Dart — the method channel call returns, no exception,
  /// nothing timed out — even when the native GStreamer pipeline is stuck
  /// and never actually starts producing frames. A timeout around the
  /// `play()` call itself can't catch that, because there's nothing for it
  /// to time out on; the only reliable signal is that the reported
  /// position stops advancing.
  static const _stallCheckInterval = Duration(seconds: 4);
  static const _stallChecksBeforeRecovery = 2;

  /// On-device evidence (2026-07-05): even though `dispose()` itself
  /// always completes well within its own timeout, the *next* video's
  /// pipeline was frequently failing to ever produce a frame (caught by
  /// the stall watchdog at ~0ms) — on a large fraction of transitions,
  /// not as a rare edge case. `dispose()` returning to Dart doesn't
  /// guarantee flutter-pi's native side has fully released the shared
  /// VAAPI decoder context yet; this settling gap gives it room to
  /// finish before the next pipeline tries to claim it.
  static const _decoderSettleDelay = Duration(milliseconds: 400);

  List<String> _queue = [];
  String? _currentPath;
  bool _advancing = false;
  Timer? _stallWatchdog;

  @override
  VideoPlayerController? build() {
    ref.onDispose(() {
      _stallWatchdog?.cancel();
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

    final logger = ref.read(appLoggerProvider);

    // Dispose the outgoing controller *before* creating the next one:
    // flutter-pi's GStreamer/VAAPI decode session is a limited shared
    // resource, so briefly having two controllers alive at once makes the
    // new one hang on its first frame waiting for hardware the old one is
    // still holding. This teardown is itself native code that can hit the
    // same kind of deadlock a stuck startup can (confirmed on-device after
    // ~76 clean transitions) — awaiting it without a timeout would let one
    // bad dispose freeze every video after it forever, which defeats the
    // whole point of the startup watchdog below never getting a chance to
    // run. If it doesn't finish in time, abandon it and move on; a leaked
    // native player is a far smaller problem than a signage screen that
    // never recovers.
    _stallWatchdog?.cancel();
    final previous = state;
    state = null;
    if (previous != null) {
      try {
        await previous.dispose().timeout(_disposeTimeout);
      } on TimeoutException {
        logger.warning(
          'Previous video controller did not dispose within ${_disposeTimeout.inSeconds}s — '
          'abandoning it and continuing anyway',
        );
      }
      await Future<void>.delayed(_decoderSettleDelay);
    }

    for (var attempt = 1; attempt <= _maxAttemptsPerVideo; attempt++) {
      final isNetworkUrl = path.startsWith('http://') || path.startsWith('https://');
      final controller = isNetworkUrl
          ? VideoPlayerController.networkUrl(Uri.parse(path))
          : VideoPlayerController.file(File(path));

      // flutter-pi's native duration query is unreliable *throughout*
      // playback, not just at startup — "Could not fetch duration" recurs
      // in its logs every few seconds for the entire time a video plays.
      // Trusting the live `controller.value.duration` on every listener
      // tick meant a single transient bad query (reporting a shorter, or
      // zero, duration) made "remaining" look like the video had already
      // finished, cutting it off at a random point mid-playback — the
      // "some videos don't play their full length" bug. This only ever
      // grows, so a later bad/short query can't undo an earlier good one.
      var knownDuration = Duration.zero;

      controller.addListener(() {
        if (_advancing || !controller.value.isInitialized) return;
        if (controller.value.duration > knownDuration) {
          knownDuration = controller.value.duration;
        }
        // Exact position == duration is unreliable — the platform's last
        // position update often lands a few hundred milliseconds short of
        // the true end, so waiting for an exact match can stall forever.
        // A small tolerance against our own stabilized duration catches
        // "effectively finished" without trusting the native isCompleted
        // flag, which is computed from the same unreliable live duration.
        final remaining = knownDuration - controller.value.position;
        if (knownDuration > Duration.zero && remaining <= const Duration(milliseconds: 300)) {
          _advancing = true;
          _playNext();
        }
      });

      try {
        await controller.initialize().timeout(_initializeTimeout);
        await controller.play().timeout(_initializeTimeout);
        state = controller;
        _startStallWatchdog(controller, path, logger);
        return;
      } on TimeoutException {
        logger.warning(
          'Video failed to start within ${_initializeTimeout.inSeconds}s '
          '(attempt $attempt/$_maxAttemptsPerVideo), retrying: $path',
        );
        unawaited(controller.dispose().timeout(_disposeTimeout, onTimeout: () {}));
      }
    }

    logger.error('Giving up on "$path" after $_maxAttemptsPerVideo failed attempts, skipping to next video');
    if (_currentPath == path) {
      await _playNext();
    }
  }

  /// Polls `controller.value.position` and recovers if it stops moving
  /// for [_stallChecksBeforeRecovery] consecutive checks while the video
  /// is supposedly playing. See the field doc on [_stallCheckInterval] for
  /// why this exists instead of just trusting `play()`'s return value.
  void _startStallWatchdog(VideoPlayerController controller, String path, AppLogger logger) {
    Duration? lastPosition;
    var stalledChecks = 0;

    _stallWatchdog = Timer.periodic(_stallCheckInterval, (timer) {
      if (state != controller || _advancing) {
        timer.cancel();
        return;
      }

      final value = controller.value;
      if (!value.isInitialized || !value.isPlaying || value.isCompleted) {
        stalledChecks = 0;
        lastPosition = null;
        return;
      }

      if (lastPosition != null && value.position == lastPosition) {
        stalledChecks++;
      } else {
        stalledChecks = 0;
      }
      lastPosition = value.position;

      if (stalledChecks >= _stallChecksBeforeRecovery) {
        timer.cancel();
        _advancing = true;
        logger.warning(
          'Playback stalled at ${value.position} (native play() reported success but '
          'produced no further frames) — recovering: $path',
        );
        unawaited(_recoverFromStall(controller));
      }
    });
  }

  Future<void> _recoverFromStall(VideoPlayerController stuck) async {
    if (state == stuck) state = null;
    try {
      await stuck.dispose().timeout(_disposeTimeout);
    } on TimeoutException {
      // Same tradeoff as everywhere else here: a leaked native player beats
      // a screen that never recovers.
    }
    // Disposed directly here rather than through _playAt's own
    // previous-controller path (state is already null by this point), so
    // the settle delay has to be repeated here too.
    await Future<void>.delayed(_decoderSettleDelay);
    await _playNext();
  }
}
