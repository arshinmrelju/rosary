import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A labelled row: optional overline + title + trailing widget.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    this.overline,
    required this.title,
    this.trailing,
  });

  final String? overline;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (overline != null) ...<Widget>[
                Text(
                  overline!.toUpperCase(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.goldDark,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(title, style: context.textTheme.titleLarge),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}