import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../home/presentation/home_screen.dart';
import '../../intention/presentation/intention_screen.dart';
import '../../reflection/presentation/reflection_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../today/presentation/today_screen.dart';

/// The persistent scaffold with responsive navigation.
///
/// Mobile/tablet use a bottom [NavigationBar]; wide desktop screens switch to
/// a [NavigationRail]. The location drives the selected destination so the
/// back button and the nav bar never disagree.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location});

  final String location;

  static const List<(String, String, IconData, IconData)> _destinations = <(
    String,
    String,
    IconData,
    IconData,
  )>[
    (AppRoutes.home, 'Home', Icons.home_outlined, Icons.home),
    (
      AppRoutes.today,
      'Today',
      Icons.calendar_today_outlined,
      Icons.calendar_today,
    ),
    (
      AppRoutes.intention,
      'Prayer Wall',
      Icons.favorite_outline,
      Icons.favorite,
    ),
    (
      AppRoutes.reflection,
      'Reflection',
      Icons.format_quote_outlined,
      Icons.format_quote,
    ),
    (AppRoutes.settings, 'Profile', Icons.person_outline, Icons.person),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere((d) => d.$1 == location);
    return index < 0 ? 0 : index;
  }

  Widget _body(BuildContext context) {
    final child = switch (location) {
      AppRoutes.today => const TodayScreen(),
      AppRoutes.intention => const IntentionScreen(),
      AppRoutes.reflection => const ReflectionScreen(),
      AppRoutes.settings => const SettingsScreen(),
      _ => const HomeScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey<String>(location), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final body = _body(context);

    return Scaffold(
      body: isWide
          ? Row(
              children: <Widget>[
                _Rail(
                  selectedIndex: _selectedIndex,
                  extended: width >= 1200,
                  onSelect: (route) => context.go(route),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide ? null : _BottomBar(
        selectedIndex: _selectedIndex,
        onSelect: (route) => context.go(route),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => onSelect(AppShell._destinations[index].$1),
      destinations: <Widget>[
        for (final (_, label, icon, activeIcon) in AppShell._destinations)
          NavigationDestination(
            icon: Icon(icon),
            selectedIcon: Icon(activeIcon),
            label: label,
          ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.selectedIndex,
    required this.extended,
    required this.onSelect,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex,
      labelType: extended ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
      leading: const _RailBrand(),
      onDestinationSelected: (index) =>
          onSelect(AppShell._destinations[index].$1),
      destinations: <NavigationRailDestination>[
        for (final (_, label, icon, activeIcon) in AppShell._destinations)
          NavigationRailDestination(
            icon: Icon(icon),
            selectedIcon: Icon(activeIcon),
            label: Text(label),
          ),
      ],
    );
  }
}

/// Quiet brand mark so the rail never feels empty.
class _RailBrand extends StatelessWidget {
  const _RailBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Semantics(
        label: 'BEAD5',
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFE3C889), Color(0xFFC9A24B)],
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFA98633), width: 2),
            ),
          ),
        ),
      ),
    );
  }
}