import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'admin_badge_controller.dart';
import 'admin_campaign_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_schedule_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_statistics_screen.dart';
import 'content/admin_bulk_content_screen.dart';
import 'content/admin_calendar_screen.dart';
import 'content/admin_daily_content_editor_screen.dart';
import 'prayer/admin_pending_screen.dart';
import 'prayer/admin_published_screen.dart';

/// A sidebar navigation entry.
class AdminNavItem {
  const AdminNavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

/// One grouped section of the sidebar ("Content", "Prayer Wall", …).
class AdminNavSection {
  const AdminNavSection(this.title, this.items);

  final String? title;
  final List<AdminNavItem> items;
}

/// Navigation model for the admin dashboard sidebar.
abstract final class AdminNav {
  static const AdminNavItem dashboard = AdminNavItem(
    AppRoutes.adminDashboard,
    'Dashboard',
    Icons.space_dashboard_outlined,
  );

  static const AdminNavItem reports = AdminNavItem(
    AppRoutes.adminReports,
    'Reports',
    Icons.flag_outlined,
  );

  static const AdminNavItem schedule = AdminNavItem(
    AppRoutes.adminSchedule,
    'Schedule',
    Icons.schedule_outlined,
  );

  static const AdminNavItem campaign = AdminNavItem(
    AppRoutes.adminCampaign,
    'Campaign',
    Icons.rocket_launch_outlined,
  );

  static const AdminNavItem statistics = AdminNavItem(
    AppRoutes.adminStatistics,
    'Statistics',
    Icons.bar_chart_outlined,
  );

  static const AdminNavItem settings = AdminNavItem(
    AppRoutes.adminSettings,
    'Settings',
    Icons.settings_outlined,
  );

  static const AdminNavItem contentToday = AdminNavItem(
    AppRoutes.adminContentToday,
    'Today',
    Icons.edit_calendar_outlined,
  );

  static const AdminNavItem contentCalendar = AdminNavItem(
    AppRoutes.adminContentCalendar,
    'Calendar',
    Icons.calendar_month_outlined,
  );

  static const AdminNavItem contentBulk = AdminNavItem(
    AppRoutes.adminContentBulk,
    'Bulk Content',
    Icons.library_add_outlined,
  );

  static const AdminNavItem prayerPending = AdminNavItem(
    AppRoutes.adminPrayerPending,
    'Pending',
    Icons.pending_actions_outlined,
  );

  static const AdminNavItem prayerPublished = AdminNavItem(
    AppRoutes.adminPrayerPublished,
    'Published',
    Icons.check_circle_outline,
  );

  static const List<AdminNavSection> sections = <AdminNavSection>[
    AdminNavSection(null, <AdminNavItem>[dashboard]),
    AdminNavSection(
      'Content',
      <AdminNavItem>[contentToday, contentCalendar, contentBulk],
    ),
    AdminNavSection(
      'Prayer Wall',
      <AdminNavItem>[prayerPending, prayerPublished],
    ),
    AdminNavSection(
      null,
      <AdminNavItem>[reports, schedule, campaign, statistics, settings],
    ),
  ];

  /// Pending-count badge for a route, or `null` to hide it.
  static int? badgeFor(String route, AdminBadgeCounts counts) {
    switch (route) {
      case AppRoutes.adminPrayerPending:
        return counts.pendingIntentions == 0 ? null : counts.pendingIntentions;
      case AppRoutes.adminReports:
        return counts.pendingReports == 0 ? null : counts.pendingReports;
      default:
        return null;
    }
  }
}

/// The persistent admin scaffold: sidebar on wide screens, drawer on narrow.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.location});

  final String location;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late final AdminBadgeController _badges;

  @override
  void initState() {
    super.initState();
    _badges = AdminBadgeController(AppScope.of(context));
    _badges.arm();
    _badges.refresh();
  }

  @override
  void didUpdateWidget(covariant AdminShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _badges.refresh();
  }

  @override
  void dispose() {
    _badges.dispose();
    super.dispose();
  }

  Widget _body() {
    final location = widget.location;
    if (location.startsWith(AppRoutes.adminContentDate)) {
      final date = location.substring('${AppRoutes.adminContentToday}/'.length);
      return AdminDailyContentEditorScreen(initialDate: date);
    }
    return switch (location) {
      AppRoutes.adminContentToday => const AdminDailyContentEditorScreen(),
      AppRoutes.adminContentCalendar => const AdminCalendarScreen(),
      AppRoutes.adminContentBulk => const AdminBulkContentScreen(),
      AppRoutes.adminPrayerPending => const AdminPendingScreen(),
      AppRoutes.adminPrayerPublished => const AdminPublishedScreen(),
      AppRoutes.adminReports => const AdminReportsScreen(),
      AppRoutes.adminSchedule => const AdminScheduleScreen(),
      AppRoutes.adminCampaign => const AdminCampaignScreen(),
      AppRoutes.adminStatistics => const AdminStatisticsScreen(),
      AppRoutes.adminSettings => const AdminSettingsScreen(),
      _ => const AdminDashboardScreen(),
    };
  }

  static String _titleFor(String location) {
    if (location.startsWith(AppRoutes.adminContentDate)) {
      return 'Edit Daily Content';
    }
    return switch (location) {
      AppRoutes.adminContentToday => 'Today\'s Content',
      AppRoutes.adminContentCalendar => 'Content Calendar',
      AppRoutes.adminContentBulk => 'Bulk Content',
      AppRoutes.adminPrayerPending => 'Moderation Queue',
      AppRoutes.adminPrayerPublished => 'Published Intentions',
      AppRoutes.adminReports => 'Reports',
      AppRoutes.adminSchedule => 'Break Schedule',
      AppRoutes.adminCampaign => 'Campaign',
      AppRoutes.adminStatistics => 'Statistics',
      AppRoutes.adminSettings => 'Settings',
      _ => 'Dashboard',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AdminBadgeScope(
      controller: _badges,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1040;
          if (wide) {
            return Scaffold(
              body: Row(
                children: <Widget>[
                  const _AdminSidebar(),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _AdminContent(
                      title: _titleFor(widget.location),
                      child: _body(),
                    ),
                  ),
                ],
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text('Admin · ${_titleFor(widget.location)}'),
            ),
            drawer: const _AdminSidebar(),
            body: _AdminContent(
              title: _titleFor(widget.location),
              child: _body(),
            ),
          );
        },
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          _AdminTopBar(title: title),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 1100,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).adminSession;
    final user = session.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user != null) ...<Widget>[
            _UserAvatar(user: user),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(user.displayName ?? 'Admin',
                    style: Theme.of(context).textTheme.labelMedium),
                Text(
                  user.role.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await session.signOut();
                if (context.mounted) context.go(AppRoutes.adminLogin);
              },
            ),
          ] else
            TextButton(
              onPressed: () => context.go(AppRoutes.adminLogin),
              child: const Text('Sign in'),
            ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return ClipOval(
        child: SizedBox.square(
          dimension: 32,
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => UserInitialsAvatar(user: user),
          ),
        ),
      );
    }
    return UserInitialsAvatar(user: user);
  }
}

class UserInitialsAvatar extends StatelessWidget {
  const UserInitialsAvatar({super.key, required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName as String? ?? 'A').trim();
    final letter = name.isEmpty ? 'A' : name[0].toUpperCase();
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.marianBlue,
      child: Text(
        letter,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  static const double drawerWidth = 300;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final counts = AdminBadgeScope.of(context).counts;
    final compact = MediaQuery.sizeOf(context).width < 1040;
    final width = compact ? drawerWidth : 264.0;

    final tiles = <Widget>[
      const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AdminSidebarBrand(),
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final section in AdminNav.sections) ...<Widget>[
        if (section.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              section.title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
            ),
          ),
        for (final item in section.items)
          _SidebarTile(
            item: item,
            selected: _isSelected(location, item.route),
            badge: AdminNav.badgeFor(item.route, counts),
            onTap: () {
              Navigator.of(context, rootNavigator: true)
                  .popUntil((route) => route.isFirst);
              context.go(item.route);
            },
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
      const SizedBox(height: AppSpacing.xl),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: TextButton.icon(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Student App'),
        ),
      ),
    ];

    final list = ListView(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), children: tiles);
    return SizedBox(width: width, child: list);
  }

  bool _isSelected(String location, String route) {
    if (route == AppRoutes.adminDashboard) {
      return location == AppRoutes.adminDashboard ||
          location == AppRoutes.admin ||
          location == AppRoutes.adminLogin;
    }
    if (route == AppRoutes.adminContentToday) {
      return location == AppRoutes.adminContentToday ||
          location.startsWith(AppRoutes.adminContentDate);
    }
    return location == route;
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: selected ? AppColors.marianBlueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? AppColors.marianBlue : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? AppColors.marianBlue
                          : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}