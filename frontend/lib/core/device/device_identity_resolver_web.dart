import 'package:uuid/uuid.dart';

/// Generates a fresh device id for this browser session. Web is only
/// used for UI preview during development — there's no real device to
/// register, so persistence across reloads isn't needed.
Future<String> resolveDeviceId(String appDataDirectoryPath) async {
  return const Uuid().v4();
}
