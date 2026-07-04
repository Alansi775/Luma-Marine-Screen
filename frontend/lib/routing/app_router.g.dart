// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kept behind a provider specifically so future requirements (deep links
/// for remote diagnostics, more admin routes) are additive edits to this
/// one file. `/admin` (and everything nested under it) redirects to the
/// hidden login screen for anyone not already signed in — there's no
/// visible link to either from normal signage playback (see the
/// long-press gesture on shared/widgets/bootstrap_screen.dart).

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// Kept behind a provider specifically so future requirements (deep links
/// for remote diagnostics, more admin routes) are additive edits to this
/// one file. `/admin` (and everything nested under it) redirects to the
/// hidden login screen for anyone not already signed in — there's no
/// visible link to either from normal signage playback (see the
/// long-press gesture on shared/widgets/bootstrap_screen.dart).

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Kept behind a provider specifically so future requirements (deep links
  /// for remote diagnostics, more admin routes) are additive edits to this
  /// one file. `/admin` (and everything nested under it) redirects to the
  /// hidden login screen for anyone not already signed in — there's no
  /// visible link to either from normal signage playback (see the
  /// long-press gesture on shared/widgets/bootstrap_screen.dart).
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

String _$goRouterHash() => r'eb0db1045faacafab573793190bfcfd4648541b8';
