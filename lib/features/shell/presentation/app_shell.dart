import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../features/home/presentation/home_screen.dart';
import '../../../features/intention/presentation/intention_screen.dart';
import '../../../features/progress/presentation/progress_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';
import '../../../features/today/presentation/today_screen.dart';

/// The persistent scaffold with bottom navigation.
///
/// The location drives the selected destination so the back button and the
/// nav bar never disagree.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location});

  final String location;

  static const List<(String, IconData, IconData)> _destinations = <(
    String,
    IconData,
    IconData,
  )>[
    (AppRoutes.home, Icons.home_outlined, Icons.home),
    (AppRoutes.today, Icons.calendar_today_outlined, Icons.calendar_today),
    (AppRoutes.intention, Icons.favorite_outline, Icons.favorite),
    (AppRoutes.progress, Icons.insights_outlined, Icons.insights),
    (AppRoutes.settings, Icons.person_outline, Icons.person),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere((d) => d.$1 == location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (location) {
      AppRoutes.today => const TodayScreen(),
      AppRoutes.intention => const IntentionScreen(),
      AppRoutes.progress => const ProgressScreen(),
      AppRoutes.settings => const SettingsScreen(),
      _ => const HomeScreen(),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey<String>(location), child: child),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          final (route, _, _) = _destinations[index];
          context.go(route);
        },
        destinations: <Widget>[
          for (final (route, icon, activeIcon) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(activeIcon),
              label: _labelFor(route),
            ),
        ],
      ),
    );
  }

  String _labelFor(String route) {
    return switch (route) {
      AppRoutes.today => 'Today',
      AppRoutes.intention => 'Intentions',
      AppRoutes.progress => 'Progress',
      AppRoutes.settings => 'Profile',
      _ => 'Home',
    };
  }
}