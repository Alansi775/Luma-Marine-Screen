/// Route path constants, kept separate from [AppRouter] so other code
/// (e.g. a future push-notification/deep-link handler) can reference a
/// path without importing go_router.
class AppRoutes {
  AppRoutes._();

  static const nowPlaying = '/';
  static const diagnostics = '/diagnostics';
  static const adminLogin = '/admin/login';
  static const admin = '/admin';
  static const adminPlaylistPattern = '/admin/playlists/:playlistId';

  static String adminPlaylist(String playlistId) => '/admin/playlists/$playlistId';
}
