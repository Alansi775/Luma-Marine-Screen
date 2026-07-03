/// Picks the right [SyncService] construction strategy for the current
/// compile target: the real Firestore-backed engine on native platforms,
/// or always-noop on Flutter Web — see `sync_service_factory_web.dart`.
library;

export 'sync_service_factory_io.dart' if (dart.library.js_interop) 'sync_service_factory_web.dart';
