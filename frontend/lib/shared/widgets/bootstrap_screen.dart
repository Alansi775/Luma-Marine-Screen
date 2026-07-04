import 'package:flutter/material.dart';

import 'brand_logo.dart';

/// The real "splash screen" for this app: flutter-pi boots straight into
/// the Flutter engine with no OS-level splash surface to hook into
/// before Dart runs, so this in-app screen is what's shown while
/// `bootstrap()` finishes its async setup, and whenever the playlist is
/// empty. Deliberately static — no spinner, no animation.
///
/// Purely presentational — the hidden long-press-to-admin gesture lives
/// on `NowPlayingScreen` (which hosts this widget), not here, so it stays
/// reachable during video playback too, not just on this idle state.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: BrandLogo(size: 220)),
    );
  }
}
