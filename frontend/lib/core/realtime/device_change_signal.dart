import 'package:firebase_database/firebase_database.dart';

/// Fires a lightweight, non-data-bearing signal whenever the admin makes
/// a change that could affect what's currently playing (upload, delete,
/// reorder, move, rename, set-active-playlist).
///
/// Realtime Database — not Firestore — is used purely as a push
/// notification channel here: Firestore's REST API (what the Linux sync
/// engine uses, since the native SDK doesn't exist there) has no
/// realtime "listen" without gRPC, but Realtime Database exposes a
/// plain-HTTP Server-Sent-Events stream that a device can hold open with
/// zero polling and react to within about a second. Firestore remains
/// the source of truth for the actual playlist/video data — this path
/// stores nothing but a timestamp.
class DeviceChangeSignal {
  DeviceChangeSignal(this._database);

  final FirebaseDatabase _database;

  Future<void> notifyChanged(String deviceId) {
    return _database.ref('deviceSignals/$deviceId/updatedAt').set(ServerValue.timestamp);
  }
}
