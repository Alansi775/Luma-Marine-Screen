// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PlaylistPlayerController)
final playlistPlayerControllerProvider = PlaylistPlayerControllerProvider._();

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
final class PlaylistPlayerControllerProvider
    extends $NotifierProvider<PlaylistPlayerController, VideoController> {
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
  Override overrideWithValue(VideoController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoController>(value),
    );
  }
}

String _$playlistPlayerControllerHash() =>
    r'b6bdf455a71b96c07426d32f1634ebd05d1468ec';

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

abstract class _$PlaylistPlayerController extends $Notifier<VideoController> {
  VideoController build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VideoController, VideoController>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VideoController, VideoController>,
              VideoController,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
