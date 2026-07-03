import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_schedule_controller.g.dart';

/// The current wall-clock time. Exists as its own provider purely so
/// tests can override it with fixed instants instead of depending on
/// [DateTime.now] directly.
@Riverpod(keepAlive: true)
DateTime now(Ref ref) => DateTime.now();

/// Determines [ThemeMode] from the device's local wall-clock time:
/// 06:00 (inclusive) to 18:00 (exclusive) is light, otherwise dark. No
/// user interaction, no `ThemeMode.system` — the schedule is the only
/// source of truth, re-evaluated once a minute since the device runs
/// 24/7 and must cross the boundary unattended.
@Riverpod(keepAlive: true)
class ThemeSchedule extends _$ThemeSchedule {
  Timer? _timer;

  @override
  ThemeMode build() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    ref.onDispose(() => _timer?.cancel());
    return _modeFor(ref.read(nowProvider));
  }

  void _tick() {
    final next = _modeFor(DateTime.now());
    if (next != state) state = next;
  }

  static ThemeMode _modeFor(DateTime time) {
    return (time.hour >= 6 && time.hour < 18) ? ThemeMode.light : ThemeMode.dark;
  }
}
