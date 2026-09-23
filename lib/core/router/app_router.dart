import 'package:go_router/go_router.dart';

import '../../features/decade/presentation/decade_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import 'app_routes.dart';

/// The single router for the app.
class AppRouter {
  AppRouter._();

  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <GoRoute>[
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const AppShell(location: AppRoutes.home),
      ),
      GoRoute(
        path: AppRoutes.today,
        builder: (context, state) => const AppShell(location: AppRoutes.today),
      ),
      GoRoute(
        path: AppRoutes.intention,
        builder: (context, state) =>
            const AppShell(location: AppRoutes.intention),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) =>
            const AppShell(location: AppRoutes.progress),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const AppShell(location: AppRoutes.settings),
      ),
      GoRoute(
        path: '${AppRoutes.decade}/:number',
        builder: (context, state) {
          final number = int.tryParse(state.pathParameters['number'] ?? '') ?? 1;
          return DecadeScreen(decadeNumber: number);
        },
      ),
    ],
  );

  static GoRouter get instance => _router;
}