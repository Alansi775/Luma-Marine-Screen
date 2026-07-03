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
      title: 'Diagnostics',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _DiagnosticRow(label: 'Device ID', value: deviceId.when(
            data: (id) => id,
            loading: () => 'resolving…',
            error: (e, _) => 'unavailable',
          )),
          _DiagnosticRow(
            label: 'Firebase',
            value: firebaseAvailable ? 'connected' : 'offline',
          ),
          _DiagnosticRow(
            label: 'Sync engine',
            value: syncService.isAvailable ? 'available' : 'unavailable',
          ),
          _DiagnosticRow(label: 'Data directory', value: directories.appDataDirectoryPath),
          _DiagnosticRow(label: 'Videos directory', value: directories.videosDirectoryPath),
          _DiagnosticRow(label: 'Logs directory', value: directories.logsDirectoryPath),
          _DiagnosticRow(
            label: 'Storage ready',
            value: directories.isReady ? 'yes' : 'no (using fallback or unwritable)',
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
