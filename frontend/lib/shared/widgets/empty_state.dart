import 'package:flutter/material.dart';

/// Muted icon + message, no animation — used wherever a feature has
/// nothing to show yet (e.g. an empty playlist before the first sync).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
