import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Reads the persisted device id from `<appDataDirectoryPath>/device_id`,
/// generating and persisting a new one on first boot.
Future<String> resolveDeviceId(String appDataDirectoryPath) async {
  final idFile = File(p.join(appDataDirectoryPath, 'device_id'));

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
