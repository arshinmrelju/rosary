import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/break_slot.dart';
import '../../../../domain/models/break_status.dart';

/// The five break slots with their current status.
///
/// When [onOpen] is provided the rows become tappable.
class BreakScheduleList extends StatelessWidget {
  const BreakScheduleList({
    super.key,
    required this.slots,
    required this.now,
    this.onOpen,
  });

  final List<BreakSlot> slots;
  final DateTime now;
  final Future<void> Function(int decadeNumber)? onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < slots.length; i++) ...<Widget>[
            _BreakTile(
              slot: slots[i],
              now: now,
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
  const _BreakTile({required this.slot, required this.now, required this.onTap});

  final BreakSlot slot;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = slot.statusAt(now, completed: slot.isCompleted);

    return ListTile(
      enabled: onTap != null,
      onTap: onTap,
      leading: _StatusIcon(status: status),
      title: Text(slot.title, style: context.textTheme.titleSmall),
      subtitle: Text(
        slot.time.label,
        style: context.textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final BreakStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      BreakStatus.completed => (
        Icons.check_circle,
        'Completed',
        const Color(0xFFC9A24B),
      ),
      BreakStatus.active => (
        Icons.radio_button_checked,
        'Now',
        const Color(0xFF1C3D8A),
      ),
      BreakStatus.upcoming => (
        Icons.radio_button_unchecked,
        'Upcoming',
        const Color(0xFF8A93A6),
      ),
      BreakStatus.missed => (
        Icons.radio_button_off,
        'Missed',
        const Color(0xFF8A93A6),
      ),
    };
    return Semantics(
      label: label,
      child: Icon(icon, color: color),
    );
  }
}