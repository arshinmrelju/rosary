import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// A short daily reflection.
class ReflectionCard extends StatelessWidget {
  const ReflectionCard({super.key, required this.reflection});

  final String? reflection;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.marianBlueSoft.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.format_quote, size: 28, color: AppColors.marianBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              reflection ?? 'Take a quiet moment today. Even one decade, prayed '
                  'with your whole heart, is a gift to the world.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}