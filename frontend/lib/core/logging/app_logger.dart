import 'dart:io';

/// App-wide logging seam.
///
/// A device that runs unattended for months needs an on-disk trail —
/// this is also the foundation the future "remote diagnostics" feature
/// will read from, so all app code should log through this instead of
/// `print`.
abstract class AppLogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message);
  void warning(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// Upgrades a console-only logger to also persist to [logDirectory].
  /// Called once directories are available, after startup has already
  /// begun logging to the console.
  Future<void> attachFileSink(Directory logDirectory);
}
