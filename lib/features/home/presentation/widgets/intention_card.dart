import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

/// Today's prayer intention.
class IntentionCard extends StatelessWidget {
  const IntentionCard({super.key, required this.intention});

  final String intention;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSectionHeader(
            overline: 'Today',
            title: 'Prayer intention',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.favorite_outline, size: 20, color: AppColors.goldDark),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  intention.trim().isEmpty
                      ? 'For peace in our campus community'
                      : intention,
                  style: context.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}