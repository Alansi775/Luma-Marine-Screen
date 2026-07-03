/// Picks the right [AppDirectories] implementation for the current
/// compile target: the `dart:io`-based one on native platforms (Linux
/// production, macOS development), or the no-op web one when compiling
/// for Flutter Web (used only for fast UI preview — see
/// `default_app_directories_web.dart`).
library;

export 'default_app_directories_io.dart'
    if (dart.library.js_interop) 'default_app_directories_web.dart';
