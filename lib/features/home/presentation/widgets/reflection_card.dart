import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// A short daily reflection. Tapping opens the full Today's Reflection screen.
class ReflectionCard extends StatelessWidget {
  const ReflectionCard({super.key, required this.reflection, this.onTap});

  final String? reflection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.marianBlueSoft.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.format_quote, size: 28, color: AppColors.marianBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Today\'s Reflection',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.marianBlue,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reflection ?? 'Take a quiet moment today. Even one decade, '
                      'prayed with your whole heart, is a gift to the world.',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkSoft,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, size: 20, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}