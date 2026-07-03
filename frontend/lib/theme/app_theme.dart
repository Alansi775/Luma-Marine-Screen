import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light/dark [ThemeData] for the app's minimal/premium/industrial design
/// language: white/black/grey primaries, no bright accents, no
/// unnecessary animation. Switched automatically by [ThemeSchedule] on a
/// day/night wall-clock schedule — never `ThemeMode.system`.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.grey900,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.grey900,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.grey900,
          outline: AppColors.grey200,
          secondary: AppColors.grey500,
        ),
        scaffoldBackground: AppColors.offWhite,
      );

  static ThemeData get dark => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.grey100,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.grey100,
          onPrimary: AppColors.nearBlack,
          surface: AppColors.grey900,
          onSurface: AppColors.grey100,
          outline: AppColors.grey700,
          secondary: AppColors.grey300,
        ),
        scaffoldBackground: AppColors.nearBlack,
      );

  static ThemeData _base(ColorScheme scheme, {required Color scaffoldBackground}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: scheme.outline,
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
    );
  }
}
