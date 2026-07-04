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

String _$syncServiceHash() => r'6f0f6464383c4644c01f40726d87f493aaeeaa79';
