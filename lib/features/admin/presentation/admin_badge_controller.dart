import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/dependencies.dart';

/// Small numeric badges shown in the admin sidebar.
class AdminBadgeCounts {
  const AdminBadgeCounts({
    this.pendingIntentions = 0,
    this.pendingReports = 0,
  });

  final int pendingIntentions;
  final int pendingReports;
}

/// Loads the sidebar badge counts (pending intentions + pending reports).
class AdminBadgeController extends ChangeNotifier {
  AdminBadgeController(this._dependencies);

  final AppDependencies _dependencies;

  AdminBadgeCounts _counts = const AdminBadgeCounts();
  AdminBadgeCounts get counts => _counts;

  Future<void> refresh() async {
    try {
      final results = await Future.wait<Object?>(
        <Future<Object?>>[
          _dependencies.moderationRepository.fetchPending(),
          _dependencies.reportsRepository.countPending(),
        ],
      );
      _counts = AdminBadgeCounts(
        pendingIntentions: (results[0] as List).length,
        pendingReports: results[1] as int,
      );
      notifyListeners();
    } catch (_) {
      // Badges are decorative — never let a count failure break the shell.
    }
  }

  @override
  void dispose() {
    _dependencies.adminSession.removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() {
    if (_dependencies.adminSession.isAdmin) refresh();
  }

  void arm() {
    _dependencies.adminSession.addListener(_onSessionChange);
  }
}

/// Inherited access to the shell's [AdminBadgeController].
class AdminBadgeScope extends InheritedNotifier<AdminBadgeController> {
  const AdminBadgeScope({
    super.key,
    required AdminBadgeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminBadgeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminBadgeScope>();
    assert(scope != null, 'AdminBadgeScope missing from the widget tree.');
    return scope!.notifier!;
  }

  static AdminBadgeController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminBadgeScope>();
    return scope?.notifier;
  }
}

/// Brand lockup for the sidebar header.
class AdminSidebarBrand extends StatelessWidget {
  const AdminSidebarBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.heroGradient,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ROSARY BREAK',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.marianBlue,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'ADMIN',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.goldDark,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}