import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';

/// Profile & settings placeholder.
///
/// Guest-first by design: when Firebase is enabled this becomes the personal
/// profile hub. For now it shows app information and the runtime mode.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppContentFrame(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            Text('Profile & Settings', style: context.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xl),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SettingsRow(
                    icon: Icons.person_outline,
                    title: 'Campus Student',
                    subtitle: 'Guest session (no account needed)',
                  ),
                  const Divider(),
                  _SettingsRow(
                    icon: Icons.business_outlined,
                    title: 'Engineering · Year 2',
                    subtitle: 'Profile fields arrive when accounts do',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SettingsLinkRow(
                    icon: Icons.self_improvement,
                    title: 'Your history',
                    subtitle: 'Your Rosary journey, day by day',
                    onTap: () => context.push(AppRoutes.history),
                  ),
                  const Divider(),
                  _SettingsLinkRow(
                    icon: Icons.notifications_outlined,
                    title: 'Reminders',
                    subtitle: 'Daily nudges near each break',
                    onTap: () => context.push(AppRoutes.reminders),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SettingsRow(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle:
                        '${AppConstants.appName} — ${AppConstants.tagline}',
                  ),
                  const Divider(),
                  _SettingsRow(
                    icon: Icons.storage_outlined,
                    title: 'Data mode',
                    subtitle: AppConfig.instance.canUseFirebase
                        ? 'Connected to Firebase'
                        : 'Running with preview (mock) data',
                  ),
                  const Divider(),
                  const _SettingsRow(
                    icon: Icons.favorite_border,
                    title: 'Accessibility',
                    subtitle: 'Large text and screen-reader friendly',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Center(
              child: Text(
                'Version 0.1.0',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SettingsLinkRow extends StatelessWidget {
  const _SettingsLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: AppColors.marianBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: context.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22, color: AppColors.marianBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}