// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PlaylistPlayerController)
final playlistPlayerControllerProvider = PlaylistPlayerControllerProvider._();

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
final class PlaylistPlayerControllerProvider
    extends
        $NotifierProvider<PlaylistPlayerController, VideoPlayerController?> {
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
  PlaylistPlayerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistPlayerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistPlayerControllerHash();

  @$internal
  @override
  PlaylistPlayerController create() => PlaylistPlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoPlayerController? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoPlayerController?>(value),
    );
  }
}

String _$playlistPlayerControllerHash() =>
    r'd840b7c560eb3b59e921acec0b52ef3d969bf701';

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

abstract class _$PlaylistPlayerController
    extends $Notifier<VideoPlayerController?> {
  VideoPlayerController? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<VideoPlayerController?, VideoPlayerController?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VideoPlayerController?, VideoPlayerController?>,
              VideoPlayerController?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
