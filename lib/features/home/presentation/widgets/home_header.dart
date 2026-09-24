import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Brand header with the official BEAD5 logo lockup and today's date.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.marianBlueSoft,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1C3D8A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Organizer & Month badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.marianBlueSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/jy-logo black.png',
                            height: 12,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${AppConstants.campaignTitle} • ${AppConstants.campusShortName}',
                            style: const TextStyle(
                              color: AppColors.marianBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Master Wordmark: BEAD5
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.marianBlue,
                    ),
                    children: [
                      TextSpan(text: 'BEAD'),
                      TextSpan(
                        text: '5',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tagline
                const Text(
                  AppConstants.tagline,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          // 5-Bead Journey Motif indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                friendlyMonthDay(today),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              const _FiveBeadsMiniMotif(),
            ],
          ),
        ],
      ),
    );
  }
}

/// A subtle five-bead connected motif: ● — ● — ● — ● — ●
class _FiveBeadsMiniMotif extends StatelessWidget {
  const _FiveBeadsMiniMotif();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BEAD5: Five Moments. One Journey.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warmIvorySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.marianBlueSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isMiddle = index == 2;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMiddle ? 9 : 7,
                  height: isMiddle ? 9 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMiddle ? AppColors.gold : AppColors.marianBlue,
                    boxShadow: [
                      BoxShadow(
                        color: (isMiddle ? AppColors.gold : AppColors.marianBlue)
                            .withValues(alpha: 0.35),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                if (index < 4)
                  Container(
                    width: 5,
                    height: 1.5,
                    color: AppColors.marianBlue.withValues(alpha: 0.3),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}