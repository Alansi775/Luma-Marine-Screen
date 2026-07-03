/// Picks the right [AppLogger] (`PlatformLogger`) implementation for the
/// current compile target: a file-backed logger on native platforms, or
/// a console-only one on Flutter Web — see `platform_logger_web.dart`.
library;

export 'platform_logger_io.dart' if (dart.library.js_interop) 'platform_logger_web.dart';
