import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/sync/presentation/providers/sync_providers.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_schedule_controller.dart';

class LumaMarineApp extends ConsumerWidget {
  const LumaMarineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly constructs the sync engine at startup, not just whenever a
    // screen happens to watch it — see sync_providers.dart.
    ref.watch(syncServiceProvider);

    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeScheduleProvider);

    return MaterialApp.router(
      title: 'Luma Marine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
