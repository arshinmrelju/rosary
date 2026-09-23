import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../domain/models/break_slot.dart';
import '../../../domain/models/break_status.dart';
import '../../today/presentation/today_controller.dart';

/// Daily progress summary.
///
/// Placeholder stage: streaks, badges and leaderboards arrive in later steps.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  TodayController? _controller;
  bool _wired = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    _controller ??= TodayController(deps);
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.load());
    }

    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final c = _controller!;
        if (c.isLoading) {
          return const AppLoadingView(message: 'Loading progress…');
        }
        if (c.error != null) {
          return AppErrorView(message: c.error!, onRetry: c.load);
        }

        return SafeArea(
          child: AppContentFrame(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Text(
                  'Progress',
                  style: context.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Rosary, one decade at a time.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _TodayProgressCard(controller: c),
                const SizedBox(height: AppSpacing.xl),

                const _ComingSoonCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Streaks',
                  message: 'A daily-prayer streak will appear here in a '
                      'future release.',
                ),
                const SizedBox(height: AppSpacing.lg),
                const _ComingSoonCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Badges',
                  message: 'Milestone badges for consistent prayer are '
                      'coming soon.',
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.controller});

  final TodayController controller;

  @override
  Widget build(BuildContext context) {
    final slots = controller.schedule?.slots ?? <BreakSlot>[];
    final count = controller.completedCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Today', style: context.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              for (var i = 1; i <= 5; i++) ...<Widget>[
                if (i > 1) const SizedBox(width: 10),
                _StepDot(
                  completed: i <= count,
                  active: i == count + 1,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$count of 5 decades',
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final slot in slots)
            _BreakLine(
              label: slot.title,
              time: slot.time.label,
              status: slot.statusAt(controller.now, completed: slot.isCompleted),
            ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.completed, required this.active});

  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AppColors.dotCompleted
        : active
        ? AppColors.dotActive
        : AppColors.dotUpcoming;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? color : Colors.transparent,
        border: Border.all(color: color, width: 2.5),
      ),
    );
  }
}

class _BreakLine extends StatelessWidget {
  const _BreakLine({
    required this.label,
    required this.time,
    required this.status,
  });

  final String label;
  final String time;
  final BreakStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      BreakStatus.completed => (Icons.check_circle, AppColors.success),
      BreakStatus.active => (Icons.radio_button_checked, AppColors.marianBlue),
      BreakStatus.upcoming => (
        Icons.radio_button_unchecked,
        AppColors.inkMuted,
      ),
      BreakStatus.missed => (Icons.radio_button_off, AppColors.inkMuted),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.textTheme.bodyMedium)),
          Text(
            time,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.goldDark, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}