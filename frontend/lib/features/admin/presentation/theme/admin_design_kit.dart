import 'dart:ui';

import 'package:flutter/material.dart';

/// The admin panel's own design language — deliberately unlike the
/// signage screen's adaptive light/dark theme (see `theme/app_theme.dart`).
/// Target look: a tactical/industrial control surface (DJI, professional
/// broadcast tooling) — restrained, low-saturation accents used as glows
/// and hairlines, never large flat saturated fills. Every "premium"
/// surface here relies on real glassmorphism (`BackdropFilter` blur over
/// a low-opacity fill), not just a solid dark grey box.
class AdminPalette {
  AdminPalette._();

  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceRaised = Color(0xFF141414);
  static const Color accent = Color(0xFF3B82F6);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF8E8E93);
  static const Color danger = Color(0xFFFF3B30);
  static const Color hairline = Color(0x0DFFFFFF); // white @ 5%
  static const Color hairlineBright = Color(0x26FFFFFF); // white @ 15%
}

/// Caps content width on the web so wide viewports don't stretch cards
/// into an illegible single row — every admin screen wraps its body in
/// this.
class AdminPageWidth extends StatelessWidget {
  const AdminPageWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child,
      ),
    );
  }
}

/// A real frosted-glass panel: heavy backdrop blur behind a *low-opacity*
/// fill, so whatever's behind it (the pure black background, other
/// panels) actually shows through softened — that translucency is what
/// reads as "glass" instead of "flat grey box". Every card, dialog, and
/// dropdown in the admin UI is built from this.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.elevated = false,
    this.borderColor,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (elevated ? AdminPalette.surfaceRaised : AdminPalette.surface).withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? AdminPalette.hairline, width: 0.6),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A tactical pill button. Deliberately avoids large saturated fills —
/// `filled` reads as a *soft-glow* accent chip (low-opacity tint +
/// glowing hairline + colored text), not a solid block. `danger` swaps
/// the accent for a muted crimson glow instead of a bright red slab.
class AdminPillButton extends StatefulWidget {
  const AdminPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.color,
    this.danger = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool filled;
  final Color? color;
  final bool danger;

  @override
  State<AdminPillButton> createState() => _AdminPillButtonState();
}

class _AdminPillButtonState extends State<AdminPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.color ?? (widget.danger ? AdminPalette.danger : AdminPalette.accent);
    final isSoftFill = widget.filled;

    final background = isSoftFill ? tint.withValues(alpha: _hovered ? 0.20 : 0.13) : Colors.transparent;
    final border = isSoftFill ? tint.withValues(alpha: _hovered ? 0.65 : 0.4) : AdminPalette.hairlineBright;
    final foreground = isSoftFill ? tint : AdminPalette.textPrimary.withValues(alpha: _hovered ? 1 : 0.85);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 0.8),
          boxShadow: isSoftFill && _hovered
              ? [BoxShadow(color: tint.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: -2)]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onPressed,
            hoverColor: Colors.transparent,
            splashColor: tint.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 15, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Monospaced technical readout — durations, counters, timestamps — kept
/// visually distinct from the humanist type used for names/labels.
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color, this.fontSize = 13});

  final String text;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        color: color ?? AdminPalette.textDim,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// A single row in a [GlassMenuButton]'s dropdown.
class GlassMenuItem {
  const GlassMenuItem({required this.label, required this.onTap, this.danger = false});

  final String label;
  final VoidCallback onTap;
  final bool danger;
}

/// Full replacement for [PopupMenuButton]: Flutter's default popup can't
/// be reskinned into real glass (no control over its Material surface),
/// so this builds the dropdown itself via [OverlayPortal] — a genuine
/// blurred glass panel with hairline borders and per-row hover states,
/// anchored to the trigger icon.
class GlassMenuButton extends StatefulWidget {
  const GlassMenuButton({super.key, required this.items, this.icon = Icons.more_vert_rounded});

  final List<GlassMenuItem> items;
  final IconData icon;

  @override
  State<GlassMenuButton> createState() => _GlassMenuButtonState();
}

class _GlassMenuButtonState extends State<GlassMenuButton> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _overlayController.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 6),
                child: _GlassMenuSurface(
                  items: widget.items,
                  onSelected: _overlayController.hide,
                ),
              ),
            ],
          );
        },
        child: IconButton(
          onPressed: _overlayController.toggle,
          icon: Icon(widget.icon, color: AdminPalette.textDim, size: 20),
          splashRadius: 20,
        ),
      ),
    );
  }
}

class _GlassMenuSurface extends StatelessWidget {
  const _GlassMenuSurface({required this.items, required this.onSelected});

  final List<GlassMenuItem> items;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: Container(
              width: 208,
              decoration: BoxDecoration(
                color: AdminPalette.surfaceRaised.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminPalette.hairlineBright, width: 0.6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items) _GlassMenuRow(item: item, onSelected: onSelected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMenuRow extends StatefulWidget {
  const _GlassMenuRow({required this.item, required this.onSelected});

  final GlassMenuItem item;
  final VoidCallback onSelected;

  @override
  State<_GlassMenuRow> createState() => _GlassMenuRowState();
}

class _GlassMenuRowState extends State<_GlassMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.danger ? AdminPalette.danger : AdminPalette.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onSelected();
          widget.item.onTap();
        },
        child: Container(
          width: double.infinity,
          color: _hovered ? AdminPalette.hairlineBright : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Text(
            widget.item.label,
            style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// The slow-pulsing glow marking whichever playlist is currently on air —
/// a soft accent-colored halo plus a thin glowing ring, not a filled
/// card.
class OnAirGlow extends StatefulWidget {
  const OnAirGlow({super.key, required this.child, required this.borderRadius});

  final Widget child;
  final double borderRadius;

  @override
  State<OnAirGlow> createState() => _OnAirGlowState();
}

class _OnAirGlowState extends State<OnAirGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = 0.5 + (_controller.value * 0.5);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: AdminPalette.accent.withValues(alpha: 0.25 * t), width: 0.8),
            boxShadow: [
              BoxShadow(color: AdminPalette.accent.withValues(alpha: 0.18 * t), blurRadius: 28, spreadRadius: -6),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Large glassy circular progress for the upload flow — a "liquid fill"
/// ring rather than a linear bar. Shows a percentage readout in the
/// center when `progress` is known, an indeterminate sweep otherwise.
class LiquidUploadRing extends StatelessWidget {
  const LiquidUploadRing({super.key, required this.progress, this.size = 56});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = progress > 0 ? (progress * 100).clamp(0, 100).toStringAsFixed(0) : null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2.5,
              backgroundColor: AdminPalette.hairline,
              valueColor: const AlwaysStoppedAnimation(AdminPalette.accent),
            ),
          ),
          if (pct != null) MonoLabel('$pct%', color: AdminPalette.textPrimary, fontSize: 13),
        ],
      ),
    );
  }
}

/// Full-viewport edge glow shown while an upload is in flight — a thin,
/// intensifying halo hugging the screen's border instead of a
/// conventional top-of-screen progress bar.
class UploadEdgeGlow extends StatelessWidget {
  const UploadEdgeGlow({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final intensity = 0.12 + (progress.clamp(0, 1) * 0.45);
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AdminPalette.accent.withValues(alpha: intensity), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AdminPalette.accent.withValues(alpha: intensity * 0.5),
                blurRadius: 36,
                spreadRadius: -8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
