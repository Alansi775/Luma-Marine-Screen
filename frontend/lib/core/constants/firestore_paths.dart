/// Firestore path builders, kept in one place so the collection layout
/// (see backend/schema/firestore-schema.md) only needs to change here.
class FirestorePaths {
  FirestorePaths._();

  static const videos = 'videos';

  static String device(String deviceId) => 'devices/$deviceId';

  static String devicePlaylist(String deviceId) => '${device(deviceId)}/playlist';

  static String deviceHealth(String deviceId) => '${device(deviceId)}/health';

  static String deviceCommands(String deviceId) => '${device(deviceId)}/commands';
}
