import 'dart:io';

import 'package:logging/logging.dart' as logging;
import 'package:path/path.dart' as p;

import 'app_logger.dart';

/// Console logger that can be upgraded to also append to a rotating file
/// once the app's data directory is known (see [attachFileSink]).
///
/// Rotation is intentionally simple: at attach-time, if the current log
/// file exceeds [_maxBytesBeforeRotation], it's renamed to `.log.old`
/// (one generation kept) before a fresh one is opened. This is a device
/// that runs for months unattended — bounding disk usage matters more
/// than sophisticated rotation policies.
class PlatformLogger implements AppLogger {
  PlatformLogger.consoleOnly() : _logger = logging.Logger('luma_marine') {
    logging.Logger.root.level = logging.Level.ALL;
    // Kept alive for the app's lifetime; there's nothing to cancel this for.
    logging.Logger.root.onRecord.listen(_handleRecord);
  }

  static const _maxBytesBeforeRotation = 5 * 1024 * 1024; // 5 MB

  final logging.Logger _logger;
  IOSink? _fileSink;

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
  Future<void> attachFileSink(String logDirectoryPath) async {
    try {
      final file = File(p.join(logDirectoryPath, 'luma_marine.log'));
      if (await file.exists() && await file.length() > _maxBytesBeforeRotation) {
        final rotated = File(p.join(logDirectoryPath, 'luma_marine.log.old'));
        if (await rotated.exists()) await rotated.delete();
        await file.rename(rotated.path);
      }
      _fileSink = File(file.path).openWrite(mode: FileMode.append);
    } on FileSystemException catch (e) {
      warning('Failed to attach file log sink, continuing console-only', error: e);
    }
  }

  void _handleRecord(logging.LogRecord record) {
    final line = '${record.time.toIso8601String()} '
        '[${record.level.name}] ${record.message}'
        '${record.error != null ? ' | error: ${record.error}' : ''}';
    // ignore: avoid_print
    print(line);
    _fileSink?.writeln(line);
  }
}
