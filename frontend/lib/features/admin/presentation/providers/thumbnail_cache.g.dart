// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thumbnail_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(thumbnailCache)
final thumbnailCacheProvider = ThumbnailCacheProvider._();

final class ThumbnailCacheProvider
    extends $FunctionalProvider<ThumbnailCache, ThumbnailCache, ThumbnailCache>
    with $Provider<ThumbnailCache> {
  ThumbnailCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thumbnailCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thumbnailCacheHash();

  @$internal
  @override
  $ProviderElement<ThumbnailCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThumbnailCache create(Ref ref) {
    return thumbnailCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThumbnailCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThumbnailCache>(value),
    );
  }
}

String _$thumbnailCacheHash() => r'df1b256cf70315aad5b29a49518825942465f0de';
