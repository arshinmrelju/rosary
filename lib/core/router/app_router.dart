import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_gate.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/decade/presentation/decade_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
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
        path: AppRoutes.reflection,
        builder: (context, state) =>
            const AppShell(location: AppRoutes.reflection),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const AppShell(location: AppRoutes.settings),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.decade}/:number',
        builder: (context, state) {
          final number = int.tryParse(state.pathParameters['number'] ?? '') ?? 1;
          return DecadeScreen(decadeNumber: number);
        },
      ),
      // ----- Admin dashboard -----
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => _adminGate(AppRoutes.admin),
        routes: <GoRoute>[
          GoRoute(
            path: 'login',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: 'dashboard',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminDashboard),
          ),
          GoRoute(
            path: 'content/today',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminContentToday),
          ),
          GoRoute(
            path: 'content/today/:date',
            builder: (context, state) =>
                _adminGate('${AppRoutes.adminContentToday}/${state.pathParameters['date']}'),
          ),
          GoRoute(
            path: 'content/calendar',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminContentCalendar),
          ),
          GoRoute(
            path: 'content/bulk',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminContentBulk),
          ),
          GoRoute(
            path: 'prayer/pending',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminPrayerPending),
          ),
          GoRoute(
            path: 'prayer/published',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminPrayerPublished),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => _adminGate(AppRoutes.adminReports),
          ),
          GoRoute(
            path: 'schedule',
            builder: (context, state) => _adminGate(AppRoutes.adminSchedule),
          ),
          GoRoute(
            path: 'campaign',
            builder: (context, state) => _adminGate(AppRoutes.adminCampaign),
          ),
          GoRoute(
            path: 'statistics',
            builder: (context, state) =>
                _adminGate(AppRoutes.adminStatistics),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => _adminGate(AppRoutes.adminSettings),
          ),
        ],
      ),
    ],
  );

  static Widget _adminGate(String location) =>
      AdminGate(child: AdminShell(location: location));

  static GoRouter get instance => _router;
}