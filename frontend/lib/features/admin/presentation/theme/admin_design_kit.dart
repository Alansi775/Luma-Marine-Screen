import 'dart:ui';
import 'package:flutter/material.dart';

class AdminPalette {
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceRaised = Color(0xFF141414);
  static const Color accent = Color(0xFF3B82F6); // Luma Blue
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF8E8E93);
  static const Color danger = Color(0xFFFF3B30);
  static const Color hairline = Color(0x0DFFFFFF); // 0.05 opacity white
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final bool elevated;
  final Color? borderColor;

  const GlassPanel({super.key, required this.child, this.borderRadius = 24, this.padding, this.elevated = false, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: elevated ? AdminPalette.surfaceRaised : AdminPalette.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AdminPalette.hairline, width: 0.8),
      ),
      padding: padding,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class AdminPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool filled;
  final Color? color;

  const AdminPillButton({super.key, required this.label, required this.onPressed, this.icon, this.filled = true, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AdminPalette.accent;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? effectiveColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: filled ? null : Border.all(color: AdminPalette.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: filled ? Colors.black : effectiveColor), const SizedBox(width: 8)],
            Text(label.toUpperCase(), style: TextStyle(color: filled ? Colors.black : effectiveColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

class MonoLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;
  const MonoLabel(this.text, {super.key, this.color, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontFamily: 'monospace', color: color ?? AdminPalette.textDim, fontSize: fontSize, letterSpacing: -0.5));
  }
}

class OnAirGlow extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  const OnAirGlow({super.key, required this.child, required this.borderRadius});

  @override
  State<OnAirGlow> createState() => _OnAirGlowState();
}

class _OnAirGlowState extends State<OnAirGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(color: AdminPalette.accent.withOpacity(0.15 * _controller.value), blurRadius: 25, spreadRadius: 2),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class LiquidUploadRing extends StatelessWidget {
  final double progress;
  final double size;
  const LiquidUploadRing({super.key, required this.progress, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _LiquidPainter(progress)),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double progress;
  _LiquidPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paintBase = Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawCircle(center, radius, paintBase);

    final paintLiquid = Paint()..color = AdminPalette.accent..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.2831 * progress, false, paintLiquid);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class UploadEdgeGlow extends StatelessWidget {
  final double progress;
  const UploadEdgeGlow({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AdminPalette.accent.withOpacity(0.4 * progress), width: 4),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}

class AdminPageWidth extends StatelessWidget {
  final Widget child;
  const AdminPageWidth({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: child));
  }
}

