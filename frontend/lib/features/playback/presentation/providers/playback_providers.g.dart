// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single swap point: if the local implementation is ever replaced (it
/// won't be — "local" is the whole point — but repositories exist so
/// other layers depend on interfaces, not drift), only this line changes.

@ProviderFor(playlistRepository)
final playlistRepositoryProvider = PlaylistRepositoryProvider._();

/// Single swap point: if the local implementation is ever replaced (it
/// won't be — "local" is the whole point — but repositories exist so
/// other layers depend on interfaces, not drift), only this line changes.

final class PlaylistRepositoryProvider
    extends
        $FunctionalProvider<
          PlaylistRepository,
          PlaylistRepository,
          PlaylistRepository
        >
    with $Provider<PlaylistRepository> {
  /// Single swap point: if the local implementation is ever replaced (it
  /// won't be — "local" is the whole point — but repositories exist so
  /// other layers depend on interfaces, not drift), only this line changes.
  PlaylistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaylistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaylistRepository create(Ref ref) {
    return playlistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaylistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaylistRepository>(value),
    );
  }
}

String _$playlistRepositoryHash() =>
    r'fcf34f40312b5f89ff2276129c50b552a18c61cf';

@ProviderFor(videoRepository)
final videoRepositoryProvider = VideoRepositoryProvider._();

final class VideoRepositoryProvider
    extends
        $FunctionalProvider<VideoRepository, VideoRepository, VideoRepository>
    with $Provider<VideoRepository> {
  VideoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoRepositoryHash();

  @$internal
  @override
  $ProviderElement<VideoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VideoRepository create(Ref ref) {
    return videoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoRepository>(value),
    );
  }
}

String _$videoRepositoryHash() => r'3a48577032f7ca372492cfaa1a87ca351f8def88';

@ProviderFor(activePlaylist)
final activePlaylistProvider = ActivePlaylistProvider._();

final class ActivePlaylistProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaylistEntry>>,
          List<PlaylistEntry>,
          Stream<List<PlaylistEntry>>
        >
    with
        $FutureModifier<List<PlaylistEntry>>,
        $StreamProvider<List<PlaylistEntry>> {
  ActivePlaylistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePlaylistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePlaylistHash();

  @$internal
  @override
  $StreamProviderElement<List<PlaylistEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlaylistEntry>> create(Ref ref) {
    return activePlaylist(ref);
  }
}

String _$activePlaylistHash() => r'd8874cc3f9073a2545925bf90fa8794b46de73ef';
