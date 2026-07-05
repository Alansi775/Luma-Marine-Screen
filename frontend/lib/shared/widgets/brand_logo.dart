import 'package:flutter/material.dart';

/// The PANO wordmark, using whichever transparent-background
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
        ? 'assets/icon/pano_white.png'
        : 'assets/icon/pano_black.png';

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, error, stackTrace) {
        // Silently swallowing this used to hide a real failure —
        // wherever the logo isn't rendering, this line in the log is
        // what to look for.
        debugPrint('BrandLogo failed to load $asset: $error');
        return SizedBox(width: size, height: size);
      },
    );
  }
}
