import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import 'today_controller.dart';
import 'widgets/break_schedule_list.dart';

/// "Today's Rosary": the five breaks of the day with a summary of today's
/// mystery and the campaign progress.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodayController? _controller;
  bool _wired = false;

  Future<void> _openDecade(int decadeNumber) async {
    await context.push(AppRoutes.decadeFor(decadeNumber));
    await _controller?.load();
  }

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
          return const AppLoadingView(message: 'Loading today\'s Rosary…');
        }
        if (c.error != null) {
          return AppErrorView(message: c.error!, onRetry: c.load);
        }

        return SafeArea(
          child: AppContentFrame(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Text(
                    'Today\'s Rosary',
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendlyDate(c.now),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _OverviewCard(controller: c),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionTitle(
                    title: 'Your five breaks',
                    subtitle: 'One decade per break — five breaks, one Rosary.',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (c.schedule != null)
                    BreakScheduleList(
                      slots: c.schedule!.slots,
                      now: c.now,
                      onOpen: _openDecade,
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.controller});

  final TodayController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final mystery = c.content?.mysterySetTitle ?? 'Rosary Mysteries';
    final intention = c.content?.intention ?? '';

    return AppCard(
      color: AppColors.marianBlueSoft.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'TODAY',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(mystery, style: context.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (intention.trim().isNotEmpty)
            Text(
              intention,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Icon(
                Icons.self_improvement,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${c.completedCount} / 5 decades completed',
                style: context.textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: context.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: context.textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
        ),
      ],
    );
  }
}