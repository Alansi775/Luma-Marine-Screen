// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive` matters here beyond the usual reason: constructing this
/// provider is what starts the real sync engine's Firestore listener (see
/// `FirestoreSyncService`) — it must be watched from somewhere at app
/// startup (see `app.dart`), not just lazily from the diagnostics screen.

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

/// `keepAlive` matters here beyond the usual reason: constructing this
/// provider is what starts the real sync engine's Firestore listener (see
/// `FirestoreSyncService`) — it must be watched from somewhere at app
/// startup (see `app.dart`), not just lazily from the diagnostics screen.

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  /// `keepAlive` matters here beyond the usual reason: constructing this
  /// provider is what starts the real sync engine's Firestore listener (see
  /// `FirestoreSyncService`) — it must be watched from somewhere at app
  /// startup (see `app.dart`), not just lazily from the diagnostics screen.
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'7bae926e9171a1170260a02e22831a54b3302586';

/// What the sync engine is doing right now, for the signage screen's
/// small non-blocking indicator — see shared/widgets/sync_activity_badge.dart.

@ProviderFor(syncActivity)
final syncActivityProvider = SyncActivityProvider._();

/// What the sync engine is doing right now, for the signage screen's
/// small non-blocking indicator — see shared/widgets/sync_activity_badge.dart.

final class SyncActivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncActivity?>,
          SyncActivity?,
          Stream<SyncActivity?>
        >
    with $FutureModifier<SyncActivity?>, $StreamProvider<SyncActivity?> {
  /// What the sync engine is doing right now, for the signage screen's
  /// small non-blocking indicator — see shared/widgets/sync_activity_badge.dart.
  SyncActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncActivityHash();

  @$internal
  @override
  $StreamProviderElement<SyncActivity?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SyncActivity?> create(Ref ref) {
    return syncActivity(ref);
  }
}

String _$syncActivityHash() => r'79482f25eda044d691ea1d587df9e3e9e37bb387';
