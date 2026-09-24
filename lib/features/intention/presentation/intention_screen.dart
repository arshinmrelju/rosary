import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
import '../../../domain/models/prayer_intention.dart';
import 'intention_controller.dart';

/// 🙏 Prayer Wall — campus-wide intentions.
///
/// Shows approved intentions (anonymously), the daily + monthly community
/// tallies and a guarded "I Prayed For This" action. New submissions go to
/// moderation (pending) and never appear here until approved.
class IntentionScreen extends StatefulWidget {
  const IntentionScreen({super.key});

  @override
  State<IntentionScreen> createState() => _IntentionScreenState();
}

class _IntentionScreenState extends State<IntentionScreen> {
  IntentionController? _controller;
  bool _wired = false;
  bool _formVisible = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pray(
    IntentionController controller,
    PrayerIntention intention,
  ) async {
    final counted = await controller.recordPrayer(intention);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          counted
              ? 'Thank you for praying for this intention.'
              : 'You have already prayed for this intention.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    _controller ??= IntentionController(deps);
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.load());
    }

    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final c = _controller!;

        return SafeArea(
          child: AppContentFrame(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Text(
                    '🙏 Prayer Wall',
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Offer an intention. The community prays for it together — '
                    'quietly, without names or comparisons.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _CommunityStatsSection(
                    day: c.dayStats,
                    month: c.monthStats,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppSectionHeader(
                    overline: 'Church of prayer',
                    title: 'Add an intention',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_formVisible)
                    _SubmitCard(
                      controller: c,
                      onDone: () => setState(() => _formVisible = false),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _formVisible = true),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('+ Add Prayer Intention'),
                    ),
                  const SizedBox(height: AppSpacing.xxl),

                  const AppSectionHeader(
                    overline: 'The community carries these',
                    title: 'Intention wall',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _IntentionWall(
                    controller: c,
                    onPray: (intention) => _pray(c, intention),
                    onAddIntention: () => setState(() => _formVisible = true),
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

/// Today + This Month community tallies (no rankings, no comparisons).
class _CommunityStatsSection extends StatelessWidget {
  const _CommunityStatsSection({required this.day, required this.month});

  final DayStats? day;
  final MonthStats? month;

  @override
  Widget build(BuildContext context) {
    final dayStats = day;
    final monthStats = month;

    if (dayStats == null || dayStats.isEmpty) {
      return AppCard(
        color: AppColors.marianBlueSoft.withValues(alpha: 0.5),
        child: Column(
          children: <Widget>[
            Text(
              '🌹 ${AppConstants.campusShortName} COMMUNITY',
              style: context.textTheme.labelMedium?.copyWith(
                color: AppColors.marianBlue,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Be the first to pray today.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '🌹 ${AppConstants.campusShortName} COMMUNITY',
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.marianBlue,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "Today's Prayer",
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              _Metric(
                icon: '📿',
                value: formatThousands(dayStats.totalDecades),
                label: 'Decades Prayed',
              ),
              _Metric(
                icon: '👥',
                value: formatThousands(dayStats.totalParticipants),
                label: 'Participants',
              ),
              _Metric(
                icon: '🙏',
                value: formatThousands(dayStats.totalIntentions),
                label: 'Intentions',
              ),
            ],
          ),
          if (monthStats != null && !monthStats.isEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'This Month',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                _Metric(
                  icon: '📿',
                  value: formatThousands(monthStats.totalDecades),
                  label: 'Decades Prayed',
                ),
                _Metric(
                  icon: '👥',
                  value: formatThousands(monthStats.totalParticipants),
                  label: 'Participants',
                ),
                _Metric(
                  icon: '🙏',
                  value: formatThousands(monthStats.totalIntentions),
                  label: 'Intentions',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: context.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The guarded "I prayed for this" wall.
class _IntentionWall extends StatelessWidget {
  const _IntentionWall({
    required this.controller,
    required this.onPray,
    required this.onAddIntention,
  });

  final IntentionController controller;
  final Future<void> Function(PrayerIntention) onPray;
  final VoidCallback onAddIntention;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const AppLoadingView(message: 'Loading intentions…');
    }
    if (controller.error != null && controller.intentions.isEmpty) {
      return AppErrorView(message: controller.error!, onRetry: controller.load);
    }
    if (controller.intentions.isEmpty) {
      return AppEmptyView(
        icon: Icons.favorite_border,
        message:
            'There are no prayer intentions yet today.\n\n'
            'Be the first to offer one.',
        actionLabel: 'Add Prayer Intention',
        onAction: onAddIntention,
      );
    }

    return Column(
      children: <Widget>[
        for (var i = 0; i < controller.intentions.length; i++) ...<Widget>[
          _IntentionTile(
            intention: controller.intentions[i],
            prayed: controller.hasPrayed(controller.intentions[i].id ?? ''),
            busy: controller.isPraying,
            onPray: () => onPray(controller.intentions[i]),
          ),
          if (i < controller.intentions.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// One approved intention with its "N people prayed" tally.
class _IntentionTile extends StatelessWidget {
  const _IntentionTile({
    required this.intention,
    required this.prayed,
    required this.busy,
    required this.onPray,
  });

  final PrayerIntention intention;
  final bool prayed;
  final bool busy;
  final VoidCallback onPray;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.marianBlueSoft,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite,
                  size: 16,
                  color: AppColors.marianBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(intention.text, style: context.textTheme.bodyLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Icon(
                prayed ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${formatThousands(intention.prayerCount)} people prayed',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
              const Spacer(),
              if (prayed)
                const AppPill(
                  label: 'Prayed ✓',
                  icon: Icons.check,
                  color: AppColors.successSoft,
                  foregroundColor: AppColors.success,
                )
              else
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onPray,
                  icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                  label: const Text('I Prayed For This'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Submission form. Never collects personal information; anonymous by default.
class _SubmitCard extends StatefulWidget {
  const _SubmitCard({required this.controller, required this.onDone});

  final IntentionController controller;
  final VoidCallback onDone;

  @override
  State<_SubmitCard> createState() => _SubmitCardState();
}

class _SubmitCardState extends State<_SubmitCard> {
  final TextEditingController _text = TextEditingController();
  bool _anonymous = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to pray for.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ok = await widget.controller.submit(
      PrayerIntention(text: _text.text, anonymous: _anonymous),
    );
    if (!mounted) return;
    if (ok) {
      _text.clear();
      widget.onDone();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thank you. This intention will appear once it is reviewed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'What would you like us to pray for?',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _text,
            maxLines: 3,
            maxLength: AppConstants.intentionMaxLength,
            decoration: const InputDecoration(
              hintText: 'A person, a need, a thank-you, a hope…',
              filled: true,
            ),
          ),
          Row(
            children: <Widget>[
              Checkbox(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v ?? true),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Post anonymously', style: context.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: widget.controller.isSubmitting ? null : _submit,
            icon: const Icon(Icons.favorite_outline, size: 20),
            label: Text(
              widget.controller.isSubmitting ? 'Sharing…' : 'Submit',
            ),
          ),
          if (widget.controller.submitError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.controller.submitError!,
              style: context.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}