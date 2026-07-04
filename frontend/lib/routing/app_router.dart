import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/admin/presentation/screens/admin_screen.dart';
import '../features/admin/presentation/screens/playlist_detail_screen.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/diagnostics/presentation/screens/diagnostics_screen.dart';
import '../features/playback/presentation/screens/now_playing_screen.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

/// Kept behind a provider specifically so future requirements (deep links
/// for remote diagnostics, more admin routes) are additive edits to this
/// one file. `/admin` (and everything nested under it) redirects to the
/// hidden login screen for anyone not already signed in — there's no
/// visible link to either from normal signage playback (see the
/// long-press gesture on shared/widgets/bootstrap_screen.dart).
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.nowPlaying,
    routes: [
      GoRoute(
        path: AppRoutes.nowPlaying,
        builder: (context, state) => const NowPlayingScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostics,
        builder: (context, state) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        redirect: (context, state) =>
            ref.read(authRepositoryProvider).isSignedIn ? null : AppRoutes.adminLogin,
        builder: (context, state) => const AdminScreen(),
        routes: [
          GoRoute(
            path: 'playlists/:playlistId',
            builder: (context, state) => PlaylistDetailScreen(
              playlistId: state.pathParameters['playlistId']!,
            ),
          ),
        ],
      ),
    ],
  );
}
