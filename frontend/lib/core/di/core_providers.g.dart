// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Infrastructure singletons resolved once in `bootstrap()` before
/// `runApp`, then injected via `ProviderScope(overrides: [...])` with
/// `overrideWithValue`. Declaring them here (rather than as plain global
/// variables) keeps every consumer going through Riverpod, so tests can
/// override them too. The bodies below should never run in practice —
/// if one does, `bootstrap()` failed to provide an override.

@ProviderFor(appLogger)
final appLoggerProvider = AppLoggerProvider._();

/// Infrastructure singletons resolved once in `bootstrap()` before
/// `runApp`, then injected via `ProviderScope(overrides: [...])` with
/// `overrideWithValue`. Declaring them here (rather than as plain global
/// variables) keeps every consumer going through Riverpod, so tests can
/// override them too. The bodies below should never run in practice —
/// if one does, `bootstrap()` failed to provide an override.

final class AppLoggerProvider
    extends $FunctionalProvider<AppLogger, AppLogger, AppLogger>
    with $Provider<AppLogger> {
  /// Infrastructure singletons resolved once in `bootstrap()` before
  /// `runApp`, then injected via `ProviderScope(overrides: [...])` with
  /// `overrideWithValue`. Declaring them here (rather than as plain global
  /// variables) keeps every consumer going through Riverpod, so tests can
  /// override them too. The bodies below should never run in practice —
  /// if one does, `bootstrap()` failed to provide an override.
  AppLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLoggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLoggerHash();

  @$internal
  @override
  $ProviderElement<AppLogger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLogger create(Ref ref) {
    return appLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLogger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLogger>(value),
    );
  }
}

String _$appLoggerHash() => r'b68434a07fb9c922756dd99006ee4257205d2231';

@ProviderFor(appDirectories)
final appDirectoriesProvider = AppDirectoriesProvider._();

final class AppDirectoriesProvider
    extends $FunctionalProvider<AppDirectories, AppDirectories, AppDirectories>
    with $Provider<AppDirectories> {
  AppDirectoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDirectoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDirectoriesHash();

  @$internal
  @override
  $ProviderElement<AppDirectories> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDirectories create(Ref ref) {
    return appDirectories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDirectories value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDirectories>(value),
    );
  }
}

String _$appDirectoriesHash() => r'0aed5fc4cd8d44cdc9448722aacfd915476b03f1';

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'40679daa59c2af80936518174026343663b6a2ee';

@ProviderFor(firebaseAvailable)
final firebaseAvailableProvider = FirebaseAvailableProvider._();

final class FirebaseAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  FirebaseAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return firebaseAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$firebaseAvailableHash() => r'cacf649143c704ac559b8f2a3edb4ebd1492b7f2';
