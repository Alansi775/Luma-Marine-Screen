import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light/dark [ThemeData] for the app's minimal/premium/industrial design
/// language: white/black/grey primaries, no bright accents, no
/// unnecessary animation. Switched automatically by [ThemeSchedule] on a
/// day/night wall-clock schedule — never `ThemeMode.system`.
///
/// Deliberately overrides every widget theme that defaults to a
/// generic-looking Material appearance (input borders, button shape,
/// text selection color, type weights/spacing) — those defaults are
/// exactly what makes an app read as a stock Android app rather than a
/// custom brand.
class AppTheme {
  AppTheme._();

  static const _radius = 4.0;
  static const _borderWidth = 1.0;

  static ThemeData get light => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.grey900,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.grey900,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.grey900,
          outline: AppColors.grey300,
          secondary: AppColors.grey500,
          error: const Color(0xFFB3261E),
        ),
        scaffoldBackground: AppColors.offWhite,
        mutedText: AppColors.grey500,
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
          error: const Color(0xFFFFB4AB),
        ),
        scaffoldBackground: AppColors.nearBlack,
        mutedText: AppColors.grey300,
      );

  static ThemeData _base(
    ColorScheme scheme, {
    required Color scaffoldBackground,
    required Color mutedText,
  }) {
    final baseText = ThemeData(brightness: scheme.brightness).textTheme;
    final textTheme = baseText.copyWith(
      headlineLarge: baseText.headlineLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(color: scheme.onSurface, height: 1.5),
      bodyMedium: baseText.bodyMedium?.copyWith(color: mutedText, height: 1.5),
      labelLarge: baseText.labelLarge?.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: mutedText,
      ),
    );

    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: scheme.outline, width: _borderWidth),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerColor: scheme.outline,
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.onSurface,
        selectionColor: scheme.onSurface.withValues(alpha: 0.2),
        selectionHandleColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: scheme.onSurface, width: _borderWidth),
        ),
        errorBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: _borderWidth),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(color: mutedText),
        floatingLabelStyle: TextStyle(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline, width: _borderWidth),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mutedText,
          textStyle: textTheme.labelLarge,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );
  }
}
