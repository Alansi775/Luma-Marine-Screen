/// Firestore path builders, kept in one place so the collection layout
/// (see backend/schema/firestore-schema.md) only needs to change here.
class FirestorePaths {
  FirestorePaths._();

  static const videos = 'videos';

  /// Device registration doesn't exist yet (see backend/schema/firestore-schema.md's
  /// "documented, not yet created" section), so every install currently
  /// targets this single well-known device id rather than a generated one.
  static const defaultDeviceId = 'primary-screen';

  static String device(String deviceId) => 'devices/$deviceId';

  static String devicePlaylist(String deviceId) => '${device(deviceId)}/playlist';

  static String deviceHealth(String deviceId) => '${device(deviceId)}/health';

  static String deviceCommands(String deviceId) => '${device(deviceId)}/commands';
}
