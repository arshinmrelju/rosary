import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../domain/models/break_slot.dart';
import '../../../../domain/models/daily_content.dart';
import 'decade_dots.dart';

/// The central progress card: today's mystery, decade dots, next break info
/// and the PRAY NOW action.
class ProgressHeroCard extends StatelessWidget {
  const ProgressHeroCard({
    super.key,
    required this.completedCount,
    required this.nextBreak,
    required this.content,
    required this.onPrayNow,
  });

  final int completedCount;
  final BreakSlot? nextBreak;
  final DailyContent? content;
  final VoidCallback onPrayNow;

  static const int totalDecades = 5;

  @override
  Widget build(BuildContext context) {
    final allDone = nextBreak == null;
    final mystery = content?.mysterySetTitle ?? 'Rosary Mysteries';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: AppColors.heroGradient,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x331C3D8A),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "TODAY'S MYSTERY",
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB9C8EC),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mystery,
            style: context.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Progress dots + count.
          Row(
            children: <Widget>[
              DecadeDots(
                completedCount: completedCount,
                nextDecade: nextBreak?.decadeNumber,
              ),
              const Spacer(),
              Text(
                '$completedCount / $totalDecades Decades',
                style: context.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFDDE6F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _NextBreakRow(allDone: allDone, nextBreak: nextBreak),
          const SizedBox(height: AppSpacing.xl),

          AppPrimaryButton(
            label: allDone
                ? 'Rosary complete — thank you'
                : 'PRAY NOW',
            icon: allDone ? Icons.check_circle_outline : Icons.self_improvement,
            onPressed: allDone ? null : onPrayNow,
          ),
        ],
      ),
    );
  }
}

class _NextBreakRow extends StatelessWidget {
  const _NextBreakRow({required this.allDone, required this.nextBreak});

  final bool allDone;
  final BreakSlot? nextBreak;

  @override
  Widget build(BuildContext context) {
    final time = nextBreak?.time.label ?? '—';
    final decade = nextBreak == null ? '—' : ordinal(nextBreak!.decadeNumber);

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          allDone ? 'YOU PRAYED ALL FIVE' : 'NEXT BREAK',
          style: context.textTheme.labelSmall?.copyWith(
            color: const Color(0xFFB9C8EC),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          allDone ? 'Come back tomorrow' : '$time  ·  $decade Decade',
          style: context.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ],
    );

    if (allDone) {
      return Row(
        children: <Widget>[
          const Icon(Icons.emoji_events_outlined, color: AppColors.goldSoft),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: label),
        ],
      );
    }

    return Row(
      children: <Widget>[
        _TimeChip(time: time),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: label),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        time,
        style: context.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}