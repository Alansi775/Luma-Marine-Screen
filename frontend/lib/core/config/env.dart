import 'dart:io';

/// Typed access to environment variables that can override default
/// runtime behavior on the deployed device (e.g. via a systemd unit's
/// `Environment=` directives) without changing code.
class Env {
  Env._();

  /// Overrides where the app stores its data (videos, database, logs).
  /// Falls back to a platform-appropriate default when unset.
  static String? get appDataDirOverride => _read('LUMA_APP_DATA_DIR');

  static String? _read(String key) {
    final value = Platform.environment[key];
    return (value == null || value.isEmpty) ? null : value;
  }
}
