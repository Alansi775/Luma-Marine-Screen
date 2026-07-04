import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sync/presentation/providers/sync_providers.dart';

/// Small, non-blocking pill shown on the signage screen (never the admin
/// screens) whenever the sync engine is actively downloading or removing
/// a video — so a viewer sees "something's happening" rather than the
/// playlist silently changing, without covering the video underneath.
/// Renders nothing when idle.
class SyncActivityBadge extends ConsumerWidget {
  const SyncActivityBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(syncActivityProvider).value;
    if (activity == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const label = 'Updating playlist…';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: activity.progress,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
