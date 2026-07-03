/// Picks the right device-id resolution strategy for the current compile
/// target: persisted-to-disk on native platforms, or a fresh
/// per-session id on Flutter Web — see `device_identity_resolver_web.dart`.
library;

export 'device_identity_resolver_io.dart'
    if (dart.library.js_interop) 'device_identity_resolver_web.dart';
