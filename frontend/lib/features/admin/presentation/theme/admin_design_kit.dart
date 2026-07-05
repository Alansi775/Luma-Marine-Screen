import 'dart:ui';

import 'package:flutter/material.dart';

/// The admin panel's own design language — deliberately unlike the
/// signage screen's *scheduled* light/dark theme (see
/// `theme/app_theme.dart`, which switches on a 06:00/18:00 wall-clock
/// schedule because it's mimicking ambient light on a yacht). The admin
/// panel instead follows the *system's* light/dark preference, like any
/// normal control-surface app — see [AdminColors.of].
///
/// Every card relies on real glassmorphism (`BackdropFilter` blur over a
/// tinted, semi-opaque fill) rather than a flat box, but the fill is
/// deliberately opaque *enough* that cards stay clearly readable against
/// the page background in both themes — pure "glass" transparency reads
/// as "everything is the same shade of dark" once the backdrop is also
/// dark, which is the opposite of what a control surface needs.
@immutable
class AdminColors {
  const AdminColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textDim,
    required this.accent,
    required this.danger,
    required this.hairline,
    required this.hairlineBright,
    required this.cardOpacity,
    required this.brightness,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textDim;
  final Color accent;
  final Color danger;
  final Color hairline;
  final Color hairlineBright;
  final double cardOpacity;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  static const dark = AdminColors(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceRaised: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textDim: Color(0xFF98989F),
    accent: Color(0xFF4DA3FF),
    danger: Color(0xFFFF6961),
    hairline: Color(0x24FFFFFF),
    hairlineBright: Color(0x40FFFFFF),
    cardOpacity: 0.82,
    brightness: Brightness.dark,
  );

  static const light = AdminColors(
    background: Color(0xFFEFEFF3),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1C1C1E),
    textDim: Color(0xFF6C6C70),
    accent: Color(0xFF0668E1),
    danger: Color(0xFFD70015),
    hairline: Color(0x1F000000),
    hairlineBright: Color(0x33000000),
    cardOpacity: 0.92,
    brightness: Brightness.light,
  );

  /// Resolves against the *system's* theme preference, not the signage
  /// side's wall-clock schedule.
  static AdminColors of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark ? dark : light;

  /// A full [ThemeData] built from this palette. The signage side's
  /// `MaterialApp.router` theme switches between `AppTheme.light`/`.dark`
  /// on a *wall-clock* schedule (see `ThemeSchedule`) — completely
  /// independent of [AdminColors], which follows the system's
  /// light/dark preference instead. Without this wrapper, every admin
  /// screen mixes two unrelated theme sources: this palette for whatever
  /// I explicitly styled, and whichever signage theme happens to be
  /// active for anything left to Material's defaults (dialog surfaces,
  /// splash/hover colors, text selection) — which is exactly why dialogs
  /// were flashing bright white at certain times of day. Every admin
  /// `Scaffold` wraps its subtree in `Theme(data: AdminColors.of(context)
  /// .themeData, ...)` to make this palette authoritative for the whole
  /// subtree, not just the widgets that read it directly.
  ThemeData get themeData {
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: hairlineBright, width: 0.8),
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      cardColor: surface,
      dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        onSurface: textPrimary,
        primary: accent,
        onPrimary: isDark ? Colors.black : Colors.white,
        error: danger,
      ),
      textTheme: base.textTheme.apply(bodyColor: textPrimary, displayColor: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: hairline,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: accent, width: 1.2)),
        labelStyle: TextStyle(color: textDim),
        floatingLabelStyle: TextStyle(color: accent),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: TextStyle(color: textPrimary),
      ),
    );
  }
}

/// Wraps a subtree so this palette — not whichever theme the signage
/// side's wall-clock schedule happens to have active — is authoritative
/// for every Material default within. Every admin screen's `build`
/// starts with this.
class AdminTheme extends StatelessWidget {
  const AdminTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(data: AdminColors.of(context).themeData, child: child);
  }
}

/// Caps content width on the web so wide viewports don't stretch cards
/// into an illegible single row — every admin screen wraps its body in
/// this, and paints the themed page background behind it.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// Deprecated alias kept only so screens mid-refactor still compile;
/// prefer [AdminScaffold] which paints the correct themed background.
class AdminPageWidth extends StatelessWidget {
  const AdminPageWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: child),
    );
  }
}

/// A frosted-glass panel: backdrop blur behind a themed, mostly-opaque
/// fill (see the class doc on [AdminColors] for why it's not more
/// transparent) with a hairline border. Every card, dialog, and dropdown
/// in the admin UI is built from this.
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
    final c = AdminColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (elevated ? c.surfaceRaised : c.surface).withValues(alpha: c.cardOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? c.hairline, width: 0.8),
            boxShadow: c.isDark
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A tactical pill button. Avoids large saturated fills — `filled` reads
/// as a soft-glow accent chip (low-opacity tint + glowing hairline +
/// colored text), not a solid block. `danger` swaps the accent for a
/// muted crimson glow instead of a bright red slab.
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
    final c = AdminColors.of(context);
    final tint = widget.color ?? (widget.danger ? c.danger : c.accent);
    final isSoftFill = widget.filled;

    final background = isSoftFill ? tint.withValues(alpha: _hovered ? 0.22 : 0.14) : Colors.transparent;
    final border = isSoftFill ? tint.withValues(alpha: _hovered ? 0.7 : 0.45) : c.hairlineBright;
    final foreground = isSoftFill ? tint : c.textPrimary.withValues(alpha: _hovered ? 1 : 0.85);

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
                    style: TextStyle(color: foreground, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.6),
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

/// A themed text field for every rename/create dialog and the login
/// form. Deliberately *not* a full pill and *not* pure black in dark
/// mode — a solid-black fill sitting inside an already-dark glass panel
/// has almost no contrast and reads as a hole in the layout rather than
/// an input. `surfaceRaised` gives it a visible, comfortable-contrast
/// surface in both themes.
class AdminTextField extends StatelessWidget {
  const AdminTextField({
    super.key,
    required this.controller,
    this.label,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    // A single InputDecoration owns the shape (fill + border) — no
    // wrapping Container/DecoratedBox. Two independent shapes (an outer
    // rounded container plus TextField's own decoration, which paints a
    // sharp-cornered highlight/fill when given `InputBorder.none`) is
    // exactly what produced the "square peeking out of a rounded
    // rectangle" glitch; one shape can't visually conflict with itself.
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c.hairlineBright, width: 0.8),
    );
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofocus: autofocus,
      autocorrect: false,
      onSubmitted: onSubmitted,
      style: TextStyle(color: c.textPrimary, fontSize: 15),
      cursorColor: c.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textDim),
        filled: true,
        fillColor: c.surfaceRaised,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: c.accent, width: 1.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// A small animated "now playing" indicator — three bars pulsing at
/// independent phases, the same visual language real media apps
/// (Spotify, Apple Music) use for "this is the one playing" — instead of
/// a pulsing-dot-plus-caption badge.
class LiveEqualizer extends StatefulWidget {
  const LiveEqualizer({super.key, this.color, this.size = 14});

  final Color? color;
  final double size;

  @override
  State<LiveEqualizer> createState() => _LiveEqualizerState();
}

class _LiveEqualizerState extends State<LiveEqualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    final color = widget.color ?? c.accent;
    const phases = [0.0, 0.35, 0.7];
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final phase in phases)
                _EqualizerBar(
                  // A bouncing 0..1..0 triangle wave per bar, phase-shifted
                  // so the three don't move in lockstep.
                  height: widget.size * (0.3 + 0.7 * (1 - (2 * (((_controller.value + phase) % 1.0) - 0.5)).abs())),
                  color: color,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EqualizerBar extends StatelessWidget {
  const _EqualizerBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height.clamp(2, double.infinity),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
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
    final c = AdminColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        color: color ?? c.textDim,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// A single row in a [GlassMenuButton]'s dropdown.
class GlassMenuItem {
  const GlassMenuItem({required this.label, required this.onTap, this.icon, this.danger = false});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool danger;
}

/// Replacement for [PopupMenuButton]: Flutter's default popup can't be
/// reskinned into real glass (no control over its Material surface), so
/// this builds the dropdown itself via [OverlayPortal] — a compact glass
/// card with icon rows and per-row hover states, anchored below the
/// trigger.
class GlassMenuButton extends StatefulWidget {
  const GlassMenuButton({super.key, required this.items, this.icon = Icons.more_horiz_rounded});

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
    final c = AdminColors.of(context);
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
                offset: const Offset(0, 8),
                child: _GlassMenuSurface(items: widget.items, onSelected: _overlayController.hide),
              ),
            ],
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surfaceRaised.withValues(alpha: c.cardOpacity * 0.6),
            border: Border.all(color: c.hairline),
          ),
          child: IconButton(
            onPressed: _overlayController.toggle,
            icon: Icon(widget.icon, color: c.textDim, size: 18),
            splashRadius: 20,
          ),
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
    final c = AdminColors.of(context);
    return Align(
      alignment: Alignment.topRight,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: 196,
              decoration: BoxDecoration(
                color: c.surfaceRaised.withValues(alpha: c.cardOpacity),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.hairlineBright, width: 0.8),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: c.isDark ? 0.4 : 0.12), blurRadius: 24)],
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) Divider(height: 1, thickness: 0.6, color: c.hairline, indent: 14, endIndent: 14),
                    _GlassMenuRow(item: items[i], onSelected: onSelected),
                  ],
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
    final c = AdminColors.of(context);
    final color = widget.item.danger ? c.danger : c.textPrimary;
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
          color: _hovered ? c.hairline : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 16, color: color.withValues(alpha: 0.85)),
                const SizedBox(width: 12),
              ],
              Text(widget.item.label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The slow-pulsing ring marking whichever playlist is currently on air.
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
    final c = AdminColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = 0.5 + (_controller.value * 0.5);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: c.accent.withValues(alpha: 0.35 * t), width: 1),
            boxShadow: [
              BoxShadow(color: c.accent.withValues(alpha: 0.2 * t), blurRadius: 28, spreadRadius: -6),
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
/// ring rather than a linear bar.
class LiquidUploadRing extends StatelessWidget {
  const LiquidUploadRing({super.key, required this.progress, this.size = 56});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
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
              backgroundColor: c.hairline,
              valueColor: AlwaysStoppedAnimation(c.accent),
            ),
          ),
          if (pct != null) MonoLabel('$pct%', color: c.textPrimary, fontSize: 13),
        ],
      ),
    );
  }
}

/// Full-viewport edge glow shown while an upload is in flight.
class UploadEdgeGlow extends StatelessWidget {
  const UploadEdgeGlow({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = AdminColors.of(context);
    final intensity = 0.12 + (progress.clamp(0, 1) * 0.45);
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: c.accent.withValues(alpha: intensity), width: 1.5),
            boxShadow: [
              BoxShadow(color: c.accent.withValues(alpha: intensity * 0.5), blurRadius: 36, spreadRadius: -8),
            ],
          ),
        ),
      ),
    );
  }
}
