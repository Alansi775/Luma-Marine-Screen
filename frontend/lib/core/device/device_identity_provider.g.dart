// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_identity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A UUID identifying this physical device, persisted to disk on native
/// platforms (regenerated per-session on Flutter Web — see
/// `device_identity_resolver.dart`). This is the key the future sync
/// engine will use for device-scoped Firestore paths
/// (`devices/{deviceId}/...`) — see backend/schema/firestore-schema.md —
/// and what multi-display/device registration will build on later.

@ProviderFor(deviceIdentity)
final deviceIdentityProvider = DeviceIdentityProvider._();

/// A UUID identifying this physical device, persisted to disk on native
/// platforms (regenerated per-session on Flutter Web — see
/// `device_identity_resolver.dart`). This is the key the future sync
/// engine will use for device-scoped Firestore paths
/// (`devices/{deviceId}/...`) — see backend/schema/firestore-schema.md —
/// and what multi-display/device registration will build on later.

final class DeviceIdentityProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// A UUID identifying this physical device, persisted to disk on native
  /// platforms (regenerated per-session on Flutter Web — see
  /// `device_identity_resolver.dart`). This is the key the future sync
  /// engine will use for device-scoped Firestore paths
  /// (`devices/{deviceId}/...`) — see backend/schema/firestore-schema.md —
  /// and what multi-display/device registration will build on later.
  DeviceIdentityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdentityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdentityHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return deviceIdentity(ref);
  }
}

String _$deviceIdentityHash() => r'8f84791a63c723479946f9a353f6a24dccc93f4a';
