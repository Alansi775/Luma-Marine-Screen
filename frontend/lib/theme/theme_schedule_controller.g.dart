// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_schedule_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current wall-clock time. Exists as its own provider purely so
/// tests can override it with fixed instants instead of depending on
/// [DateTime.now] directly.

@ProviderFor(now)
final nowProvider = NowProvider._();

/// The current wall-clock time. Exists as its own provider purely so
/// tests can override it with fixed instants instead of depending on
/// [DateTime.now] directly.

final class NowProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// The current wall-clock time. Exists as its own provider purely so
  /// tests can override it with fixed instants instead of depending on
  /// [DateTime.now] directly.
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$nowHash() => r'6ce0b0f491f51ecbcb4c9775ab2b7eab5f0d9d39';

/// Determines [ThemeMode] from the device's local wall-clock time:
/// 06:00 (inclusive) to 18:00 (exclusive) is light, otherwise dark. No
/// user interaction, no `ThemeMode.system` — the schedule is the only
/// source of truth, re-evaluated once a minute since the device runs
/// 24/7 and must cross the boundary unattended.

@ProviderFor(ThemeSchedule)
final themeScheduleProvider = ThemeScheduleProvider._();

/// Determines [ThemeMode] from the device's local wall-clock time:
/// 06:00 (inclusive) to 18:00 (exclusive) is light, otherwise dark. No
/// user interaction, no `ThemeMode.system` — the schedule is the only
/// source of truth, re-evaluated once a minute since the device runs
/// 24/7 and must cross the boundary unattended.
final class ThemeScheduleProvider
    extends $NotifierProvider<ThemeSchedule, ThemeMode> {
  /// Determines [ThemeMode] from the device's local wall-clock time:
  /// 06:00 (inclusive) to 18:00 (exclusive) is light, otherwise dark. No
  /// user interaction, no `ThemeMode.system` — the schedule is the only
  /// source of truth, re-evaluated once a minute since the device runs
  /// 24/7 and must cross the boundary unattended.
  ThemeScheduleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeScheduleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeScheduleHash();

  @$internal
  @override
  ThemeSchedule create() => ThemeSchedule();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeScheduleHash() => r'631b41f77ed5b66433735d6ca3934519d93c3888';

/// Determines [ThemeMode] from the device's local wall-clock time:
/// 06:00 (inclusive) to 18:00 (exclusive) is light, otherwise dark. No
/// user interaction, no `ThemeMode.system` — the schedule is the only
/// source of truth, re-evaluated once a minute since the device runs
/// 24/7 and must cross the boundary unattended.

abstract class _$ThemeSchedule extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
