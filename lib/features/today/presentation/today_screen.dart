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
import '../../../core/widgets/decade_dots.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../domain/models/rosary_break.dart';
import '../../../domain/schedule/break_day_state.dart';
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

        final mystery = c.content?.mysterySetTitle ?? 'Rosary Mysteries';

        return SafeArea(
          child: AppContentFrame(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Text(
                    "Today's Rosary",
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendlyDate(c.now),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  OfflineBanner(offline: c.isOffline),
                  if (c.isOffline) const SizedBox(height: AppSpacing.md),
                  const SizedBox(height: AppSpacing.xl),

                  _OverviewCard(
                    mystery: mystery,
                    intention: c.content?.intention ?? '',
                    completedCount: c.completedCount,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (c.campaignPaused) ...<Widget>[
                    const _PausedMessageCard(),
                    const SizedBox(height: AppSpacing.xxl),
                  ] else ...<Widget>[
                    _TodayHeading(
                      completedCount: c.completedCount,
                      state: c.dayState,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (c.schedule != null)
                      BreakScheduleList(
                        slots: c.schedule!.slots,
                        now: c.now,
                        dayState: c.dayState,
                        onOpen: _openDecade,
                      ),

                    if (c.dayEnded && c.remainingCount > 0) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      _CatchUpCard(
                        remaining: c.remainingCount,
                        breaks: c.breaks,
                        onCompleteDecade: _openDecade,
                      ),
                    ],

                    if (c.dayState?.allCompleted ?? false) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      const _JourneyFooter(),
                    ],
                  ],
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

/// Shown when organizers pause the campaign: a calm note instead of pushing
/// the five breaks.
class _PausedMessageCard extends StatelessWidget {
  const _PausedMessageCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.goldSoft.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'A LITTLE PAUSE',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The campaign is resting today.',
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your Rosary is still yours — come back when the campaign '
            'resumes. We are glad you are here.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero summary: today's mystery, dots and "n / 5 completed".
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.mystery,
    required this.intention,
    required this.completedCount,
  });

  final String mystery;
  final String intention;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.marianBlueSoft.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'TODAY',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.goldDark,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Text(
                '$completedCount / 5 completed',
                style: context.textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(mystery, style: context.textTheme.titleLarge),
          if (intention.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              intention,
              style: context.textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          DecadeDots(completedCount: completedCount),
        ],
      ),
    );
  }
}

/// After the day has passed: a warm, guilt-free invitation to finish the
/// remaining decades. Never blames the student for missed breaks.
class _CatchUpCard extends StatelessWidget {
  const _CatchUpCard({
    required this.remaining,
    required this.breaks,
    required this.onCompleteDecade,
  });

  final int remaining;
  final List<RosaryBreak> breaks;
  final ValueChanged<int> onCompleteDecade;

  @override
  Widget build(BuildContext context) {
    final incomplete = breaks.where((b) => !b.prayerCompleted).toList();

    return AppCard(
      color: AppColors.goldSoft.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'STILL TIME TO PRAY',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The remaining $remaining decade${remaining == 1 ? '' : 's'} '
            'can still be prayed today.',
            style: context.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your Rosary is still yours — pick any decade whenever '
            'you\'re ready.',
            style: context.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (incomplete.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            for (final br in incomplete) ...<Widget>[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onCompleteDecade(br.decadeNumber),
                  icon: const Icon(Icons.self_improvement),
                  label: Text('Pray ${ordinal(br.decadeNumber)} decade · '
                      '${formatHourMinute(br.startTime.hour, br.startTime.minute)}'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

/// Closing line of the Today screen: the promise of the campaign.
class _JourneyFooter extends StatelessWidget {
  const _JourneyFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '5 breaks · 1 Rosary · everyday',
          textAlign: TextAlign.center,
          style: context.textTheme.labelLarge?.copyWith(
            color: AppColors.marianBlue,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your Rosary journey is complete for today. See you tomorrow.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "Your five breaks" heading reflecting the day phase.
class _TodayHeading extends StatelessWidget {
  const _TodayHeading({required this.completedCount, required this.state});

  final int completedCount;
  final BreakDayState? state;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (state?.phase) {
      BreakDayPhase.dayComplete =>
        'You prayed all five decades. Come back tomorrow.',
      BreakDayPhase.breakIsActive =>
        'A break is happening now — a few minutes is all it takes.',
      BreakDayPhase.breakEnded =>
        'That break has passed, but you can still pray anytime.',
      BreakDayPhase.nextBreak || BreakDayPhase.beforeFirstBreak =>
        'One decade per break — five breaks, one Rosary.',
      null => 'One decade per break — five breaks, one Rosary.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Your five breaks', style: context.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: context.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}