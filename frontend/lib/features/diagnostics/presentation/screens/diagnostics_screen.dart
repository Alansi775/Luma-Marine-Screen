import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/device_identity_provider.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../sync/presentation/providers/sync_providers.dart';

/// A minimal read-only diagnostics view. Deliberately thin — it exists
/// to prove that "remote diagnostics" (a named future requirement) is an
/// additive feature on top of this foundation, not a rewrite: everything
/// shown here already exists behind a provider.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directories = ref.watch(appDirectoriesProvider);
    final firebaseAvailable = ref.watch(firebaseAvailableProvider);
    final deviceId = ref.watch(deviceIdentityProvider);
    final syncService = ref.watch(syncServiceProvider);

    return AppScaffold(
      title: 'Tanılama',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          _DiagnosticRow(label: 'Cihaz Kimliği', value: deviceId.when(
            data: (id) => id,
            loading: () => 'çözümleniyor…',
            error: (e, _) => 'kullanılamıyor',
          )),
          _DiagnosticRow(
            label: 'Firebase',
            value: firebaseAvailable ? 'bağlı' : 'çevrimdışı',
          ),
          _DiagnosticRow(
            label: 'Senkronizasyon motoru',
            value: syncService.isAvailable ? 'kullanılabilir' : 'kullanılamıyor',
          ),
          _DiagnosticRow(label: 'Veri dizini', value: directories.appDataDirectoryPath),
          _DiagnosticRow(label: 'Video dizini', value: directories.videosDirectoryPath),
          _DiagnosticRow(label: 'Günlük dizini', value: directories.logsDirectoryPath),
          _DiagnosticRow(
            label: 'Depolama hazır',
            value: directories.isReady ? 'evet' : 'hayır (yedek kullanılıyor veya yazılamıyor)',
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
