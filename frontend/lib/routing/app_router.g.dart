// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Two flat routes today. Kept behind a provider specifically so future
/// requirements (auth/device-registration redirect guards, deep links
/// for remote diagnostics) are additive edits to this one file.

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// Two flat routes today. Kept behind a provider specifically so future
/// requirements (auth/device-registration redirect guards, deep links
/// for remote diagnostics) are additive edits to this one file.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Two flat routes today. Kept behind a provider specifically so future
  /// requirements (auth/device-registration redirect guards, deep links
  /// for remote diagnostics) are additive edits to this one file.
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'32cdbfdfd8d24b2029460fc95609d9c1cbe22b9b';
