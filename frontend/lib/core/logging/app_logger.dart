/// App-wide logging seam.
///
/// A device that runs unattended for months needs an on-disk trail —
/// this is also the foundation the future "remote diagnostics" feature
/// will read from, so all app code should log through this instead of
/// `print`. Takes a plain path string (not `dart:io` `Directory`) so this
/// interface stays compilable on Flutter Web, where file logging isn't
/// meaningful anyway — see `console_logger.dart`.
abstract class AppLogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message);
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// Upgrades a console-only logger to also persist to [logDirectoryPath].
  /// Called once directories are available, after startup has already
  /// begun logging to the console.
  Future<void> attachFileSink(String logDirectoryPath);
}
