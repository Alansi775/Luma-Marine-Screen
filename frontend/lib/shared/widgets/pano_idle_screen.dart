import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand_logo.dart';

/// Premium idle/standby screen shown whenever the signage side has
/// nothing to play — an empty playlist, a sync error, or the brief gap
/// between videos. Built as a single `CustomPainter` driven by one
/// `AnimationController` rather than a heavier effects library (Rive/
/// Lottie): this device has a real, hardware-confirmed video-decode
/// ceiling (see `playlist_player_controller.dart`), so this stays
/// intentionally cheap — three soft radial gradients drifting slowly,
/// not per-pixel shader work — and never competes with video decode
/// for the GPU, since it's only ever on screen when nothing is decoding.
class PanoIdleScreen extends StatefulWidget {
  const PanoIdleScreen({super.key, this.statusMessage});

  /// Small, low-key diagnostic text shown beneath the caption (e.g. "sync
  /// error, retrying"). Null shows nothing extra — the clean standby
  /// look. Deliberately never shows a raw exception here — this is a
  /// customer-facing premium display, not a debug console; the real
  /// error is already logged via AppLogger by whoever detected it.
  final String? statusMessage;

  @override
  State<PanoIdleScreen> createState() => _PanoIdleScreenState();
}

class _PanoIdleScreenState extends State<PanoIdleScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7);
    final ink = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        color: background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AuraPainter(t: _controller.value, isDark: isDark),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final phase = math.sin(_controller.value * 2 * math.pi);
                      return Opacity(
                        opacity: 0.85 + 0.15 * phase,
                        child: Transform.scale(scale: 0.94 + 0.06 * phase, child: child),
                      );
                    },
                    child: const BrandLogo(size: 160),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'P A N O   S Y S T E M S',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 6,
                      color: ink.withValues(alpha: 0.38),
                    ),
                  ),
                  if (widget.statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.24)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({required this.t, required this.isDark});

  final double t;
  final bool isDark;

  static const _darkBlobs = [Color(0xFF1A1A22), Color(0xFF14141C), Color(0xFF101018)];
  static const _lightBlobs = [Color(0xFFEDEDF2), Color(0xFFE6E8ED), Color(0xFFEFEFEF)];

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = isDark ? _darkBlobs : _lightBlobs;
    final w = size.width;
    final h = size.height;
    final angle = t * 2 * math.pi;

    // Three soft blobs on independent, slow paths at different speeds so
    // the motion reads as organic rather than a mechanically obvious loop,
    // even though it repeats exactly every [AnimationController.duration].
    _paintBlob(
      canvas,
      blobs[0],
      center: Offset(w * (0.3 + 0.12 * math.sin(angle)), h * (0.35 + 0.10 * math.cos(angle * 0.8))),
      radius: w * 0.5,
    );
    _paintBlob(
      canvas,
      blobs[1],
      center: Offset(w * (0.7 + 0.10 * math.cos(angle * 0.6)), h * (0.65 + 0.12 * math.sin(angle * 0.7))),
      radius: w * 0.45,
    );
    _paintBlob(
      canvas,
      blobs[2],
      center: Offset(w * (0.5 + 0.08 * math.sin(angle * 1.3)), h * (0.5 + 0.08 * math.cos(angle * 1.1))),
      radius: w * 0.35,
    );
  }

  void _paintBlob(Canvas canvas, Color color, {required Offset center, required double radius}) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: isDark ? 0.55 : 0.7), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => oldDelegate.t != t || oldDelegate.isDark != isDark;
}
