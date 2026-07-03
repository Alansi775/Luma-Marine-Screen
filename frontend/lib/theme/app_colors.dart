import 'package:flutter/widgets.dart';

/// Grayscale palette for the minimal/premium/industrial design language.
/// Accent use is deliberately rare — see [marineAccent].
class AppColors {
  AppColors._();

  static const nearBlack = Color(0xFF0E0E0E);
  static const grey900 = Color(0xFF1A1A1A);
  static const grey700 = Color(0xFF3A3A3A);
  static const grey500 = Color(0xFF757575);
  static const grey300 = Color(0xFFBDBDBD);
  static const grey200 = Color(0xFFE0E0E0);
  static const grey100 = Color(0xFFF0F0F0);
  static const offWhite = Color(0xFFFAFAFA);
  static const white = Color(0xFFFFFFFF);

  /// Sparing use only: active/selection indicators, never large surfaces.
  static const marineAccent = Color(0xFF5C6B73);
}
