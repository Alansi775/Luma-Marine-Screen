import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_marine/theme/theme_schedule_controller.dart';

void main() {
  ThemeMode modeAt(DateTime instant) {
    final container = ProviderContainer(
      overrides: [nowProvider.overrideWithValue(instant)],
    );
    addTearDown(container.dispose);
    return container.read(themeScheduleProvider);
  }

  group('ThemeSchedule', () {
    test('is dark one second before 06:00', () {
      expect(modeAt(DateTime(2026, 1, 1, 5, 59, 59)), ThemeMode.dark);
    });

    test('is light exactly at 06:00', () {
      expect(modeAt(DateTime(2026, 1, 1, 6, 0, 0)), ThemeMode.light);
    });

    test('is light one second before 18:00', () {
      expect(modeAt(DateTime(2026, 1, 1, 17, 59, 59)), ThemeMode.light);
    });

    test('is dark exactly at 18:00', () {
      expect(modeAt(DateTime(2026, 1, 1, 18, 0, 0)), ThemeMode.dark);
    });
  });
}
