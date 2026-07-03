import 'package:logging/logging.dart' as logging;

import 'app_logger.dart';

/// Console-only logger for Flutter Web.
///
/// Web is used only for fast UI preview during development — there's no
/// meaningful place to persist a log file in a browser tab, and
/// "remote diagnostics" (the reason the native logger writes to disk)
/// isn't a concern for a preview build. [attachFileSink] is a no-op.
class PlatformLogger implements AppLogger {
  PlatformLogger.consoleOnly() : _logger = logging.Logger('luma_marine') {
    logging.Logger.root.level = logging.Level.ALL;
    logging.Logger.root.onRecord.listen(_handleRecord);
  }

  final logging.Logger _logger;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.fine(message, error, stackTrace);

  @override
  void info(String message) => _logger.info(message);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.warning(message, error, stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.severe(message, error, stackTrace);

  @override
  Future<void> attachFileSink(String logDirectoryPath) async {}

  void _handleRecord(logging.LogRecord record) {
    final line = '${record.time.toIso8601String()} '
        '[${record.level.name}] ${record.message}'
        '${record.error != null ? ' | error: ${record.error}' : ''}';
    // ignore: avoid_print
    print(line);
  }
}
