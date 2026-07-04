import 'package:flutter/material.dart';

/// The Luma Marine wordmark, using whichever transparent-background
/// variant reads correctly against the current theme (dark wordmark on
/// light backgrounds, light wordmark on dark). Shared by the splash
/// screen and the admin-facing screens so the brand reads consistently
/// everywhere it appears.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/icon/LUMA_MARINE_logo_white.png'
        : 'assets/icon/LUMA_MARINE_logo_black.png';

    return Image.asset(
      asset,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
    );
  }
}
