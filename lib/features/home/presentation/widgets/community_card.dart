import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/day_stats.dart';

/// Community participation summary from the daily stats.
class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key, required this.stats});

  final DayStats? stats;

  @override
  Widget build(BuildContext context) {
    final participants = stats?.totalParticipants ?? 0;
    final decades = stats?.totalDecades ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Metric(
              icon: Icons.groups_outlined,
              value: '$participants',
              label: 'Students',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE9EDF4),
          ),
          Expanded(
            child: _Metric(
              icon: Icons.self_improvement_outlined,
              value: '$decades',
              label: 'Decades prayed',
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(value, style: context.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}