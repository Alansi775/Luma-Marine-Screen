import 'package:firebase_core/firebase_core.dart';

import '../logging/app_logger.dart';
import 'firebase_options.dart';

/// Best-effort Firebase initialization.
///
/// Firebase is a sync input, never a hard dependency: playback must work
/// with zero connectivity and zero valid Firebase config. This must never
/// throw or block `runApp` — a slow or failing init just means the app
/// starts in offline-only mode, exactly like a real network outage.
class FirebaseBootstrapper {
  FirebaseBootstrapper(this._logger);

  final AppLogger _logger;

  static const _initTimeout = Duration(seconds: 5);

  /// Returns whether Firebase is available for this run. Never throws.
  Future<bool> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_initTimeout);
      _logger.info('Firebase initialized');
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Firebase unavailable, continuing in offline-only mode',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
