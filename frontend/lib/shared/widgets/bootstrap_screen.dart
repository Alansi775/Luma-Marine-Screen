import 'package:flutter/material.dart';

/// The real "splash screen" for this app: flutter-pi boots straight into
/// the Flutter engine with no OS-level splash surface to hook into
/// before Dart runs, so this in-app screen is what's shown while
/// `bootstrap()` finishes its async setup. Deliberately static — no
/// spinner, no animation.
class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/icon/logo.png',
          width: 160,
          height: 160,
          errorBuilder: (_, _, _) => const SizedBox(width: 160, height: 160),
        ),
      ),
    );
  }
}
