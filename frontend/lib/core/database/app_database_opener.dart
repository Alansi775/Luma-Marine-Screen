/// Picks the right database-opening strategy for the current compile
/// target: with an in-memory fallback on native platforms, or a plain
/// open on Flutter Web (whose WASM backend already degrades gracefully
/// on its own) — see `app_database_opener_web.dart`.
library;

export 'app_database_opener_io.dart' if (dart.library.js_interop) 'app_database_opener_web.dart';
