import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/core_providers.dart';
import 'device_identity_resolver.dart';

part 'device_identity_provider.g.dart';

/// A UUID identifying this physical device, persisted to disk on native
/// platforms (regenerated per-session on Flutter Web — see
/// `device_identity_resolver.dart`). This is the key the future sync
/// engine will use for device-scoped Firestore paths
/// (`devices/{deviceId}/...`) — see backend/schema/firestore-schema.md —
/// and what multi-display/device registration will build on later.
@Riverpod(keepAlive: true)
Future<String> deviceIdentity(Ref ref) async {
  final directories = ref.watch(appDirectoriesProvider);
  return resolveDeviceId(directories.appDataDirectoryPath);
}
