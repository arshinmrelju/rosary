import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/day_stats.dart';

/// Compact "the campus prays together" card on Home.
///
/// Deliberately small — Prayer remains the primary action on Home; this is a
/// quiet link into the community, not the centrepiece.
class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key, required this.stats});

  final DayStats? stats;

  @override
  Widget build(BuildContext context) {
    final decades = stats?.totalDecades ?? 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '🌹 ${AppConstants.campusShortName} PRAYS TOGETHER',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.marianBlue,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (decades == 0)
                  Text(
                    'Be the first to pray today.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: formatThousands(decades),
                          style: context.textTheme.headlineSmall?.copyWith(
                            color: AppColors.goldDark,
                          ),
                        ),
                        TextSpan(
                          text: ' decades\nprayed today.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.intention),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 52),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text('View Prayer Wall'),
          ),
        ],
      ),
    );
  }
}