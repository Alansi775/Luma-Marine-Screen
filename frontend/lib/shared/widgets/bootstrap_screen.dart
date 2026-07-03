import 'package:flutter/material.dart';

/// The real "splash screen" for this app: flutter-pi boots straight into
/// the Flutter engine with no OS-level splash surface to hook into
/// before Dart runs, so this in-app screen is what's shown while
/// `bootstrap()` finishes its async setup. Deliberately static — no
/// spinner, no animation.
///
/// Uses whichever logo variant reads correctly against the current
/// theme's background (dark wordmark on the light background, light
/// wordmark on the dark background) rather than a single asset.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/icon/LUMA_MARINE_logo_white.png'
        : 'assets/icon/LUMA_MARINE_logo_black.png';

    return Scaffold(
      body: Center(
        child: Image.asset(
          logoAsset,
          width: 220,
          height: 220,
          errorBuilder: (_, _, _) => const SizedBox(width: 220, height: 220),
        ),
      ),
    );
  }
}
