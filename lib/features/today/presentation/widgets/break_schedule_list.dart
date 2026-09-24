import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/break_slot.dart';
import '../../../../domain/models/break_status.dart';
import '../../../../domain/schedule/break_day_state.dart';

/// The five break slots with their current status.
///
/// When [onOpen] is provided the rows become tappable.
class BreakScheduleList extends StatelessWidget {
  const BreakScheduleList({
    super.key,
    required this.slots,
    required this.now,
    this.dayState,
    this.onOpen,
  });

  final List<BreakSlot> slots;
  final DateTime now;
  final BreakDayState? dayState;
  final Future<void> Function(int decadeNumber)? onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < slots.length; i++) ...<Widget>[
            _BreakTile(
              slot: slots[i],
              now: now,
              dayState: dayState,
              onTap: onOpen == null
                  ? null
                  : () => onOpen!(slots[i].decadeNumber),
            ),
            if (i < slots.length - 1)
              const Divider(height: 1, indent: 20, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

class _BreakTile extends StatelessWidget {
  const _BreakTile({
    required this.slot,
    required this.now,
    required this.dayState,
    required this.onTap,
  });

  final BreakSlot slot;
  final DateTime now;
  final BreakDayState? dayState;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = slot.statusAt(now, completed: slot.isCompleted);

    // "Current" and "Next" emphasises are derived from the day state, not the
    // raw status, so the recommended journey reads clearly.
    final isNow = status == BreakStatus.active;
    final isNext = dayState != null &&
        status == BreakStatus.upcoming &&
        slot.decadeNumber == dayState!.nextToPray?.decadeNumber &&
        dayState!.phase == BreakDayPhase.nextBreak;

    final (label, foreground) = switch (status) {
      BreakStatus.completed => ('Completed', AppColors.success),
      BreakStatus.active => ('Now', AppColors.marianBlue),
      BreakStatus.upcoming => (isNext ? 'Next' : 'Upcoming', AppColors.inkSoft),
      BreakStatus.missed => ('Missed', AppColors.inkMuted),
    };

    final rowColor = isNow
        ? AppColors.marianBlueSoft.withValues(alpha: 0.7)
        : Colors.transparent;

    return Material(
      color: rowColor,
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        leading: _StatusIndicator(status: status),
        title: Text(
          '${_ordinal(slot.decadeNumber)} Decade',
          style: context.textTheme.titleSmall?.copyWith(
            color: isNow ? AppColors.marianBlue : null,
          ),
        ),
        subtitle: Text(
          isNow ? '${slot.time.label} · praying now' : slot.time.label,
          style: context.textTheme.bodySmall?.copyWith(color: foreground),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppPill(
              label: label,
              color: _pillColor(context, status, isNow),
              foregroundColor: _pillForeground(context, status, isNow),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.inkMuted),
            ],
          ],
        ),
      ),
    );
  }

  Color _pillColor(BuildContext context, BreakStatus status, bool isNow) {
    final scheme = Theme.of(context).colorScheme;
    if (isNow) return AppColors.marianBlue;
    if (status == BreakStatus.completed) return AppColors.successSoft;
    return scheme.surfaceContainerHighest;
  }

  Color _pillForeground(BuildContext context, BreakStatus status, bool isNow) {
    final scheme = Theme.of(context).colorScheme;
    if (isNow) return Colors.white;
    if (status == BreakStatus.completed) return AppColors.success;
    return scheme.onSurfaceVariant;
  }

  String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final BreakStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      BreakStatus.completed => (
        Icons.check_circle,
        AppColors.success,
        'Completed',
      ),
      BreakStatus.active => (
        Icons.circle,
        AppColors.marianBlue,
        'Now',
      ),
      BreakStatus.upcoming => (
        Icons.radio_button_unchecked,
        const Color(0xFF8A93A6),
        'Upcoming',
      ),
      BreakStatus.missed => (
        Icons.radio_button_off,
        const Color(0xFF8A93A6),
        'Missed',
      ),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 22, color: color),
    );
  }
}