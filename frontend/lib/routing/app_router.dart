import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/diagnostics/presentation/screens/diagnostics_screen.dart';
import '../features/playback/presentation/screens/now_playing_screen.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

/// Two flat routes today. Kept behind a provider specifically so future
/// requirements (auth/device-registration redirect guards, deep links
/// for remote diagnostics) are additive edits to this one file.
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
    ],
  );
}
