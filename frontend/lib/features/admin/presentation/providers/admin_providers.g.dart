// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceChangeSignal)
final deviceChangeSignalProvider = DeviceChangeSignalProvider._();

final class DeviceChangeSignalProvider
    extends
        $FunctionalProvider<
          DeviceChangeSignal,
          DeviceChangeSignal,
          DeviceChangeSignal
        >
    with $Provider<DeviceChangeSignal> {
  DeviceChangeSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceChangeSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceChangeSignalHash();

  @$internal
  @override
  $ProviderElement<DeviceChangeSignal> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceChangeSignal create(Ref ref) {
    return deviceChangeSignal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceChangeSignal value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceChangeSignal>(value),
    );
  }
}

String _$deviceChangeSignalHash() =>
    r'a08742d9f09ae3235ce9149a8af24622bbb2b4e0';

@ProviderFor(videoUploadService)
final videoUploadServiceProvider = VideoUploadServiceProvider._();

final class VideoUploadServiceProvider
    extends
        $FunctionalProvider<
          VideoUploadService,
          VideoUploadService,
          VideoUploadService
        >
    with $Provider<VideoUploadService> {
  VideoUploadServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoUploadServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoUploadServiceHash();

  @$internal
  @override
  $ProviderElement<VideoUploadService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoUploadService create(Ref ref) {
    return videoUploadService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoUploadService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoUploadService>(value),
    );
  }
}

String _$videoUploadServiceHash() =>
    r'38ec7eeacc7c3f525eef14e9ab928f6fd2bf00d8';

@ProviderFor(playlistManagementRepository)
final playlistManagementRepositoryProvider =
    PlaylistManagementRepositoryProvider._();

final class PlaylistManagementRepositoryProvider
    extends
        $FunctionalProvider<
          PlaylistManagementRepository,
          PlaylistManagementRepository,
          PlaylistManagementRepository
        >
    with $Provider<PlaylistManagementRepository> {
  PlaylistManagementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistManagementRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistManagementRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaylistManagementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaylistManagementRepository create(Ref ref) {
    return playlistManagementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaylistManagementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaylistManagementRepository>(value),
    );
  }
}

String _$playlistManagementRepositoryHash() =>
    r'09aaa686e9cf7417c46d8b86536fe08fbd105bae';

@ProviderFor(adminPlaylists)
final adminPlaylistsProvider = AdminPlaylistsProvider._();

final class AdminPlaylistsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminPlaylist>>,
          List<AdminPlaylist>,
          Stream<List<AdminPlaylist>>
        >
    with
        $FutureModifier<List<AdminPlaylist>>,
        $StreamProvider<List<AdminPlaylist>> {
  AdminPlaylistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminPlaylistsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminPlaylistsHash();

  @$internal
  @override
  $StreamProviderElement<List<AdminPlaylist>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AdminPlaylist>> create(Ref ref) {
    return adminPlaylists(ref);
  }
}

String _$adminPlaylistsHash() => r'4e21649b07fc80da1b0e49f41ecb9795476d8823';

@ProviderFor(playlistEntries)
final playlistEntriesProvider = PlaylistEntriesFamily._();

final class PlaylistEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaylistVideoItem>>,
          List<PlaylistVideoItem>,
          Stream<List<PlaylistVideoItem>>
        >
    with
        $FutureModifier<List<PlaylistVideoItem>>,
        $StreamProvider<List<PlaylistVideoItem>> {
  PlaylistEntriesProvider._({
    required PlaylistEntriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playlistEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playlistEntriesHash();

  @override
  String toString() {
    return r'playlistEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<PlaylistVideoItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlaylistVideoItem>> create(Ref ref) {
    final argument = this.argument as String;
    return playlistEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaylistEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playlistEntriesHash() => r'bea8787db2d77ab13e5309169600abbc6c31fdd0';

final class PlaylistEntriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<PlaylistVideoItem>>, String> {
  PlaylistEntriesFamily._()
    : super(
        retry: null,
        name: r'playlistEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlaylistEntriesProvider call(String playlistId) =>
      PlaylistEntriesProvider._(argument: playlistId, from: this);

  @override
  String toString() => r'playlistEntriesProvider';
}

@ProviderFor(activePlaylistId)
final activePlaylistIdProvider = ActivePlaylistIdProvider._();

final class ActivePlaylistIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  ActivePlaylistIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePlaylistIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePlaylistIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return activePlaylistId(ref);
  }
}

String _$activePlaylistIdHash() => r'a4a628e4dbc31edc4cbdcd3d8219ce787da5d587';
