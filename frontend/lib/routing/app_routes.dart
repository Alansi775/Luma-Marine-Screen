/// Route path constants, kept separate from [AppRouter] so other code
/// (e.g. a future push-notification/deep-link handler) can reference a
/// path without importing go_router.
class AppRoutes {
  AppRoutes._();

  static const nowPlaying = '/';
  static const diagnostics = '/diagnostics';
}
