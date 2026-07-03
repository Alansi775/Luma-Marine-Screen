import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../di/core_providers.dart';

part 'device_identity_provider.g.dart';

/// A UUID generated on first boot and persisted to disk, identifying this
/// physical device. This is the key the future sync engine will use for
/// device-scoped Firestore paths (`devices/{deviceId}/...`) — see
/// backend/schema/firestore-schema.md — and what multi-display/device
/// registration will build on later.
@Riverpod(keepAlive: true)
Future<String> deviceIdentity(Ref ref) async {
  final directories = ref.watch(appDirectoriesProvider);
  final idFile = File(p.join(directories.appDataDirectory.path, 'device_id'));

  if (await idFile.exists()) {
    final existing = (await idFile.readAsString()).trim();
    if (existing.isNotEmpty) return existing;
  }

  final id = const Uuid().v4();
  try {
    await idFile.writeAsString(id);
  } on FileSystemException {
    // Non-persistent id for this session only; better than crashing.
  }
  return id;
}
